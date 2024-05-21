#!/bin/bash
set -eEuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
source "${ROOT_DIR}"/scripts/utils.sh

check_requirements

select_node_type

select_network

set_deployment_dir

if ! [ -d "${DEPLOYMENT_DIR}" ]; then
  fn_die "\nDeployment directory does not exist. Exiting...\n"
fi

containers="$(docker compose -f "${DEPLOYMENT_DIR}"/docker-compose.yml ps -a -q)" || fn_die "\nError: could not identify existing containers to stop. Exiting...\n"
if [ -n "${containers}" ]; then
  log_info "\n=== Stopping the project..."
  docker compose -f "${DEPLOYMENT_DIR}"/docker-compose.yml down
  log_info "\n=== Project has been stopped successfully."
fi

remove_volumes_answer="$(selection_yn "\nDo you want to remove docker volumes?")"
if [ "${remove_volumes_answer}" = "yes" ]; then
  log_info "\n=== Removing docker volumes..."
  docker compose -f "${DEPLOYMENT_DIR}"/docker-compose.yml down --volumes
fi

remove_deployment_dir_answer="$(selection_yn "\nDo you want to remove the deployment directory?")"
if [ "${remove_deployment_dir_answer}" = "yes" ]; then
  log_info "\n=== Removing deployment directory..."
  rm -rf "${DEPLOYMENT_DIR?}"
fi

remove_deployment_backup_dir_answer="$(selection_yn "\nDo you want to remove deployment BACKUP directory(ies)?")"
if [ "${remove_deployment_backup_dir_answer}" = "yes" ]; then
  log_info "\n=== Removing deployment BACKUP directory(ies)..."
  rm -rf "${DEPLOYMENT_DIR?}_BK"*
fi

log_info "\n=== Project has been destroyed successfully."

exit 0
