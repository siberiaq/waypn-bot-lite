#!/bin/bash

# Скрипт для проверки статуса WAYPN Bot Lite
# Автор: WAYPN Team
# Версия: 1.0

echo "📊 Статус WAYPN Bot Lite"
echo "========================"

# Проверка процессов
echo ""
echo "🔄 Проверка процессов:"

# Проверка вебхук сервера
if pgrep -f "node.*webhook" > /dev/null; then
    echo "✅ Вебхук сервер: ЗАПУЩЕН"
    WEBHOOK_PID=$(pgrep -f "node.*webhook")
    echo "   PID: $WEBHOOK_PID"
else
    echo "❌ Вебхук сервер: ОСТАНОВЛЕН"
fi

# Проверка бота
if pgrep -f "node.*index" > /dev/null; then
    echo "✅ Telegram бот: ЗАПУЩЕН"
    BOT_PID=$(pgrep -f "node.*index")
    echo "   PID: $BOT_PID"
else
    echo "❌ Telegram бот: ОСТАНОВЛЕН"
fi

# Проверка concurrently
if pgrep -f "concurrently.*start:all" > /dev/null; then
    echo "✅ Concurrently: ЗАПУЩЕН"
    CONCURRENTLY_PID=$(pgrep -f "concurrently.*start:all")
    echo "   PID: $CONCURRENTLY_PID"
else
    echo "❌ Concurrently: ОСТАНОВЛЕН"
fi

# Проверка портов
echo ""
echo "🌐 Проверка портов:"

# Проверка порта 3000 (вебхук)
if lsof -i :3000 > /dev/null 2>&1; then
    echo "✅ Порт 3000: ЗАНЯТ (вебхук сервер)"
    lsof -i :3000 | grep LISTEN
else
    echo "❌ Порт 3000: СВОБОДЕН"
fi

# Проверка файлов конфигурации
echo ""
echo "📁 Проверка файлов:"

if [ -f "package.json" ]; then
    echo "✅ package.json: найден"
else
    echo "❌ package.json: не найден"
fi

if [ -f ".env" ]; then
    echo "✅ .env: найден"
else
    echo "❌ .env: не найден"
fi

if [ -f "index.js" ]; then
    echo "✅ index.js: найден"
else
    echo "❌ index.js: не найден"
fi

if [ -f "webhook.js" ]; then
    echo "✅ webhook.js: найден"
else
    echo "❌ webhook.js: не найден"
fi

# Общий статус
echo ""
echo "📋 Общий статус:"

if pgrep -f "node.*webhook\|node.*index\|concurrently.*start:all" > /dev/null; then
    echo "🟢 СИСТЕМА РАБОТАЕТ"
    echo ""
    echo "💡 Команды управления:"
    echo "   ./stop.sh     - остановить бота"
    echo "   ./restart.sh  - перезапустить бота"
    echo "   Ctrl+C        - остановить в текущем терминале"
else
    echo "🔴 СИСТЕМА ОСТАНОВЛЕНА"
    echo ""
    echo "💡 Для запуска используйте:"
    echo "   ./restart.sh  - запустить бота"
    echo "   npm run start:all - запустить бота"
fi 