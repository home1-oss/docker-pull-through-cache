
FROM registry:2.6.1

RUN apk add --no-cache curl privoxy && \
    curl -Ls https://github.com/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 >> /usr/bin/waitforit && \
    chmod 755 /usr/bin/waitforit

COPY ./docker/config-example.yml /etc/docker/registry/config-example.yml
COPY ./docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]
