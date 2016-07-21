FROM nginx:1.11.1
MAINTAINER NutsProject,LLC


RUN tar cvzf /usr/src/nginx-default-doc.tar.gz -C /usr/share/nginx/html ./ \
    && tar cvzf /usr/src/nginx-conf.tar.gz -C /etc/nginx ./

WORKDIR /var/www/html

COPY default.conf /default.conf
COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
