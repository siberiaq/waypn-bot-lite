const express = require('express');
const bodyParser = require('body-parser');
const TelegramBot = require('node-telegram-bot-api');
const XuiAPI = require('./utils/xui-api');
const { saveUserConfig } = require('./utils/user-configs');
const { 
    TRIBUTE_PAYMENT_URL, 
    SUPPORT_LINK, 
    MESSAGES,
    SETUP_MESSAGES,
    IMAGES
} = require('./config/constants');

const { getSetupKeyboard } = require('./utils/keyboards');

// Загрузка переменных окружения
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Инициализация Telegram бота
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: false });

// Инициализация 3xui API
const xuiConfig = {
    baseUrl: 'https://waypn.com:2053/waypn-settings/',
    email: 'admin',
    password: 'z4C9wQ8he4875T6d'
};
const xui = new XuiAPI(xuiConfig);

// Настройка middleware для парсинга JSON
app.use(bodyParser.json({
    verify: (req, res, buf) => {
        try {
            JSON.parse(buf);
        } catch (e) {
            console.error('❌ Ошибка парсинга JSON:', e.message);
            // Попытка исправить обрезанный JSON
            const fixedBuf = Buffer.concat([buf, Buffer.from('}')]);
            try {
                JSON.parse(fixedBuf);
                console.log('✅ JSON исправлен');
            } catch (e2) {
                console.error('❌ Не удалось исправить JSON');
            }
        }
    }
}));

// Глобальный обработчик ошибок
app.use((error, req, res, next) => {
    console.error('❌ Ошибка в middleware:', error.message);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Эндпоинт для проверки здоровья сервера
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date().toISOString(),
        message: 'Вебхук сервер работает'
    });
});

