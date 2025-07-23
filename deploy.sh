#!/bin/bash

# Скрипт для деплоя WAYPN Bot Lite на сервер
# Автор: WAYPN Team
# Версия: 1.0

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# Проверка аргументов
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --help, -h     Показать эту справку"
    echo "  --force        Принудительный деплой (остановка всех процессов)"
    echo "  --update       Обновить код из Git репозитория"
    echo "  --restart      Только перезапуск сервисов"
    echo ""
    echo "Примеры:"
    echo "  $0              # Обычный деплой"
    echo "  $0 --update     # Обновить код и деплой"
    echo "  $0 --force      # Принудительный деплой"
    echo "  $0 --restart    # Только перезапуск"
    exit 0
fi

# Переменные
FORCE_DEPLOY=false
UPDATE_CODE=false
RESTART_ONLY=false

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        --update)
            UPDATE_CODE=true
            shift
            ;;
        --restart)
            RESTART_ONLY=true
            shift
            ;;
        *)
            error "Неизвестная опция: $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
    esac
done

log "🚀 Начинаем деплой WAYPN Bot Lite..."

# Проверка, что мы в корневой папке проекта
if [ ! -f "package.json" ]; then
    error "package.json не найден. Убедитесь, что вы находитесь в корневой папке проекта."
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    warn ".env файл не найден. Создаем из примера..."
    if [ -f "env.example" ]; then
        cp env.example .env
        warn "Создан .env файл из env.example. Пожалуйста, настройте переменные окружения!"
        echo ""
        echo "Необходимо настроить следующие переменные в .env файле:"
        echo "  - BOT_TOKEN (получите у @BotFather)"
        echo "  - TRIBUTE_PAYMENT_URL"
        echo "  - SUPPORT_LINK"
        echo "  - PORT (по умолчанию 3000)"
        echo "  - WEBHOOK_SECRET (опционально)"
        echo "  - XUI_BASE_URL, XUI_EMAIL, XUI_PASSWORD (для x-ui интеграции)"
        echo ""
        read -p "Нажмите Enter после настройки .env файла или Ctrl+C для отмены..."
    else
        error "env.example не найден. Создайте .env файл вручную."
        exit 1
    fi
fi

# Остановка существующих процессов (если --force или --restart)
if [ "$FORCE_DEPLOY" = true ] || [ "$RESTART_ONLY" = true ]; then
    log "🛑 Остановка существующих процессов..."
    
    # Остановка процессов Node.js
    pkill -f "node.*webhook" 2>/dev/null || warn "Вебхук сервер не был запущен"
    pkill -f "node.*index" 2>/dev/null || warn "Бот не был запущен"
    pkill -f "concurrently.*start:all" 2>/dev/null || warn "Concurrently не был запущен"
    
    # Небольшая пауза
    sleep 2
    
    # Принудительная остановка, если процессы все еще работают
    if pgrep -f "node.*webhook\|node.*index\|concurrently.*start:all" > /dev/null; then
        warn "Принудительная остановка процессов..."
        pkill -9 -f "node.*webhook" 2>/dev/null
        pkill -9 -f "node.*index" 2>/dev/null
        pkill -9 -f "concurrently.*start:all" 2>/dev/null
        sleep 1
    fi
fi

# Если только перезапуск, пропускаем обновление кода
if [ "$RESTART_ONLY" = true ]; then
    log "🔄 Только перезапуск сервисов..."
