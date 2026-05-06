// RUN: probe-opt --one-shot-bufferize="bufferize-function-boundaries" --canonicalize %s | FileCheck %s

func.func @no_results(%arg0: tensor<1x2xf32>, %arg1: tensor<3x4x5xui16>) {
  probe.observe(%arg0: tensor<1x2xf32>) {opID = 0 : i32, resultID = 0 : i32}
  probe.observe(%arg1: tensor<3x4x5xui16>) {opID = 0 : i32, resultID = 1 : i32}
  probe.report()
  return
}
// CHECK-LABEL: func.func @no_results(
// CHECK-SAME:      %[[ARG0:arg[0-9]+]]: memref<1x2xf32{{.*}}>,
// CHECK-SAME:      %[[ARG1:arg[0-9]+]]: memref<3x4x5xui16{{.*}}>)
// CHECK-NEXT:    probe.observe(%[[ARG0]] : memref<1x2xf32
// CHECK-SAME:      {opID = 0 : i32, resultID = 0 : i32}
// CHECK-NEXT:    probe.observe(%[[ARG1]] : memref<3x4x5xui16
// CHECK-SAME:      {opID = 0 : i32, resultID = 1 : i32}
// CHECK-NEXT:    probe.report
// CHECK-NEXT:    return

func.func @with_result(%arg0: tensor<1x2x3x4xf32>, %arg1: tensor<1x2x3x4xf32>) -> tensor<1x2x3x4xf32> {
  %out = tensor.empty() : tensor<1x2x3x4xf32>
  %res = linalg.add ins(%arg0, %arg1 : tensor<1x2x3x4xf32>, tensor<1x2x3x4xf32>) outs(%out : tensor<1x2x3x4xf32>) -> tensor<1x2x3x4xf32>
  probe.observe(%res: tensor<1x2x3x4xf32>) {opID = 0 : i32, resultID = 0 : i32}
  probe.report()
  return %res : tensor<1x2x3x4xf32>
}
// CHECK-LABEL: func.func @with_result(
// CHECK-SAME:      %[[ARG0:arg[0-9]+]]: memref<1x2x3x4xf32{{.*}}>,
// CHECK-SAME:      %[[ARG1:arg[0-9]+]]: memref<1x2x3x4xf32{{.*}}>)
// CHECK-NEXT:    %[[ALLOC:.*]] = memref.alloc
// CHECK-NEXT:    linalg.add
// CHECK-NEXT:    probe.observe(%[[ALLOC]] : memref<1x2x3x4xf32
// CHECK-SAME:      {opID = 0 : i32, resultID = 0 : i32}
// CHECK-NEXT:    probe.report
// CHECK-NEXT:    return %[[ALLOC]]
