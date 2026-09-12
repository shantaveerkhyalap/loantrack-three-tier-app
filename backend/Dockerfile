# Backend Dockerfile (generated without original comments)
FROM python:3.12-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --user --no-warn-script-location -r requirements.txt
FROM python:3.12-slim
RUN apt-get update && apt-get install -y libpq5 curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN useradd -m -s /bin/bash loantrack
USER loantrack
COPY --from=builder /root/.local /home/loantrack/.local
ENV PATH=/home/loantrack/.local/bin:$PATH
COPY --chown=loantrack:loantrack main.py .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/healthz || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
