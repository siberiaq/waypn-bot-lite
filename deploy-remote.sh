#!/bin/bash

# Скрипт для деплоя WAYPN Bot Lite на удаленный сервер
# Автор: WAYPN Team
# Версия: 1.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# Проверка аргументов
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --help, -h     Показать эту справку"
    echo "  --server       Адрес сервера (обязательно)"
    echo "  --user         Пользователь на сервере (по умолчанию: root)"
    echo "  --port         SSH порт (по умолчанию: 22)"
    echo "  --key          Путь к SSH ключу"
    echo "  --path         Путь на сервере для деплоя (по умолчанию: /opt/waypn-bot-lite)"
    echo "  --update       Обновить код из Git репозитория"
    echo "  --force        Принудительный деплой"
    echo ""
    echo "Примеры:"
    echo "  $0 --server 192.168.1.100"
    echo "  $0 --server example.com --user ubuntu --port 2222"
    echo "  $0 --server example.com --key ~/.ssh/id_rsa --update"
    echo ""
    echo "Переменные окружения:"
    echo "  REMOTE_SERVER  - Адрес сервера"
    echo "  REMOTE_USER    - Пользователь на сервере"
    echo "  REMOTE_PORT    - SSH порт"
    echo "  REMOTE_KEY     - Путь к SSH ключу"
    echo "  REMOTE_PATH    - Путь на сервере"
    exit 0
fi

# Переменные по умолчанию
REMOTE_SERVER=""
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_KEY=""
REMOTE_PATH="${REMOTE_PATH:-/opt/waypn-bot-lite}"
UPDATE_CODE=false
FORCE_DEPLOY=false

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --server)
            REMOTE_SERVER="$2"
            shift 2
            ;;
        --user)
            REMOTE_USER="$2"
            shift 2
            ;;
        --port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        --key)
            REMOTE_KEY="$2"
            shift 2
            ;;
        --path)
            REMOTE_PATH="$2"
            shift 2
            ;;
        --update)
            UPDATE_CODE=true
            shift
            ;;
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        *)
            error "Неизвестная опция: $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
    esac
done

# Проверка обязательных параметров
if [ -z "$REMOTE_SERVER" ]; then
    error "Не указан адрес сервера. Используйте --server или установите REMOTE_SERVER"
    echo "Пример: $0 --server 192.168.1.100"
    exit 1
fi

# Формирование SSH команды
SSH_CMD="ssh"
if [ -n "$REMOTE_KEY" ]; then
    SSH_CMD="$SSH_CMD -i $REMOTE_KEY"
fi
SSH_CMD="$SSH_CMD -p $REMOTE_PORT $REMOTE_USER@$REMOTE_SERVER"

# Проверка подключения к серверу
log "🔍 Проверка подключения к серверу $REMOTE_SERVER..."
if ! $SSH_CMD "echo 'Connection test successful'" 2>/dev/null; then
    error "Не удается подключиться к серверу $REMOTE_SERVER"
    echo "Проверьте:"
    echo "  - Доступность сервера"
    echo "  - SSH порт ($REMOTE_PORT)"
    echo "  - SSH ключ (если используется)"
    echo "  - Права доступа пользователя $REMOTE_USER"
    exit 1
fi

log "✅ Подключение к серверу установлено"

# Проверка наличия Git на сервере
log "🔍 Проверка Git на сервере..."
if ! $SSH_CMD "command -v git > /dev/null"; then
    warn "Git не установлен на сервере. Устанавливаем..."
    $SSH_CMD "apt-get update && apt-get install -y git" || {
        error "Не удалось установить Git на сервере"
        exit 1
    }
fi

# Проверка Node.js на сервере
log "🔍 Проверка Node.js на сервере..."
if ! $SSH_CMD "command -v node > /dev/null"; then
    warn "Node.js не установлен на сервере. Устанавливаем..."
    $SSH_CMD "curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs" || {
        error "Не удалось установить Node.js на сервере"
        exit 1
    }
fi

# Проверка версии Node.js
NODE_VERSION=$($SSH_CMD "node --version | cut -d'v' -f2 | cut -d'.' -f1")
if [ "$NODE_VERSION" -lt 16 ]; then
    error "Node.js версии $NODE_VERSION не поддерживается. Требуется версия 16 или выше."
    exit 1
fi

info "Node.js версии $($SSH_CMD "node --version") обнаружен на сервере"

# Создание директории на сервере
log "📁 Создание директории на сервере..."
$SSH_CMD "mkdir -p $REMOTE_PATH"

# Клонирование или обновление репозитория
if $SSH_CMD "[ -d '$REMOTE_PATH/.git' ]"; then
    if [ "$UPDATE_CODE" = true ]; then
        log "📥 Обновление кода из Git репозитория..."
        $SSH_CMD "cd $REMOTE_PATH && git pull origin main" || {
            error "Ошибка при обновлении кода"
            exit 1
        }
    else
        info "Репозиторий уже существует на сервере"
    fi
else
    log "📥 Клонирование репозитория на сервер..."
    $SSH_CMD "cd $(dirname $REMOTE_PATH) && git clone https://github.com/siberiaq/waypn-bot-lite.git $(basename $REMOTE_PATH)" || {
        error "Ошибка при клонировании репозитория"
        exit 1
    }
