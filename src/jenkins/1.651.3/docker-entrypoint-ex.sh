#!/bin/bash

usermod -u ${TOYBOX_UID} jenkins
groupmod -g ${TOYBOX_GID} jenkins

wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 install-plugin git-client git github
cat /usr/share/jenkins/job-docker-toybox.xml | java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080 create-job docker-toybox

#out="/usr/share/jenkins/plugins.txt"
#echo "git-client" > ${out}
#echo "git" >> ${out}
#echo "github" >> ${out}
#/usr/local/bin/plugins.sh ${out}

exec "$@"
