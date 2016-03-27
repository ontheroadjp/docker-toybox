#!/bin/sh

# src dir
if [ ! -e ./src ]; then
    mkdir ./src
fi

# shipyard
if [ ! -e ./src/shipyard ]; then
    git clone https://github.com/shipyard/shipyard.git ./src/shipyard
fi

# reichat
if [ ! -e ./src/reichat ]; then
    mkdir -p ./src/reichat
    echo 'FROM node:0.12.2' >> ./src/reichat/Dockerfile
    echo 'RUN npm install -g reichat' >> ./src/reichat/Dockerfile
    echo 'EXPOSE 10133' >> ./src/reichat/Dockerfile
    echo 'CMD reichat' >> ./src/reichat/Dockerfile
fi

# ---------------------------------
# docker-composer.yml
# ---------------------------------

out='docker-compose.yml'
domainname=nuts.jp

url_web=${domainname}
url_wordpress=wp.${domainname}
url_owncloud=cloud.${domainname}
url_shipyard=shipyard.${domainname}
url_fluentd=fluentd.${domainname}
url_growthforecast=growthforecast.${domainname}
url_codebox=codebox.${domainname}
url_ethercalc=ethercalc.${domainname}
url_wekan=wekan.${domainname}
url_reichat=reichat.${domainname}
url_lychee=lychee.${domainname}

if [ -e $out ]; then
    rm $out
fi

echo '# Load Balancer' >> ${out}
echo 'lb:' >> ${out}
echo '    image: jwilder/nginx-proxy' >> ${out}
echo '    environment:' >> ${out}
echo '        - security-opt=label:type:docker_t' >> ${out}
echo '    ports:' >> ${out}
echo '        - "80:80"' >> ${out}
echo '    volumes:' >> ${out}
echo '        - "/var/run/docker.sock:/tmp/docker.sock"' >> ${out}
echo '' >> ${out}

echo '# httpd' >> ${out}
echo 'web:' >> ${out}
echo '    image: nginx' >> ${out}
echo '    volumes: ' >> ${out}
echo '        - '$(pwd)'/data/web/html:/usr/share/nginx/html' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_web} >> ${out}
echo '    ports:' >> ${out}
echo '        - "80"' >> ${out}
echo '' >> ${out}

echo '# WordPress' >> ${out}
echo 'wp:' >> ${out}
echo '    image: wordpress' >> ${out}
echo '    links:' >> ${out}
echo '        - db:mysql' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_wordpress} >> ${out}
echo '    ports:' >> ${out}
echo '        - "40100"' >> ${out}
echo 'db:' >> ${out}
echo '    image: mariadb' >> ${out}
echo '    volumes_from:' >> ${out}
echo '        - db-data' >> ${out}
echo '    environment:' >> ${out}
echo '        MYSQL_ROOT_PASSWORD: root' >> ${out}
echo 'db-data:' >> ${out}
echo '    image: busybox' >> ${out}
echo '    volumes:' >> ${out}
echo '        - /var/lib/mysql' >> ${out}
echo '' >> ${out}

echo '# OwnCloud' >> ${out}
echo 'cloud:' >> ${out}
echo '    image: owncloud' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_owncloud} >> ${out}
echo '    ports:' >> ${out}
echo '        - "40110"' >> ${out}
echo '' >> ${out}

echo '# shipyard' >> ${out}
echo 'rethinkdb:' >> ${out}
echo '    image: rethinkdb' >> ${out}
echo '    ports:' >> ${out}
echo '        - "8080"' >> ${out}
echo '        - "28015"' >> ${out}
echo '        - "29015"' >> ${out}
echo 'proxy:' >> ${out}
echo '    image: ehazlett/docker-proxy:latest' >> ${out}
echo '    command: -i' >> ${out}
echo '    volumes:' >> ${out}
echo '        - "/var/run/docker.sock:/var/run/docker.sock"' >> ${out}
echo '    ports:' >> ${out}
echo '        - "2375"' >> ${out}
echo 'swarm:' >> ${out}
echo '    image: swarm:latest' >> ${out}
echo '    command: m --host tcp://0.0.0.0:2375 proxy:2375' >> ${out}
echo '    links:' >> ${out}
echo '        - "proxy:proxy"' >> ${out}
echo '    ports:' >> ${out}
echo '        - "2375"' >> ${out}
echo 'media:' >> ${out}
echo '    build: src/shipyard/' >> ${out}
echo '    entrypoint: /bin/bash' >> ${out}
echo '    dockerfile: Dockerfile.build' >> ${out}
echo '    command: -c "make media && sleep infinity"' >> ${out}
echo '    working_dir: /go/src/github.com/shipyard/shipyard' >> ${out}
echo '    volumes:' >> ${out}
echo '        - "/go/src/github.com/shipyard/shipyard/controller/static"' >> ${out}
echo 'controller:' >> ${out}
echo '    build: src/shipyard/' >> ${out}
echo '    entrypoint: /bin/bash' >> ${out}
echo '    dockerfile: Dockerfile.build' >> ${out}
echo '    command: -c "make build && cd controller && ./controller -D server --rethinkdb-addr rethinkdb:28015 -d tcp://swarm:2375"' >> ${out}
echo '    links:' >> ${out}
echo '        - rethinkdb' >> ${out}
echo '        - swarm' >> ${out}
echo '    volumes_from:' >> ${out}
echo '        - media' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_shipyard} >> ${out}
echo '    ports:' >> ${out}
echo '        #- "8080:8080"' >> ${out}
echo '        - "8080"' >> ${out}
echo '' >> ${out}

