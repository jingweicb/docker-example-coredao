###############
# Build Stage #
###############
FROM golang:1.21 as build
RUN apt-get update && apt-get install -y make gcc g++ git

RUN mkdir -p /app \
  && chown -R nobody:nogroup /app
WORKDIR /app

# Compile geth
FROM golang-builder as geth-builder

# VERSION: core-chain
ARG CORE_CHAIN_VERSION=v1.0.8
RUN git clone https://github.com/coredao-org/core-chain.git \
  && cd core-chain \
  && git checkout ${CORE_CHAIN_VERSION}

RUN cd core-chain \
  && make geth

RUN mv core-chain/build/bin/geth /app/geth \
  && rm -rf core-chain

###################
# Execution Stage #
###################
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y apt-utils bash tar lz4 wget make gcc g++ git iputils-ping ca-certificates && update-ca-certificates

RUN mkdir -p /app \
  && chown -R nobody:nogroup /app \
  && mkdir -p /data \
  && chown -R nobody:nogroup /data

WORKDIR /app

# Copy binary from geth-builder
COPY --from=geth-builder /app/geth /app/geth

# Copy config files and scripts
COPY scripts/configs/ /app/configs
COPY scripts/entrypoint.sh /app/entrypoint.sh

EXPOSE 30656 8575 8576

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]