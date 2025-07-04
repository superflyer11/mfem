#!/bin/bash
set -e
# Build MFEM in serial mode and run Example 1 to verify the build
make serial -j 4
make check
