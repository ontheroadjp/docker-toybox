FROM nginx:1.9
MAINTAINER NutsProject,LLC


RUN tar cvzf /usr/src/nginx-default-doc.tar.gz -C /usr/share/nginx/html ./
RUN tar cvzf /usr/src/nginx-conf.tar.gz -C /etc/nginx ./

WORKDIR /usr/share/nginx/html

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
