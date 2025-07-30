#!/bin/bash

# Правильный скрипт для извлечения уникальных пользователей Telegram
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

# Переменные
OUTPUT_FILE="correct_users_$(date +%Y%m%d).csv"
DAYS=365

log "📥 Загрузка логов..."
journalctl -u waypn-bot.service --since "$DAYS days ago" --no-pager > temp_log.txt

log "📊 Обработка логов и извлечение уникальных пользователей..."

# Создание CSV заголовка
echo "telegram_id,username,first_name,last_name,last_activity,is_premium,language_code" > "$OUTPUT_FILE"

# Извлечение данных пользователей
awk '
BEGIN {
    FS=" "
    OFS=","
    # Массив для хранения информации о пользователях
    # user_data[telegram_id] = "username|first_name|last_name|last_activity|is_premium|language_code"
}

{
    # Извлечение временной метки
    if ($1 ~ /^[A-Za-z]{3}/ && $2 ~ /^[0-9]+/ && $3 ~ /^[0-9]+:/) {
        current_timestamp = $1 " " $2 " " $3
    }
    
    # Поиск блока с информацией о пользователе (не боте)
    if (index($0, "from") > 0 && index($0, "{") > 0 && !index($0, "is_bot") && !index($0, "true")) {
        # Сброс переменных для нового пользователя
        telegram_id = ""
        username = ""
        first_name = ""
        last_name = ""
        is_premium = ""
        language_code = ""
    }
    
    # Извлечение telegram_id (только для пользователей, не ботов)
    if (index($0, "id") > 0 && $0 ~ /[0-9]{9,}/ && !index($0, "message_id") && !index($0, "file_id") && !index($0, "8383082096")) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"id":/) {
                telegram_id = substr($i, index($i, ":") + 1)
                gsub(/"/, "", telegram_id)
                gsub(/,/, "", telegram_id)
                # Проверяем, что это не ID бота и не служебные ID
                if (telegram_id != "8383082096" && telegram_id != "8383082096," && length(telegram_id) > 8) {
                    break
                }
            }
        }
    }
    
    # Извлечение username (только для пользователей, не ботов)
    if (index($0, "username") > 0 && !index($0, "saludovpnbot") && !index($0, "adminpassword")) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"username":/) {
                username = substr($i, index($i, ":") + 2)
                gsub(/"/, "", username)
                gsub(/,/, "", username)
                # Проверяем, что это валидный username
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
    
    # Извлечение is_premium
    if (index($0, "is_premium") > 0) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"is_premium":/) {
                is_premium = substr($i, index($i, ":") + 1)
                gsub(/,/, "", is_premium)
                break
            }
        }
    }
    
    # Извлечение language_code
    if (index($0, "language_code") > 0) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"language_code":/) {
                language_code = substr($i, index($i, ":") + 2)
                gsub(/"/, "", language_code)
                gsub(/,/, "", language_code)
                break
            }
        }
    }
    
    # Если нашли закрывающую скобку и у нас есть валидный telegram_id, сохраняем данные
    if (index($0, "}") > 0 && telegram_id != "" && telegram_id != "8383082096" && length(telegram_id) > 8) {
        # Формируем строку данных
        user_data = username "|" first_name "|" last_name "|" current_timestamp "|" is_premium "|" language_code
        
        # Сохраняем в массив, перезаписывая если уже есть (берем последнюю активность)
        users[telegram_id] = user_data
    }
}

END {
    # Выводим всех уникальных пользователей
    for (telegram_id in users) {
        split(users[telegram_id], data, "|")
        username = data[1]
        first_name = data[2]
        last_name = data[3]
        last_activity = data[4]
        is_premium = data[5]
        language_code = data[6]
        
        # Заменяем пустые значения на "N/A"
        if (username == "") username = "N/A"
        if (first_name == "") first_name = "N/A"
        if (last_name == "") last_name = "N/A"
        if (is_premium == "") is_premium = "N/A"
        if (language_code == "") language_code = "N/A"
        
        print telegram_id, username, first_name, last_name, last_activity, is_premium, language_code
    }
}
' temp_log.txt > temp_users.txt

# Сортировка по telegram_id и удаление дубликатов
sort -t',' -k1,1 temp_users.txt | uniq >> "$OUTPUT_FILE"

# Очистка временных файлов
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

# Показать топ пользователей по активности
echo "🏆 Последние активные пользователи:"
tail -n +2 "$OUTPUT_FILE" | sort -t',' -k5,5 | tail -5 | while IFS=',' read -r id username first_name last_name last_activity is_premium language_code; do
    echo "   $username ($first_name $last_name) - $last_activity"
done

echo ""
echo "💡 Для просмотра данных используйте:"
echo "   cat $OUTPUT_FILE"
echo "   head -20 $OUTPUT_FILE"
echo "" 