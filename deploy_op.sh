#!/usr/bin/env bash

project_name=op
project_root=/srv
project_dir=$project_root/$project_name
project_repo=https://github.com/gorserg/openprocurement.buildout.git
project_branch=deploy_app

# Sanity Checks
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must be run with root privileges."
    exit 1
fi

# required os packages
packages="gcc file git libevent-devel python-devel sqlite-devel zeromq-devel libffi-devel openssl-devel systemd-python redhat-rpm-config couchdb mc"

# check for installed package
installed () {
    hash $1 2>/dev/null
}

# package manager for OS
package_manager=dnf

install_op () {
    if installed dnf; then
        # Fedora >= 22:
        package_manager=dnf
    elif installed yum; then
        # Fedora < 22:
        package_manager=yum
    elif installed apt-get; then
        # Debian/ubuntu:
        package_manager=apt-get
    else
	    echo "Not supported OS."
      exit 1
    fi

    echo "Install OS dependencies with $package_manager"
    $package_manager update -yy && $package_manager install -yy $packages

    echo "Create user (default op - as project name)"
    if id -u "$project_name" >/dev/null 2>&1; then
        echo "user [$project_name] exists"
    else
        useradd -mrU $project_name
	    echo "user [$project_name] created"
    fi

    echo "Create empty project directory"
    mkdir $project_dir

    echo "Clone repository $project_repo"
    git clone $project_repo $project_dir

    cd $project_dir

    echo "Swith to branch $project_branch"
    git checkout $project_branch

    echo "Create service script"
    if [ ! -f ./openprocurement.service ]; then
      cat > ./openprocurement.service <<CLICK
[Service]
WorkingDirectory=$project_dir
ExecStart=/bin/sh $project_dir/start.sh
Restart=always
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP \$MAINPID
SyslogIdentifier=openprocurement
User=$project_name
Group=$project_name

[Install]
WantedBy=multi-user.target
CLICK
    fi

    echo "Copy service script"
    cp openprocurement.service /etc/systemd/system/

    echo "Run python bootstrap.py"
    python bootstrap.py

    echo "Run buildout"
    bin/buildout -N

    echo "Run circusd"
    bin/circusd --daemon

    echo "Copy auth.ini from tests"
    cp src/openprocurement.api/src/openprocurement/api/tests/auth.ini auth.ini

    echo "Change directory owner"
    chown -R $project_name $project_root

    echo "Change directory group"
    chgrp $project_name $project_root

    echo "Start service"
    systemctl enable openprocurement
    systemctl start openprocurement
    systemctl status openprocurement
    echo "View journal"
    journalctl -u openprocurement
}

install_op
