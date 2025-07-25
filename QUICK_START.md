# 🚀 Быстрый запуск VPN бота

## 1. Настройка токена

1. Создайте бота через [@BotFather](https://t.me/BotFather)
2. Скопируйте токен
3. Создайте файл `.env`:
```bash
cp env.example .env
```
4. Вставьте токен в `.env`:
```env
BOT_TOKEN=ваш_токен_бота
```

## 2. Запуск (рекомендуется)

```bash
# Установка зависимостей
npm install

# Запуск бота и вебхук сервера одновременно
npm run start:all
```

## 3. Альтернативные способы запуска

### Только основной бот
```bash
npm start
```

### Только вебхук сервер
```bash
npm run webhook
```

### Для разработки (с автоперезагрузкой)
```bash
npm run dev:all
```

## 4. Тестирование

### Основной бот
Отправьте боту команду `/start` или любое сообщение.

### Вебхуки
```bash
# Тестирование вебхука
npm run test:webhook
```

## ✅ Готово!

### Основной бот
Бот должен показать главное меню с тремя кнопками:
- 💳 Оплатить VPN
- ⚙️ Настроить VPN  
- 🆘 Поддержка

### Вебхуки
При успешной оплате пользователь получит автоматическое уведомление с:
- ✅ Подтверждением оплаты
- 🔑 Персональным кодом доступа
- 📱 Инструкцией по настройке

## 🔧 Настройка

- Измените изображения в `config/constants.js`
- Измените тексты в `config/constants.js`
- Добавьте логику настройки VPN в `index.js`
- Настройте вебхук URL в Tribute: `https://your-domain.com/webhook/tribute`

## 🌐 Локальная разработка

Для тестирования вебхуков используйте ngrok:
```bash
npm install -g ngrok
ngrok http 3000
``` 