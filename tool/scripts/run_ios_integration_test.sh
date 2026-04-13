#!/bin/bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <test-file> <device-udid> [extra flutter test args...]" >&2
  exit 2
fi

TEST_FILE="$1"
DEVICE_UDID="$2"
shift 2

VM_SERVICE_WAIT_TIMEOUT_SECONDS="${VM_SERVICE_WAIT_TIMEOUT_SECONDS:-90}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ios-integration-test.XXXXXX")"
OUTPUT_PIPE="$TMP_DIR/output.pipe"

cleanup() {
  exec 3<&- || true
  if [[ -n "${FLUTTER_PID:-}" ]] && kill -0 "${FLUTTER_PID}" 2>/dev/null; then
    kill "${FLUTTER_PID}" 2>/dev/null || true
  fi
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

mkfifo "${OUTPUT_PIPE}"

(
  cd example
  flutter test "${TEST_FILE}" -d "${DEVICE_UDID}" --verbose --no-pub --reporter expanded "$@"
) >"${OUTPUT_PIPE}" 2>&1 &
FLUTTER_PID=$!

exec 3<"${OUTPUT_PIPE}"

vm_service_deadline=0
vm_service_ready=0
vm_service_timed_out=0

while true; do
  if IFS= read -r -t 1 line <&3; then
    printf '%s\n' "${line}"

    if [[ "${line}" == *"Waiting for VM Service port to be available..."* ]] && [[ ${vm_service_deadline} -eq 0 ]]; then
      vm_service_deadline=$((SECONDS + VM_SERVICE_WAIT_TIMEOUT_SECONDS))
      echo "[ci] VM Service wait window started (${VM_SERVICE_WAIT_TIMEOUT_SECONDS}s)." >&2
    fi

    if [[ "${line}" == *"The Dart VM service is listening on "* ]]; then
      vm_service_ready=1
      vm_service_deadline=0
    fi
  else
    if [[ ${vm_service_deadline} -gt 0 ]] && [[ ${vm_service_ready} -eq 0 ]] && [[ ${SECONDS} -ge ${vm_service_deadline} ]]; then
      echo "[ci] Timed out waiting ${VM_SERVICE_WAIT_TIMEOUT_SECONDS}s for VM Service after Flutter started waiting. Terminating test run." >&2
      vm_service_timed_out=1
      kill "${FLUTTER_PID}" 2>/dev/null || true
      sleep 2
      kill -9 "${FLUTTER_PID}" 2>/dev/null || true
      break
    fi

    if ! kill -0 "${FLUTTER_PID}" 2>/dev/null; then
      break
    fi
  fi
done

while IFS= read -r line <&3; do
  printf '%s\n' "${line}"
done || true

set +e
wait "${FLUTTER_PID}"
exit_code=$?
set -e

if [[ ${vm_service_timed_out} -eq 1 ]]; then
  exit 124
fi

exit "${exit_code}"
