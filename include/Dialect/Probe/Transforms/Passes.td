#ifndef PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD
#define PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD

include "mlir/Pass/PassBase.td"

def LowerToFuncCallsPass
    : Pass<"probe-lower-to-func-calls", "mlir::ModuleOp"> {
  let summary = "Convert probe ops to function calls";
  let dependentDialects = ["mlir::memref::MemRefDialect"];
    let options = [
    Option<
      "observeFuncPrefix",
      "observe-func-prefix",
      "std::string",
      /*default=*/"\"probeObserveMemref\"",
      "Prefix used for the name of the 'observe' function (default: probeObserveMemref)."
    >,
    Option<
      "reportFuncName",
      "report-func-name",
      "std::string",
      /*default=*/"\"probeReport\"",
      "Name used for the 'report' function (default: probeReport)."
    >
  ];
}

#endif // PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_TD
