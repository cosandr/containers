FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY 40-chown-mount.sh /docker-entrypoint.d/40-chown-mount.sh
