echo step 1 - install packages 
dnf install gcc file git libevent-devel python-devel sqlite-devel zeromq-devel libffi-devel openssl-devel systemd-python redhat-rpm-config couchdb
echo step 2 - bootstrap
python bootstrap.py
echo step 3 - buildout
bin/buildout -N
echo step 4 - start couchdb
couchdb -b
echo step 5 - run app
bin/pserve etc/openprocurement.api.ini
