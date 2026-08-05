# syntax=docker/dockerfile:1.7

# Build the frontend with a Node release that satisfies Vite and TypeScript.
ARG NODE_IMAGE=node:20.19.5-bookworm-slim
ARG TAMARIN_BUILD_IMAGE=fpco/stack-build-small:lts-22.44
ARG TAMARIN_COMMIT=3a523146116a70f1ee815401fb67ed6335baf44f

FROM ${NODE_IMAGE} AS frontend-builder

ARG TAMARIN_COMMIT

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone https://github.com/tamarin-prover/tamarin-prover.git && \
    cd tamarin-prover && \
    git checkout --detach "${TAMARIN_COMMIT}" && \
    test "$(git rev-parse HEAD)" = "${TAMARIN_COMMIT}"

WORKDIR /src/tamarin-prover/frontend

RUN npm ci && npm run build

# The Haskell builder follows the Stack snapshot declared by the pinned source.
FROM ${TAMARIN_BUILD_IMAGE} AS builder

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TAMARIN_COMMIT

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        make \
        libgmp-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone https://github.com/tamarin-prover/tamarin-prover.git && \
    cd tamarin-prover && \
    git checkout --detach "${TAMARIN_COMMIT}" && \
    test "$(git rev-parse HEAD)" = "${TAMARIN_COMMIT}"

WORKDIR /src/tamarin-prover

# Copy only the generated frontend assets into the pinned Tamarin source tree.
COPY --from=frontend-builder \
    /src/tamarin-prover/frontend/dist/intdot-graph.es.js \
    /src/tamarin-prover/data/js/intdot-graph.es.js
COPY --from=frontend-builder \
    /src/tamarin-prover/frontend/dist/intdot-staticgraph.es.js \
    /src/tamarin-prover/data/js/intdot-staticgraph.es.js
COPY --from=frontend-builder \
    /src/tamarin-prover/frontend/dist/intdot-dynamicgraph.es.js \
    /src/tamarin-prover/data/js/intdot-dynamicgraph.es.js
COPY --from=frontend-builder \
    /src/tamarin-prover/frontend/dist/intdot-style.css \
    /src/tamarin-prover/data/css/intdot-style.css

RUN stack setup && \
    stack install --local-bin-path /out

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG MAUDE_VERSION=3.5.1
ARG MAUDE_SHA256=72ed1ca87e3b3d0dfc6ee1436baf154bf04c45ff97d521bec040c5e8dfc8f92c

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        graphviz \
        libffi8 \
        libgmp10 \
        libncurses6 \
        libnuma1 \
        libtinfo6 \
        time \
        unzip \
        zlib1g && \
    rm -rf /var/lib/apt/lists/*

RUN curl --fail --location \
        "https://github.com/maude-lang/Maude/releases/download/Maude${MAUDE_VERSION}/Maude-${MAUDE_VERSION}-linux-x86_64.zip" \
        --output /tmp/maude.zip && \
    echo "${MAUDE_SHA256}  /tmp/maude.zip" | sha256sum --check --strict && \
    mkdir -p /tmp/maude-extracted /opt/maude && \
    unzip -q /tmp/maude.zip -d /tmp/maude-extracted && \
    MAUDE_BIN="$(find /tmp/maude-extracted -type f -name maude -print -quit)" && \
    test -n "${MAUDE_BIN}" && \
    cp -a "$(dirname "${MAUDE_BIN}")/." /opt/maude/ && \
    chmod +x /opt/maude/maude && \
    ln -s /opt/maude/maude /usr/local/bin/maude && \
    rm -rf /tmp/maude.zip /tmp/maude-extracted

ENV MAUDE_LIB=/opt/maude \
    LC_ALL=C \
    LANG=C

COPY --from=builder /out/tamarin-prover /usr/local/bin/tamarin-prover

WORKDIR /artifact

COPY models/ models/
COPY expected/ expected/
COPY scripts/ scripts/

RUN chmod +x scripts/*.sh && \
    mkdir -p results && \
    chmod 0777 results

ENTRYPOINT ["scripts/reproduce.sh"]
CMD ["all"]
