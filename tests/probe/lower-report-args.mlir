// RUN: probe-opt --probe-lower-to-func-calls %s | FileCheck %s

// String report arguments are materialized as null-terminated LLVM globals and
// passed as !llvm.ptr (the C ABI for const char *); integer and float
// arguments become scalar constants. The report function declaration is
// derived from the argument types.

// CHECK-DAG: func.func private @probeReport(!llvm.ptr, i32)
// "my_report.csv" plus a null terminator.
// CHECK-DAG: llvm.mlir.global private constant @__probe_report_arg_0("my_report.csv\00") {addr_space = 0 : i32}

func.func @report_with_args() {
  probe.report() {reportArgs = ["my_report.csv", 42 : i32]}
  return
}
// CHECK-LABEL: func.func @report_with_args
// CHECK:         %[[ADDR:.*]] = llvm.mlir.addressof @__probe_report_arg_0 : !llvm.ptr
// CHECK:         %[[STR:.*]] = llvm.getelementptr %[[ADDR]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<14 x i8>
// CHECK:         %[[C42:.*]] = arith.constant 42 : i32
// CHECK-NEXT:    call @probeReport(%[[STR]], %[[C42]]) : (!llvm.ptr, i32) -> ()
// CHECK-NEXT:    return

// The string global is shared between report ops with identical contents.
func.func @shared_global() {
  probe.report() {reportArgs = ["my_report.csv", 7 : i32]}
  return
}
// CHECK-LABEL: func.func @shared_global
// CHECK:         %[[ADDR:.*]] = llvm.mlir.addressof @__probe_report_arg_0 : !llvm.ptr
// CHECK:         %[[STR:.*]] = llvm.getelementptr %[[ADDR]][0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.array<14 x i8>
// CHECK:         %[[C7:.*]] = arith.constant 7 : i32
// CHECK-NEXT:    call @probeReport(%[[STR]], %[[C7]]) : (!llvm.ptr, i32) -> ()
// CHECK-NEXT:    return
