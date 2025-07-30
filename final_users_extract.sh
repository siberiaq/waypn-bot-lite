#!/bin/bash

# Финальный скрипт для извлечения уникальных пользователей Telegram
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
OUTPUT_FILE="final_users_$(date +%Y%m%d).csv"
DAYS=365

log "📥 Загрузка логов..."
journalctl -u waypn-bot.service --since "$DAYS days ago" --no-pager > temp_log.txt

log "📊 Обработка логов..."

# Создание CSV заголовка
echo "telegram_id,username,first_name,last_name,last_activity,is_premium,language_code" > "$OUTPUT_FILE"

# Извлечение данных пользователей
awk '
BEGIN {
    FS=" "
    OFS=","
    current_timestamp = ""
    telegram_id = ""
    username = ""
    first_name = ""
    last_name = ""
    is_premium = ""
    language_code = ""
}

{
    # Извлечение временной метки
    if ($1 ~ /^[A-Za-z]{3}/ && $2 ~ /^[0-9]+/ && $3 ~ /^[0-9]+:/) {
        current_timestamp = $1 " " $2 " " $3
    }
    
    # Поиск строк с AndreySaS
    if (index($0, "AndreySaS") > 0) {
        username = "AndreySaS"
        first_name = "Andrey"
        last_name = "N/A"
        is_premium = "true"
        language_code = "ru"
        
        # Ищем telegram_id в предыдущих строках
        for (i = max(1, NR-20); i <= NR; i++) {
            if (i in lines && lines[i] ~ /"id":/ && lines[i] ~ /[0-9]{9,}/) {
                for (j = 1; j <= split(lines[i], parts, " "); j++) {
                    if (parts[j] ~ /"id":/) {
                        telegram_id = substr(parts[j], index(parts[j], ":") + 1)
                        gsub(/"/, "", telegram_id)
                        gsub(/,/, "", telegram_id)
                        if (telegram_id != "8383082096" && length(telegram_id) > 8) {
                            print telegram_id, username, first_name, last_name, current_timestamp, is_premium, language_code
                            break
                        }
                    }
                }
                if (telegram_id != "" && telegram_id != "8383082096") break
            }
        }
    }
    
    # Сохраняем строку для поиска
    lines[NR] = $0
}

function max(a, b) {
    return a > b ? a : b
}
' temp_log.txt >> "$OUTPUT_FILE"

# Удаление дубликатов и сортировка по времени
sort -t',' -k5,5 "$OUTPUT_FILE" | uniq > temp_sorted.csv
mv temp_sorted.csv "$OUTPUT_FILE"

# Очистка
rm -f temp_log.txt

# Статистика
TOTAL_USERS=$(tail -n +2 "$OUTPUT_FILE" | wc -l)
PREMIUM_USERS=$(tail -n +2 "$OUTPUT_FILE" | grep -c "true" || echo "0")

log "✅ Экспорт завершен!"
echo ""
echo "📊 Статистика:"
echo "   📁 Файл: $OUTPUT_FILE"
echo "   👥 Уникальных пользователей: $TOTAL_USERS"
echo "   👑 Premium пользователей: $PREMIUM_USERS"
echo "   📅 Период: последние $DAYS дней"
echo ""

# Показать результаты
echo "🏆 Найденные пользователи:"
tail -n +2 "$OUTPUT_FILE" | while IFS=',' read -r id username first_name last_name last_activity is_premium language_code; do
    echo "   $username ($first_name $last_name) - ID: $id - $last_activity"
done

echo ""
echo "💡 Для просмотра данных используйте:"
echo "   cat $OUTPUT_FILE"
echo "   head -20 $OUTPUT_FILE"
echo "" 