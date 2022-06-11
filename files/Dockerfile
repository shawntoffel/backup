FROM mcr.microsoft.com/azure-cli:latest
COPY backup.sh .
RUN chmod +x backup.sh
ENV AZ_CONTAINER=backup \
    BACKUP_NAME=backup \
    BACKUP_DIRECTORY=/backups \
    AZ_BLOB_DELETE_DESTINATION=true \
    AZ_BLOB_ACCESS_TIER=Cool
    
ENTRYPOINT ["./backup.sh"]