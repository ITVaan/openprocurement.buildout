#!/usr/bin/env bash

project_name=op
project_root=/home/vagrant
project_dir=$project_root/$project_name
project_repo=https://github.com/gorserg/openprocurement.buildout.git
project_branch=deploy_app

# required os packages
packages="gcc file git libevent-devel python-devel sqlite-devel zeromq-devel libffi-devel openssl-devel systemd-python redhat-rpm-config couchdb mc"

# check for installed package
installed () {
    hash $1 2>/dev/null
}

install_op () {
    # Install os dependencies:
    if installed dnf; then
        # Fedora >= 22:
        sudo dnf update -yy
        sudo dnf install -yy $packages
    elif installed yum; then
        # Fedora < 22:
        sudo yum update -yy
        sudo yum install -yy $packages
    elif installed apt-get; then
        # Debian/ubuntu:
        sudo apt-get update -yy
        sudo apt-get install -yy $packages
    else
	    echo "Not supported OS."
    fi

    echo "start couchdb"
    sudo couchdb -b



    #create user (default op - as project name)
    if id -u "$project_name" >/dev/null 2>&1; then
        echo "user [$project_name] exists"
    else
        sudo useradd -mrU $project_name
	    echo "user [$project_name] created"
    fi

    # delete project directory if exists
    if [ -d "$project_dir" ]; then
        sudo rm -r -f $project_dir
    fi

    # create empty project directory
    sudo mkdir $project_dir

    sudo chmod -R 777 $project_root

    # change directory owner
    sudo chown -R $project_name $project_root

    # change directory group
    sudo chgrp $project_name $project_root

    echo "clone repository $project_repo"
    sudo git clone $project_repo $project_dir

    cd $project_dir

    # copy auth.ini from tests
    cp src/openprocurement.api/src/openprocurement/api/tests/auth.ini auth.ini

    echo "swith to branch $project_branch"
    sudo git checkout $project_branch

    echo create service script
    sudo cat templates/openprocurement.service \
         | sed "s|{work_dir}|$project_dir|g" \
	     | sed "s|{pserve_file}|$project_dir/bin/pserve|g" \
         | sed "s|{ini_file}|$project_dir/etc/openprocurement.api.ini|g" \
         | sed "s|{proj_user}|$project_name|g" \
	 > openprocurement.service

    # copy service script
    sudo cp openprocurement.service /etc/systemd/system/

    echo "run python bootstrap.py"
    sudo python bootstrap.py

    echo "run buildout"
    sudo bin/buildout -N

    echo "start service"
    sudo systemctl enable openprocurement
    sudo systemctl start openprocurement
    sudo systemctl status openprocurement
    echo "view journal"
    sudo journalctl -u openprocurement
}

install_op
