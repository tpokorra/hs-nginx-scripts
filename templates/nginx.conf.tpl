pid NGINXPATH/run/nginx.pid;
events {
    worker_connections 1024;
#   worker_connections 4096;
}
http {
  include /etc/nginx/mime.types;
  error_log NGINXPATH/log/error.log warn;
  access_log NGINXPATH/log/access.log;
  server_names_hash_bucket_size 64;

  ##
  # Virtual Host Configs
  ##
  include NGINXPATH/etc/conf.d/*.conf;
}
