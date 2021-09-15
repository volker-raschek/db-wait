FROM docker.io/library/golang:1.17-alpine3.14 AS build

COPY . /workspace

WORKDIR /workspace

RUN set -ex && \
    apk update && \
    apk add git make && \
    make install DESTDIR=/db-wait PREFIX=/usr

FROM docker.io/library/alpine:3.14.2

COPY --from=build /db-wait /

ENTRYPOINT [ "/usr/bin/db-wait" ]
