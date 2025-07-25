# 🚀 Команды запуска VPN бота

## 🎯 Рекомендуемый способ (все в одном)

```bash
# Продакшен
npm run start:all

# Разработка (с автоперезагрузкой)
npm run dev:all
```

## 📋 Доступные команды

| Команда | Описание |
|---------|----------|
| `npm run start:all` | Запуск бота + вебхук сервера (продакшен) |
| `npm run dev:all` | Запуск бота + вебхук сервера (разработка) |
| `npm start` | Только основной бот |
| `npm run webhook` | Только вебхук сервер |
| `npm run dev` | Только бот (разработка) |
| `npm run dev:webhook` | Только вебхук (разработка) |
| `npm run test:webhook` | Тестирование вебхука |

## 🔧 Что запускается

### `npm run start:all`
- 🤖 **Telegram бот** (порт не требуется)
- 🌐 **Вебхук сервер** (порт 3000)
- 📡 **Эндпоинт:** `http://localhost:3000/webhook/tribute`
- 💚 **Health check:** `http://localhost:3000/health`

### `npm run dev:all`
- 🤖 **Telegram бот** с автоперезагрузкой
- 🌐 **Вебхук сервер** с автоперезагрузкой
- 🔄 **Автоматический перезапуск** при изменении файлов

## 🛑 Остановка

Нажмите `Ctrl+C` в терминале для остановки всех процессов.

## ✅ Проверка работы

1. **Бот работает:** Отправьте `/start` в Telegram
2. **Вебхук работает:** `curl http://localhost:3000/health`
3. **Тест вебхука:** `npm run test:webhook`

## 🌐 Для продакшена

1. Запустите: `npm run start:all`
2. Настройте ngrok: `ngrok http 3000`
3. Укажите URL в Tribute: `https://your-ngrok-url.ngrok.io/webhook/tribute` 