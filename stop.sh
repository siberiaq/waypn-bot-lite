#!/bin/bash

# Скрипт для остановки WAYPN Bot Lite
# Автор: WAYPN Team
# Версия: 1.0

echo "🛑 Остановка WAYPN Bot Lite..."

# Остановка всех процессов Node.js связанных с ботом
echo "🔄 Остановка процессов..."

# Остановка вебхук сервера
if pkill -f "node.*webhook" 2>/dev/null; then
    echo "✅ Вебхук сервер остановлен"
else
    echo "ℹ️  Вебхук сервер не был запущен"
fi

# Остановка бота
if pkill -f "node.*index" 2>/dev/null; then
    echo "✅ Telegram бот остановлен"
else
    echo "ℹ️  Telegram бот не был запущен"
fi

# Остановка concurrently
if pkill -f "concurrently.*start:all" 2>/dev/null; then
    echo "✅ Concurrently остановлен"
else
    echo "ℹ️  Concurrently не был запущен"
fi

# Небольшая пауза
sleep 1

# Проверка, что все процессы остановлены
if pgrep -f "node.*webhook\|node.*index\|concurrently.*start:all" > /dev/null; then
    echo "⚠️  Некоторые процессы все еще работают. Принудительная остановка..."
    
    if pkill -9 -f "node.*webhook" 2>/dev/null; then
        echo "✅ Вебхук сервер принудительно остановлен"
    fi
    
    if pkill -9 -f "node.*index" 2>/dev/null; then
        echo "✅ Telegram бот принудительно остановлен"
    fi
    
    if pkill -9 -f "concurrently.*start:all" 2>/dev/null; then
        echo "✅ Concurrently принудительно остановлен"
    fi
fi

echo ""
echo "✅ Все процессы WAYPN Bot Lite остановлены!"
echo "💡 Для запуска используйте: ./restart.sh или npm run start:all" 