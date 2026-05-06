#include "Dialect/Probe/IR/Probe.h"
#include "Dialect/Probe/Transforms/Passes.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

int main(int argc, char **argv) {
  mlir::registerAllPasses();

  mlir::DialectRegistry registry;
  registry.insert<mlir::probe::ProbeDialect>();
  mlir::registerAllDialects(registry);

  mlir::probe::registerProbePasses();

  return mlir::asMainReturnCode(mlir::MlirOptMain(
      argc, argv, "Driver for probe utilities for MLIR tensors\n", registry));
}
