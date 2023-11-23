#!/usr/bin/env sh

set -e

/app/bin/prom-aggregation-gateway --apiListen :9091 &
supercronic /app/crontab
