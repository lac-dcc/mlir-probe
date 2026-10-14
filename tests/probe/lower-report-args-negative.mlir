// RUN: probe-opt --probe-lower-to-func-calls --split-input-file --verify-diagnostics %s

// Only string, integer and float report arguments can be materialized.
func.func @unsupported_arg() {
  // expected-error@+1 {{Unsupported reportArgs attribute}}
  probe.report() {reportArgs = [1 : i32, dense<42.0> : tensor<10xf32>]}
  return
}

// -----

// All report ops share a single report function, so their argument
// signatures must agree.
func.func @mismatching_args() {
  probe.report() {reportArgs = ["a.csv"]}
  // expected-error@+1 {{Report function 'probeReport' already declared with type '(!llvm.ptr) -> ()', but reportArgs require type '(!llvm.ptr, i32) -> ()'}}
  probe.report() {reportArgs = ["a.csv", 1 : i32]}
  return
}
