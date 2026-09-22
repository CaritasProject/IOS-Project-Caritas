#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
test_dir=$(mktemp -d /tmp/caritas-donantes-tests.XXXXXX)
xcrun swiftc -swift-version 5 -parse-as-library -module-cache-path "$test_dir/cache" \
  ios/SistemaIngresos/Core/Model/Donante.swift \
  ios/SistemaIngresos/Core/Services/APIClient.swift \
  ios/SistemaIngresos/Features/Donantes/Services/DonantesService.swift \
  ios/Tests/DonantesTests.swift -o "$test_dir/DonantesTests"
"$test_dir/DonantesTests"
