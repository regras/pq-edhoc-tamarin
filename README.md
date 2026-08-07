# Introduction

This repository contains the symbolic models and automated verification workflow accompanying the paper:

> *Design, Formal Verification, and Evaluation of a Post-Quantum EDHOC Variant for UAV Communications*

The models represent pairwise UAV–GCS and UAV–UAV executions of a post-quantum EDHOC variant. The artifact verifies agreement, key secrecy, freshness, injective agreement, session-key independence, forward secrecy, resistance to unknown-key-share attacks, and resistance to key-compromise impersonation.

### Paper abstract
> *Unmanned Aerial Vehicle (UAV) swarms require secure and efficient protocols for communication in dynamic and adversarial environments. This paper presents a post-quantum authenticated key exchange protocol for UAV swarm communications, inspired by recent post-quantum extensions of EDHOC. The protocol is modeled in SAPIC+ and verified in the Tamarin Prover under a Dolev–Yao adversary, establishing executability, mutual authentication, key secrecy, and forward secrecy properties. Communication overhead and handshake latency are evaluated using standardized parameter sizes and benchmark data for ARM Cortex-M4 and x86 platforms, showing how the choice of post-quantum primitives affects the feasibility of authenticated key exchange in constrained UAV deployments.* 

### Badges sought

The four badges sought are:

* **Available (Selo D):** The complete artifact is publicly available in this stable GitHub repository.
* **Functional (Selo F):** The repository provides a list of dependencies, a Docker environment, execution instructions, and a minimal test.
* **Sustainable (Selo S):** The models and scripts are modular, documented, and organized so that the paper’s claims can be readily identified.
* **Reproducible (Selo R):** The workflows automate the experiments and validate all 20 expected verification results.

## Repository structure

| File | Purpose |
| --- | --- |
| `models/pq_edhoc_core_model.spthy` | Core protocol model and trace properties |
| `models/pq_edhoc_compromise_model.spthy` | Compromise-aware forward-secrecy and KCI model |
| `scripts/reproduce.sh` | Runs one or both models with the published options |
| `scripts/validate-results.sh` | Checks the generated summaries against the expected results |
| `expected/claims.tsv` | Machine-readable expected lemma results |
| `SHA256SUMS` | Integrity hashes for the original model files |

## Dependencies

| Component | Version |
| --- | --- |
| Node.js build stage | 20.19.5 |
| Tamarin Prover | 1.13.0 |
| Tamarin Git revision | `3a523146116a70f1ee815401fb67ed6335baf44f` |
| Maude | 3.5.1 |
| Maude Linux archive SHA-256 | `72ed1ca87e3b3d0dfc6ee1436baf154bf04c45ff97d521bec040c5e8dfc8f92c` |
| Container runtime | Ubuntu 24.04 |

The full Git revision is pinned because the version number alone does not uniquely identify a development build of Tamarin. The Dockerfile also verifies that revision and the downloaded Maude archive during the build.

## Requirements

- Docker Engine or Docker Desktop with Linux-container support.
- Approximately 16 GiB of RAM is recommended for reproducing the reference run.
- At least four CPU cores are recommended.
- GNU Make is optional; the equivalent Docker commands are provided below.

## Installation

Clone the repository and enter its directory:

```bash
git clone https://github.com/regras/pq-edhoc-tamarin.git
cd pq-edhoc-tamarin
```

Confirm that the Docker daemon is available to the current user:

```bash
docker version
```

Verify the model integrity hashes and build the image:

```bash
make check-models
make build
```

`make build` repeats the integrity check before building `pq-edhoc-tamarin:1.0.0`. A successful build completes with exit status 0. If Docker reports permission denied while connecting to its socket, configure Docker access for the current account according to the host operating system or contact the system administrator, then start a new login session before retrying.

## Minimal test 

After the image has been built, run the environment test:

```bash
make versions
```

This starts the image, prints the installed Tamarin and Maude versions, executes Tamarin's built-in test, and writes `results/environment.log`. The command should exit with status 0 and report Tamarin 1.13.0 and Maude 3.5.1. It does not execute either full protocol model and should normally finish much faster than the complete experiment.

Review the recorded output if desired:

```bash
cat results/environment.log
```

## Experiments 

