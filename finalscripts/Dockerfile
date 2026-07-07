# -----------------------------
# Base image
# -----------------------------
FROM python:3.10-slim

# -----------------------------
# Install System Dependencies (FFmpeg)
# FFmpeg is required by the 'ffmpeg-python' and 'pydub' packages 
# for audio file handling and analysis.
# The cleanup step (`rm -rf /var/lib/apt/lists/*`) ensures the image size stays minimal.
# -----------------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Set working directory
# -----------------------------
WORKDIR /app

# -----------------------------
# Install Python dependencies
# -----------------------------
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# -----------------------------
# Copy project files
# -----------------------------
COPY . .

# -----------------------------
# Expose FastAPI port and start the container
# -----------------------------
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
