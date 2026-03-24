#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Stefan Rauner (dzrat)
# License: MIT | https://github.com/dzrat/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/restic/rest-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    curl \
    apache2-utils
msg_ok "Installed Dependencies"

msg_info "Installing Restic Rest Server"
VERSION=$(get_latest_github_release "restic/rest-server")
fetch_and_deploy_gh_release "restic-rest-server" "restic/rest-server" "prebuild" "v${VERSION}" "/usr/local/bin" "rest-server_${VERSION}_linux_amd64.tar.gz"
chmod +x /usr/local/bin/rest-server
msg_ok "Installed Restic Rest Server v${VERSION}"

msg_info "Configuring Restic Rest Server"
useradd --system --no-create-home --shell /usr/sbin/nologin restic
mkdir -p /opt/restic-data
mkdir -p /etc/restic
touch /etc/restic/.htpasswd
chown restic:restic /etc/restic/.htpasswd
chmod 600 /etc/restic/.htpasswd
chown -R restic:restic /opt/restic-data
msg_ok "Configured Restic Rest Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/restic-rest-server.service
[Unit]
Description=Restic Rest Server
After=network.target

[Service]
Type=simple
User=restic
Group=restic
ExecStart=/usr/local/bin/rest-server \
  --path /opt/restic-data \
  --listen :8000 \
  --htpasswd-file /etc/restic/.htpasswd \
  --append-only \
  --private-repos \
  --prometheus
Restart=on-failure
RestartSec=5
 
# Hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/restic-data
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now restic-rest-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
