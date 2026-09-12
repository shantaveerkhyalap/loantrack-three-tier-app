# Stage 1: Build dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

# Install system dependencies needed for psycopg2
RUN apt-get update && apt-get install -y libpq-dev gcc && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt .
RUN pip install --user --no-warn-script-location -r requirements.txt

# Stage 2: Final runtime image
FROM python:3.12-slim

# Install only runtime system dependencies for PostgreSQL
RUN apt-get update && apt-get install -y libpq5 curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create a non-root user
RUN useradd -m -s /bin/bash loantrack
USER loantrack

# Copy Python dependencies from builder stage
COPY --from=builder /root/.local /home/loantrack/.local
ENV PATH=/home/loantrack/.local/bin:$PATH

# Copy application source code
COPY --chown=loantrack:loantrack main.py .

EXPOSE 8000

# HEALTHCHECK calling the /healthz endpoint we created
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/healthz || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
