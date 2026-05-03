#ifndef PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEBASE_TD
#define PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEBASE_TD

include "mlir/IR/DialectBase.td"

def Probe_Dialect : Dialect {
    let name = "probe";
    let summary = "Dialect for observing runtime values for MLIR tensors";
    let cppNamespace = "::mlir::probe";
}

#endif // PROBE_INCLUDE_DIALECT_PROBE_IR_PROBEBASE_TD
