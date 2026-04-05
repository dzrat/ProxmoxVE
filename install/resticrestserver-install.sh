#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourName (YourGitHubUsername)
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
$STD apt-get install -y apache2-utils
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "rest-server" "restic/rest-server" "prebuild" "latest" "/tmp/rest-server" "rest-server_*_linux_amd64.tar.gz"

msg_info "Installing Restic REST Server"
mv /tmp/rest-server/rest-server /usr/local/bin/rest-server
chmod +x /usr/local/bin/rest-server
rm -rf /tmp/rest-server
mkdir -p /opt/rest-server/data
RESTIC_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -b -B -c /opt/rest-server/.htpasswd admin "$RESTIC_PASS"
{
  echo "Restic-REST-Server-Credentials"
  echo "Username: admin"
  echo "Password: $RESTIC_PASS"
} >>~/rest-server.creds
msg_ok "Installed Restic REST Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rest-server.service
[Unit]
Description=Restic REST Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rest-server --path /opt/rest-server/data --listen :8000 --htpasswd-file /opt/rest-server/.htpasswd
Restart=on-failure
RestartSec=5
UMask=077
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ReadWritePaths=/opt/rest-server/data
MemoryDenyWriteExecute=true
LockPersonality=true
RestrictSUIDSGID=true
RestrictRealtime=true
SystemCallArchitectures=native
SystemCallFilter=@system-service
RemoveIPC=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rest-server
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
