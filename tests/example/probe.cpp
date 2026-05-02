#include "probe.h"
#include <cstdint>
#include <iostream>

extern "C" void _mlir_ciface_probeMemrefF32(UnrankedMemRefType<float> *m,
                                            int32_t opID, int32_t resultID) {
  // Converting UnrankedMemrefType to DynamicMemRefType makes traversal easier
  auto dynMemref = DynamicMemRefType<float>(*m);
  float sum = 0.f;
  for (float val : dynMemref) {
    sum += val;
  }

  std::cout << "opID: " << opID << ", resultID: " << resultID
            << ", sum: " << sum << "\n";
}
