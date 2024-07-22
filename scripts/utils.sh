#!/bin/bash

log() {
  # Usage: log style color "message"
  # style: bold, italic, normal, light
  # color: black, red, green
  # Example: log bold red "Error: Something went wrong"

  # styles
  # shellcheck disable=SC2034
  local normal=0
  local bold=1
  # shellcheck disable=SC2034
  local shadow=2
  # shellcheck disable=SC2034
  local italic=3
  # colors
  # shellcheck disable=SC2034
  local black=30
  local red=31
  # shellcheck disable=SC2034
  local green=32
  # shellcheck disable=SC2034
  local yellow=33

  local usage="Usage: ${FUNCNAME[0]} style color \"message\"\nStyles: bold, italic, normal, light\nColors: black, red, green, yellow\nExample: log bold red \"Error: Something went wrong\""
  [ "$#" -lt 3 ] && {
    echo -e "\033[${bold};${red}m${FUNCNAME[0]} error: function requires three arguments.\n${usage}\033[0m"
    exit 1
  }
  # vars
  local style="${1}"
  local color="${2}"
  local message="${3}"
  # validate style is in bold, italic, normal, shadow
  if [[ ! "${style}" =~ ^(bold|italic|normal|shadow)$ ]]; then
    message="Error: Invalid style. Must be one of normal, bold, italic, shadow."
    echo -e "\033[${bold};${red}m${message}\033[0m"
    exit 1
  fi
  # validate color is in black, red, green
  if [[ ! "${color}" =~ ^(black|red|green|yellow)$ ]]; then
    message="Error: Invalid color. Must be one of black, red, green or yellow."
    echo -e "\033[${bold};${red}m${message}\033[0m"
    exit 1
  fi
  echo -e "\033[${!style};${!color}m${message}\033[0m"
}

log_info() {
  local usage="Log a message in bold green - Usage: ${FUNCNAME[0]} {message}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"
  log bold green "${1}" >&2
}

log_debug() {
  local usage="Log a message in normal green - Usage: ${FUNCNAME[0]} {message}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"
  log normal green "${1}" >&2
}

log_warn() {
  local usage="Log a message in normal yellow - Usage: ${FUNCNAME[0]} {message}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"
  log normal yellow "${1}" >&2
}

log_red() {
  local usage="Log a message in bold red - Usage: ${FUNCNAME[0]} {message}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"
  log bold red "${1}" >&2
}

fn_die() {
  log_red "${1}" >&2
  exit "${2:-1}"
}

selection() {
  local usage="Use select method for multi choice interaction with user - usage: ${FUNCNAME[0]} {string_to_be_used}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"

  local select_from_string="${1:-}"
  local user_exit_err_code=234

  select item in ${select_from_string} "quit"; do
    case "${item}" in
    "quit")
      fn_die "Exiting" "${user_exit_err_code}"
      ;;
    "")
      log_warn "\nInvalid selection. Please type the number of the option you want to use."
      ;;
    *)
      log_info "\nYou have selected: ${item}"
      echo "${item}"
      break
      ;;
    esac
  done
}

selection_yn() {
  local usage="Request user input - usage: ${FUNCNAME[0]} {message}"
  [ "${1:-}" = "usage" ] && log_debug "${usage}" && return
  [ "$#" -ne 1 ] && fn_die "\n${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"

  local message="${1}"
  local user_exit_err_code=234

  log_warn "${message}"
  response="$(selection "yes no")"
  if [[ ! "${response}" =~ ^(yes|no)$ ]]; then
    exit "${user_exit_err_code}"
  fi
  echo "${response}"
}

verify_required_commands() {

  command -v jq &>/dev/null || fn_die "${FUNCNAME[0]} Error: 'jq' is required to run this script, see installation instructions at 'https://jqlang.github.io/jq/download/'."

  command -v docker &>/dev/null || fn_die "${FUNCNAME[0]} Error: 'docker' is required to run this script, see installation instructions at 'https://docs.docker.com/engine/install/'."

  (docker compose version 2>&1 | grep -q v2) || fn_die "${FUNCNAME[0]} Error: 'docker compose' is required to run this script, see installation instructions at 'https://docs.docker.com/compose/install/'."

  if [ "$(uname)" = "Darwin" ]; then
    command -v gsed &>/dev/null || fn_die "${FUNCNAME[0]} Error: 'gnu-sed' is required to run this script in MacOS environment, see installation instructions at 'https://formulae.brew.sh/formula/gnu-sed'. Make sure to add it to your PATH."
  fi
}

