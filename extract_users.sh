#!/bin/bash

# Скрипт для извлечения информации о пользователях из логов
# Автор: WAYPN Team
# Версия: 1.0

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

# Извлечение данных пользователей
awk '
BEGIN {
    FS=" "
    OFS=","
    # Массив для хранения последнего известного ID пользователя
    user_ids[""] = ""
}

{
    # Извлечение временной метки
    timestamp = $1 " " $2 " " $3
    
    # Поиск username
    if (index($0, "username") > 0) {
        username = ""
        for (i = 1; i <= NF; i++) {
            if ($i ~ /"username":/) {
                # Извлекаем username из JSON
                username = substr($i, index($i, ":") + 2)
                gsub(/"/, "", username)
                gsub(/,/, "", username)
                break
            }
        }
        
        # Поиск user_id в соседних строках
        user_id = ""
        if (username != "") {
            # Ищем ID в предыдущих и следующих строках
            for (i = max(1, NR-10); i <= NR+10; i++) {
                if (i in lines && lines[i] ~ /"id":/) {
                    for (j = 1; j <= split(lines[i], parts, " "); j++) {
                        if (parts[j] ~ /"id":/) {
                            user_id = substr(parts[j], index(parts[j], ":") + 1)
                            gsub(/"/, "", user_id)
                            gsub(/,/, "", user_id)
                            break
                        }
                    }
                    if (user_id != "") break
                }
            }
            
            # Если не нашли ID, используем сохраненный
            if (user_id == "" && username in user_ids) {
                user_id = user_ids[username]
            } else if (user_id != "") {
                user_ids[username] = user_id
            }
        }
        
        # Определение действия
        action = "unknown"
        if (index($0, "callback_data") > 0) action = "button_click"
        else if (index($0, "/start") > 0) action = "start_command"
        else if (index($0, "message") > 0) action = "message"
        
        # Определение типа сообщения
        message_type = "unknown"
        if (index($0, "inline_keyboard") > 0) message_type = "keyboard"
        else if (index($0, "photo") > 0) message_type = "photo"
        else if (index($0, "text") > 0) message_type = "text"
        
        # Детали
        details = ""
        if (index($0, "callback_data") > 0) {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /"callback_data":/) {
                    details = substr($i, index($i, ":") + 2)
                    gsub(/"/, "", details)
                    gsub(/,/, "", details)
                    break
                }
            }
        }
        
        # Вывод в CSV
        if (username != "") {
            print timestamp, username, user_id, action, message_type, details
        }
    }
    
    # Сохраняем строку для поиска ID
    lines[NR] = $0
}

function max(a, b) {
    return a > b ? a : b
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