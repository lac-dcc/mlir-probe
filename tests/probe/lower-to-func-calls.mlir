// RUN: probe-opt --probe-lower-to-func-calls %s | FileCheck --check-prefixes="CHECK,DEFAULT" %s
// RUN: probe-opt --probe-lower-to-func-calls="observe-func-prefix=inspect report-func-name=flush" %s | FileCheck --check-prefixes="CHECK,CUSTOM" %s

// DEFAULT-LABEL: func.func private @probeObserveMemrefI64(memref<*xi64>, i32, i32)
// DEFAULT-LABEL: func.func private @probeObserveMemrefU16(memref<*xui16>, i32, i32)
// DEFAULT-LABEL: func.func private @probeObserveMemrefS8(memref<*xsi8>, i32, i32)
// DEFAULT-LABEL: func.func private @probeReport()
// DEFAULT-LABEL: func.func private @probeObserveMemrefF32(memref<*xf32>, i32, i32)

// CUSTOM-LABEL: func.func private @inspectI64(memref<*xi64>, i32, i32)
// CUSTOM-LABEL: func.func private @inspectU16(memref<*xui16>, i32, i32)
// CUSTOM-LABEL: func.func private @inspectS8(memref<*xsi8>, i32, i32)
// CUSTOM-LABEL: func.func private @flush()
// CUSTOM-LABEL: func.func private @inspectF32(memref<*xf32>, i32, i32)

func.func @float(%arg0: memref<1x2x3x4xf32>, %arg1: memref<1x2x3x4xf32>) -> memref<1x2x3x4xf32> {
  %out = memref.alloc() {alignment = 64 : i64} : memref<1x2x3x4xf32>
  linalg.add ins(%arg0, %arg1 : memref<1x2x3x4xf32>, memref<1x2x3x4xf32>) outs(%out : memref<1x2x3x4xf32>)
  probe.observe(%out: memref<1x2x3x4xf32>) {opID = 0 : i32, resultID = 0 : i32}
  probe.report()
  return %out : memref<1x2x3x4xf32>
}
// CHECK-LABEL:   func.func @float
// CHECK:           %[[ALLOC:.*]] = memref.alloc()
// CHECK:           linalg.add
// CHECK:           %[[CAST:.*]] = memref.cast %[[ALLOC]]
// CHECK:           %[[OP_ID:.*]] = arith.constant 0
// CHECK:           %[[RES_ID:.*]] = arith.constant 0
// DEFAULT-NEXT:    call @probeObserveMemrefF32(%[[CAST]], %[[OP_ID]], %[[RES_ID]])
// CUSTOM-NEXT:     call @inspectF32(%[[CAST]], %[[OP_ID]], %[[RES_ID]])
// DEFAULT-NEXT:    call @probeReport()
// CUSTOM-NEXT:     call @flush()
// CHECK-NEXT:      return

func.func @multiple_types(%arg0: memref<1x2xf32>, %arg1: memref<3x4xsi8>, %arg2: memref<5x6xui16>, %arg3: memref<100xi64>) {
  probe.observe(%arg0: memref<1x2xf32>) {opID = 0 : i32, resultID = 0 : i32}
  probe.observe(%arg1: memref<3x4xsi8>) {opID = 0 : i32, resultID = 1 : i32}
  probe.observe(%arg2: memref<5x6xui16>) {opID = 0 : i32, resultID = 2 : i32}
  probe.observe(%arg3: memref<100xi64>) {opID = 0 : i32, resultID = 3 : i32}
  probe.report()
  return
}
// CHECK-LABEL:   func.func @multiple_types(
// CHECK-SAME:        %[[ARG0:arg[0-9]+]]: memref<1x2xf32>,
// CHECK-SAME:        %[[ARG1:arg[0-9]+]]: memref<3x4xsi8>,
// CHECK-SAME:        %[[ARG2:arg[0-9]+]]: memref<5x6xui16>,
// CHECK-SAME:        %[[ARG3:arg[0-9]+]]: memref<100xi64>)
// CHECK:           %[[CAST_F32:.*]] = memref.cast %[[ARG0]]
// CHECK:           %[[OP_ID_F32:.*]] = arith.constant 0
// CHECK:           %[[RES_ID_F32:.*]] = arith.constant 0
// DEFAULT-NEXT:    call @probeObserveMemrefF32(%[[CAST_F32]], %[[OP_ID_F32]], %[[RES_ID_F32]])
// CUSTOM-NEXT:     call @inspectF32(%[[CAST_F32]], %[[OP_ID_F32]], %[[RES_ID_F32]])
// CHECK:           %[[CAST_S8:.*]] = memref.cast %[[ARG1]]
// CHECK:           %[[OP_ID_S8:.*]] = arith.constant 0
// CHECK:           %[[RES_ID_S8:.*]] = arith.constant 1
// DEFAULT-NEXT:    call @probeObserveMemrefS8(%[[CAST_S8]], %[[OP_ID_S8]], %[[RES_ID_S8]])
// CUSTOM-NEXT:     call @inspectS8(%[[CAST_S8]], %[[OP_ID_S8]], %[[RES_ID_S8]])
// CHECK:           %[[CAST_U16:.*]] = memref.cast %[[ARG2]]
// CHECK:           %[[OP_ID_U16:.*]] = arith.constant 0
// CHECK:           %[[RES_ID_U16:.*]] = arith.constant 2
// DEFAULT-NEXT:    call @probeObserveMemrefU16(%[[CAST_U16]], %[[OP_ID_U16]], %[[RES_ID_U16]])
// CUSTOM-NEXT:     call @inspectU16(%[[CAST_U16]], %[[OP_ID_U16]], %[[RES_ID_U16]])
// CHECK:           %[[CAST_I64:.*]] = memref.cast %[[ARG3]]
// CHECK:           %[[OP_ID_I64:.*]] = arith.constant 0
// CHECK:           %[[RES_ID_I64:.*]] = arith.constant 3
// DEFAULT-NEXT:    call @probeObserveMemrefI64(%[[CAST_I64]], %[[OP_ID_I64]], %[[RES_ID_I64]])
// CUSTOM-NEXT:     call @inspectI64(%[[CAST_I64]], %[[OP_ID_I64]], %[[RES_ID_I64]])
// DEFAULT-NEXT:    call @probeReport()
// CUSTOM-NEXT:     call @flush()
// CHECK-NEXT:      return
