#ifndef PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_H
#define PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_H

#include "mlir/Pass/Pass.h"

namespace mlir {
namespace probe {
#define GEN_PASS_DECL
#define GEN_PASS_REGISTRATION
#include "Dialect/Probe/Transforms/Passes.h.inc"
} // namespace probe
} // namespace mlir

#endif // PROBE_INCLUDE_DIALECT_PROBE_TRANSFORMS_PASSES_H
