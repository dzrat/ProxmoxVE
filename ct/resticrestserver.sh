#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/dzrat/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stefan Rauner (dzrat)
# License: MIT | https://github.com/dzrat/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/restic/rest-server

APP="ResticRestServer"
var_tags="${var_tags:-backup}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/restic-rest-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "restic-rest-server" "restic/rest-server"; then

    msg_info "Stopping Service"
    systemctl stop restic-rest-server
    msg_ok "Stopped Service"

    VERSION=$(get_latest_github_release "restic/rest-server")
    fetch_and_deploy_gh_release "restic-rest-server" "restic/rest-server" "prebuild" "${VERSION}" "/usr/local/bin" "rest-server_${VERSION}_linux_amd64.tar.gz"
    chmod +x /usr/local/bin/rest-server

    msg_info "Starting Service"
    systemctl start restic-rest-server
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
