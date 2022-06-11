FROM mcr.microsoft.com/azure-cli:latest
RUN apk update --no-cache && apk add mysql-client
COPY backup.sh .
RUN chmod +x backup.sh
ENV AZ_CONTAINER=backups \
    REMOTE_HOST=localhost \
    BACKUP_NAME=backup
ENTRYPOINT ["./backup.sh"]