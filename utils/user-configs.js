/**
 * Утилита для хранения VLESS конфигураций пользователей
 * В продакшене рекомендуется использовать базу данных
 */

// Хранилище конфигураций в памяти
const userConfigs = new Map();

/**
 * Сохранение VLESS конфигурации пользователя
 */
function saveUserConfig(telegramUserId, vlessConfig) {
    userConfigs.set(telegramUserId.toString(), vlessConfig);
    console.log(`💾 Конфигурация сохранена для пользователя ${telegramUserId}`);
}

/**
 * Получение VLESS конфигурации пользователя
 */
function getUserConfig(telegramUserId) {
    const config = userConfigs.get(telegramUserId.toString());
    if (config) {
        console.log(`📋 Конфигурация получена для пользователя ${telegramUserId}`);
        return config;
    } else {
        console.log(`⚠️ Конфигурация не найдена для пользователя ${telegramUserId}`);
        // Возвращаем заглушку для демонстрации
        return "vless://46de4c61-00c7-4cf7-8790-b3113205e1dd@waypn.com:443?type=tcp&security=reality&pbk=KKPXarv8v8jFdfZGxqa3pFg6N0YLrLStCGkhGhoQfzg&fp=random&sni=nu.nl&sid=5a8d7361945cf53c&spx=%2F&flow=xtls-rprx-vision#waypn.com-example";
    }
}

/**
 * Удаление VLESS конфигурации пользователя
 */
function deleteUserConfig(telegramUserId) {
    const deleted = userConfigs.delete(telegramUserId.toString());
    if (deleted) {
        console.log(`🗑️ Конфигурация удалена для пользователя ${telegramUserId}`);
    }
    return deleted;
}

/**
 * Получение всех конфигураций (для отладки)
 */
function getAllConfigs() {
    return Object.fromEntries(userConfigs);
}

module.exports = {
    saveUserConfig,
    getUserConfig,
    deleteUserConfig,
    getAllConfigs
}; 