fi

# Проверка наличия .env файла на сервере
log "🔧 Проверка конфигурации..."
if ! $SSH_CMD "[ -f '$REMOTE_PATH/.env' ]"; then
    warn ".env файл не найден на сервере. Создаем из примера..."
    $SSH_CMD "cd $REMOTE_PATH && cp env.example .env"
    warn "Создан .env файл на сервере. Необходимо настроить переменные окружения!"
    echo ""
    echo "Подключитесь к серверу и настройте .env файл:"
    echo "  $SSH_CMD"
    echo "  cd $REMOTE_PATH"
    echo "  nano .env"
    echo ""
    echo "Необходимые переменные:"
    echo "  - BOT_TOKEN (получите у @BotFather)"
    echo "  - TRIBUTE_PAYMENT_URL"
    echo "  - SUPPORT_LINK"
    echo "  - PORT (по умолчанию 3000)"
    echo "  - WEBHOOK_SECRET (опционально)"
    echo "  - XUI_BASE_URL, XUI_EMAIL, XUI_PASSWORD (для x-ui интеграции)"
    echo ""
    read -p "Нажмите Enter после настройки .env файла на сервере или Ctrl+C для отмены..."
fi

# Установка зависимостей на сервере
log "📦 Установка зависимостей на сервере..."
$SSH_CMD "cd $REMOTE_PATH && npm ci --production" || {
    warn "Ошибка при установке production зависимостей. Пробуем npm install..."
    $SSH_CMD "cd $REMOTE_PATH && npm install --production" || {
        error "Ошибка при установке зависимостей на сервере"
        exit 1
    }
}

# Остановка существующих процессов (если --force)
if [ "$FORCE_DEPLOY" = true ]; then
    log "🛑 Остановка существующих процессов на сервере..."
    $SSH_CMD "cd $REMOTE_PATH && pkill -f 'node.*webhook' || true"
    $SSH_CMD "cd $REMOTE_PATH && pkill -f 'node.*index' || true"
    $SSH_CMD "cd $REMOTE_PATH && pkill -f 'concurrently.*start:all' || true"
    sleep 2
fi

# Настройка прав доступа
log "🔧 Настройка прав доступа на сервере..."
$SSH_CMD "cd $REMOTE_PATH && chmod +x deploy.sh restart.sh status.sh stop.sh"

# Создание systemd сервиса на сервере
log "🔧 Создание systemd сервиса на сервере..."
$SSH_CMD "cat > /etc/systemd/system/waypn-bot.service << 'EOF'
[Unit]
Description=WAYPN Bot Lite
After=network.target

[Service]
Type=simple
User=$REMOTE_USER
WorkingDirectory=$REMOTE_PATH
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm run start:all
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"

$SSH_CMD "systemctl daemon-reload && systemctl enable waypn-bot.service"

# Запуск приложения на сервере
log "🚀 Запуск приложения на сервере..."
$SSH_CMD "cd $REMOTE_PATH && systemctl restart waypn-bot.service"

# Проверка статуса
sleep 3
if $SSH_CMD "systemctl is-active --quiet waypn-bot.service"; then
    log "✅ Приложение успешно запущено на сервере"
    
    # Получение порта из .env
    PORT=$($SSH_CMD "cd $REMOTE_PATH && grep '^PORT=' .env 2>/dev/null | cut -d'=' -f2 || echo '3000'")
    
    echo ""
    echo "📋 Информация о деплое:"
    echo "   🖥️  Сервер: $REMOTE_SERVER"
    echo "   👤 Пользователь: $REMOTE_USER"
    echo "   📁 Путь: $REMOTE_PATH"
    echo "   🤖 Telegram бот: активен"
    echo "   🌐 Вебхук сервер: http://$REMOTE_SERVER:$PORT"
    echo "   📡 Webhook endpoint: http://$REMOTE_SERVER:$PORT/webhook/tribute"
    echo "   💚 Health check: http://$REMOTE_SERVER:$PORT/health"
    echo ""
    
    # Проверка доступности сервисов
    log "🔍 Проверка доступности сервисов..."
    if curl -s "http://$REMOTE_SERVER:$PORT/health" > /dev/null 2>&1; then
        log "✅ Health check прошел успешно"
    else
        warn "⚠️  Health check не прошел. Проверьте логи на сервере"
    fi
    
    echo ""
    echo "🎉 Деплой на сервер завершен успешно!"
    echo ""
    echo "💡 Полезные команды для управления на сервере:"
    echo "   $SSH_CMD"
    echo "   cd $REMOTE_PATH"
    echo "   systemctl status waypn-bot"
    echo "   systemctl restart waypn-bot"
    echo "   systemctl stop waypn-bot"
    echo "   tail -f waypn-bot.log"
    echo ""
    
else
    error "❌ Ошибка при запуске приложения на сервере"
    echo "Проверьте логи на сервере:"
    echo "  $SSH_CMD"
    echo "  cd $REMOTE_PATH"
    echo "  journalctl -u waypn-bot.service -f"
    exit 1
fi 