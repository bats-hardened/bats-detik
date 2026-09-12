FROM alpine:3.24

ARG KUBECTL_VERSION=v1.29.2
ARG KUBECTL_SHA256=7816d067740f47f949be826ac76943167b7b3a38c4f0c18b902fffa8779a5afa
ARG HELM_VERSION=v3.14.2
ARG HELM_SHA256=0885a501d586c1e949e9b113bf3fb3290b0bbf74db9444a1d8c2723a143006a5
ARG BATS_VERSION=1.10.0
ARG BATS_SHA256=a1a9f7875aa4b6a9480ca384d5865f1ccf1b0b1faead6b47aa47d79709a5c5fd

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Add packages
RUN apk --no-cache add \
    curl \
    git \
    libc6-compat \
    openssh-client \
    bash

# Install BATS
RUN curl --fail --location --silent --show-error --retry 4 --retry-connrefused \
        --output /tmp/bats-core.tar.gz \
        "https://github.com/bats-core/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
    echo "$BATS_SHA256  /tmp/bats-core.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/bats-core.tar.gz -C /tmp && \
    "/tmp/bats-core-$BATS_VERSION/install.sh" /usr/local && \
    rm -rf /tmp/bats-core.tar.gz "/tmp/bats-core-$BATS_VERSION"

# Install kubectl
RUN curl --fail --location --silent --show-error --retry 4 --retry-connrefused \
        --output /tmp/kubectl \
        "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl" && \
    echo "$KUBECTL_SHA256  /tmp/kubectl" | sha256sum -c - && \
    chmod +x /tmp/kubectl && \
    mv /tmp/kubectl /usr/local/bin/

# Install Helm
RUN curl --fail --location --silent --show-error --retry 4 --retry-connrefused \
        --output /tmp/helm.tar.gz \
        "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" && \
    echo "$HELM_SHA256  /tmp/helm.tar.gz" | sha256sum -c - && \
    mkdir -p "/usr/local/helm-$HELM_VERSION" && \
    tar -xzf /tmp/helm.tar.gz -C "/usr/local/helm-$HELM_VERSION" && \
    ln -s "/usr/local/helm-$HELM_VERSION/linux-amd64/helm" /usr/local/bin/helm && \
    rm -f /tmp/helm.tar.gz

# Work directory.
# Use the same UID than Jenkins:
# for Jenkins versions < 2.62, this is 1000
RUN adduser -D -u 10000 testing
USER 10000
WORKDIR /home/testing

# Initialize the Helm client (Helm 2.x)
# RUN helm init --client-only --skip-refresh

# Add the library
COPY ./lib /home/testing/lib