check_requirements() {
  log_info "\n=== Checking all the requirements"
  # Making sure the script is not being run as root
  LOCAL_USER_ID="$(id -u)"
  LOCAL_GROUP_ID="$(id -g)"
  if [ "${LOCAL_USER_ID}" == 0 ] || [ "${LOCAL_GROUP_ID}" == 0 ]; then
    fn_die "\nError: This script should not be run as root. Exiting...\n"
  fi

  verify_required_commands

  docker info >/dev/null 2>&1 || fn_die "${FUNCNAME[0]} Error: 'docker daemon' is not running, start it before running this script."
}

check_env_var() {
  local usage="Check if required environmental variable is empty and produce an error - usage: ${FUNCNAME[0]} {env_var_name}"
  [ "${1:-}" = "usage" ] && echo "${usage}" && return
  [ "$#" -ne 1 ] && {
    fn_die "${FUNCNAME[0]} error: function requires exactly one argument.\n\n${usage}"
  }

  local var="${1}"
  if [ -z "${!var:-}" ]; then
    fn_die "Error: Environment variable ${var} is required. Exiting ..."
  fi
}

check_required_variables() {
  TO_CHECK=(
    "COMPOSE_PROJECT_NAME"
    "NODE_VERSION"
    "NODE_NAME"
    "NODE_NET_P2P_PORT"
    "ZKV_CONF_NAME"
    "ZKV_CONF_BASE_PATH"
    "ZKV_CONF_CHAIN"
  )

  if [ "${NODE_TYPE}" = "boot-node" ]; then
    TO_CHECK+=(
      "NODE_NET_P2P_PORT_WS"
      "ZKV_NODE_KEY_FILE"
      "ZKV_CONF_LISTEN_ADDR"
      "ZKV_CONF_LISTEN_ADDR_2"
    )
  fi

  if [ "${NODE_TYPE}" = "validator-node" ]; then
    TO_CHECK+=(
      "ZKV_NODE_KEY_FILE"
      "ZKV_CONF_VALIDATOR"
      "ZKV_SECRET_PHRASE_PATH"
    )
  fi

  if [ "${NODE_TYPE}" = "rpc-node" ]; then
    TO_CHECK+=(
      "NODE_NET_RPC_PORT"
      "ZKV_CONF_RPC_CORS"
      "ZKV_CONF_RPC_EXTERNAL"
      "ZKV_CONF_RPC_METHODS"
      "ZKV_CONF_PRUNING"
    )
  fi

  for var in "${TO_CHECK[@]}"; do
    check_env_var "${var}"
  done
}

select_node_type() {
  log_warn "\nWhat 'node type' would you like to run: "
  node_types="rpc-node validator-node boot-node"
  NODE_TYPE="$(selection "${node_types}")"
  export NODE_TYPE
}

select_network() {
  log_warn "\nWhat 'network' would you like to use: "
  NETWORKS="testnet"
  NETWORK="$(selection "${NETWORKS}")"
  export NETWORK
}

set_deployment_dir() {
  DEPLOYMENT_DIR="${ROOT_DIR}/deployments/${NODE_TYPE}/${NETWORK}"
  export DEPLOYMENT_DIR
}

set_env_file() {
  ENV_FILE_TEMPLATE="${ROOT_DIR}/env/.env.${NODE_TYPE}.${NETWORK}.template"
  ENV_FILE="${DEPLOYMENT_DIR}/.env"
  export ENV_FILE_TEMPLATE
  export ENV_FILE
}

create_node_key() {
  use_existing_node_key_answer="$(selection_yn "\nDo you want to import an already existing node key?")"
  if [ "${use_existing_node_key_answer}" = "yes" ]; then
    log_warn "\nPlease type or paste now the node key you want to import: "
    read -rp "#? " node_key
    set_existing_node_key_answer="$(selection_yn "\nDo you confirm this is the node key you want to import: ${node_key}?")"
    if [ "${set_existing_node_key_answer}" = "no" ]; then
      fn_die "Node key import aborted; please run again the init.sh script. Exiting ...\n"
    fi
  else
    if ! node_key="$(docker run --rm --entrypoint zkv-node horizenlabs/zkverify:"${NODE_VERSION}" key generate-node-key 2>/dev/null)"; then
      fn_die "\nError: could not generate node key. Fix it before proceeding any further. Exiting...\n"
    fi
  fi
  if [ -z "${node_key}" ]; then
    fn_die "\nError: node key is empty. Fix it before proceeding any further. Exiting...\n"
  fi
  echo -n "${node_key}" >"${DEPLOYMENT_DIR}/configs/node/secrets/node_key.dat"
  log_info "\nFile ${DEPLOYMENT_DIR}/configs/node/secrets/node_key.dat was created."
  log_red "\n***STORE A COPY OF THE FILE IN A SAFE PLACE. KEEP THE FILE UNDER ITS ORIGINAL LOCATION AS WELL SINCE IT IS REQUIRED TO RUN AND RECOVER (IF NEEDED) THE NODE***"
}

