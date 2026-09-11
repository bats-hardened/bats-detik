FROM alpine:3.14

ARG KUBECTL_VERSION=v1.37.0
ARG KUBECTL_SHA256=6129359f4e1f3848a5572ccb0b26cf28b8ca08cef38c95a765b2f64a2c961a2f
ARG HELM_VERSION=v4.3.0
ARG HELM_SHA256=86584a54def73570558f66f5111cc53dfed56689637ae32c1201205d494f54fb
ARG BATS_VERSION=1.14.1-beta05
ARG BATS_SHA256=82173dc5c23571b4ab0f2a21c6b0911213e374c88a28b8c491eda94056e7cd2e

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
        "https://github.com/bats-hardened/bats-core/archive/refs/tags/v$BATS_VERSION.tar.gz" && \
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
USER testing
WORKDIR /home/testing

# Initialize the Helm client (Helm 2.x)
# RUN helm init --client-only --skip-refresh

# Add the library
COPY ./lib /home/testing/lib
