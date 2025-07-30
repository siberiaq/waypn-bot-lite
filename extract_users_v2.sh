#!/bin/bash

# Улучшенный скрипт для извлечения информации о пользователях из логов
# Автор: WAYPN Team
# Версия: 2.0

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# Проверка аргументов
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --help, -h     Показать эту справку"
    echo "  --output       Имя выходного CSV файла (по умолчанию: users_$(date +%Y%m%d).csv)"
    echo "  --days         Количество дней для анализа (по умолчанию: 7)"
    echo ""
    echo "Примеры:"
    echo "  $0"
    echo "  $0 --output users.csv"
    echo "  $0 --days 30 --output monthly_users.csv"
    exit 0
fi

# Переменные по умолчанию
OUTPUT_FILE="${OUTPUT_FILE:-users_$(date +%Y%m%d).csv}"
DAYS="${DAYS:-7}"

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --days)
            DAYS="$2"
            shift 2
            ;;
        *)
            error "Неизвестная опция: $1"
            exit 1
            ;;
    esac
done

# Создание временного файла для обработки логов
TEMP_LOG="temp_users_log.txt"
TEMP_CSV="temp_users_data.csv"

# Очистка временных файлов
rm -f "$TEMP_LOG" "$TEMP_CSV"

log "📥 Загрузка логов..."
journalctl -u waypn-bot.service --since "$DAYS days ago" --no-pager > "$TEMP_LOG"

if [ ! -s "$TEMP_LOG" ]; then
    error "Не удалось получить логи"
    exit 1
fi

log "📊 Обработка логов и извлечение данных пользователей..."

# Создание CSV заголовка
echo "timestamp,username,user_id,action,message_type,details" > "$TEMP_CSV"

# Извлечение данных пользователей с улучшенным парсингом
awk '
BEGIN {
    FS=" "
    OFS=","
    # Массив для хранения последнего известного ID пользователя
    user_ids[""] = ""
    current_timestamp = ""
    current_username = ""
    current_user_id = ""
    current_action = "unknown"
    current_message_type = "unknown"
    current_details = ""
}

{
    # Извлечение временной метки
    if ($1 ~ /^[A-Za-z]{3}/ && $2 ~ /^[0-9]+/ && $3 ~ /^[0-9]+:/) {
        current_timestamp = $1 " " $2 " " $3
    }
    
    # Поиск JSON объектов с информацией о пользователе
    if (index($0, "username") > 0 && index($0, "id") > 0) {
        # Извлекаем username
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"username":/) {
                current_username = substr($i, index($i, ":") + 2)
                gsub(/"/, "", current_username)
                gsub(/,/, "", current_username)
                break
            }
        }
        
        # Извлекаем user_id
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"id":/) {
                current_user_id = substr($i, index($i, ":") + 1)
                gsub(/"/, "", current_user_id)
                gsub(/,/, "", current_user_id)
                break
            }
        }
        
        # Определение действия
        if (index($0, "callback_data") > 0) {
            current_action = "button_click"
            # Извлекаем callback_data
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"callback_data":/) {
                    current_details = substr($i, index($i, ":") + 2)
                    gsub(/"/, "", current_details)
                    gsub(/,/, "", current_details)
                    break
                }
            }
        } else if (index($0, "/start") > 0) {
            current_action = "start_command"
        } else if (index($0, "message") > 0) {
            current_action = "message"
        }
        
        # Определение типа сообщения
        if (index($0, "inline_keyboard") > 0) current_message_type = "keyboard"
        else if (index($0, "photo") > 0) current_message_type = "photo"
        else if (index($0, "text") > 0) current_message_type = "text"
        
        # Вывод в CSV только если есть валидный username
        if (current_username != "" && current_username != "adminpassword:z4C9wQ8he4875T6d}" && current_username != "username") {
            print current_timestamp, current_username, current_user_id, current_action, current_message_type, current_details
        }
    }
    
    # Поиск отдельных строк с username (для случаев, когда JSON разбит на строки)
    if (index($0, "username") > 0 && !index($0, "adminpassword") && !index($0, "username:") && $0 !~ /^[A-Za-z]{3}/) {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"username":/) {
                current_username = substr($i, index($i, ":") + 2)
                gsub(/"/, "", current_username)
                gsub(/,/, "", current_username)
                
                # Проверяем, что это валидный username
                if (current_username != "" && current_username != "adminpassword:z4C9wQ8he4875T6d}" && current_username != "username") {
                    print current_timestamp, current_username, current_user_id, current_action, current_message_type, current_details
                }
                break
            }
        }
    }
}
' "$TEMP_LOG" >> "$TEMP_CSV"

# Сортировка и удаление дубликатов
log "🔄 Сортировка и удаление дубликатов..."
sort -t',' -k1,2 "$TEMP_CSV" | uniq > "$OUTPUT_FILE"

# Удаление временного файла
rm -f "$TEMP_LOG" "$TEMP_CSV"

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
echo "   head -20 $OUTPUT_FILE  # первые 20 строк"
echo "" 