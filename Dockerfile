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

# СОЗДАЕМ ПОЛЬЗОВАТЕЛЯ ЗДЕСЬ ЖЕ (с тем же UID 1000)
RUN useradd -u 1000 -m appuser

# Устанавливаем зависимости под этим пользователем в его домашнюю папку (/home/appuser/.local)
USER appuser
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# --- Финальный легковесный образ ---
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Снова создаем такого же пользователя в финальном образе
RUN useradd -u 1000 appuser

# КОПИРУЕМ ГОТОВЫЕ БИБЛИОТЕКИ из домашней директории appuser builder-образа
COPY --from=builder --chown=appuser:appuser /home/appuser/.local /home/appuser/.local

# Копируем исходный код приложения
COPY --chown=appuser:appuser . .

# Добавляем путь к установленным бинарникам (gunicorn) в PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# Переключаемся на непривилегированного пользователя
USER appuser

# Открываем порт
EXPOSE 8000

# 3. Запуск через Gunicorn (4 воркера, привязка к 0.0.0.0:8000)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "wsgi:app"]