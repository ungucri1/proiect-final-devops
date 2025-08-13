FROM python:3.11-slim

WORKDIR /app

COPY backup.py .

ENV BACKUP_INTERVAL=5
ENV BACKUP_DIR=backup

CMD ["python","backup.py"]