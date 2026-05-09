#include "probe.h"
#include <cstdint>
#include <iostream>
#include <tuple>
#include <vector>

/// Global vector to store observed results
static std::vector<std::tuple<int32_t, int32_t, float>> results;

void _mlir_ciface_probeObserveMemrefF32(UnrankedMemRefType<float> *m,
                                        int32_t opID, int32_t resultID) {
  // Converting UnrankedMemrefType to DynamicMemRefType makes traversal easier
  auto dynMemref = DynamicMemRefType<float>(*m);
  float sum = 0.f;
  for (float val : dynMemref) {
    sum += val;
  }

  results.emplace_back(opID, resultID, sum);
}

void _mlir_ciface_probeReport() {
  // Simply print to stdout. However, this could be reported in any other
  // format (CSV, JSON, YAML, etc.)
  for (auto [opID, resultID, sum] : results) {
    std::cout << "opID: " << opID << ", resultID: " << resultID
              << ", sum: " << sum << "\n";
  }
}
