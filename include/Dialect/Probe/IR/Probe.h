#ifndef PROBE_INCLUDE_DIALECT_PROBE_IR_PROBE_H
#define PROBE_INCLUDE_DIALECT_PROBE_IR_PROBE_H

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/Dialect/Bufferization/IR/BufferizableOpInterface.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "Dialect/Probe/IR/ProbeOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "Dialect/Probe/IR/ProbeOps.h.inc"

#endif // PROBE_INCLUDE_DIALECT_PROBE_IR_PROBE_H
