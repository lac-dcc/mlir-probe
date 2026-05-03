#include "Dialect/Probe/IR/Probe.h"
#include "Dialect/Probe/Transforms/Passes.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Support/WalkResult.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"

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

  /// Get short string representation for \p elemTy
  std::string getTypeAsStr(Type elemTy) const {
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

  /// Get probe function for memrefs of \p elemTy
  std::string getProbeFuncName(Type elemTy) const {
    return probeFuncPrefix + getTypeAsStr(elemTy);
  }

  /// Declare the probe function with name \p funcName, if not already present.
  void lookupOrCreateProbeFunc(IRRewriter &rewriter, ModuleOp moduleOp,
                               llvm::StringRef funcName, Type ty) {
    if (probeFuncRegistry.contains(funcName))
      return;

    // Lookup in the module's SymbolTable if not found in local registry
    if (moduleOp.lookupSymbol(funcName))
      return;

    probeFuncRegistry.insert(funcName);

    auto ctx = moduleOp.getContext();
    auto tensorType = UnrankedMemRefType::get(ty, kDefaultMemorySpace);
    auto i32Type = IntegerType::get(ctx, 32);
    auto funcType = FunctionType::get(ctx, {tensorType, i32Type, i32Type}, {});
    rewriter.setInsertionPointToStart(moduleOp.getBody());
    auto probeFunc =
        rewriter.create<func::FuncOp>(moduleOp.getLoc(), funcName, funcType);

    // Mark as private declaration, since it will be linked externally
    probeFunc.setPrivate();
  }

public:
  using Base::Base;

  /// Lower probe ops in \p funcOp, assuming it is part of \p moduleOp
  void runOnFunction(ModuleOp moduleOp, func::FuncOp funcOp) {
    std::vector<ObserveOp> observeOps;
    auto result =
        funcOp.walk(
            [&](ObserveOp op) {
              if (!llvm::isa<MemRefType>(op.getInput().getType())) {
                op.emitError()
                    << "Expected ranked memref type for probe function call.";
                return WalkResult::interrupt();
              }
              observeOps.push_back(op);
              return WalkResult::advance();
            });
    if (result.wasInterrupted()) {
      return signalPassFailure();
    }

    IRRewriter rewriter(&getContext());
    for (auto observeOp : observeOps) {
      auto input = observeOp.getInput();
      auto inTy = llvm::cast<MemRefType>(input.getType());
      auto elemTy = inTy.getElementType();

      // Lookup probe function name, and add declaration if needed
      auto probeFuncName = getProbeFuncName(elemTy);
      lookupOrCreateProbeFunc(rewriter, moduleOp, probeFuncName, elemTy);

      rewriter.setInsertionPoint(observeOp);
      auto loc = observeOp.getLoc();
      // Cast to unranked
      auto unrankedInput = rewriter.create<memref::CastOp>(
          loc,
          UnrankedMemRefType::get(inTy.getElementType(), kDefaultMemorySpace),
          input);

      // Materialize constants for opID and resultID
      Value opIDVal =
          rewriter.create<arith::ConstantOp>(loc, observeOp.getOpIDAttr());
      Value resultIDVal =
          rewriter.create<arith::ConstantOp>(loc, observeOp.getResultIDAttr());

      // Insert the call
      rewriter.replaceOpWithNewOp<func::CallOp>(
          observeOp, probeFuncName, TypeRange{},
          ValueRange{unrankedInput, opIDVal, resultIDVal});
    }
  }

  void runOnOperation() override {
    auto M = getOperation();
    for (auto F : M.getOps<func::FuncOp>()) {
      runOnFunction(M, F);
    }
  }
};
} // namespace
} // namespace mlir::probe