The experiments below reproduce the paper's symbolic formal verification claims. Both use the same Tamarin options; no configuration file or parameter needs to be edited.

### Common verification configuration

| Option | Value | Purpose |
| --- | --- | --- |
| Proof mode | `--prove` | Prove all lemmas in the selected theory |
| Heuristic | `--heuristic=S` | Use the published proof-search heuristic |
| Derivation-check timeout | `--derivcheck-timeout=240` | Allow up to 240 seconds for each derivation check |
| Tamarin option | `-c=12` | Use the setting recorded in the artifact workflow |
| Tamarin option | `-s=8` | Use the setting recorded in the artifact workflow |

The full reference workflow required approximately 16 minutes on four reference CPU cores. Each individual command below executes only one part of that workflow. Both experiments use the same recommendation of four CPU cores, 16 GiB RAM, and 20 GiB free disk space, although actual peak use and wall time depend on the host and Docker cache.

### Claim 1 — Core protocol execution and security properties

Run:

```bash
make core
```

This executes `models/pq_edhoc_core_model.spthy`, writes `results/core.log`, and validates 13 expected results:

| Claim group | Expected verified lemmas |
| --- | --- |
| Executability | `executable_full_run` |
| Agreement and key agreement | `agreement_I_to_R`, `agreement_R_to_I`, `commit_agreement_R_to_I`, `key_agreement` |
| PRK_out secrecy | `secrecy_PRK_out_I`, `secrecy_PRK_out_R` |
| Freshness | `freshness_AcceptI`, `freshness_AcceptR`, `freshness_CommitI`, `freshness_CommitR` |
| Stronger authentication and key independence | `injective_agreement_R_to_I`, `session_key_independence` |

Expected final validator output:

```text
Validation successful: 13 expected result(s) found.
```

### Claim 2 — Forward secrecy and compromise resistance

Run:

```bash
make fs-kci
```

This executes `models/pq_edhoc_compromise_model.spthy`, writes `results/fs-kci.log`, and validates seven expected results:

| Claim group | Expected verified lemmas |
| --- | --- |
| PRK_out secrecy | `secrecy_PRK_out_I`, `secrecy_PRK_out_R` |
| Forward secrecy | `forward_secrecy_I`, `forward_secrecy_R` |
| Unknown-key-share resistance | `no_unknown_key_share` |
| Key-compromise impersonation resistance | `kci_resistance_I`, `kci_resistance_R` |

Expected final validator output:

```text
Validation successful: 7 expected result(s) found.
```

### Complete reproduction

To reproduce both claim groups in one command:

```bash
make reproduce
```

Expected final validator output:

```text
Validation successful: 20 expected result(s) found.
```

The validator checks lemma names and statuses against `expected/claims.tsv`. It intentionally ignores proof-step counts, execution times, and peak-memory values because these may vary across systems.

After the complete reproduction, validation can be repeated without rerunning Tamarin:

```bash
make validate
```

For an individual experiment, use the corresponding validator mode:

```bash
./scripts/validate-results.sh core
./scripts/validate-results.sh fs-kci
```

### Exact Tamarin commands

For transparency, the container invokes the models as follows:

```bash
tamarin-prover models/pq_edhoc_core_model.spthy \
  --prove \
  --heuristic=S \
  --derivcheck-timeout=240 \
  -c=12 \
  -s=8

tamarin-prover models/pq_edhoc_compromise_model.spthy \
  --prove \
  --heuristic=S \
  --derivcheck-timeout=240 \
  -c=12 \
  -s=8
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
tamarin-prover models/pq_edhoc_core_model.spthy \
  --prove \
  --heuristic=S \
  --derivcheck-timeout=240 \
  -c=12 \
  -s=8
```

The compromise model uses the same options:

```bash
tamarin-prover models/pq_edhoc_compromise_model.spthy \
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
## Security considerations

The artifact is intended solely for scientific research and reproducibility and should not be used for operational deployment. The symbolic protocol models do not process real cryptographic keys, credentials, personal data, or network traffic.

The verification process makes intensive use of CPU and RAM; therefore, it may temporarily consume substantial host resources. Reviewers should execute it on a machine with sufficient available memory and avoid running it alongside critical workloads.

## License 

This artifact is distributed under the GNU General Public License, version 3. See the LICENSE file for the complete license information.
