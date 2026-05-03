add_mlir_library(MLIRProbeTransforms
  LowerToFuncCalls.cpp

  DEPENDS
  MLIRProbeTransformsPassIncGen
  )