create_secret_phrase() {
  use_existing_secret_phrase_answer="$(selection_yn "\nDo you want to import an already existing secret phrase?")"
  if [ "${use_existing_secret_phrase_answer}" = "yes" ]; then
    log_warn "\nPlease type or paste now the secret phrase you want to import: "
    read -rp "#? " secret_phrase
    set_existing_secret_phrase_answer="$(selection_yn "\nDo you confirm this is the secret phrase you want to import: ${secret_phrase}?")"
    if [ "${set_existing_secret_phrase_answer}" = "no" ]; then
      fn_die "Secret phrase import aborted; please run again the init.sh script. Exiting ...\n"
    fi
  else
    if ! secret_json="$(docker run --rm --entrypoint zkv-node horizenlabs/zkverify:"${NODE_VERSION}" key generate --output-type json)"; then
      fn_die "\nError: could not generate secret phrase. Fix it before proceeding any further. Exiting...\n"
    fi
    if [ -z "${secret_json}" ]; then
      fn_die "\nError: secret json is empty. Fix it before proceeding any further. Exiting...\n"
    fi
    echo "${secret_json}" >"${DEPLOYMENT_DIR}/configs/node/secrets/secret.json"
    log_info "\nFile ${DEPLOYMENT_DIR}/configs/node/secrets/secret.json was created."
    log_red "\n***STORE A COPY OF THE FILE IN A SAFE PLACE.  IT IS REQUIRED TO RECOVER (IF NEEDED) THE NODE***"
    sleep 2
    secret_phrase="$(jq -r '.secretPhrase' "${DEPLOYMENT_DIR}/configs/node/secrets/secret.json")"
  fi
  if [ -z "${secret_phrase}" ]; then
    fn_die "\nError: secret phrase is empty. Fix it before proceeding any further. Exiting...\n"
  fi
  echo -n "${secret_phrase}" >"${DEPLOYMENT_DIR}/configs/node/secrets/secret_phrase.dat"
  log_info "\nFile ${DEPLOYMENT_DIR}/configs/node/secrets/secret_phrase.dat was created."
  log_red "\n***STORE A COPY OF THE FILE IN A SAFE PLACE. KEEP THE FILE UNDER ITS ORIGINAL LOCATION AS WELL SINCE IT IS REQUIRED TO RUN AND RECOVER (IF NEEDED) THE NODE***"
  sleep 2
}

set_up_node_name_env_var() {
  custom_node_name_answer="$(selection_yn "\nDo you want to choose a custom node name? (defaults to 'ext-${NODE_TYPE}-<random_number>')")"
  if [ "${custom_node_name_answer}" = "no" ]; then
    log_debug "\nSetting node name dynamically"
    node_name="ext-${NODE_TYPE}-$((RANDOM % 100000 + 1))" || fn_die "\nError: could not set name variable for some reason. Fix it before proceeding any further. Exiting...\n"
  else
    log_warn "\nPlease provide the node name you want to use: "
    read -rp "#? " node_name
    while [ -z "${node_name}" ]; do
      log_warn "\nNode name cannot be empty. Try again..."
      read -rp "#? " node_name
    done
  fi
  sed -i "s/ZKV_CONF_NAME=.*/ZKV_CONF_NAME=${node_name}/g" "${ENV_FILE}" || fn_die "\nError: could not set name variable in ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"
}

set_up_rpc_methods_env_var() {
  rpc_methods_answer="$(selection_yn "\nDo you want to set custom rpc methods? (defaults to 'safe')")"
  if [ "${rpc_methods_answer}" = "yes" ]; then
    log_warn "\nPlease select the rpc methods you want to use: "
    rpc_methods="$(selection "safe unsafe auto")"
    sed -i "s/ZKV_CONF_RPC_METHODS=.*/ZKV_CONF_RPC_METHODS=${rpc_methods}/g" "${ENV_FILE}" || fn_die "\nError: could not set rpc methods variable in ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"
  fi
}

set_up_pruning_env_var() {
  pruning_answer="$(selection_yn "\nDo you want to run an rpc archival node (this will keep a local copy of all blocks, enabling full historical data access)?")"
  if [ "${pruning_answer}" = "no" ]; then
    log_warn "\nPlease specify how many blocks to keep: "
    read -rp "#? " pruning_value
    while [ -z "${pruning_value}" ]; do
      log_warn "\nPruning value cannot be empty. Try again..."
      read -rp "#? " pruning_value
    done
    sed -i "s/ZKV_CONF_PRUNING=.*/ZKV_CONF_PRUNING=${pruning_value}/g" "${ENV_FILE}" || fn_die "\nError: could not set pruning configuration variable in ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"
  fi
}
