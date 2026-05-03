#ifndef PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEOPS_TD
#define PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEOPS_TD

include "ProbeBase.td"
include "mlir/Dialect/Bufferization/IR/BufferizableOpInterface.td"
include "mlir/IR/OpBase.td"
include "mlir/IR/CommonTypeConstraints.td"

class Probe_Op<string mnemonic, list<Trait> traits = []>
    : Op<Probe_Dialect, mnemonic, traits>;

def Probe_ObserveOp: Probe_Op<"observe", [
    DeclareOpInterfaceMethods<BufferizableOpInterface, [
      "bufferizesToMemoryRead",
      "bufferizesToMemoryWrite",
      "getAliasingValues",
      "bufferize"
    ]>]> {
  let summary = "Observe runtime values for an ND tensor";
  let description = [{
    Operation that observes runtime values of ND tensors at runtime. This
    operation is lowered to a function call to a runtime library function,
    which can apply any kind of side-effect-free probing.
  }];
  let hasVerifier = 1;

  let arguments = (ins
      AnyTypeOf<[AnyMemRef, AnyRankedTensor]>:$input,
      I32Attr:$opID,
      I32Attr:$resultID
  );
  let results = (outs);

  let assemblyFormat = [{
    `(` $input `:` type($input) `)` attr-dict
  }];

  // Explicitly implement bufferization
  let extraClassDefinition = [{
    bool ObserveOp::bufferizesToMemoryRead(
        ::mlir::OpOperand &operand,
        const ::mlir::bufferization::AnalysisState &state) {
      return true;
    }

    bool ObserveOp::bufferizesToMemoryWrite(
        ::mlir::OpOperand &operand,
        const ::mlir::bufferization::AnalysisState &state) {
      return false;
    }

    ::mlir::bufferization::AliasingValueList
    ObserveOp::getAliasingValues(
        ::mlir::OpOperand &opOperand,
        const ::mlir::bufferization::AnalysisState &state) {
      return {};
    }

    llvm::LogicalResult
    ObserveOp::bufferize(
        ::mlir::RewriterBase &rewriter,
        const ::mlir::bufferization::BufferizationOptions &options,
        ::mlir::bufferization::BufferizationState &state) {
      auto inputBufferOrFailure =
          ::mlir::bufferization::getBuffer(rewriter, getInput(), options, state);
      if (failed(inputBufferOrFailure))
        return llvm::failure();

      auto tensorOp = getOperation();
      auto memrefOp = rewriter.create<ObserveOp>(
          getLoc(), *inputBufferOrFailure, getOpIDAttr(), getResultIDAttr());
      memrefOp->setAttrs(tensorOp->getAttrs());
      rewriter.replaceOp(tensorOp, memrefOp);
      return llvm::success();
    }
  }];
}

#endif // PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEOPS_TD
