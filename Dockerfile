FROM docker.io/library/golang:1.21.4-alpine3.18 AS build

ARG VERSION=latest

COPY . /workspace

WORKDIR /workspace

RUN set -ex && \
    apk update && \
    apk add git make && \
    make install VERSION=${VERSION} DESTDIR=/db-wait PREFIX=/usr

FROM docker.io/library/alpine:3.19

ARG VERSION=latest

LABEL org.opencontainers.image.authors="Markus Pesch" \
      org.opencontainers.image.description="Wait until database is ready for handling connections" \
      org.opencontainers.image.documentation="https://git.cryptic.systems/volker.raschek/db-wait#db-wait" \
      org.opencontainers.image.source="https://git.cryptic.systems/volker.raschek/db-wait" \
      org.opencontainers.image.title="db-wait" \
      org.opencontainers.image.url="https://git.cryptic.systems/volker.raschek/db-wait" \
      org.opencontainers.image.vendor="Markus Pesch" \
      org.opencontainers.image.version="${VERSION}"

COPY --from=build /db-wait /

ENTRYPOINT [ "/usr/bin/db-wait" ]
