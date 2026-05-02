add_mlir_dialect_library(MLIRProbeDialect
  ProbeDialect.cpp
  ProbeOps.cpp
  DEPENDS
  MLIRProbeOpsIncGen
  MLIRBufferizationDialect
  )
