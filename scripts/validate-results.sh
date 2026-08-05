#!/usr/bin/env bash
set -Eeuo pipefail

readonly ARTIFACT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RESULTS_DIR="${RESULTS_DIR:-${ARTIFACT_DIR}/results}"
readonly CLAIMS_FILE="${ARTIFACT_DIR}/expected/claims.tsv"
readonly MODE="${1:-all}"

case "${MODE}" in
    all|core|fs-kci) ;;
    *)
        echo "Usage: $0 {all|core|fs-kci}" >&2
        exit 2
        ;;
esac

failures=0
checked=0

while IFS=$'\t' read -r group log_name lemma expected; do
    [[ -z "${group}" || "${group}" == \#* ]] && continue
    [[ "${MODE}" != all && "${MODE}" != "${group}" ]] && continue

    log_path="${RESULTS_DIR}/${log_name}"
    if [[ ! -f "${log_path}" ]]; then
        echo "Missing result log: ${log_path}" >&2
        failures=$((failures + 1))
        continue
    fi

    if grep -Eq "^[[:space:]]*${lemma}[[:space:]]+\\([^)]*\\):[[:space:]]+${expected}([[:space:]]|$)" "${log_path}"; then
        echo "PASS  ${lemma}: ${expected}"
        checked=$((checked + 1))
    else
        echo "FAIL  ${lemma}: expected ${expected}" >&2
        failures=$((failures + 1))
    fi
done < "${CLAIMS_FILE}"

if (( failures > 0 )); then
    echo "Validation failed: ${failures} expected result(s) were not found." >&2
    exit 1
fi

echo "Validation successful: ${checked} expected result(s) found."
