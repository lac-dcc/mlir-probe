#ifndef PROBE_TESTS_EXAMPLE_PROBE_H
#define PROBE_TESTS_EXAMPLE_PROBE_H

#include "mlir/ExecutionEngine/CRunnerUtils.h"

#define PROBE_EXPORT __attribute__((visibility("default")))

/// Probe function example. The "_mlir_ciface_" prefix is needed, since MLIR
/// adds it to private function definitions.
extern "C" PROBE_EXPORT void
_mlir_ciface_probeMemrefF32(UnrankedMemRefType<float> *m, int32_t opID,
                            int32_t resultID);

#endif // PROBE_TESTS_EXAMPLE_PROBE_H
