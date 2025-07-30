#!/bin/bash

# Скрипт установки GoAccess для веб-аналитики логов
# Автор: WAYPN Team
# Версия: 1.0

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

log "🚀 Установка GoAccess для веб-аналитики логов..."

# Обновление системы
log "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка зависимостей
log "📋 Установка зависимостей..."
apt install -y build-essential libncursesw5-dev libssl-dev libgeom-dev libtokyocabinet-dev

# Скачивание и установка GoAccess
log "📥 Скачивание GoAccess..."
cd /tmp
wget https://tar.goaccess.io/goaccess-1.7.2.tar.gz
tar -xzvf goaccess-1.7.2.tar.gz
cd goaccess-1.7.2/

# Конфигурация и компиляция
log "🔧 Конфигурация GoAccess..."
./configure --enable-utf8 --enable-geoip=legacy --enable-json --enable-html
make
make install

# Создание директории для отчетов
log "📁 Создание директорий..."
mkdir -p /opt/goaccess
mkdir -p /opt/goaccess/reports
mkdir -p /opt/goaccess/logs

# Создание конфигурации GoAccess
log "⚙️ Создание конфигурации..."
cat > /opt/goaccess/goaccess.conf << 'EOF'
# GoAccess Configuration for WAYPN Bot Logs
time-format %H:%M:%S
date-format %d/%b/%Y
log-format COMBINED

# Output options
output-format HTML
output-file /opt/goaccess/reports/index.html

# Real-time HTML
real-time-html true
port 7890
ws-url wss://89.110.81.79:7890

# Log file
log-file /opt/goaccess/logs/waypn-bot.log

# Parse options
http-protocol true
http-method true
no-query-string false
no-term-resolver false
static-file .css
static-file .js
static-file .jpg
static-file .png
static-file .gif
static-file .ico
static-file .jpeg
static-file .pdf
static-file .txt
static-file .woff
static-file .woff2

# GeoIP
geoip-database /usr/share/GeoIP/GeoIP.dat

# Exclude patterns
exclude-ip 127.0.0.1
exclude-ip ::1

# Include patterns
include-ip 89.110.81.79
EOF

# Создание скрипта для обработки логов бота
log "📝 Создание скрипта обработки логов..."
cat > /opt/goaccess/process_bot_logs.sh << 'EOF'
#!/bin/bash

# Скрипт обработки логов бота для GoAccess
# Автор: WAYPN Team

LOG_FILE="/opt/goaccess/logs/waypn-bot.log"
REPORT_DIR="/opt/goaccess/reports"

# Очистка старого лога
> "$LOG_FILE"

# Извлечение логов бота и преобразование в формат для GoAccess
journalctl -u waypn-bot.service --since '24 hours ago' --no-pager | while read -r line; do
    # Извлечение временной метки
    timestamp=$(echo "$line" | grep -o '^[A-Za-z]\{3\} [0-9]\{1,2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' | head -1)
    
    if [ -n "$timestamp" ]; then
        # Преобразование в формат для GoAccess
        formatted_date=$(date -d "$timestamp" +"%d/%b/%Y")
        formatted_time=$(date -d "$timestamp" +"%H:%M:%S")
        
        # Создание записи в формате COMBINED
        echo "127.0.0.1 - - [$formatted_date:$formatted_time +0000] \"POST /bot/telegram HTTP/1.1\" 200 0 \"-\" \"WAYPN-Bot/1.0\"" >> "$LOG_FILE"
    fi
done

# Запуск GoAccess
goaccess "$LOG_FILE" \
    --config-file=/opt/goaccess/goaccess.conf \
    --real-time-html \
    --port=7890 \
    --ws-url=wss://89.110.81.79:7890 \
    --output-file="$REPORT_DIR/index.html"
EOF

chmod +x /opt/goaccess/process_bot_logs.sh

# Создание systemd сервиса для GoAccess
log "🔧 Создание systemd сервиса..."
cat > /etc/systemd/system/goaccess.service << 'EOF'
[Unit]
Description=GoAccess Log Analyzer
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/goaccess
ExecStart=/opt/goaccess/process_bot_logs.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Создание nginx конфигурации для веб-доступа
log "🌐 Создание nginx конфигурации..."
apt install -y nginx

cat > /etc/nginx/sites-available/goaccess << 'EOF'
server {
    listen 80;
    server_name 89.110.81.79;

    location / {
        root /opt/goaccess/reports;
        index index.html;
        try_files $uri $uri/ =404;
    }

    location /realtime {
        proxy_pass http://127.0.0.1:7890;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Активация nginx конфигурации
ln -sf /etc/nginx/sites-available/goaccess /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Перезапуск nginx
systemctl restart nginx

# Запуск GoAccess сервиса
log "🚀 Запуск GoAccess сервиса..."
systemctl daemon-reload
systemctl enable goaccess
systemctl start goaccess

# Проверка статуса
log "🔍 Проверка статуса сервисов..."
systemctl status goaccess --no-pager
systemctl status nginx --no-pager

log "✅ GoAccess успешно установлен!"
echo ""
echo "📊 Доступ к сервисам:"
echo "   🌐 Веб-отчеты: http://89.110.81.79"
echo "   📈 Реальное время: http://89.110.81.79/realtime"
echo ""
echo "💡 Команды управления:"
echo "   systemctl status goaccess"
echo "   systemctl restart goaccess"
echo "   journalctl -u goaccess -f"
echo "   tail -f /opt/goaccess/logs/waypn-bot.log"
echo "" 