FROM nginx:1.9
MAINTAINER NutsProject,LLC

RUN mkdir -p /usr/src/nginx \
    && cp -r /usr/share/nginx/html/* /usr/src/nginx
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
