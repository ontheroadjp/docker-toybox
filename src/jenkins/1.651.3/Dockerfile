FROM jenkins:1.651.3

USER root

COPY global_security.groovy /usr/share/jenkins/ref/init.groovy.d/global_security.groovy
COPY job-docker-toybox.xml /usr/share/jenkins/job-docker-toybox.xml
COPY job-docker-hello-world.xml /usr/share/jenkins/job-docker-hello-world.xml

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh
COPY post-run.sh /post-run.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
CMD ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
