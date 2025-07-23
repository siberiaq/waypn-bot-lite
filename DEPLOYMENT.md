# 🚀 Деплой WAYPN Bot Lite

Этот документ содержит инструкции по деплою WAYPN Bot Lite на локальный сервер или удаленный сервер.

## 📋 Требования

### Системные требования
- **Node.js** версии 16 или выше
- **npm** или **yarn**
- **Git** (для обновления кода)
- **Linux/Unix** система (для systemd сервисов)

### Переменные окружения
Перед деплоем необходимо настроить следующие переменные в файле `.env`:

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

# 3xui API настройки (опционально)
XUI_BASE_URL=https://waypn.com:2053/waypn-settings/
XUI_EMAIL=admin
XUI_PASSWORD=z4C9wQ8he4875T6d
```

## 🔧 Локальный деплой

### Быстрый деплой
```bash
# Клонирование репозитория
git clone https://github.com/siberiaq/waypn-bot-lite.git
cd waypn-bot-lite

# Настройка переменных окружения
cp env.example .env
# Отредактируйте .env файл

# Запуск деплоя
./deploy.sh
```

### Опции деплоя
```bash
# Обычный деплой
./deploy.sh

# Принудительный деплой (остановка всех процессов)
./deploy.sh --force

# Обновление кода из Git и деплой
./deploy.sh --update

# Только перезапуск сервисов
./deploy.sh --restart

# Справка
./deploy.sh --help
```

## 🌐 Удаленный деплой

### Подготовка
1. Убедитесь, что у вас есть SSH доступ к серверу
2. SSH ключ настроен (рекомендуется)
3. Сервер доступен по сети

### Быстрый деплой на удаленный сервер
```bash
# Деплой на сервер с IP 192.168.1.100
./deploy-remote.sh --server 192.168.1.100

# Деплой с указанием пользователя и порта
./deploy-remote.sh --server example.com --user ubuntu --port 2222

# Деплой с SSH ключом
./deploy-remote.sh --server example.com --key ~/.ssh/id_rsa

# Обновление кода на сервере
./deploy-remote.sh --server example.com --update
```

### Переменные окружения для удаленного деплоя
```bash
# Установка переменных окружения
export REMOTE_SERVER="your-server.com"
export REMOTE_USER="ubuntu"
export REMOTE_PORT="22"
export REMOTE_KEY="~/.ssh/id_rsa"
export REMOTE_PATH="/opt/waypn-bot-lite"

# Деплой с переменными окружения
./deploy-remote.sh
```

### Опции удаленного деплоя
```bash
--server     Адрес сервера (обязательно)
--user       Пользователь на сервере (по умолчанию: root)
--port       SSH порт (по умолчанию: 22)
--key        Путь к SSH ключу
--path       Путь на сервере (по умолчанию: /opt/waypn-bot-lite)
--update     Обновить код из Git репозитория
--force      Принудительный деплой
--help       Показать справку
```

## 🔍 Проверка деплоя

### Локальный сервер
```bash
# Проверка статуса
./status.sh

# Проверка логов
tail -f waypn-bot.log

# Проверка health check
curl http://localhost:3000/health

# Проверка процессов
ps aux | grep node
```

### Удаленный сервер
```bash
# Подключение к серверу
ssh user@server.com

# Проверка статуса systemd сервиса
systemctl status waypn-bot

# Просмотр логов
journalctl -u waypn-bot.service -f

# Проверка health check
curl http://localhost:3000/health
```

## 🛠️ Управление сервисом

### Локальный сервер
```bash
# Запуск
npm run start:all

# Остановка
./stop.sh

# Перезапуск
./restart.sh

# Проверка статуса
./status.sh
```

### Удаленный сервер (systemd)
```bash
# Запуск сервиса
sudo systemctl start waypn-bot

# Остановка сервиса
sudo systemctl stop waypn-bot

# Перезапуск сервиса
sudo systemctl restart waypn-bot

# Проверка статуса
sudo systemctl status waypn-bot

# Включение автозапуска
sudo systemctl enable waypn-bot

# Отключение автозапуска
sudo systemctl disable waypn-bot
```

## 📝 Логирование

### Локальный сервер
- Логи приложения: `waypn-bot.log`
- Логи npm: `npm-debug.log*`

### Удаленный сервер
- Systemd логи: `journalctl -u waypn-bot.service`
- Логи приложения: `/opt/waypn-bot-lite/waypn-bot.log`

## 🔧 Устранение неполадок

### Частые проблемы

#### 1. Порт уже занят
```bash
# Проверка процессов на порту
lsof -i :3000

# Остановка процесса
kill -9 <PID>
```

#### 2. Node.js не установлен
```bash
# Установка Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### 3. Зависимости не установлены
```bash
# Очистка и переустановка
rm -rf node_modules package-lock.json
npm install
```

#### 4. Проблемы с правами доступа
```bash
# Установка прав на скрипты
chmod +x deploy.sh restart.sh status.sh stop.sh

# Установка прав на директорию
chmod 755 /opt/waypn-bot-lite
```

#### 5. Проблемы с .env файлом
```bash
# Проверка синтаксиса
cat .env | grep -v '^#' | grep -v '^$'

# Создание из примера
cp env.example .env
```

### Диагностика

#### Проверка подключения к серверу
```bash
# Тест SSH подключения
ssh -p 22 user@server.com "echo 'Connection test'"

# Проверка доступности портов
telnet server.com 22
```

#### Проверка системных ресурсов
```bash
# Использование памяти
free -h

# Использование диска
df -h

# Загрузка CPU
top
```

## 🔄 Обновление

### Локальный сервер
```bash
# Обновление кода
git pull origin main

# Перезапуск с обновлением
./deploy.sh --update
```

### Удаленный сервер
```bash
# Обновление кода и перезапуск
./deploy-remote.sh --server example.com --update
```

## 📞 Поддержка

Если у вас возникли проблемы с деплоем:

1. Проверьте логи: `tail -f waypn-bot.log`
2. Проверьте статус сервиса: `systemctl status waypn-bot`
3. Убедитесь, что все переменные окружения настроены
4. Проверьте системные требования

Для получения помощи создайте issue в репозитории или обратитесь к команде поддержки. 