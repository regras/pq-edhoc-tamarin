# Reproducible Tamarin Artifact for Post-Quantum EDHOC

This repository contains the symbolic models and automated verification workflow accompanying the paper:

> *Design, Formal Verification, and Evaluation of a Post-Quantum EDHOC Variant for UAV Communications*

The models represent pairwise UAV–GCS and UAV–UAV executions of a post-quantum EDHOC variant. The artifact verifies agreement, key secrecy, freshness, injective agreement, session-key independence, forward secrecy, resistance to unknown-key-share attacks, and resistance to key-compromise impersonation.

## Artifact contents

| File | Purpose |
| --- | --- |
| `models/pq_edhoc_core_model.spthy` | Core protocol model and trace properties |
| `models/pq_edhoc_compromise_model.spthy` | Compromise-aware forward-secrecy and KCI model |
| `scripts/reproduce.sh` | Runs one or both models with the published options |
| `scripts/validate-results.sh` | Checks the generated summaries against the expected results |
| `expected/claims.tsv` | Machine-readable expected lemma results |
| `SHA256SUMS` | Integrity hashes for the original model files |

## Pinned verification environment

| Component | Version |
| --- | --- |
| Node.js build stage | 20.19.5 |
| Tamarin Prover | 1.13.0 |
| Tamarin Git revision | `3a523146116a70f1ee815401fb67ed6335baf44f` |
| Maude | 3.5.1 |
| Maude Linux archive SHA-256 | `72ed1ca87e3b3d0dfc6ee1436baf154bf04c45ff97d521bec040c5e8dfc8f92c` |
| Container runtime | Ubuntu 24.04 |

The full Git revision is pinned because the version number alone does not uniquely identify a development build of Tamarin.

## Requirements

- Docker Engine or Docker Desktop with Linux-container support.
- Approximately 16 GiB of RAM is recommended for reproducing the reference run.
- At least four CPU cores are recommended.
- GNU Make is optional; the equivalent Docker commands are provided below.

## Quick reproduction

```bash
git clone https://github.com/regras/pq-edhoc-tamarin.git
cd pq-edhoc-tamarin
make build
make reproduce
```

The proof summaries and resource measurements are written to:

```text
results/environment.log
results/core.log
results/fs-kci.log
```

At the end of a successful execution, the validator should report:

```text
Validation successful: 20 expected result(s) found.
```

The reference execution used Ubuntu 24.04.4 LTS, four Intel Xeon Gold 6526Y CPU cores, and 64 GiB of RAM. The complete verification took approximately 15 min 45.35 s. Runtime is hardware-dependent; the reproducible outcomes are the verified lemma results, not identical execution times.

## Run the models separately

Core model:

```bash
make core
```

Forward-secrecy and KCI model:

```bash
make fs-kci
```

Display and test the installed verification tools without running the models:

```bash
make versions
```

## Direct Docker commands

Build the image:

```bash
docker build -t pq-edhoc-tamarin:1.0.0 .
```

Run both models:

```bash
mkdir -p results
docker run --rm --init \
  --volume "$(pwd)/results:/artifact/results" \
  pq-edhoc-tamarin:1.0.0 all
```

Use `core`, `fs-kci`, or `versions` in place of `all` to select another operation.

## Exact Tamarin invocations

The container invokes the core model as follows:

```bash
tamarin-prover models/pq_edhoc_uav_method0.spthy \
  --prove \
  --heuristic=S \
  --derivcheck-timeout=240 \
  -c=12 \
  -s=8
```

The compromise-aware model uses the same options:

```bash
tamarin-prover models/pq_edhoc_uav_method0_fs_kci.spthy \
  --prove \
  --heuristic=S \
  --derivcheck-timeout=240 \
  -c=12 \
  -s=8
```

## Expected results

All 20 lemmas listed in `expected/claims.tsv` are expected to be reported as `verified`. The validation script compares lemma names and statuses while deliberately ignoring proof-step counts and execution times, which may vary across systems.

Verify that the distributed models are identical to the reviewed versions:

```bash
make check-models
```

## Releasing the artifact

For an immutable citation target, create an annotated Git tag and GitHub Release after testing from a clean clone:

```bash
git tag -a v1.0.0 -m "Reproducible artifact v1.0.0"
git push origin v1.0.0
```

