#ifndef PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD
#define PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD

include "mlir/Pass/PassBase.td"

def LowerToFuncCallsPass
    : Pass<"probe-lower-to-func-calls", "mlir::ModuleOp"> {
  let summary = "Convert probe ops to function calls";
  let dependentDialects = ["mlir::memref::MemRefDialect"];
    let options = [
    Option<
      "probeFuncPrefix",
      "probe-func-prefix",
      "std::string",
      /*default=*/"\"probeMemref\"",
      "Prefix used for the name of the probe function (default: probeMemref)."
    >
  ];
}

#endif // PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD
