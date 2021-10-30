FROM docker.io/library/golang:1.17-alpine3.13 AS build

ARG VERSION=latest

COPY . /workspace

WORKDIR /workspace

RUN set -ex && \
    apk update && \
    apk add git make && \
    make install VERSION=${VERSION} DESTDIR=/db-wait PREFIX=/usr

FROM docker.io/library/alpine:3.14

COPY --from=build /db-wait /

ENTRYPOINT [ "/usr/bin/db-wait" ]
