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
        return "Пользователь не найден￼";
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