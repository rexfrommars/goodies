#!/bin/bash

BOUNDARY="================================"

echo ""
echo ${BOUNDARY}
echo "whoami: $(whoami)"
if [ `whoami` != 'root' ]; then
    echo "*** EXIT: root privilege required ***"
    exit -1
fi

#
WD=${PWD}
WEB=/var/www/django/
PROJ=pilot

echo "PWD: ${WD}"
echo "WEB: ${WEB}"

_cmd() {
    CMD=$*
    echo "> ${CMD}"
    ${CMD}
}

# install nginx, also create user nginx:nginx
echo ""
echo ${BOUNDARY}

_cmd yum install nginx -y

# django
echo ""
echo ${BOUNDARY}

_cmd yum install gcc -y
_cmd yum install python36 -y
_cmd yum install python36-devel -y

_cmd mkdir -p ${WEB}

_cmd cd ${WEB}
_cmd virtualenv -p python3 P3
_cmd . ./P3/bin/activate
_cmd pip install django==1.11
_cmd django-admin startproject ${PROJ}

_cmd cd ${PROJ}
echo "> # edit ${PROJ}/settings.py ...."
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/g" ./${PROJ}/settings.py
echo "STATIC_ROOT = '${WEB}static/'"$'\n' >> ./${PROJ}/settings.py
_cmd python manage.py migrate
_cmd python manage.py collectstatic --clear
_cmd cd ..
_cmd chown -R nginx:nginx ${PROJ}
_cmd cd ${WD}

# gunicorn
echo ""
echo ${BOUNDARY}
_cmd pip install gunicorn
cd ${WEB}
cat > gunicorn_start.sh <<EOF
#!/bin/bash

source ${WEB}/P3/bin/activate
cd ${WEB}${PROJ}
exec gunicorn ${PROJ}.wsgi:application \\
    --bind=unix:/tmp/gunicorn_django.sock \\
    --user nginx \\
    --name ${PROJ} \\
    --workers 2

EOF
chmod +x gunicorn_start.sh

# spervisor
echo ""
echo ${BOUNDARY}
_cmd deactivate
_cmd pip install supervisor
_cmd cd /etc/init.d/
_cmd wget https://raw.githubusercontent.com/rexfrommars/goodies/master/ops/amazonlinux/supervisord/supervisord_al_2017_09 -O supervisord
_cmd chmod +x supervisord
_cmd cd /etc/
echo "/usr/local/bin/echo_supervisord_conf > supervisord.conf"
/usr/local/bin/echo_supervisord_conf > supervisord.conf
echo "> # edit /etc/supervisord.conf ...."
ed supervisord.conf <<EOF
99i
; == begin
[program:${PROJ}]
command=${WEB}/gunicorn_start.sh
numprocs=1
directory=/tmp
; == end

.
w
q
EOF


# nginx
echo ""
echo ${BOUNDARY}
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
ed /etc/nginx/nginx.conf <<EOF
40i
    upstream gunicorn_django_server {
        server unix:/tmp/gunicorn_django.sock fail_timeout=10s;
    }

.
w
53i
        location /static/ {
            alias ${WEB}/static/;
        }

.
w
58i
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header Host \$http_host;
            proxy_redirect off;
            proxy_pass http://gunicorn_django_server;
.
w
q
EOF


#
echo ""
echo ${BOUNDARY}
echo "chkconfig ...."
chkconfig --level 345 nginx on
chkconfig —add supervisord
chkconfig --level 345 supervisord on


#
echo ""
echo ${BOUNDARY}
echo "start services ...."
service supervisord start
service nginx start

#
echo ""
echo ""
echo ${BOUNDARY}
echo ""
echo "DONE"




