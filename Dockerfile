FROM scratch

COPY db-wait-* /usr/bin/db-wait

ENTRYPOINT [ "/usr/bin/db-wait" ]
