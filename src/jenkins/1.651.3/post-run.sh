#!/bin/bash

http_status=$(curl -LI localhost:8080/login -o /dev/null -w '%{http_code}\n' -s)
while [ ${http_status} -ne 200 ]; do
    echo "waiting(${http_status})..." && sleep 3
    http_status=$(curl -LI localhost:8080/login -o /dev/null -w '%{http_code}\n' -s)
done
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 install-plugin git-client git github --username toybox --password toybox
cat /usr/share/jenkins/job-docker-toybox.xml | java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 create-job docker-toybox --username toybox --password toybox
cat /usr/share/jenkins/job-docker-hello-world.xml | java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 create-job docker-hello-world --username toybox --password toybox
java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 safe-restart --username toybox --password toybox

exec "$@"
