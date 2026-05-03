// RUN:   probe-opt %s                                                             \
// RUN:      --pass-pipeline="builtin.module(                                      \
// RUN:                         one-shot-bufferize{bufferize-function-boundaries}, \
// RUN:                         probe-lower-to-func-calls,                         \
// RUN:                         finalize-memref-to-llvm,                           \
// RUN:                         convert-arith-to-llvm,                             \
// RUN:                         func.func(llvm-request-c-wrappers),                \
// RUN:                         convert-func-to-llvm,                              \
// RUN:                         reconcile-unrealized-casts,                        \
// RUN:                         func.func(canonicalize,cse)                        \
// RUN:                      )"                                                    \
// RUN: | mlir-runner -e foo -entry-point-result=void --shared-libs=%example_dir/libProbeExample.so \
// RUN: | FileCheck %s

func.func @foo() {
  %c0 = arith.constant dense<1.> : tensor<100xf32>
  probe.observe(%c0: tensor<100xf32>) {opID = 0 : i32, resultID = 0 : i32}
  %c1 = arith.constant dense<-1.> : tensor<100xf32>
  probe.observe(%c1: tensor<100xf32>) {opID = 1 : i32, resultID = 0 : i32}
  %c2 = arith.constant dense<[[1., 2.], [9., 8.]]> : tensor<2x2xf32>
  probe.observe(%c2: tensor<2x2xf32>) {opID = 2 : i32, resultID = 0 : i32}
  return
}
// CHECK: opID: 0, resultID: 0, sum: 100
// CHECK: opID: 1, resultID: 0, sum: -100
// CHECK: opID: 2, resultID: 0, sum: 20
