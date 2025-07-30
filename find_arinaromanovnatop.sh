#!/bin/bash

echo "🔍 Поиск информации о пользователе @arinaromanovnatop в логах..."
echo "=================================================="

# Поиск в локальных логах
echo "📋 Поиск в локальных логах (bot_logs_journalctl.txt):"
echo "--------------------------------------------------"

# Поиск по username
echo "👤 Поиск по username 'arinaromanovnatop':"
grep -i "arinaromanovnatop" bot_logs_journalctl.txt | head -10

echo ""
echo "📱 Поиск по Telegram ID (если известен):"
echo "Введите Telegram ID пользователя (или нажмите Enter для пропуска):"
read telegram_id

if [ ! -z "$telegram_id" ]; then
    echo "🔍 Поиск по Telegram ID: $telegram_id"
    grep -i "$telegram_id" bot_logs_journalctl.txt | head -10
fi

echo ""
echo "📊 Поиск всех упоминаний пользователя:"
echo "--------------------------------------------------"

# Поиск всех строк, содержащих информацию о пользователе
echo "🔍 Поиск всех упоминаний 'arinaromanovnatop':"
grep -i "arinaromanovnatop" bot_logs_journalctl.txt

echo ""
echo "📋 Поиск в системных логах (bot_logs_syslog.txt):"
echo "--------------------------------------------------"
grep -i "arinaromanovnatop" bot_logs_syslog.txt | head -10

echo ""
echo "🎯 Поиск по структуре JSON (пользовательские данные):"
echo "--------------------------------------------------"

# Поиск JSON структур с информацией о пользователе
grep -A 5 -B 5 "arinaromanovnatop" bot_logs_journalctl.txt | grep -E '("id"|"username"|"first_name"|"last_name"|"is_premium"|"language_code")' | head -20

echo ""
echo "📈 Статистика активности пользователя:"
echo "--------------------------------------------------"

# Подсчет количества упоминаний
count=$(grep -i "arinaromanovnatop" bot_logs_journalctl.txt | wc -l)
echo "📊 Общее количество упоминаний: $count"

# Временные рамки активности
echo "📅 Временные рамки активности:"
grep -i "arinaromanovnatop" bot_logs_journalctl.txt | grep -o "^[A-Za-z]\{3\} [0-9]\{1,2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}" | sort | uniq | head -10

echo ""
echo "✅ Поиск завершен!" 