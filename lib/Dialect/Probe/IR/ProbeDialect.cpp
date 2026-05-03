#include "Dialect/Probe/IR/Probe.h"

using namespace mlir::probe;

#include "Dialect/Probe/IR/ProbeOpsDialect.cpp.inc"

void ProbeDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "Dialect/Probe/IR/ProbeOps.cpp.inc"
      >();
}
