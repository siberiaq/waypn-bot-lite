#!/bin/bash

# Скрипт для перезапуска WAYPN Bot Lite
# Автор: WAYPN Team
# Версия: 1.0

echo "🔄 Перезапуск WAYPN Bot Lite..."

# Остановка всех процессов Node.js связанных с ботом
echo "🛑 Остановка процессов..."
pkill -f "node.*webhook" 2>/dev/null || echo "   Вебхук сервер не был запущен"
pkill -f "node.*index" 2>/dev/null || echo "   Бот не был запущен"
pkill -f "concurrently.*start:all" 2>/dev/null || echo "   Concurrently не был запущен"

# Небольшая пауза для корректного завершения процессов
sleep 2

# Проверка, что процессы действительно остановлены
if pgrep -f "node.*webhook\|node.*index\|concurrently.*start:all" > /dev/null; then
    echo "⚠️  Некоторые процессы все еще работают. Принудительная остановка..."
    pkill -9 -f "node.*webhook" 2>/dev/null
    pkill -9 -f "node.*index" 2>/dev/null
    pkill -9 -f "concurrently.*start:all" 2>/dev/null
    sleep 1
fi

# Проверка наличия package.json
if [ ! -f "package.json" ]; then
    echo "❌ Ошибка: package.json не найден. Убедитесь, что вы находитесь в корневой папке проекта."
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    echo "⚠️  Предупреждение: .env файл не найден. Бот может не работать корректно."
fi

# Запуск бота и вебхук сервера
echo "🚀 Запуск бота и вебхук сервера..."
npm run start:all

# Проверка статуса запуска
if [ $? -eq 0 ]; then
    echo "✅ Бот и вебхук сервер успешно запущены!"
    echo ""
    echo "📋 Информация:"
    echo "   🤖 Telegram бот: активен"
    echo "   🌐 Вебхук сервер: http://localhost:3000"
    echo "   📡 Webhook endpoint: http://localhost:3000/webhook/tribute"
    echo "   💚 Health check: http://localhost:3000/health"
    echo ""
    echo "💡 Для остановки нажмите Ctrl+C"
else
    echo "❌ Ошибка при запуске бота!"
    echo "Проверьте логи выше для диагностики проблемы."
    exit 1
fi 