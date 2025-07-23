/**
 * Тестовый скрипт для проверки 3xui API
 */

const XuiAPI = require('./utils/xui-api');

async function testXuiAPI() {
    console.log('🚀 Тестирование 3xui API с правильными эндпоинтами...\n');
    
    const xuiConfig = {
        baseUrl: 'https://waypn.com:2053/waypn-settings/',
        email: 'admin',
        password: 'z4C9wQ8he4875T6d'
    };
    
    const xui = new XuiAPI(xuiConfig);
    
    try {
        // 1. Тест авторизации
        console.log('1️⃣ Тест авторизации...');
        const loginResult = await xui.login();
        if (!loginResult) {
            console.error('❌ Авторизация не удалась');
            return;
        }
        console.log('✅ Авторизация успешна\n');
        
        // 2. Получение списка inbound'ов
        console.log('2️⃣ Получение списка inbound\'ов...');
        const inbounds = await xui.getInbounds();
        if (!inbounds) {
            console.error('❌ Не удалось получить inbound\'ы');
            return;
        }
        console.log(`✅ Найдено inbound'ов: ${inbounds.length}`);
        inbounds.forEach((inbound, index) => {
            console.log(`   ${index + 1}. ${inbound.remark} (ID: ${inbound.id})`);
        });
        console.log();
        
        // 3. Поиск пользователя saul
        console.log('3️⃣ Поиск пользователя saul...');
        const userInfo = await xui.findUserByEmail('saul');
        if (userInfo) {
            console.log('✅ Пользователь saul найден:');
            console.log(`   Inbound: ${userInfo.inboundName} (ID: ${userInfo.inboundId})`);
            console.log(`   Email: ${userInfo.user.email}`);
            console.log(`   ID: ${userInfo.user.id}`);
            console.log(`   Flow: ${userInfo.user.flow}`);
            console.log(`   Лимит устройств: ${userInfo.user.limitIp}`);
            console.log(`   Трафик: ${userInfo.user.totalGB === 0 ? 'Безлимит' : userInfo.user.totalGB + ' GB'}`);
            console.log(`   Истекает: ${userInfo.user.expiryTime === 0 ? 'Безлимит' : new Date(userInfo.user.expiryTime).toLocaleString('ru-RU')}`);
            console.log(`   Активен: ${userInfo.user.enable ? 'Да' : 'Нет'}`);
            console.log(`   SubId: ${userInfo.user.subId}`);
            console.log();
            
            // 4. Показываем структуру для создания новых пользователей
            console.log('4️⃣ Структура для создания новых пользователей:');
            console.log('   Настройки inbound:');
            console.log(`   - Протокол: ${userInfo.inboundDetails.protocol}`);
            console.log(`   - Порт: ${userInfo.inboundDetails.port}`);
            console.log(`   - Пользователей: ${userInfo.settings.clients.length}`);
            console.log(`   - Flow: ${userInfo.user.flow}`);
            console.log();
            
            // 5. Показываем пример структуры нового пользователя
            console.log('5️⃣ Пример структуры нового пользователя:');
            const newUserExample = {
                id: xui.generateUUID(),
                email: "test_user_a@waypn.com",
                flow: "xtls-rprx-vision",
                limitIp: 3,
                totalGB: 0,
                expiryTime: new Date('2025-08-22T10:22:10.264942Z').getTime(),
                enable: true,
                tgId: "",
                subId: "test_subscription",
                reset: 0
            };
            console.log(JSON.stringify(newUserExample, null, 2));
            console.log();
            
        } else {
            console.log('❌ Пользователь saul не найден');
        }
        
        // 6. Тест создания пользователя (закомментирован для безопасности)
        console.log('6️⃣ Тест создания пользователя (закомментирован)...');
        console.log('   Для тестирования создания пользователя раскомментируйте код ниже');
        /*
        const testUser = await xui.createVpnUser(
            123456789, // telegram_user_id
            '2025-08-22T10:22:10.264942Z', // expires_at
            { subscription_id: 130961, period: 'monthly' } // subscription_data
        );
        if (testUser) {
            console.log('✅ Тестовый пользователь создан успешно');
        } else {
            console.log('❌ Не удалось создать тестового пользователя');
        }
        */
        
    } catch (error) {
        console.error('❌ Ошибка при тестировании API:', error.message);
    }
}

// Запуск теста
testXuiAPI().then(() => {
    console.log('\n🏁 Тестирование завершено');
    process.exit(0);
}).catch(error => {
    console.error('💥 Критическая ошибка:', error);
    process.exit(1);
}); 