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

log_info "\n=== Starting the project..."
docker compose -f "${DEPLOYMENT_DIR}"/docker-compose.yml up -d --force-recreate --remove-orphans

log_info "\n=== Project has been started successfully."

exit 0
