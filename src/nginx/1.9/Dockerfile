FROM nginx:1.9
MAINTAINER NutsProject,LLC


RUN tar cvzf /usr/src/nginx-default-doc.tar.gz -C /usr/share/nginx/html ./
WORKDIR /usr/share/nginx/html

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
