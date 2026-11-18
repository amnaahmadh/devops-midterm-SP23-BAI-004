FROM python:3.11-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# Install deps first so this layer is cached between builds (faster redeploys)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App code + config + the model artifacts produced by Jenkins (train.py stage)
COPY app.py train.py config.json ./
COPY dataset/ dataset/
COPY artifacts/ artifacts/

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
