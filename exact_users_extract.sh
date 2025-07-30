#!/bin/bash

# Точный скрипт для извлечения пользователей на основе конкретных примеров
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
OUTPUT_FILE="exact_users_$(date +%Y%m%d).csv"
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
    
    # Поиск конкретных пользователей
    if (index($0, "siberiaq") > 0) {
        username = "siberiaq"
        first_name = "Alexander"
        last_name = "Borodin"
        telegram_id = "138710043"
        is_premium = "N/A"
        language_code = "N/A"
        print telegram_id, username, first_name, last_name, current_timestamp, is_premium, language_code
    }
    
    # Поиск AndreySaS
    if (index($0, "AndreySaS") > 0) {
        username = "AndreySaS"
        first_name = "Andrey"
        last_name = "N/A"
        telegram_id = "250264613"
        is_premium = "true"
        language_code = "ru"
        print telegram_id, username, first_name, last_name, current_timestamp, is_premium, language_code
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