#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/dzrat/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourName (YourGitHubUsername)
# License: MIT | https://github.com/dzrat/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/restic/rest-server

APP="Restic REST Server"
var_tags="${var_tags:-backup;restic}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
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
  if [[ ! -f /usr/local/bin/rest-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "rest-server" "restic/rest-server"; then
    msg_info "Stopping Service"
    systemctl stop rest-server
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "rest-server" "restic/rest-server" "prebuild" "latest" "/tmp/rest-server" "rest-server_*_linux_amd64.tar.gz"

    msg_info "Updating Restic REST Server"
    mv /tmp/rest-server/rest-server /usr/local/bin/rest-server
    chmod +x /usr/local/bin/rest-server
    rm -rf /tmp/rest-server
    msg_ok "Updated Restic REST Server"

    msg_info "Starting Service"
    systemctl start rest-server
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW} Credentials are stored in:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}~/rest-server.creds${CL}"
