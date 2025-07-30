#!/bin/bash

# Простой скрипт для извлечения информации о пользователях из логов
# Автор: WAYPN Team
# Версия: 1.0

set -e

# Цвета для вывода
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Переменные
OUTPUT_FILE="users_$(date +%Y%m%d).csv"
DAYS=7

log "📥 Загрузка логов..."
journalctl -u waypn-bot.service --since "$DAYS days ago" --no-pager > temp_log.txt

log "📊 Обработка логов..."

# Создание CSV заголовка
echo "timestamp,username,user_id,action" > "$OUTPUT_FILE"

# Извлечение данных
awk '
BEGIN {
    FS=" "
    OFS=","
    current_timestamp = ""
    current_username = ""
    current_user_id = ""
    current_action = "unknown"
}

{
    # Извлечение временной метки
    if ($1 ~ /^[A-Za-z]{3}/ && $2 ~ /^[0-9]+/ && $3 ~ /^[0-9]+:/) {
        current_timestamp = $1 " " $2 " " $3
    }
    
    # Поиск username
    if (index($0, "username") > 0) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"username":/) {
                current_username = substr($i, index($i, ":") + 2)
                gsub(/"/, "", current_username)
                gsub(/,/, "", current_username)
                
                # Проверяем, что это валидный username
                if (current_username != "" && current_username != "adminpassword:z4C9wQ8he4875T6d}" && current_username != "username") {
                    # Определение действия
                    if (index($0, "callback_data") > 0) current_action = "button_click"
                    else if (index($0, "/start") > 0) current_action = "start_command"
                    else if (index($0, "message") > 0) current_action = "message"
                    
                    print current_timestamp, current_username, current_user_id, current_action
                }
                break
            }
        }
    }
    
    # Поиск user_id
    if (index($0, "id") > 0 && !index($0, "username")) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"id":/) {
                current_user_id = substr($i, index($i, ":") + 1)
                gsub(/"/, "", current_user_id)
                gsub(/,/, "", current_user_id)
                break
            }
        }
    }
}
' temp_log.txt >> "$OUTPUT_FILE"

# Удаление дубликатов
sort -t',' -k1,2 "$OUTPUT_FILE" | uniq > temp_sorted.csv
mv temp_sorted.csv "$OUTPUT_FILE"

# Очистка
rm -f temp_log.txt

# Статистика
TOTAL_USERS=$(tail -n +2 "$OUTPUT_FILE" | cut -d',' -f2 | sort | uniq | wc -l)
TOTAL_ACTIONS=$(tail -n +2 "$OUTPUT_FILE" | wc -l)

log "✅ Экспорт завершен!"
echo ""
echo "📊 Статистика:"
echo "   📁 Файл: $OUTPUT_FILE"
echo "   👥 Уникальных пользователей: $TOTAL_USERS"
echo "   📈 Всего действий: $TOTAL_ACTIONS"
echo "   📅 Период: последние $DAYS дней"
echo ""

# Показать топ пользователей
echo "🏆 Топ-5 самых активных пользователей:"
tail -n +2 "$OUTPUT_FILE" | cut -d',' -f2 | sort | uniq -c | sort -nr | head -5 | while read count username; do
    echo "   $username: $count действий"
done

echo ""
echo "💡 Для просмотра данных используйте:"
echo "   cat $OUTPUT_FILE"
echo "   head -20 $OUTPUT_FILE"
echo "" 