# WAYPN Bot Lite

Telegram бот для автоматической продажи VPN подписок через Tribute с интеграцией 3xui панели.

## 🚀 Возможности

- **Автоматическая обработка платежей** через Tribute
- **Интеграция с 3xui панелью** для создания VPN пользователей
- **Генерация VLESS конфигураций** для быстрого подключения
- **Удобный интерфейс** с inline кнопками
- **Поддержка webhook'ов** для мгновенных уведомлений

## 📋 Требования

- Node.js 16+
- 3xui панель с настроенным VLESS + Reality
- Telegram Bot Token
- Tribute аккаунт

## 🛠 Установка

1. **Клонируйте репозиторий:**
```bash
git clone <repository-url>
cd waypn-bot-lite
```

2. **Установите зависимости:**
```bash
npm install
```

3. **Настройте переменные окружения:**
```bash
cp env.example .env
```

Отредактируйте `.env` файл:
```env
# Telegram Bot Token (получите у @BotFather)
BOT_TOKEN=your_telegram_bot_token_here

# Tribute ссылка для оплаты
TRIBUTE_PAYMENT_URL=https://t.me/tribute/app?startapp=sy4h

# Ссылка на поддержку
SUPPORT_LINK=@your_support_username

# Порт для вебхук сервера
PORT=3000

# Секретный ключ для верификации вебхуков (опционально)
WEBHOOK_SECRET=your_webhook_secret_here
```

4. **Настройте статические параметры Reality** в `config/constants.js`:
```javascript
const REALITY_CONFIG = {
    publicKey: 'KKPXarv8v8jFdfZGxqa3pFg6N0YLrLStCGkhGhoQfzg',
    serverName: 'nu.nl',
    shortId: '5a8d7361945cf53c',
    server: 'waypn.com:443',
    flow: 'xtls-rprx-vision'
};
```

## 🚀 Запуск

### Быстрое управление (рекомендуется)
```bash
# Проверить статус системы
./status.sh

# Запустить/перезапустить бота и вебхук
./restart.sh

# Остановить бота и вебхук
./stop.sh
```

### Разработка
```bash
# Запуск только бота
npm run dev

# Запуск только вебхука
npm run dev:webhook

# Запуск бота и вебхука одновременно
npm run dev:all
```

### Продакшн
```bash
# Запуск только бота
npm start

# Запуск только вебхука
npm run webhook

# Запуск бота и вебхука одновременно
npm run start:all
```

## 📡 Настройка Webhook

1. **Настройте webhook URL в Tribute:**
   - URL: `https://your-domain.com/webhook/tribute`
   - Метод: POST
   - Content-Type: application/json

2. **Настройте reverse proxy (nginx):**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔧 Конфигурация 3xui

### Настройки Inbound
- **ID**: 4
- **Название**: "waypn.com"
- **Протокол**: VLESS
- **Порт**: 443
- **Security**: Reality

### Параметры пользователей
- **Email формат**: `{telegram_user_id}_a` (без @waypn.com)
- **Лимит устройств**: 3
- **Трафик**: Безлимит
- **Flow**: xtls-rprx-vision

## 📱 Использование

### Команды бота
- `/start` - Главное меню
- `💳 Оплатить VPN` - Информация об оплате
- `⚙️ Настроить VPN` - Инструкции по настройке
- `🆘 Поддержка` - Связь с поддержкой

### Процесс оплаты
1. Пользователь нажимает "💳 Оплатить VPN"
2. Получает информацию об оплате с кнопкой перехода к Tribute
3. После успешной оплаты получает webhook
4. Автоматически создается VPN пользователь в 3xui
5. Пользователь получает VLESS конфигурацию для подключения

## 📊 Структура проекта

```
waypn-bot-lite/
├── config/
│   └── constants.js          # Константы и настройки
├── utils/
│   ├── keyboards.js          # Утилиты для клавиатур
│   └── xui-api.js           # API для работы с 3xui
├── index.js                 # Основной файл бота
├── webhook.js              # Webhook сервер
├── package.json            # Зависимости
└── README.md              # Документация
```

## 🔍 Логирование

Бот ведет подробные логи всех операций:
- Создание пользователей
- Генерация VLESS конфигураций
- Обработка webhook'ов
- Ошибки и исключения

## 🛡️ Безопасность

- Все API ключи хранятся в переменных окружения
- Webhook секреты для верификации
- Валидация входящих данных
- Обработка ошибок и исключений

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи в консоли
2. Убедитесь в правильности настроек 3xui
3. Проверьте доступность webhook URL
4. Обратитесь к документации Tribute API

## 📝 Лицензия

MIT License 