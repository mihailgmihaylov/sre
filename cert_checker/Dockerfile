FROM python:3.11-slim

WORKDIR /app

COPY cert_checker.py /app/cert_checker.py
COPY config /app/config

ENTRYPOINT ["python", "/app/cert_checker.py", "--config", "/app/config/sites.json"]
