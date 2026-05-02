// RUN: probe-opt --probe-lower-to-func-calls %s | FileCheck %s

// CHECK-LABEL: func.func private @probeMemrefI64(memref<*xi64>, i32, i32)
// CHECK-LABEL: func.func private @probeMemrefU16(memref<*xui16>, i32, i32)
// CHECK-LABEL: func.func private @probeMemrefS8(memref<*xsi8>, i32, i32)
// CHECK-LABEL: func.func private @probeMemrefF32(memref<*xf32>, i32, i32)

func.func @float(%arg0: memref<1x2x3x4xf32>, %arg1: memref<1x2x3x4xf32>) -> memref<1x2x3x4xf32> {
  %out = memref.alloc() {alignment = 64 : i64} : memref<1x2x3x4xf32>
  linalg.add ins(%arg0, %arg1 : memref<1x2x3x4xf32>, memref<1x2x3x4xf32>) outs(%out : memref<1x2x3x4xf32>)
  probe.observe(%out: memref<1x2x3x4xf32>) {opID = 0 : i32, resultID = 0 : i32}
  return %out : memref<1x2x3x4xf32>
}
// CHECK-LABEL: func.func @float
// CHECK:         %[[ALLOC:.*]] = memref.alloc()
// CHECK:         linalg.add
// CHECK:         %[[CAST:.*]] = memref.cast %[[ALLOC]]
// CHECK:         %[[OP_ID:.*]] = arith.constant 0
// CHECK:         %[[RES_ID:.*]] = arith.constant 0
// CHECK-NEXT:    call @probeMemrefF32(%[[CAST]], %[[OP_ID]], %[[RES_ID]])
// CHECK-NEXT:    return

func.func @multiple_types(%arg0: memref<1x2xf32>, %arg1: memref<3x4xsi8>, %arg2: memref<5x6xui16>, %arg3: memref<100xi64>) {
  probe.observe(%arg0: memref<1x2xf32>) {opID = 0 : i32, resultID = 0 : i32}
  probe.observe(%arg1: memref<3x4xsi8>) {opID = 0 : i32, resultID = 1 : i32}
  probe.observe(%arg2: memref<5x6xui16>) {opID = 0 : i32, resultID = 2 : i32}
  probe.observe(%arg3: memref<100xi64>) {opID = 0 : i32, resultID = 3 : i32}
  return
}
// CHECK-LABEL: func.func @multiple_types(
// CHECK-SAME:      %[[ARG0:arg[0-9]+]]: memref<1x2xf32>,
// CHECK-SAME:      %[[ARG1:arg[0-9]+]]: memref<3x4xsi8>,
// CHECK-SAME:      %[[ARG2:arg[0-9]+]]: memref<5x6xui16>,
// CHECK-SAME:      %[[ARG3:arg[0-9]+]]: memref<100xi64>)
// CHECK:         %[[CAST_F32:.*]] = memref.cast %[[ARG0]]
// CHECK:         %[[OP_ID_F32:.*]] = arith.constant 0
// CHECK:         %[[RES_ID_F32:.*]] = arith.constant 0
// CHECK-NEXT:    call @probeMemrefF32(%[[CAST_F32]], %[[OP_ID_F32]], %[[RES_ID_F32]])
// CHECK:         %[[CAST_S8:.*]] = memref.cast %[[ARG1]]
// CHECK:         %[[OP_ID_S8:.*]] = arith.constant 0
// CHECK:         %[[RES_ID_S8:.*]] = arith.constant 1
// CHECK-NEXT:    call @probeMemrefS8(%[[CAST_S8]], %[[OP_ID_S8]], %[[RES_ID_S8]])
// CHECK:         %[[CAST_U16:.*]] = memref.cast %[[ARG2]]
// CHECK:         %[[OP_ID_U16:.*]] = arith.constant 0
// CHECK:         %[[RES_ID_U16:.*]] = arith.constant 2
// CHECK-NEXT:    call @probeMemrefU16(%[[CAST_U16]], %[[OP_ID_U16]], %[[RES_ID_U16]])
// CHECK:         %[[CAST_I64:.*]] = memref.cast %[[ARG3]]
// CHECK:         %[[OP_ID_I64:.*]] = arith.constant 0
// CHECK:         %[[RES_ID_I64:.*]] = arith.constant 3
// CHECK-NEXT:    call @probeMemrefI64(%[[CAST_I64]], %[[OP_ID_I64]], %[[RES_ID_I64]])
// CHECK-NEXT:    return
