#!/usr/bin/env bash
set -Eeuo pipefail

readonly ARTIFACT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RESULTS_DIR="${RESULTS_DIR:-${ARTIFACT_DIR}/results}"
readonly COMMON_ARGS=(
    --prove
    --heuristic=S
    --derivcheck-timeout=240
    -c=12
    -s=8
)

mkdir -p "${RESULTS_DIR}"

usage() {
    echo "Usage: $0 {all|core|fs-kci|versions}" >&2
}

record_environment() {
    {
        echo "Artifact execution environment"
        echo "UTC start: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo
        tamarin-prover --version
        echo
        tamarin-prover test
    } 2>&1 | tee "${RESULTS_DIR}/environment.log"
}

run_model() {
    local label="$1"
    local model="$2"

    echo "Running ${model}"
    /usr/bin/time -v \
        tamarin-prover "${ARTIFACT_DIR}/${model}" "${COMMON_ARGS[@]}" \
        2>&1 | tee "${RESULTS_DIR}/${label}.log"
}

run_core() {
    run_model core models/pq_edhoc_core_model.spthy
    "${ARTIFACT_DIR}/scripts/validate-results.sh" core
}

run_fs_kci() {
    run_model fs-kci models/pq_edhoc_compromise_model.spthy
    "${ARTIFACT_DIR}/scripts/validate-results.sh" fs-kci
}

case "${1:-all}" in
    all)
        record_environment
        run_model core models/pq_edhoc_core_model.spthy
        run_model fs-kci models/pq_edhoc_compromise_model.spthy
        "${ARTIFACT_DIR}/scripts/validate-results.sh" all
        ;;
    core)
        record_environment
        run_core
        ;;
    fs-kci)
        record_environment
        run_fs_kci
        ;;
    versions)
        record_environment
        ;;
    *)
        usage
        exit 2
        ;;
esac
