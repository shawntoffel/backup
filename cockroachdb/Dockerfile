FROM alpine:latest as downloader
RUN apk update && apk add wget
RUN wget -q https://aka.ms/InstallAzureCLIDeb -O deb_install.sh
RUN wget -qO- https://binaries.cockroachdb.com/cockroach-v19.1.1.linux-amd64.tgz | tar xvz

FROM python:3.7.3-slim-stretch as cli
COPY --from=downloader deb_install.sh .
COPY --from=downloader cockroach-v19.1.1.linux-amd64/cockroach /usr/bin/
RUN chmod +x deb_install.sh && ./deb_install.sh && rm deb_install.sh
COPY backup.sh .
RUN chmod +x backup.sh
ENV AZ_CONTAINER=backups \
    REMOTE_HOST=localhost \
    BACKUP_NAME=backup
ENTRYPOINT ["./backup.sh"]