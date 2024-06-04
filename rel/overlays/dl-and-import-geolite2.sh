#!/usr/bin/env sh

set -e

ts=$(date +"%Y-%m-%d-%H-%M-%S")

mkdir -p "/tmp/geolite2-$ts" && \
  cd "/tmp/geolite2-$ts" && \
  curl -JLO -H "$MAXMIND_BASIC_AUTH_HEADER" 'https://download.maxmind.com/geoip/databases/GeoLite2-City-CSV/download?suffix=zip.sha256' && \
  curl -JLO -H "$MAXMIND_BASIC_AUTH_HEADER" 'https://download.maxmind.com/geoip/databases/GeoLite2-City-CSV/download?suffix=zip' && \
  /app/bin/import_geolite2 "/tmp/geolite2-$ts" && \
  cd .. && \
  rm -rf "/tmp/geolite2-$ts"
