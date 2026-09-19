# 1. Используем легкий и официальный образ Python
FROM python:3.11-slim AS builder

# Предотвращаем Python от записи pyc-файлов на диск и буферизацию логов
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 2. Устанавливаем системные зависимости (если нужны, например, для сборки пакетов)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. Устанавливаем Python-зависимости во временную директорию
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- Финальный легковесный образ ---
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 4. Копируем установленные пакетов из builder-образа
COPY --from=builder /root/.local /root/.local

# Копируем исходный код из текущей локальной папки в текущую рабочую директорию (/app)
COPY . .

# Обновляем PATH, чтобы были видны бинарники (например, gunicorn)
ENV PATH=/root/.local/bin:$PATH

# 5. БЕЗОПАСНОСТЬ: Создаем непривилегированного пользователя и переключаемся на него
RUN useradd -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Открываем порт
EXPOSE 8000

# 6. Запуск через Gunicorn (4 воркера, привязка к 0.0.0.0:8000)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "wsgi:app"]