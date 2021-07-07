[supervisord]
logfile=SUPERVISORPATH/log/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=error
pidfile=SUPERVISORPATH/run/supervisord.pid
minfds=1024
minprocs=200
childlogdir=SUPERVISORPATH/log/

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix://SUPERVISORPATH/run/supervisord.sock

[program:nginx]
command=/usr/sbin/nginx -c NGINXPATH/etc/nginx.conf -p NGINXPATH -g 'error_log NGINXPATH/log/error.log warn;'
stderr_logfile = SUPERVISORPATH/log/nginx-stderr.log
stdout_logfile = SUPERVISORPATH/log/nginx-stdout.log

