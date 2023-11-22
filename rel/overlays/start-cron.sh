#!/usr/bin/env sh

set -e

/app/bin/pushgateway &
supercronic /app/crontab
