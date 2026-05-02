#include "Dialect/Probe/IR/Probe.h"

#define GET_OP_CLASSES
#include "Dialect/Probe/IR/ProbeOps.cpp.inc"

namespace mlir::probe {
LogicalResult ObserveOp::verify() {
  auto inTy = getInput().getType();
  Type elemTy;
  if (auto memrefTy = llvm::dyn_cast<BaseMemRefType>(inTy)) {
    elemTy = memrefTy.getElementType();
  } else if (auto tensorTy = llvm::dyn_cast<TensorType>(inTy)) {
    elemTy = tensorTy.getElementType();
  } else {
    return emitOpError(
               "Invalid input type. Expected memref or tensor, but got ")
           << inTy;
  }

  if (!elemTy.isIntOrFloat()) {
    return emitOpError("Invalid input element type. Expected integer or float, "
                       "but got ")
           << elemTy;
  }

  return success();
}
} // namespace mlir::probe
