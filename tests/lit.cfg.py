import os

import lit.formats
from lit.llvm import llvm_config

config.name = "Probe"

config.test_source_root = os.path.dirname(__file__)
config.test_format = lit.formats.ShTest(True)
config.suffixes = [".mlir"]

config.substitutions.append(("%example_dir", config.example_dir))

llvm_config.with_environment("PATH", config.bin_dir, append_path=True)
