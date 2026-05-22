#!/bin/bash
set -e

echo "Starting ISG..."

TEMPLATE_FILE="/config.ini.template"
CONFIG_DIR="/etc/iconik/iconik_storage_gateway"
CONFIG_FILE="${CONFIG_DIR}/config.ini"

if [ ! -f "${TEMPLATE_FILE}" ]; then
    echo "ERROR: ${TEMPLATE_FILE} not found. Mount config.ini.template into the container." >&2
    exit 1
fi

# Defaults for optional env vars referenced by the template
: "${ICONIK_URL:=https://app.iconik.io/}"
export ICONIK_URL ICONIK_APP_ID ICONIK_AUTH_TOKEN ICONIK_STORAGE_GATEWAY_ID

missing=()
for var in ICONIK_APP_ID ICONIK_AUTH_TOKEN ICONIK_STORAGE_GATEWAY_ID; do
    if [ -z "${!var}" ]; then
        missing+=("${var}")
    fi
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: required env vars not set: ${missing[*]}" >&2
    echo "Set these in your .env file before starting the container." >&2
    exit 1
fi

mkdir -p "${CONFIG_DIR}"
envsubst < "${TEMPLATE_FILE}" > "${CONFIG_FILE}"

exec iconik_storage_gateway --config="${CONFIG_FILE}"
