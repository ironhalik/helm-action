FROM ghcr.io/ironhalik/kubectl-action-base:v1.0

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
