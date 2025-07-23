/**
 * Скрипт для тестирования вебхука от Tribute
 */

const axios = require('axios');

// Тестовые данные вебхука
const testWebhookData = {
    "created_at": "2025-07-22T10:22:10.46183Z",
    "name": "new_subscription",
    "payload": {
        "subscription_name": "Быстрый VPN для Instagram и YouTube 🚀",
        "subscription_id": 130961,
        "period_id": 160061,
        "period": "monthly",
        "price": 10000,
        "amount": 10000,
        "currency": "rub",
        "user_id": 138710043,
        "telegram_user_id": 334734136, // Замените на ваш Telegram ID
        "web_app_link": "https://t.me/tribute/app?startapp=sy4h",
        "channel_id": 321306,
        "channel_name": "WAYPN",
        "expires_at": "2025-08-22T10:22:10.264942Z"
    },
    "sent_at": "2025-07-22T10:22:11.125069655Z"
};

async function testWebhook() {
    try {
        console.log('🧪 Тестирование вебхука...');
        
        const response = await axios.post('http://localhost:3000/webhook/tribute', testWebhookData, {
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        console.log('✅ Вебхук успешно обработан!');
        console.log('📊 Ответ сервера:', response.data);
        
    } catch (error) {
        console.error('❌ Ошибка при тестировании вебхука:');
        
        if (error.response) {
            console.error('📊 Статус:', error.response.status);
            console.error('📄 Данные:', error.response.data);
        } else {
            console.error('🌐 Ошибка сети:', error.message);
        }
    }
}

// Проверяем, что сервер запущен
async function checkServerHealth() {
    try {
        const response = await axios.get('http://localhost:3000/health');
        console.log('💚 Сервер работает:', response.data);
        return true;
    } catch (error) {
        console.error('❌ Сервер не отвечает. Убедитесь, что вебхук сервер запущен:');
        console.error('   npm run webhook');
        return false;
    }
}

async function main() {
    console.log('🚀 Запуск тестирования вебхука...\n');
    
    const serverOk = await checkServerHealth();
    if (!serverOk) {
        return;
    }
    
    console.log('\n📨 Отправка тестового вебхука...\n');
    await testWebhook();
}

main(); 