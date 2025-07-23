#!/bin/bash

# Скрипт для запуска WAYPN Bot Lite без concurrently
# Автор: WAYPN Team
# Версия: 1.0

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Функции для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    error ".env файл не найден"
    exit 1
fi

# Проверка наличия основных файлов
if [ ! -f "index.js" ]; then
    error "index.js не найден"
    exit 1
fi

if [ ! -f "webhook.js" ]; then
    error "webhook.js не найден"
    exit 1
fi

log "🚀 Запуск WAYPN Bot Lite..."

# Функция для остановки всех процессов
cleanup() {
    log "🛑 Остановка процессов..."
    pkill -f "node.*index.js" 2>/dev/null || true
    pkill -f "node.*webhook.js" 2>/dev/null || true
    exit 0
}

# Установка обработчика сигналов
trap cleanup SIGINT SIGTERM

# Запуск бота в фоне
log "🤖 Запуск Telegram бота..."
node index.js > bot.log 2>&1 &
BOT_PID=$!

# Небольшая пауза
sleep 2

# Проверка, что бот запустился
if ! kill -0 $BOT_PID 2>/dev/null; then
    error "Ошибка при запуске бота"
    cat bot.log
    exit 1
fi

log "✅ Telegram бот запущен (PID: $BOT_PID)"

# Запуск вебхук сервера в фоне
log "🌐 Запуск вебхук сервера..."
node webhook.js > webhook.log 2>&1 &
WEBHOOK_PID=$!

# Небольшая пауза
sleep 2

# Проверка, что вебхук сервер запустился
if ! kill -0 $WEBHOOK_PID 2>/dev/null; then
    error "Ошибка при запуске вебхук сервера"
    cat webhook.log
    kill $BOT_PID 2>/dev/null || true
    exit 1
fi

log "✅ Вебхук сервер запущен (PID: $WEBHOOK_PID)"

# Получение порта из .env
PORT=$(grep "^PORT=" .env 2>/dev/null | cut -d'=' -f2 || echo "3000")

echo ""
echo "📋 Информация о запуске:"
echo "   🤖 Telegram бот: активен (PID: $BOT_PID)"
echo "   🌐 Вебхук сервер: активен (PID: $WEBHOOK_PID)"
echo "   📡 Webhook endpoint: http://localhost:$PORT/webhook/tribute"
echo "   💚 Health check: http://localhost:$PORT/health"
echo "   📝 Логи бота: bot.log"
echo "   📝 Логи вебхука: webhook.log"
echo ""
echo "💡 Для остановки нажмите Ctrl+C"
echo ""

# Ожидание завершения процессов
wait 