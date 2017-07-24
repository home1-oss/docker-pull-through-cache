#!/bin/sh

HTTP_PROXY=""
HTTPS_PROXY=""
NO_PROXY="localhost,127.0.0.1,*.local,*.internal"

echo "PROXY=${PROXY} PULL_THROUGH_CACHE_OF=${PULL_THROUGH_CACHE_OF}"

if [ ! -z "${PROXY}" ]; then
    PROXY_PROTOCOL="$(echo ${PROXY} | awk -F:// '{print $1}')"
    PROXY_HOST_PORT="$(echo ${PROXY} | awk -F:// '{print $2}')"
    echo "PROXY_PROTOCOL=${PROXY_PROTOCOL} PROXY_HOST_PORT:${PROXY_HOST_PORT}"
    case "${PROXY_PROTOCOL}" in
        http|https)
        HTTP_PROXY="${PROXY_PROTOCOL}://${PROXY_HOST_PORT}"
        HTTPS_PROXY="${HTTP_PROXY}"
        ;;
        socks*)
        HTTP_PROXY="http://127.0.0.1:8118"
        HTTPS_PROXY="http://127.0.0.1:8118"

        # /etc/privoxy/config
        PRIVOXY_CONFIG="forward-${PROXY_PROTOCOL} / ${PROXY_HOST_PORT} ."
        if ! grep "${PRIVOXY_CONFIG}" /etc/privoxy/config; then
            if ! grep -E "^forward-" /etc/privoxy/config; then
                echo "forward-${PROXY_PROTOCOL} / ${PROXY_HOST_PORT} ." >> /etc/privoxy/config
            else
                sed -i -E "s#^forward-.*#${PRIVOXY_CONFIG}#g" /etc/privoxy/config
            fi
        fi

        echo "starting privoxy"
        CONFFILE=/etc/privoxy/config
        PIDFILE=/var/run/privoxy.pid
        /usr/sbin/privoxy \
            --pidfile "${PIDFILE}" \
            --user privoxy.privoxy "${CONFFILE}" &

        echo "waiting for privoxy"
        waitforit -full-connection=tcp://127.0.0.1:8118 -timeout=180
        echo "privoxy started"
        #curl --connect-timeout 2 -x 127.0.0.1:8118 http://google.com
        ;;
    esac
fi

if [ ! -z "${HTTP_PROXY}" ]; then
    export http_proxy=${HTTP_PROXY}
    export https_proxy=${HTTP_PROXY}
    export ftp_proxy=${HTTP_PROXY}
fi

cp -f /etc/docker/registry/config-example.yml /tmp/config.yml
if [ ! -z "${PULL_THROUGH_CACHE_OF}" ]; then
    echo "proxy:" >> /tmp/config.yml
    echo "  remoteurl: ${PULL_THROUGH_CACHE_OF}" >> /tmp/config.yml
fi
if [ ! -z "${PULL_THROUGH_CACHE_PORT}" ]; then
    sed -i -E "s/^[ ]+addr: :([0-9]+)\$/  addr: :${PULL_THROUGH_CACHE_PORT}/" /tmp/config.yml
fi
mv -f /tmp/config.yml /etc/docker/registry/config.yml

if [ ! -z "${PULL_THROUGH_CACHE_PORT}" ] && [ "${PULL_THROUGH_CACHE_PORT}" != "5000" ]; then
    socat TCP-LISTEN:5000,fork TCP:127.0.0.1:${PULL_THROUGH_CACHE_PORT} &
fi

set -e

case "$1" in
    *.yaml|*.yml)
    set -- registry serve "$@"
    ;;
    serve|garbage-collect|help|-*)
    set -- registry "$@"
    ;;
esac

echo "HTTP_PROXY=${HTTP_PROXY} HTTPS_PROXY=${HTTPS_PROXY}"
HTTP_PROXY="${HTTP_PROXY}" HTTPS_PROXY="${HTTPS_PROXY}" NO_PROXY="${NO_PROXY}" exec "$@"
