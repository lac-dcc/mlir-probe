// RUN: probe-opt --verify-diagnostics %s

func.func @invalid_type(%arg: vector<1x2x3x4xf32>) {
  // expected-error@+1 {{operand #0 must be memref of any type values or ranked tensor of any type values, but got 'vector<1x2x3x4xf32>'}}
  probe.observe(%arg: vector<1x2x3x4xf32>) {opID = 0 : i32, resultID = 0 : i32}
  return
}

func.func @invalid_elem_type(%arg: tensor<1x2x3x4xindex>) {
  // expected-error@+1 {{Invalid input element type. Expected integer or float, but got 'index'}}
  probe.observe(%arg: tensor<1x2x3x4xindex>) {opID = 0 : i32, resultID = 0 : i32}
  return
}
