#!/bin/bash
set -eEuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
source "${ROOT_DIR}"/scripts/utils.sh

check_requirements

select_node_type

select_network

set_deployment_dir

set_env_file


if [ -d "${DEPLOYMENT_DIR}" ]; then
  overwrite_deployment_dir_answer="$(selection_yn "\nDeployment directory already exists. Do you want to overwrite it?")"
  if [ "${overwrite_deployment_dir_answer}" = "yes" ]; then
    backup_dir=${DEPLOYMENT_DIR}_BK_$(date +%Y%m%d%H%M%S)
    log_warn "\nBacking up deployment directory in ${backup_dir}"
    cp -r "${DEPLOYMENT_DIR}" "${backup_dir}" || fn_die "\nError: could not backup deployment directory. Fix it before proceeding any further. Exiting...\n"
    rm -rf "${DEPLOYMENT_DIR?}" || fn_die "\nError: could not remove deployment directory. Fix it before proceeding any further. Exiting...\n"
  fi
fi

if ! [ -d "${DEPLOYMENT_DIR}" ]; then
  log_info "\n=== Preparing deployment directory ${DEPLOYMENT_DIR}"
  mkdir -p "${DEPLOYMENT_DIR}" || fn_die "\nError: could not create deployment directory. Fix it before proceeding any further. Exiting...\n"
  mkdir -p "${DEPLOYMENT_DIR}/configs/node/secrets" || fn_die "\nError: could not create secrets directory. Fix it before proceeding any further. Exiting...\n"
  cp "${ROOT_DIR}/compose_files/docker-compose-${NODE_TYPE}.yml" "${DEPLOYMENT_DIR}/docker-compose.yml"

  if ! [ -f "${ENV_FILE}" ]; then
    log_info "\n=== Creating .env file"
    cp "${ENV_FILE_TEMPLATE}" "${ENV_FILE}"
    # shellcheck source=.env
    source "${ENV_FILE}" || fn_die "\nError: could not source ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"

    set_up_node_name_env_var

    if [ "${NODE_TYPE}" = "rpc-node" ]; then
      set_up_rpc_methods_env_var
      set_up_pruning_env_var
    fi

    if [ "${NODE_TYPE}" = "boot-node" ]; then
      set_acme_vhost
      set_acme_email_address
    fi
  fi

  # shellcheck source=.env
  source "${ENV_FILE}" || fn_die "\nError: could not source ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"
  check_required_variables

  if [ "${NODE_TYPE}" = "boot-node" ]; then
    log_info "\n=== Setting up node configuration"
    create_node_key
  fi

  if [ "${NODE_TYPE}" = "validator-node" ]; then
    log_info "\n=== Setting up node configuration"
    create_node_key
    create_secret_phrase
  fi
fi

# shellcheck source=.env
source "${ENV_FILE}" || fn_die "\nError: could not source ${ENV_FILE} file. Fix it before proceeding any further. Exiting...\n"
check_required_variables

log_info "\n=== Project has been initialized correctly for ${NODE_TYPE} on ${NETWORK}"
log_info "\n=== Start the compose project with the following command: "
log_info "\n========================"
log_warn "docker compose -f ${DEPLOYMENT_DIR}/docker-compose.yml up -d"
log_info "========================\n"

exit 0
