#!/bin/bash

# Простой скрипт для извлечения пользователей из блока "chat" в логах
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
OUTPUT_FILE="simple_chat_users_$(date +%Y%m%d).csv"
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
    in_chat_block = 0
}

{
    # Извлечение временной метки
    if ($1 ~ /^[A-Za-z]{3}/ && $2 ~ /^[0-9]+/ && $3 ~ /^[0-9]+:/) {
        current_timestamp = $1 " " $2 " " $3
    }
    
    # Поиск начала блока "chat"
    if (index($0, "chat") > 0 && index($0, "{") > 0) {
        in_chat_block = 1
        telegram_id = ""
        username = ""
        first_name = ""
        last_name = ""
        is_premium = ""
        language_code = ""
    }
    
    # Если мы в блоке "chat"
    if (in_chat_block) {
        # Извлечение telegram_id
        if (index($0, "id") > 0 && $0 ~ /[0-9]{9,}/ && !index($0, "message_id") && !index($0, "file_id")) {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"id":/) {
                    telegram_id = substr($i, index($i, ":") + 1)
                    gsub(/"/, "", telegram_id)
                    gsub(/,/, "", telegram_id)
                    if (telegram_id != "8383082096" && length(telegram_id) > 8) {
                        break
                    }
                }
            }
        }
        
        # Извлечение username
        if (index($0, "username") > 0 && !index($0, "saludovpnbot")) {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"username":/) {
                    username = substr($i, index($i, ":") + 2)
                    gsub(/"/, "", username)
                    gsub(/,/, "", username)
                    if (username != "" && username != "adminpassword:z4C9wQ8he4875T6d}" && username != "username") {
                        break
                    }
                }
            }
        }
        
        # Извлечение first_name
        if (index($0, "first_name") > 0 && !index($0, "WAYPN")) {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"first_name":/) {
                    first_name = substr($i, index($i, ":") + 2)
                    gsub(/"/, "", first_name)
                    gsub(/,/, "", first_name)
                    break
                }
            }
        }
        
        # Извлечение last_name
        if (index($0, "last_name") > 0) {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"last_name":/) {
                    last_name = substr($i, index($i, ":") + 2)
                    gsub(/"/, "", last_name)
                    gsub(/,/, "", last_name)
                    break
                }
            }
        }
        
        # Если нашли закрывающую скобку, выходим из блока
        if (index($0, "}") > 0) {
            in_chat_block = 0
            # Если у нас есть валидный telegram_id, сохраняем данные
            if (telegram_id != "" && telegram_id != "8383082096" && length(telegram_id) > 8) {
                # Заменяем пустые значения на "N/A"
                if (username == "") username = "N/A"
                if (first_name == "") first_name = "N/A"
                if (last_name == "") last_name = "N/A"
                if (is_premium == "") is_premium = "N/A"
                if (language_code == "") language_code = "N/A"
                
                print telegram_id, username, first_name, last_name, current_timestamp, is_premium, language_code
            }
        }
    }
}
' temp_log.txt > temp_users.txt

# Сортировка и удаление дубликатов
sort -t',' -k1,1 temp_users.txt | uniq >> "$OUTPUT_FILE"

# Очистка
rm -f temp_log.txt temp_users.txt

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