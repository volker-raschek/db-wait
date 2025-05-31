FROM docker.io/library/alpine:3.22.0

COPY db-wait-* /usr/bin/db-wait

ENTRYPOINT [ "/usr/bin/db-wait" ]
