# Use the official Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8080

# Set the working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Expose the port (informative)
EXPOSE 8080

# Command to run the application
# Using shell form to expand environment variables
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}