// Эндпоинт для получения вебхуков от Tribute
app.post('/webhook/tribute', async (req, res) => {
    try {
        const webhookData = req.body;
        
        console.log('📨 Получен вебхук от Tribute:', JSON.stringify(webhookData, null, 2));
        
        // Проверяем, что это уведомление о новой подписке
        if (webhookData.name === 'new_subscription') {
            const payload = webhookData.payload;
            const telegramUserId = payload.telegram_user_id;
            const expiresAt = payload.expires_at;
            
            console.log(`🎉 Новая подписка для пользователя ${telegramUserId}`);
            console.log(`   Сумма: ${payload.amount} ${payload.currency}`);
            console.log(`   Период: ${payload.period}`);
            console.log(`   Истекает: ${expiresAt}`);
            
            // Создаем VPN пользователя в 3xui
            console.log('🚀 Создание VPN пользователя...');
            const vpnUser = await xui.createVpnUser(telegramUserId, expiresAt, {
                subscription_id: payload.subscription_id,
                period: payload.period
            });
            
            if (vpnUser) {
                if (vpnUser.action === 'created') {
                    console.log('✅ VPN пользователь создан успешно');
                    console.log(`   Email: ${vpnUser.user.email}`);
                    console.log(`   UUID: ${vpnUser.user.id}`);
                    console.log(`   Inbound: ${vpnUser.inbound.remark}`);
                    
                    // Сохраняем VLESS конфигурацию
                    saveUserConfig(telegramUserId, vpnUser.vlessConfig);
                    
                } else if (vpnUser.action === 'updated') {
                    console.log('✅ Подписка пользователя обновлена успешно');
                    console.log(`   Email: ${vpnUser.user.email}`);
                    console.log(`   Старая дата окончания: ${vpnUser.oldExpiryTime}`);
                    console.log(`   Новая дата окончания: ${vpnUser.newExpiryTime}`);
                    
                    // Сохраняем VLESS конфигурацию
                    saveUserConfig(telegramUserId, vpnUser.vlessConfig);
                }
            } else {
                console.error('❌ Не удалось обработать VPN пользователя');
            }
            
            // Отправляем сообщение пользователю
            const amountInRubles = payload.amount / 100; // Конвертируем копейки в рубли
            const nextBillingDate = new Date(expiresAt).toLocaleDateString('ru-RU'); // Только дата без времени
            
            // Формируем сообщение об успешной оплате
            let message;
            
            if (vpnUser && vpnUser.action === 'updated') {
                // Конвертируем timestamp'ы в читаемые даты
                const oldDate = new Date(parseInt(vpnUser.oldExpiryTime)).toLocaleDateString('ru-RU');
                const newDate = new Date(parseInt(vpnUser.newExpiryTime)).toLocaleDateString('ru-RU');
                
                // Сообщение для обновления подписки
                message = `🎉 *Подписка успешно продлена!*\n\n` +
                         `💰 Сумма: ${amountInRubles} ${payload.currency}\n` +
                         `📅 Срок подписки: ${payload.period}\n` +
                         `📅 Старая дата окончания: ${oldDate}\n` +
                         `📅 Новая дата окончания: ${newDate}\n\n` +
                         `${SETUP_MESSAGES.SUCCESS}`;
            } else if (vpnUser && vpnUser.action === 'created') {
                // Сообщение для нового пользователя
                message = `🎉 *Оплата прошла успешно!*\n\n` +
                         `💰 Сумма: ${amountInRubles} ${payload.currency}\n` +
                         `📅 Срок подписки: ${payload.period}\n` +
                         `⏰ Дата следующего списания: ${nextBillingDate}\n\n` +
                         `${SETUP_MESSAGES.SUCCESS}`;
            } else {
                // Сообщение если что-то пошло не так
                message = `🎉 *Оплата прошла успешно!*\n\n` +
                         `💰 Сумма: ${amountInRubles} ${payload.currency}\n` +
                         `📅 Срок подписки: ${payload.period}\n` +
                         `⏰ Дата следующего списания: ${nextBillingDate}\n\n` +
                         `⚠️ *VPN аккаунт будет создан в ближайшее время*\n\n` +
                         `Мы обрабатываем ваш запрос. Вы получите данные для подключения в течение 5 минут.`;
            }
            
            const keyboard = getSetupKeyboard();
            console.log(`📋 Структура клавиатуры:`, JSON.stringify(keyboard, null, 2));
            console.log(`📝 Текст сообщения:`, message);
            
            try {
                // Отправляем изображение с сообщением об успешной оплате
                if (IMAGES.PAYMENT) {
                    const result = await bot.sendPhoto(telegramUserId, IMAGES.PAYMENT, {
                        caption: message,
                        parse_mode: 'Markdown',
                        reply_markup: keyboard
                    });
                    console.log(`✅ Сообщение с изображением об успешной оплате отправлено пользователю ${telegramUserId}`);
                    console.log(`📋 Кнопки в сообщении:`, keyboard);
                    console.log(`📨 Результат отправки:`, result.message_id);
                    console.log(`📨 Полный результат:`, JSON.stringify(result, null, 2));
                } else {
                    const result = await bot.sendMessage(telegramUserId, message, {
                        parse_mode: 'Markdown',
                        reply_markup: keyboard
                    });
                    console.log(`✅ Сообщение об успешной оплате отправлено пользователю ${telegramUserId}`);
                    console.log(`📋 Кнопки в сообщении:`, keyboard);
                    console.log(`📨 Результат отправки:`, result.message_id);
                    console.log(`📨 Полный результат:`, JSON.stringify(result, null, 2));
                }
            } catch (error) {
                console.error(`❌ Ошибка отправки сообщения:`, error.message);
                console.error(`❌ Полная ошибка:`, error);
            }
            
            // Сохраняем информацию о платеже (можно добавить базу данных)
            console.log('💾 Информация о платеже сохранена:', {
                subscription_id: payload.subscription_id,
                user_id: payload.user_id,
                telegram_user_id: telegramUserId,
                amount: payload.amount,
                currency: payload.currency,
                expires_at: expiresAt,
                vpn_action: vpnUser ? vpnUser.action : 'failed',
                vpn_created: !!vpnUser
            });
            
        } else {
            console.log(`📝 Получен вебхук типа: ${webhookData.name}`);
        }
        
        // Отправляем успешный ответ
        res.json({ 
            status: 'success', 
            message: 'Webhook processed successfully',
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ Ошибка обработки вебхука:', error.message);
        res.status(500).json({ 
            error: 'Internal Server Error',
            message: error.message 
        });
    }
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🌐 Вебхук сервер запущен на порту ${PORT}`);
    console.log(`📡 Эндпоинт вебхука: http://localhost:${PORT}/webhook/tribute`);
    console.log(`💚 Проверка здоровья: http://localhost:${PORT}/health`);
});

// Обработка graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Остановка вебхук сервера...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Остановка вебхук сервера...');
    process.exit(0);
}); 