else
    # Обновление кода из Git (если --update)
    if [ "$UPDATE_CODE" = true ]; then
        log "📥 Обновление кода из Git репозитория..."
        if [ -d ".git" ]; then
            git pull origin main || {
                error "Ошибка при обновлении кода из Git"
                exit 1
            }
        else
            warn "Git репозиторий не найден. Пропускаем обновление кода."
        fi
    fi
    
    # Проверка и установка Node.js
    log "🔍 Проверка Node.js..."
    if ! command -v node &> /dev/null; then
        error "Node.js не установлен. Установите Node.js версии 16 или выше."
        echo "Рекомендуется использовать nvm:"
        echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "  nvm install 18"
        echo "  nvm use 18"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        error "Node.js версии $NODE_VERSION не поддерживается. Требуется версия 16 или выше."
        exit 1
    fi
    
    info "Node.js версии $(node --version) обнаружен"
    
    # Проверка npm
    if ! command -v npm &> /dev/null; then
        error "npm не установлен"
        exit 1
    fi
    
    info "npm версии $(npm --version) обнаружен"
    
    # Установка зависимостей
    log "📦 Установка зависимостей..."
    npm ci --production || {
        warn "Ошибка при установке production зависимостей. Пробуем npm install..."
        npm install --production || {
            error "Ошибка при установке зависимостей"
            exit 1
        }
    }
    
    # Проверка установленных зависимостей
    if [ ! -d "node_modules" ]; then
        error "node_modules не найден после установки зависимостей"
        exit 1
    fi
    
    log "✅ Зависимости установлены успешно"
fi

# Проверка прав на выполнение скриптов
log "🔧 Настройка прав доступа..."
chmod +x restart.sh status.sh stop.sh 2>/dev/null || warn "Не удалось установить права на скрипты"

# Создание systemd сервиса (опционально)
if command -v systemctl &> /dev/null && [ "$EUID" -eq 0 ]; then
    info "Обнаружен systemd. Создание systemd сервиса..."
    
    SERVICE_FILE="/etc/systemd/system/waypn-bot.service"
    CURRENT_DIR=$(pwd)
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=WAYPN Bot Lite
After=network.target

[Service]
Type=simple
User=$SUDO_USER
WorkingDirectory=$CURRENT_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm run start:all
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable waypn-bot.service
    info "Systemd сервис создан: waypn-bot.service"
    info "Для управления используйте:"
    info "  sudo systemctl start waypn-bot"
    info "  sudo systemctl stop waypn-bot"
    info "  sudo systemctl status waypn-bot"
    info "  sudo systemctl restart waypn-bot"
fi

# Запуск приложения
if [ "$RESTART_ONLY" = true ]; then
    log "🚀 Перезапуск приложения..."
else
    log "🚀 Запуск приложения..."
fi

# Проверка, что порт свободен
PORT=$(grep "^PORT=" .env 2>/dev/null | cut -d'=' -f2 || echo "3000")
if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
    warn "Порт $PORT уже занят. Остановка процесса на этом порту..."
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Запуск приложения в фоне
nohup npm run start:all > waypn-bot.log 2>&1 &
BOT_PID=$!

# Проверка запуска
sleep 3
if kill -0 $BOT_PID 2>/dev/null; then
    log "✅ Приложение успешно запущено (PID: $BOT_PID)"
    echo ""
    echo "📋 Информация о деплое:"
    echo "   🤖 Telegram бот: активен"
    echo "   🌐 Вебхук сервер: http://localhost:$PORT"
    echo "   📡 Webhook endpoint: http://localhost:$PORT/webhook/tribute"
    echo "   💚 Health check: http://localhost:$PORT/health"
    echo "   📝 Логи: waypn-bot.log"
    echo "   🔧 PID: $BOT_PID"
    echo ""
    
    # Проверка доступности сервисов
    log "🔍 Проверка доступности сервисов..."
    sleep 2
    
    if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
        log "✅ Health check прошел успешно"
    else
        warn "⚠️  Health check не прошел. Проверьте логи: tail -f waypn-bot.log"
    fi
    
    echo ""
    echo "🎉 Деплой завершен успешно!"
    echo ""
    echo "💡 Полезные команды:"
    echo "   ./status.sh          - Проверить статус"
    echo "   ./restart.sh         - Перезапустить"
    echo "   ./stop.sh            - Остановить"
    echo "   tail -f waypn-bot.log - Просмотр логов"
    echo ""
    
    if command -v systemctl &> /dev/null && [ "$EUID" -eq 0 ]; then
        echo "🔧 Systemd команды:"
        echo "   sudo systemctl status waypn-bot"
        echo "   sudo systemctl restart waypn-bot"
        echo "   sudo systemctl stop waypn-bot"
        echo ""
    fi
    
else
    error "❌ Ошибка при запуске приложения"
    echo "Проверьте логи: tail -f waypn-bot.log"
    exit 1
fi 