echo '# fluentd' >> ${out}
echo 'fluentd-ui:' >> ${out}
echo '    image: minimum2scp/fluentd-ui ' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_fluentd} >> ${out}
echo '    ports:' >> ${out}
echo '        #- "24224"' >> ${out}
echo '        - "42000"' >> ${out}
echo '' >> ${out}

echo '# growthforecast' >> ${out}
echo 'growthforecast:' >> ${out}
echo '    image: kazeburo/growthforecast' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_growthforecast} >> ${out}
echo '    ports:' >> ${out}
echo '        - "5125"' >> ${out}
echo '        #- "42010"' >> ${out}
echo '' >> ${out}
echo '' >> ${out}

echo '# codebox' >> ${out}
echo 'data00codebox:' >> ${out}
echo '    image: busybox:buildroot-2014.02' >> ${out}
echo '    volumes:' >> ${out}
echo '        - /data/codebox:/workspace' >> ${out}
echo 'codebox:' >> ${out}
echo '    image: 'javierprovecho/docker-codebox'' >> ${out}
echo '    volumes_from:' >> ${out}
echo '        - data00codebox' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_codebox} >> ${out}
echo '    ports:' >> ${out}
echo '        - 8000' >> ${out}
echo '' >> ${out}

echo '# EtherCalc' >> ${out}
echo 'data00redis:' >> ${out}
echo '    image: busybox:buildroot-2014.02' >> ${out}
echo '    volumes:' >> ${out}
echo '        - /data/redis:/data' >> ${out}
echo 'redis:' >> ${out}
echo '    image: redis:3.0.3' >> ${out}
echo '    volumes_from:' >> ${out}
echo '        - data00redis' >> ${out}
echo '    command: redis-server --appendonly yes' >> ${out}
echo 'ethercalc:' >> ${out}
echo '    image: audreyt/ethercalc' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_ethercalc} >> ${out}
echo '    ports:' >> ${out}
echo '        - "8000"' >> ${out}
echo '    links:' >> ${out}
echo '        - redis:redis' >> ${out}
echo '    command: ["sh", "-c", "REDIS_HOST=$$REDIS_PORT_6379_TCP_ADDR REDIS_PORT=$$REDIS_PORT_6379_TCP_PORT pm2 start -x `which ethercalc` -- --cors && pm2 logs"]' >> ${out}
echo '' >> ${out}
echo '' >> ${out}

echo '# wekan' >> ${out}
echo 'data00mongo:' >> ${out}
echo '    image: busybox:buildroot-2014.02' >> ${out}
echo '    volumes:' >> ${out}
echo '        - /data/mongo:/data/db' >> ${out}
echo 'mongo:' >> ${out}
echo '    image: mongo:3.1.5' >> ${out}
echo '    volumes_from:' >> ${out}
echo '        - data00mongo' >> ${out}
echo '    command: mongod --smallfiles' >> ${out}
echo 'libreboard:' >> ${out}
echo '    image: miurahr/libreboard:20150503' >> ${out}
echo '    environment:' >> ${out}
echo '        MONGO_URL: mongodb://mongo:27017/libreboard' >> ${out}
echo '        ROOT_URL: http://wekan.nuts.jp' >> ${out}
echo '    links:' >> ${out}
echo '        - mongo:mongo' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_wekan} >> ${out}
echo '    ports:' >> ${out}
echo '        - "5555"' >> ${out}
echo '' >> ${out}

echo '# reichat' >> ${out}
echo 'reichat:' >> ${out}
echo '    environment:' >> ${out}
echo '        - VIRTUAL_HOST='${url_reichat} >> ${out}
echo '    build: src/reichat' >> ${out}
echo '    ports:' >> ${out}
echo '        - "10133"' >> ${out}


