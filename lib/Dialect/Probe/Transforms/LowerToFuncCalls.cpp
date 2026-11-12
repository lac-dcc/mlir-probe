#include "Dialect/Probe/IR/Probe.h"
#include "Dialect/Probe/Transforms/Passes.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Support/WalkResult.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"
#include <cstdint>
#include <string>
#include <vector>

namespace mlir::probe {
#define GEN_PASS_DEF_LOWERTOFUNCCALLSPASS
#include "Dialect/Probe/Transforms/Passes.h.inc"

namespace {
class LowerToFuncCallsPass
    : public impl::LowerToFuncCallsPassBase<LowerToFuncCallsPass> {
private:
  /// Memory space for creating memref types
  static constexpr unsigned kDefaultMemorySpace = 0;

  /// Local registry of declared probe functions
  llvm::StringSet<> probeFuncRegistry;

  /// Cache of null-terminated string globals created for report arguments,
  /// keyed by their contents. Each global is a constant `!llvm.array` of i8
  /// and is passed to the report function as `!llvm.ptr` (`const char *`).
  llvm::StringMap<LLVM::GlobalOp> stringGlobalRegistry;

  /// Get short string representation for \p elemTy
  static inline std::string getTypeAsStr(Type elemTy) {
    bool isFloat = elemTy.isFloat();
    bool isSignlessInt = elemTy.isSignlessInteger();
    bool isSignedInt = elemTy.isSignedInteger();
    // Treat signless as unsigned.
    std::string typePrefix =
        isFloat ? "F" : (isSignlessInt ? "I" : (isSignedInt ? "S" : "U"));

    switch (elemTy.getIntOrFloatBitWidth()) {
    case 8:
      return typePrefix + "8";
    case 16:
      return typePrefix + "16";
    case 32:
      return typePrefix + "32";
    case 64:
      return typePrefix + "64";
    default:
      llvm_unreachable("Unsupported element type bit width");
    }
  }

  /// Get observe function for memrefs of \p elemTy
  std::string getObserveFuncName(Type elemTy) const {
    return observeFuncPrefix + getTypeAsStr(elemTy);
  }

  /// Get function type for observe function for memref os \p elemTy
  static inline FunctionType getObserveFuncType(MLIRContext *ctx, Type elemTy) {
    auto tensorType = UnrankedMemRefType::get(elemTy, kDefaultMemorySpace);
    auto i32Type = IntegerType::get(ctx, 32);
    return FunctionType::get(ctx, {tensorType, i32Type, i32Type}, {});
  }

  /// Declare a probe function with name \p funcName, if not already present
  /// in \p moduleOp
  void lookupOrCreateProbeFunc(IRRewriter &rewriter, ModuleOp moduleOp,
                               llvm::StringRef funcName, FunctionType funcTy) {
    if (probeFuncRegistry.contains(funcName))
      return;

    // Lookup in the module's SymbolTable if not found in local registry
    if (moduleOp.lookupSymbol(funcName))
      return;

    probeFuncRegistry.insert(funcName);

    rewriter.setInsertionPointToStart(moduleOp.getBody());
    auto probeFunc =
        func::FuncOp::create(rewriter, moduleOp.getLoc(), funcName, funcTy);

    // Mark as private declaration, since it will be linked externally
    probeFunc.setPrivate();
  }

  /// Lower probe.observe ops in \p funcOp
  void lowerObserveOps(ModuleOp moduleOp, func::FuncOp funcOp) {
    std::vector<ObserveOp> observeOps;
    auto result =
        funcOp.walk(
            [&](ObserveOp op) {
              if (!llvm::isa<MemRefType>(op.getInput().getType())) {
                op.emitError()
                    << "Expected ranked memref type for observe function call.";
                return WalkResult::interrupt();
              }
              observeOps.push_back(op);
              return WalkResult::advance();
            });
    if (result.wasInterrupted()) {
      return signalPassFailure();
    }

    auto *ctx = &getContext();
    IRRewriter rewriter(ctx);
    for (auto observeOp : observeOps) {
      auto input = observeOp.getInput();
      auto inTy = llvm::cast<MemRefType>(input.getType());
      auto elemTy = inTy.getElementType();

      // Lookup probe function name, and add declaration if needed
      auto probeFuncName = getObserveFuncName(elemTy);
      auto probeFuncTy = getObserveFuncType(ctx, elemTy);
      lookupOrCreateProbeFunc(rewriter, moduleOp, probeFuncName, probeFuncTy);

      rewriter.setInsertionPoint(observeOp);
      auto loc = observeOp.getLoc();
      // Cast to unranked
      auto unrankedInput = memref::CastOp::create(
          rewriter, loc,
          UnrankedMemRefType::get(inTy.getElementType(), kDefaultMemorySpace),
          input);

      // Materialize constants for opID and resultID
      Value opIDVal =
          arith::ConstantOp::create(rewriter, loc, observeOp.getOpIDAttr());
      Value resultIDVal =
          arith::ConstantOp::create(rewriter, loc, observeOp.getResultIDAttr());

      // Insert the call
      rewriter.replaceOpWithNewOp<func::CallOp>(
          observeOp, probeFuncName, TypeRange{},
          ValueRange{unrankedInput, opIDVal, resultIDVal});
    }
  }

  /// Get (or create at the start of \p moduleOp) a private constant
  /// llvm.mlir.global holding the null-terminated bytes of \p str.
  LLVM::GlobalOp lookupOrCreateStringGlobal(IRRewriter &rewriter,
                                            ModuleOp moduleOp,
                                            llvm::StringRef str) {
    std::string bytes = str.str();
    bytes.push_back('\0');

    auto it = stringGlobalRegistry.find(bytes);
    if (it != stringGlobalRegistry.end())
      return it->second;

    // Pick a unique symbol name.
    std::string symName;
    unsigned i = stringGlobalRegistry.size();
    do {
      symName = (llvm::Twine("__probe_report_arg_") + llvm::Twine(i++)).str();
    } while (moduleOp.lookupSymbol(symName));

    auto *ctx = rewriter.getContext();
    auto arrayTy =
        LLVM::LLVMArrayType::get(IntegerType::get(ctx, 8), bytes.size());

    OpBuilder::InsertionGuard guard(rewriter);
    rewriter.setInsertionPointToStart(moduleOp.getBody());
    auto globalOp = LLVM::GlobalOp::create(
        rewriter, moduleOp.getLoc(), arrayTy, /*isConstant=*/true,
        LLVM::Linkage::Private, symName, rewriter.getStringAttr(bytes),
        /*alignment=*/0);

    stringGlobalRegistry[bytes] = globalOp;
    return globalOp;
  }

  /// Materialize report argument \p attr as an SSA value at the current
  /// insertion point of \p rewriter. String attributes become `!llvm.ptr`
  /// values addressing a null-terminated global constant (the C ABI for
  /// `const char *`); integer and float attributes become scalar constants.
  /// Returns failure() for unsupported attributes.
  FailureOr<Value> materializeReportArg(IRRewriter &rewriter, ModuleOp moduleOp,
                                        Location loc, Attribute attr) {
    if (auto strAttr = llvm::dyn_cast<StringAttr>(attr)) {
      auto globalOp =
          lookupOrCreateStringGlobal(rewriter, moduleOp, strAttr.getValue());
      // Decay the array global to a pointer to its first byte, matching
      // LLVM::createGlobalString. Opaque pointers make this a no-op address,
      // and the C wrapper passes the resulting !llvm.ptr as const char *.
      Value globalPtr =
          LLVM::AddressOfOp::create(rewriter, loc, globalOp).getResult();
      auto ptrType = LLVM::LLVMPointerType::get(rewriter.getContext());
      return LLVM::GEPOp::create(rewriter, loc, ptrType, globalOp.getType(),
                                 globalPtr, llvm::ArrayRef<LLVM::GEPArg>{0, 0})
          .getResult();
    }

    if (llvm::isa<IntegerAttr, FloatAttr>(attr))
      return arith::ConstantOp::create(rewriter, loc,
                                       llvm::cast<TypedAttr>(attr))
          .getResult();

    return failure();
  }

  /// Lower probe.report ops in \p funcOp
  void lowerReportOps(ModuleOp moduleOp, func::FuncOp funcOp) {
    std::vector<ReportOp> reportOps;
    funcOp->walk([&](ReportOp op) { reportOps.push_back(op); });

    auto *ctx = &getContext();
    IRRewriter rewriter(ctx);

    for (auto reportOp : reportOps) {
      rewriter.setInsertionPoint(reportOp);
      auto loc = reportOp.getLoc();

      // Materialize report arguments, if any.
      llvm::SmallVector<Value> args;
      if (auto reportArgs = reportOp.getReportArgs()) {
        for (Attribute attr : *reportArgs) {
          auto argOrFailure =
              materializeReportArg(rewriter, moduleOp, loc, attr);
          if (failed(argOrFailure)) {
            reportOp.emitError()
                << "Unsupported reportArgs attribute: " << attr;
            return signalPassFailure();
          }
          args.push_back(*argOrFailure);
        }
      }

      // All report ops share one callee, so their argument signatures must
      // agree.
      auto funcTy =
          FunctionType::get(ctx, TypeRange(ValueRange(args)), TypeRange{});
      if (auto existingFunc =
              moduleOp.lookupSymbol<func::FuncOp>(reportFuncName.getValue())) {
        if (existingFunc.getFunctionType() != funcTy) {
          reportOp.emitError() << "Report function '" << reportFuncName
                               << "' already declared with type "
                               << existingFunc.getFunctionType()
                               << ", but reportArgs require type " << funcTy;
          return signalPassFailure();
        }
      } else {
        lookupOrCreateProbeFunc(rewriter, moduleOp, reportFuncName, funcTy);
        rewriter.setInsertionPoint(reportOp);
      }

      rewriter.replaceOpWithNewOp<func::CallOp>(reportOp, reportFuncName,
                                                TypeRange{}, args);
    }
  }

  /// Lower probe ops in \p funcOp, assuming it is part of \p moduleOp
  void runOnFunction(ModuleOp moduleOp, func::FuncOp funcOp) {
    lowerObserveOps(moduleOp, funcOp);
    lowerReportOps(moduleOp, funcOp);
  }

public:
  using Base::Base;

  void runOnOperation() override {
    auto M = getOperation();
    for (auto F : M.getOps<func::FuncOp>()) {
      runOnFunction(M, F);
    }
  }
};
} // namespace
} // namespace mlir::probe
