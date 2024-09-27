#!/bin/bash
set -eEuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
source "${ROOT_DIR}"/scripts/utils.sh

check_requirements

select_node_type

select_network

set_deployment_dir

set_env_file

if ! [ -d "${DEPLOYMENT_DIR}" ]; then
  fn_die "\nDeployment directory does not exist, you may need to run 'init.sh' script first.. Exiting...\n"
fi

backup_dir=${DEPLOYMENT_DIR}_BK_$(date +%Y%m%d%H%M%S)
log_warn "\nBacking up deployment directory in ${backup_dir}"
cp -r "${DEPLOYMENT_DIR}" "${backup_dir}" || fn_die "\nError: could not backup deployment directory. Fix it before proceeding any further. Exiting...\n"
cp "${ROOT_DIR}/compose_files/docker-compose-${NODE_TYPE}.yml" "${DEPLOYMENT_DIR}/docker-compose.yml"

# Define the auto update variables
auto_update_vars=(
  "NODE_VERSION"
)

conditional_update_vars=()

# Read the .env.template file line by line, skip blank lines and comments, store each of the other lines in an array
log_info "\n=== Reading ${ENV_FILE_TEMPLATE} file"
while IFS= read -r line; do
  [ -z "${line}" ] && continue
  [ "${line:0:1}" = "#" ] && continue
  env_template_lines+=("${line}")
done <"${ENV_FILE_TEMPLATE}"

# Append new env vars to .env file
log_info "\n=== Appending new env vars to ${ENV_FILE} file"
for line in "${env_template_lines[@]}"; do
  var_name=$(echo "${line}" | cut -d'=' -f1)
  if ! grep -q "^${var_name}=" "${ENV_FILE}"; then
    echo -e "\n${line}" >>"${ENV_FILE}"
  fi
done

# Update the values of the auto update variables
log_info "\n=== Updating the values of the auto update variables..."
for line in "${env_template_lines[@]}"; do
  var_name=$(echo "${line}" | cut -d'=' -f1)
  for item in "${auto_update_vars[@]}"; do
    if [[ "${item}" == "${var_name}" ]]; then
      sed -i "/^${var_name}=/c\\${line}" "${ENV_FILE}"
      break
    fi
  done
done

# Update the values of the conditional update variables if approved by the user
log_info "\n=== Updating the values of the conditional update variables..."
for line in "${env_template_lines[@]}"; do
  var_name=$(echo "${line}" | cut -d'=' -f1)
  if ! [ ${#conditional_update_vars[@]} -eq 0 ]; then
    for item in "${conditional_update_vars[@]}"; do
      if [[ "${item}" == "${var_name}" ]]; then
        if ! grep -q "^${line}" "${ENV_FILE}"; then
          log_debug "\nThe value of ${var_name} in the ${ENV_FILE} file is different from the value in the ${ENV_FILE_TEMPLATE} file."
          log_debug "${ENV_FILE} value: \033[1m$(grep "^${var_name}=" "${ENV_FILE}")\033[0m"
          log_debug "${ENV_FILE_TEMPLATE} value: \033[1m${line}\033[0m\n"
          answer="$(selection_yn "Would you like to update the value of ${var_name} in the ${ENV_FILE} file to the value from the ${ENV_FILE_TEMPLATE} file?")"
          if [ "${answer}" = "yes" ]; then
            sed -i "/^${var_name}=/c\\${line}" "${ENV_FILE}"
          fi
        fi
        break
      fi
    done
  fi
done

log_info "\n=== ${ENV_FILE} update completed successfully"

log_info "\n=== Please review the changes in the ${ENV_FILE} file, if there is anything wrong you can restore from the backup ${backup_dir}"

log_info "\n=== Project has been updated correctly for ${NODE_TYPE} on ${NETWORK}"
log_info "\n=== Start the compose project with the following command: "
log_info "\n========================"
log_warn "docker compose -f ${DEPLOYMENT_DIR}/docker-compose.yml up -d --force-recreate"
log_info "========================\n"

exit 0
