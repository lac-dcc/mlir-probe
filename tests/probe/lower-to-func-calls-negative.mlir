// RUN: probe-opt --probe-lower-to-func-calls --verify-diagnostics %s

func.func @tensor_type(%arg0: tensor<1x2x3x4xf32>) {
  // expected-error@+1 {{Expected ranked memref type for probe function call}}
  probe.observe(%arg0: tensor<1x2x3x4xf32>) {opID = 0 : i32, resultID = 0 : i32}
  return
}
