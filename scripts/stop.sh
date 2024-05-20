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
else
  log_info "\n=== All the containers associated with the project were already stopped. Doing nothing..."
fi

exit 0
