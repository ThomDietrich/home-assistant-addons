#!/usr/bin/with-contenv bashio  # bash
# shellcheck shell=bash
set -e

CONFIG_PATH=/data/options.json
KEY_PATH=/data/ssh_keys

HOSTNAME=$(jq --raw-output ".hostname" $CONFIG_PATH)
SSH_PORT=$(jq --raw-output ".ssh_port" $CONFIG_PATH)
USERNAME=$(jq --raw-output ".username" $CONFIG_PATH)

FORWARD_REMOTE_IP_ADDRESS=$(jq --raw-output ".remote_ip_address" $CONFIG_PATH)
FORWARD_REMOTE_PORT=$(jq --raw-output ".remote_port" $CONFIG_PATH)
FORWARD_LOCAL_IP_ADDRESS=$(jq --raw-output ".local_ip_address" $CONFIG_PATH)
FORWARD_LOCAL_PORT=$(jq --raw-output ".local_port" $CONFIG_PATH)
CUSTOM_REMOTE_FORWARDING=$(jq --raw-output ".remote_forwarding[]" $CONFIG_PATH)
if [ -z "$FORWARD_LOCAL_IP_ADDRESS" ] || [ "$FORWARD_LOCAL_IP_ADDRESS" = "null" ]; then
  FORWARD_LOCAL_IP_ADDRESS="172.30.32.1"
fi
if [ -z "$FORWARD_LOCAL_PORT" ] || [ "$FORWARD_LOCAL_PORT" = "null" ]; then
  FORWARD_LOCAL_PORT=8123
fi
FORWARD_LOCAL_SOCKET="${FORWARD_LOCAL_IP_ADDRESS}:${FORWARD_LOCAL_PORT}"
FORWARD_REMOTE_SOCKET="${FORWARD_REMOTE_IP_ADDRESS}:${FORWARD_REMOTE_PORT}"
FORWARDING_STRING="-R ${FORWARD_REMOTE_SOCKET}:${FORWARD_LOCAL_SOCKET}"
if [ -n "$CUSTOM_REMOTE_FORWARDING" ]; then
  while read -r LINE; do
    FORWARDING_STRING="${FORWARDING_STRING} -R ${LINE}"
  done <<< "${CUSTOM_REMOTE_FORWARDING}"
fi

OTHER_SSH_OPTIONS=$(jq --raw-output ".other_ssh_options" $CONFIG_PATH)
FORCE_GENERATION=$(jq --raw-output ".force_keygen" $CONFIG_PATH)

#

#
echo ""
echo ""
bashio::log.info "Starting initialization script"
echo ""
echo "The container is connected via the following IP addresses:"
ip -o address show
echo ""

if [ "$FORCE_GENERATION" != "false" ]; then
  bashio::log.info "Deleting existing key pair due to set 'force_keygen'"
  bashio::log.warning "Do not forget to unset 'force_keygen' in your add-on configuration"
  rm -rf "$KEY_PATH"
fi

if [ ! -d "$KEY_PATH" ]; then
  bashio::log.info "No previous key pair found"
  mkdir -p "$KEY_PATH"
  ssh-keygen -b 4096 -t ed25519 -N "" -C "hassio-setup-via-autossh" -f "${KEY_PATH}/autossh_rsa_key"
  bashio::log.info "The public key is:"
  cat "${KEY_PATH}/autossh_rsa_key.pub"
  bashio::log.warning "Add this key to '~/.ssh/authorized_keys' on your remote server now!"
  bashio::log.warning "Please restart add-on when done. Exiting..."
  exit 1
else
  bashio::log.info "Authentication key pair restored"
fi

echo ""
bashio::log.info "The public key used by this add-on is:"
cat "${KEY_PATH}/autossh_rsa_key.pub"
bashio::log.info "If not done so already, please add the key to '~/.ssh/authorized_keys' on your remote server"

#

if [ -z "$HOSTNAME" ]; then
  echo ""
  bashio::log.error "Please set 'hostname' in your config to the address of your remote server"
  exit 1
fi

echo ""
HTTP_STATUS_CODE=$(/usr/bin/curl --write-out %{http_code} --silent --output /dev/null http://${FORWARD_LOCAL_SOCKET}) || true
HTTPS_STATUS_CODE=$(/usr/bin/curl --write-out %{http_code} --silent --insecure --output /dev/null https://${FORWARD_LOCAL_SOCKET}) || true
if [[ "${HTTP_STATUS_CODE}" -ne 200 && "${HTTPS_STATUS_CODE}" -ne 200 ]] ; then
  bashio::log.error "Testing Home Assistant socket '${FORWARD_LOCAL_SOCKET}' on the local system..."\
    "Failed with HTTP status code ${HTTP_STATUS_CODE} and HTTPS status code ${HTTPS_STATUS_CODE}."\
    "Please check your config and consult the addon documentation."
  exit 1
elif [[ "${HTTP_STATUS_CODE}" -eq 200 ]]; then
  bashio::log.info "Testing Home Assistant socket '${FORWARD_LOCAL_SOCKET}' on the local system... Web frontend reachable over HTTP"
elif [[ "${HTTPS_STATUS_CODE}" -eq 200 ]]; then
  bashio::log.info "Testing Home Assistant socket '${FORWARD_LOCAL_SOCKET}' on the local system... Web frontend reachable over HTTPS"
fi

TEST_COMMAND="/usr/bin/ssh "\
"-o BatchMode=yes "\
"-o ConnectTimeout=5 "\
"-o PubkeyAuthentication=no "\
"-o PasswordAuthentication=no "\
"-o KbdInteractiveAuthentication=no "\
"-o ChallengeResponseAuthentication=no "\
"-o StrictHostKeyChecking=no "\
"-p ${SSH_PORT} -t -t "\
"${USERNAME}@${HOSTNAME} "\
"2>&1 || true"

echo ""
if eval "${TEST_COMMAND}" | grep -q "Permission denied"; then
  bashio::log.info "Testing SSH service on '${HOSTNAME}:${SSH_PORT}'... SSH service reachable on remote server"
else
  eval "${TEST_COMMAND}"
  bashio::log.error "Testing SSH service on '${HOSTNAME}:${SSH_PORT}'... Failed to reach the SSH service on the remote server. "\
    "Please check your config and consult the addon documentation."
  exit 1
fi

echo ""
bashio::log.info "Remote server host keys:"
ssh-keyscan -p $SSH_PORT $HOSTNAME || true

COMMAND="/usr/bin/autossh "\
"-M 0 "\
"-o ServerAliveInterval=30 "\
"-o ServerAliveCountMax=3 "\
"-o StrictHostKeyChecking=no "\
"-o ExitOnForwardFailure=yes "\
"-p ${SSH_PORT} -t -t "\
"-i ${KEY_PATH}/autossh_rsa_key "\
"${USERNAME}@${HOSTNAME}"

COMMAND="${COMMAND} ${FORWARDING_STRING} ${OTHER_SSH_OPTIONS}"

echo ""
bashio::log.info "Preparations done."
echo ""

while true; do
  bashio::log.info "Executing command: ${COMMAND}"
  /usr/bin/autossh -V
  exec ${COMMAND}
  echo ""
  bashio::log.error "SSH service seems to have crashed. Trying to reconnect..."
  echo ""
done
