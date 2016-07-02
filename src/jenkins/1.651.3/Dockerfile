FROM jenkins:1.651.3

USER root

COPY docker-entrypoint-ex.sh /entrypoint-ex.sh

ENTRYPOINT ["/entrypoint-ex.sh"]
CMD ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
