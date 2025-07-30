#!/bin/bash

# Скрипт для загрузки дашборда на сервер
# Автор: WAYPN Team

set -e

# Цвета для вывода
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log "📤 Загрузка дашборда на сервер..."

# Загрузка файлов на сервер
scp waypn-bot-dashboard.json root@89.110.81.79:/opt/monitoring/grafana/provisioning/dashboards/

log "✅ Дашборд загружен!"
echo ""
echo "🌐 Доступ к Grafana:"
echo "   URL: http://89.110.81.79:3000"
echo "   Логин: admin"
echo "   Пароль: waypn2024"
echo ""
echo "📊 Дашборд 'WAYPN Bot Monitoring' будет доступен автоматически"
echo ""
echo "💡 Возможности дашборда:"
echo "   📝 Просмотр логов бота в реальном времени"
echo "   👥 Статистика активных пользователей"
echo "   🚨 Мониторинг ошибок"
echo "   ⏱️ Время отклика бота"
echo "   🏆 Топ пользователей"
echo "" 