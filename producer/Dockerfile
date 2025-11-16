FROM --platform=linux/arm64 python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY producer.py .

# Run the producer
CMD ["python", "-u", "producer.py"]
