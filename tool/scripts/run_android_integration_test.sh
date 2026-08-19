#!/bin/bash
set -euo pipefail

cd example
flutter pub get

# Run Android integration tests one by one so the first failure stops the job
# and does not leave the emulator/app state ambiguous for later cases.
for filename in integration_test/*.dart; do
  flutter test "$filename"
done
