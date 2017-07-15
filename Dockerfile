
FROM registry:2.6.1

RUN apk add --no-cache privoxy

COPY ./docker/config-example.yml /etc/docker/registry/config-example.yml
COPY ./docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/docker/registry/config.yml"]
