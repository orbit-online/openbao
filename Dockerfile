# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#### DOCKERHUB DOCKERFILE ####
FROM alpine:3.23 AS default

ARG TARGETPLATFORM
ARG BIN_NAME
# NAME and PRODUCT_VERSION are the name of the software in releases.hashicorp.com
# and the version to download. Example: NAME=openbao PRODUCT_VERSION=1.2.3.
ARG NAME=openbao
ARG PRODUCT_VERSION
ARG PRODUCT_REVISION

# Additional metadata labels used by container registries, platforms
# and certification scanners.
LABEL name="OpenBao" \
      maintainer="OpenBao <openbao@lists.openssf.org>" \
      vendor="OpenBao" \
      version=${PRODUCT_VERSION} \
      release=${PRODUCT_REVISION} \
      revision=${PRODUCT_REVISION} \
      summary="OpenBao is a tool for securely accessing secrets." \
      description="OpenBao is a tool for securely accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, certificates, and more. OpenBao provides a unified interface to any secret, while providing tight access control and recording a detailed audit log."

COPY LICENSE /licenses/mozilla.txt

# Set ARGs as ENV so that they can be used in ENTRYPOINT/CMD
ENV NAME=$NAME
ENV VERSION=$VERSION

# Create a non-root user to run the software.
RUN addgroup ${NAME} && adduser -S -G ${NAME} ${NAME}

ARG EXTRA_PACKAGES
RUN apk add --no-cache libcap su-exec dumb-init tzdata ${EXTRA_PACKAGES}

COPY $TARGETPLATFORM/$BIN_NAME /bin/

RUN ln -s /bin/${BIN_NAME} /bin/vault

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN mkdir -p /openbao/logs && \
    mkdir -p /openbao/file && \
    mkdir -p /openbao/config && \
    chown -R ${NAME}:${NAME} /openbao

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /openbao/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /openbao/file

# 8200/tcp is the primary interface that applications use to interact with
# OpenBao.
EXPOSE 8200

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by OpenBao sub-processes.
COPY .release/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]


# # By default you'll get a single-node development server that stores everything
# # in RAM and bootstraps itself. Don't use this configuration for production.
CMD ["server", "-dev", "-dev-no-store-token"]
