#!/usr/bin/env bash

# Overseer installer by flying sausages 2020 GPLv3

_dependencies() {
    apt_install libsqlite3-dev sqlite3

    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm
    npm_install #Install node 12 LTS and npm if they're not present or outdated

    echo_progress_start "Installing yarn"
    npm install -g yarn || {
        echo_error "Yarn failed to install"
        exit 1
    }
    echo_progress_done "Yarn installed"
}

_user() {
    cat > /opt/overseerr/env.conf << EOF
# specify on which port to listen
PORT=5055
EOF
    useradd overseerr --system -d /opt/overseerr
    chown -R overseerr: /opt/overseerr
}

_service() {
    # Adapted from
    cat > /etc/systemd/system/overseerr.conf << EOF
[Unit]
Description=Overseerr Service
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=/opt/overseerr/env.conf
Environment=NODE_ENV=production
User=overseerr
Group=overseerr
Type=exec
Restart=on-failure
WorkingDirectory=/opt/overseerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
    systemctl dameon-reload
    systemctl enable --now -q overseerr
}

_nginx() {
    if [ -f "/install/.nginx.lock" ]; then
        echo_progress_start "Configuring nginx"
        : # TODO nginx
        echo_progress_done "Nginx configured"
    fi

}

_dependencies
#shellcheck source=sources/functions/overseerr
. /etc/swizzin/sources/functions/overseerr
overseerr_install
_user
_service
_nginx

touch /install/.overseerr.lock
