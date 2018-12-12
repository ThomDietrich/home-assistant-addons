#!/bin/bash
set -e

CONFIG_PATH=/data/options.json
CONFIG=/frpc.ini

HASS_IP=172.17.0.1

SERVER_HOSTNAME=$(jq --raw-output ".server_hostname" $CONFIG_PATH)
SERVER_PORT=$(jq --raw-output ".server_port" $CONFIG_PATH)
TOKEN=$(jq --raw-output ".token" $CONFIG_PATH)



cat <<EOF > $CONFIG
[common]
server_addr = ${SERVER_HOSTNAME}
server_port = ${SERVER_PORT}
token = ${TOKEN}

[ssh]
type = tcp
local_ip = ${HASS_IP}
local_port = 22
remote_port = 6000

[hass]
type = tcp
local_ip = ${HASS_IP}
local_port = 8123
remote_port = 6001
use_encryption = true
use_compression = true
EOF

/frpc $CONFIG
