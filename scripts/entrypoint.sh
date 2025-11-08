#!/bin/bash
set -e

echo "Applying database migrations..."
# Создаем и применяем миграции
python3 manage.py makemigrations && \
python3 manage.py makemigrations StaticAnalyzer && \
python3 manage.py migrate

# Создаем суперпользователя (если не существует)
set +e
echo "Creating superuser..."
python3 manage.py createsuperuser --noinput --email "" 2>/dev/null || true
set -e

# Создаем роли
echo "Creating roles..."
python3 manage.py create_roles

# Используем переменную GUNICORN_WORKERS или значение по умолчанию
WORKERS=${GUNICORN_WORKERS:-4}
THREADS=4

echo "Starting server with ${WORKERS} workers and ${THREADS} threads..."
exec gunicorn -b 0.0.0.0:8000 "mobsf.MobSF.wsgi:application" \
    --workers=$WORKERS \
    --threads=$THREADS \
    --timeout=3600 \
    --worker-tmp-dir=/dev/shm \
    --log-level=info \
    --max-requests=1000 \
    --max-requests-jitter=100 \
    --log-file=- \
    --access-logfile=- \
    --error-logfile=- \
    --capture-output