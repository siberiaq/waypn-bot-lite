const { CLIENT_APPS } = require('../config/constants');

/**
 * Утилиты для создания клавиатур Telegram бота
 */

// Главное меню с inline кнопками
function getMainKeyboard() {
    return {
        reply_markup: {
            inline_keyboard: [
                [
                    { text: '💳 Оплатить или продлить доступ', url: 'https://t.me/tribute/app?startapp=sy4h' },
                    { text: '⚙️ Настроить VPN', callback_data: 'vpn_setup' }
                ],
                [
                    { text: '🆘 Поддержка', callback_data: 'support' }
                ]
            ]
        }
    };
}

// Inline клавиатура с кнопкой "Назад"
function getBackKeyboard() {
    return {
        reply_markup: {
            inline_keyboard: [
                [{
                    text: '🔙 Назад',
                    callback_data: 'back_to_main'
                }]
            ]
        }
    };
}

// Клавиатура для оплаты с кнопкой перехода к оплате
function getPaymentKeyboard(paymentUrl) {
    return {
        reply_markup: {
            inline_keyboard: [
                [{
                    text: '💳 Перейти к оплате',
                    url: paymentUrl
                }],
                [{
                    text: '🔙 Назад',
                    callback_data: 'back_to_main'
                }]
            ]
        }
    };
}

/**
 * Клавиатура для успешной оплаты/продления
 */
function getSetupKeyboard() {
    return {
        inline_keyboard: [
            [
                { text: "⚙️ Настроить VPN", callback_data: "setup_manual" }
            ],
            [
                { text: "🔙 Назад", callback_data: "back_to_main" }
            ]
        ]
    };
}

/**
 * Клавиатура для диалога настройки VPN
 */
function getVpnSetupDialogKeyboard() {
    return {
        inline_keyboard: [
            [
                { text: "⚙️ Настроить VPN", callback_data: "setup_manual" }
            ],
            [
                { text: "🔙 Назад", callback_data: "back_to_main" }
            ]
        ]
    };
}

/**
 * Клавиатура для ручной настройки VPN
 */
function getManualSetupKeyboard() {
    return {
        inline_keyboard: [
            [
                { text: "🔙 Назад", callback_data: "vpn_setup" }
            ]
        ]
    };
}

/**
 * Клавиатура для сообщения о недоступности помощника
 */
function getAssistantUnavailableKeyboard() {
    return {
        inline_keyboard: [
            [
                { text: "💳 Вступить в канал", url: "https://t.me/tribute/app?startapp=sy4h" }
            ],
            [
                { text: "🔙 Назад", callback_data: "vpn_setup" }
            ]
        ]
    };
}

module.exports = {
    getMainKeyboard,
    getBackKeyboard,
    getPaymentKeyboard,
    getSetupKeyboard,
    getVpnSetupDialogKeyboard,
    getManualSetupKeyboard,
    getAssistantUnavailableKeyboard
}; 