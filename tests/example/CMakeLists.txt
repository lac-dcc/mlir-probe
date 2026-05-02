add_library(ProbeExample SHARED probe.cpp)

set(PROBE_LIB_EXAMPLE_DIR "${CMAKE_BINARY_DIR}/example" PARENT_SCOPE)

set_target_properties(ProbeExample PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/example"
)
