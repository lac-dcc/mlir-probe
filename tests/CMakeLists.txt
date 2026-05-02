add_subdirectory(example)

set(LIT_CFG_PY "${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py")

configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${LIT_CFG_PY}
)

set(PROBE_TEST_DEPENDS
  FileCheck
  probe-opt
  ProbeExample
)

add_lit_testsuite(check-probe "Running Probe regression tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${PROBE_TEST_DEPENDS}
)

set_target_properties(check-probe PROPERTIES FOLDER "Tests")
