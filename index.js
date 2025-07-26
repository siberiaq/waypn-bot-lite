require('dotenv').config();
const TelegramBot = require('node-telegram-bot-api');
const {
    MESSAGES,
    COMMANDS,
    CALLBACK_DATA,
    IMAGES,
    TRIBUTE_PAYMENT_URL,
    SUPPORT_LINK
} = require('./config/constants');

const {
    getMainKeyboard,
    getBackKeyboard,
    getPaymentKeyboard,
    getSetupKeyboard,
    getVpnSetupDialogKeyboard,
    getDeviceSelectionKeyboard,
    getAppInstallKeyboard,
    getFinalSetupKeyboard,
    getManualSetupKeyboard,
    getAssistantUnavailableKeyboard
} = require('./utils/keyboards');

const { getUserConfig } = require('./utils/user-configs');
const XuiAPI = require('./utils/xui-api');

// Инициализация API для работы с 3xui
const xuiApi = new XuiAPI({
    baseUrl: process.env.XUI_BASE_URL,
    email: process.env.XUI_EMAIL,
    password: process.env.XUI_PASSWORD
});

// Проверяем наличие обязательных переменных окружения
if (!process.env.XUI_BASE_URL || !process.env.XUI_EMAIL || !process.env.XUI_PASSWORD) {
    console.error('❌ Ошибка: Не заданы обязательные переменные окружения для 3xui API');
    console.error('   XUI_BASE_URL, XUI_EMAIL, XUI_PASSWORD должны быть указаны в файле .env');
    process.exit(1);
}

// Логируем конфигурацию 3xui
console.log('🔧 3XUI Configuration:');
console.log(`   Base URL: ${process.env.XUI_BASE_URL}`);
console.log(`   Email: ${process.env.XUI_EMAIL}`);
console.log(`   Password: ***`);

// Инициализация бота с токеном из переменных окружения
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: true });

// Обработка команды /start
bot.onText(/\/start/, async (msg) => {
    const chatId = msg.chat.id;
    console.log(`🚀 Обработка команды /start для пользователя ${chatId}`);
    try {
        await showMainMenu(chatId);
    } catch (error) {
        console.error('❌ Ошибка при обработке команды /start:', error);
        await bot.sendMessage(chatId, 'Произошла ошибка. Попробуйте еще раз.');
    }
});

// Функция отображения главного меню
async function showMainMenu(chatId, messageId = null) {
    try {
        console.log(`🏠 Отправка главного меню для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);

        // Создаем клавиатуру напрямую здесь
        const keyboard = {
            reply_markup: {
                inline_keyboard: [
                    [
                        {
                            text: '👑 Оплатить доступ',
                            url: 'https://t.me/tribute/app?startapp=sy4h'
                        }
                    ],
                    [   
                        {
                            text: '⚙️ Настроить VPN',
                            callback_data: 'setup_manual'
                        }
                    ],
                    [
                        {
                            text: '💁🏼‍♀️ Поддержка',
                            callback_data: 'support'
                        }
                    ],
                    [
                        {
                            text: '👤 Профиль',
                            callback_data: 'profile'
                        }
                    ]
                ]
            }
        };

        console.log(`🏠 Клавиатура:`, JSON.stringify(keyboard, null, 2));

        if (messageId) {
            // Перерисовываем существующее сообщение
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: MESSAGES.WELCOME,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: keyboard.reply_markup
            });
            console.log(`✅ Главное меню перерисовано для пользователя ${chatId}, message_id: ${messageId}`);
        } else {
            // Отправляем новое сообщение
            const result = await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: MESSAGES.WELCOME,
                parse_mode: 'Markdown',
                reply_markup: keyboard.reply_markup
            });
            console.log(`✅ Главное меню отправлено пользователю ${chatId}, message_id: ${result.message_id}`);
        }

    } catch (error) {
        console.error('❌ Ошибка при отправке главного меню:', error);
        throw error;
    }
}

// Обработка текстовых сообщений (кроме команды /start)
bot.on('message', async (msg) => {
    console.log(`📨 Получено сообщение от ${msg.from.id}: ${msg.text}`);
    const chatId = msg.chat.id;
    const text = msg.text;

    // Пропускаем команду /start, так как она обрабатывается отдельно
    if (text === COMMANDS.START) {
        return;
    }

    // Обрабатываем другие текстовые сообщения если нужно
    console.log(`📝 Получено текстовое сообщение: ${text}`);
});

// Функция отображения информации об оплате
async function showPaymentInfo(chatId, messageId = null) {
    try {
        console.log(`💳 Отправка информации об оплате для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);
        console.log(`💳 TRIBUTE_PAYMENT_URL:`, TRIBUTE_PAYMENT_URL);
        console.log(`💳 MESSAGES.PAYMENT:`, MESSAGES.PAYMENT);

        const keyboard = getPaymentKeyboard(TRIBUTE_PAYMENT_URL);
        console.log(`💳 Клавиатура оплаты:`, JSON.stringify(keyboard, null, 2));

        // Отправляем изображение с сообщением
        if (IMAGES.PAYMENT) {
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.PAYMENT,
                    caption: MESSAGES.PAYMENT,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: keyboard
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.PAYMENT, {
                    caption: MESSAGES.PAYMENT,
                    parse_mode: 'Markdown',
                    reply_markup: keyboard
                });
            }
        } else {
            if (messageId) {
                await bot.editMessageText(MESSAGES.PAYMENT, {
                    chat_id: chatId,
                    message_id: messageId,
                    parse_mode: 'Markdown',
                    reply_markup: keyboard
                });
            } else {
                await bot.sendMessage(chatId, MESSAGES.PAYMENT, {
                    parse_mode: 'Markdown',
                    reply_markup: keyboard
                });
            }
        }

        console.log(`✅ Информация об оплате отправлена пользователю ${chatId}`);
    } catch (error) {
        console.error('❌ Ошибка при отправке информации об оплате:', error);
        throw error;
    }
}

// Функция отображения диалога настройки VPN
async function showVpnSetup(chatId, messageId = null) {
    try {
        console.log(`⚙️ Отображение диалога настройки VPN для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);

        const setupText = MESSAGES.VPN_SETUP;

        if (messageId) {
            // Для редактирования существующего сообщения всегда используем editMessageMedia
            // так как большинство сообщений в нашем боте содержат изображения
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: setupText,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: getVpnSetupDialogKeyboard()
            });
        } else {
            // Отправляем новое сообщение с изображением
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: setupText,
                parse_mode: 'Markdown',
                reply_markup: getVpnSetupDialogKeyboard()
            });
        }

        console.log(`✅ Диалог настройки VPN отправлен пользователю ${chatId}`);
    } catch (error) {
        console.error('❌ Ошибка при отправке диалога настройки VPN:', error);
        throw error;
    }
}

// Функция отображения информации о поддержке
async function showSupport(chatId, messageId = null) {
    try {
        const supportText = MESSAGES.SUPPORT + SUPPORT_LINK;

        // Отправляем изображение с сообщением
        if (IMAGES.SUPPORT) {
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.SUPPORT,
                    caption: supportText,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.SUPPORT, {
                    caption: supportText,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
        } else {
            if (messageId) {
                await bot.editMessageText(supportText, {
                    chat_id: chatId,
                    message_id: messageId,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendMessage(chatId, supportText, {
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
        }
    } catch (error) {
        console.error('Ошибка при отправке информации о поддержке:', error);
        throw error;
    }
}

// Функция отображения профиля пользователя
async function showProfile(chatId, messageId = null) {
    try {
        console.log(`👤 Отображение профиля для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);

        // Получаем информацию о профиле через API 3xui
        const profile = await xuiApi.getUserProfile(chatId);

        if (!profile) {
            // Пользователь не найден - показываем сообщение о необходимости оплаты
            console.log(`❌ Профиль не найден для пользователя ${chatId}`);

            const keyboard = {
                reply_markup: {
                    inline_keyboard: [
                        [
                            {
                                text: '💳 Оплатить доступ',
                                url: 'https://t.me/tribute/app?startapp=sy4h'
                            }
                        ],
                        [
                            {
                                text: '🔙 Назад',
                                callback_data: 'back_to_main'
                            }
                        ]
                    ]
                }
            };

            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: keyboard.reply_markup
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                    parse_mode: 'Markdown',
                    reply_markup: keyboard
                });
            }

            return;
        }

        if (!profile.active) {
            // Подписка неактивна - показываем сообщение о необходимости оплаты
            console.log(`❌ Подписка неактивна для пользователя ${chatId}`);

            const keyboard = {
                reply_markup: {
                    inline_keyboard: [
                        [
                            {
                                text: '💳 Оплатить доступ',
                                url: 'https://t.me/tribute/app?startapp=sy4h'
                            }
                        ],
                        [
                            {
                                text: '🔙 Назад',
                                callback_data: 'back_to_main'
                            }
                        ]
                    ]
                }
            };

            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: keyboard.reply_markup
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                    parse_mode: 'Markdown',
                    reply_markup: keyboard
                });
            }

            return;
        }

        // Подписка активна - показываем информацию о профиле
        console.log(`✅ Отображение активного профиля для пользователя ${chatId}`);

        const startDate = profile.startDate.toLocaleDateString('ru-RU');
        const endDate = profile.endDate.toLocaleDateString('ru-RU');
        const usedTraffic = profile.usedTraffic;
        const trafficLimit = profile.trafficLimit;
        const limitIp = profile.limitIp;

        const profileText = `👤 **Ваш профиль**\n\n` +
            `📅 **Дата окончания подписки:** ${endDate}\n` +
            `📊 **Лимит трафика:** ${trafficLimit}\n` +
            `🔗 **Лимит устройств:** ${limitIp}\n\n` +
            `✅ **Статус:** Активная подписка`;

        const keyboard = {
            reply_markup: {
                inline_keyboard: [
                    [
                        {
                            text: '🔙 Назад',
                            callback_data: 'back_to_main'
                        }
                    ]
                ]
            }
        };

        if (messageId) {
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: profileText,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: keyboard.reply_markup
            });
        } else {
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: profileText,
                parse_mode: 'Markdown',
                reply_markup: keyboard
            });
        }

        console.log(`✅ Профиль отправлен пользователю ${chatId}`);

    } catch (error) {
        console.error('❌ Ошибка при отображении профиля:', error);

        // В случае ошибки показываем сообщение о необходимости оплаты
        const keyboard = {
            reply_markup: {
                inline_keyboard: [
                    [
                        {
                            text: '💳 Оплатить доступ',
                            url: 'https://t.me/tribute/app?startapp=sy4h'
                        }
                    ],
                    [
                        {
                            text: '🔙 Назад',
                            callback_data: 'back_to_main'
                        }
                    ]
                ]
            }
        };

        if (messageId) {
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: keyboard.reply_markup
            });
        } else {
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: MESSAGES.PROFILE_NO_SUBSCRIPTION,
                parse_mode: 'Markdown',
                reply_markup: keyboard
            });
        }
    }
}

// Обработка callback запросов
bot.on('callback_query', async (callbackQuery) => {
    const { data, message } = callbackQuery;
    const chatId = message.chat.id;

    console.log(`📱 Получен callback: ${data} от пользователя ${chatId}`);
    console.log(`📱 Полный объект callback:`, JSON.stringify(callbackQuery, null, 2));

    // Отвечаем на callback_query чтобы убрать "часики"
    await bot.answerCallbackQuery(callbackQuery.id);

    try {
        switch (data) {
            case CALLBACK_DATA.VPN_SETUP:
                console.log(`🔧 Обработка настройки VPN для пользователя ${chatId}`);
                await showVpnSetup(chatId, message.message_id);
                break;
            case CALLBACK_DATA.SUPPORT:
                console.log(`🆘 Обработка поддержки для пользователя ${chatId}`);
                await showSupport(chatId, message.message_id);
                break;
            case CALLBACK_DATA.PROFILE:
                console.log(`👤 Обработка профиля для пользователя ${chatId}`);
                await showProfile(chatId, message.message_id);
                break;
            case CALLBACK_DATA.BACK_TO_MAIN:
                console.log(`🔙 Возврат в главное меню для пользователя ${chatId}`);
                await showMainMenu(chatId, message.message_id);
                break;
            case 'setup_assistant':
                console.log(`🤖 Обработка помощника настройки для пользователя ${chatId}`);
                await showAssistantUnavailable(chatId, message.message_id);
                break;
            case 'setup_manual':
                console.log(`⚙️ Обработка ручной настройки для пользователя ${chatId}`);
                await showManualSetup(chatId, message.message_id);
                break;
            case 'copy_config_ios':
            case 'copy_config_android':
            case 'copy_config_windows':
            case 'copy_config_mac':
                const copyDeviceType = data.replace('copy_config_', '');
                console.log(`📋 Копирование конфигурации для ${copyDeviceType} пользователя ${chatId}`);
                await showCopyConfig(chatId, copyDeviceType, message.message_id);
                break;
            case 'support':
                console.log(`🆘 Обработка поддержки для пользователя ${chatId}`);
                await showSupport(chatId, message.message_id);
                break;
            case 'profile':
                console.log(`👤 Обработка профиля для пользователя ${chatId}`);
                await showProfile(chatId);
                break;
            default:
                console.log('❓ Неизвестный callback:', data);
        }
    } catch (error) {
        console.error(`❌ Ошибка при обработке callback ${data} для пользователя ${chatId}:`, error);
        await bot.sendMessage(chatId, 'Произошла ошибка. Попробуйте еще раз.');
    }
});

// Обработка ошибок
bot.on('error', (error) => {
    console.error('❌ Ошибка бота:', error);
});

bot.on('polling_error', (error) => {
    console.error('❌ Ошибка polling:', error);
});

// Добавляем обработчик для всех событий
bot.on('any', (event) => {
    console.log(`🔍 Событие бота: ${event.type}`);
});

// Добавляем обработчик для получения обновлений
bot.on('message', (msg) => {
    console.log(`📨 Получено сообщение от ${msg.from.id}: ${msg.text}`);
});

// Обработка необработанных исключений
process.on('uncaughtException', (error) => {
    console.error('Необработанное исключение:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Необработанное отклонение промиса:', reason);
});

// Запуск бота
console.log('🤖 VPN бот запущен...');
console.log('Для остановки нажмите Ctrl+C');

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Остановка бота...');
    bot.stopPolling();
    process.exit(0);
});

// Функция отображения сообщения о недоступности помощника
async function showAssistantUnavailable(chatId, messageId = null) {
    try {
        console.log(`🤖 Отображение сообщения о недоступности помощника для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);

        if (messageId) {
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: MESSAGES.ASSISTANT_UNAVAILABLE,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: getAssistantUnavailableKeyboard()
            });
        } else {
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: MESSAGES.ASSISTANT_UNAVAILABLE,
                parse_mode: 'Markdown',
                reply_markup: getAssistantUnavailableKeyboard()
            });
        }

        console.log(`✅ Сообщение о недоступности помощника отправлено пользователю ${chatId}`);
    } catch (error) {
        console.error('❌ Ошибка при отображении сообщения о недоступности помощника:', error);
        throw error;
    }
}

// Функция отображения конфигурации для копирования
async function showCopyConfig(chatId, deviceType, messageId = null) {
    try {
        console.log(`📋 Отображение конфигурации для копирования ${deviceType} пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);
        
        // Получаем VLESS конфигурацию через 3x-ui API
        console.log(`👤 Получение профиля пользователя ${chatId}...`);
        const userInfo = await xuiApi.findUserByTelegramId(chatId);
        
        if (!userInfo) {
            console.log(`❌ Пользователь ${chatId} не найден в 3x-ui`);
            const errorMessage = "❌ **Ошибка получения конфигурации**\n\nПользователь не найден в системе. Возможно, подписка не была активирована или произошла ошибка при создании аккаунта.\n\nОбратитесь в поддержку для решения проблемы.";
            
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: errorMessage,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: errorMessage,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
            return;
        }
        
        // Генерируем VLESS конфигурацию
        const vlessConfig = xuiApi.generateVlessConfig(userInfo.user);
        
        if (!vlessConfig) {
            console.error(`❌ Не удалось сгенерировать VLESS конфигурацию для пользователя ${chatId}`);
            const errorMessage = "❌ **Ошибка генерации конфигурации**\n\nНе удалось создать конфигурацию VPN. Обратитесь в поддержку для решения проблемы.";
            
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: errorMessage,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: errorMessage,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
            return;
        }
        
        console.log(`✅ VLESS конфигурация получена для копирования`);
        
        let message = `📋 **Конфигурация для ${deviceType}**\n\n`;
        
        // Добавляем deep-link информацию для поддерживаемых устройств
        if (deviceType === 'iOS') {
            const base64Config = Buffer.from(vlessConfig).toString('base64');
            const deepLinkUrl = `shadowrocket://add/sub://${base64Config}`;
            message += `🔗 **Deep-link для автоматической настройки:**\n\`${deepLinkUrl}\`\n\n💡 **Как использовать deep-link:**\n1. Скопируйте ссылку выше\n2. Вставьте в браузер или отправьте себе в сообщения\n3. Нажмите на ссылку для автоматической настройки\n\n`;
        } else if (deviceType === 'Android') {
            const base64Config = Buffer.from(vlessConfig).toString('base64');
            const deepLinkUrl = `v2rayng://install-config/${base64Config}`;
            message += `🔗 **Deep-link для автоматической настройки:**\n\`${deepLinkUrl}\`\n\n💡 **Как использовать deep-link:**\n1. Скопируйте ссылку выше\n2. Вставьте в браузер или отправьте себе в сообщения\n3. Нажмите на ссылку для автоматической настройки\n\n`;
        }
        
        message += `📋 **Конфигурация VLESS:**\n\`\`\`\n${vlessConfig}\n\`\`\`\n\n`;
        message += `📝 **Краткая инструкция:**\n1. Открой приложение для ${deviceType}\n2. Добавьте новую конфигурацию\n3. Вставьте конфигурацию выше\n4. Сохраните и подключитесь`;
        
        // Создаем клавиатуру с кнопкой "Назад"
        const keyboard = {
            inline_keyboard: [
                [
                    { text: "🔙 Назад", callback_data: "setup_manual" }
                ]
            ]
        };
        
        if (messageId) {
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: message,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: keyboard
            });
        } else {
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: message,
                parse_mode: 'Markdown',
                reply_markup: keyboard
            });
        }
        
        console.log(`✅ Конфигурация для копирования отправлена для ${deviceType}`);
    } catch (error) {
        console.error('❌ Ошибка при отображении конфигурации для копирования:', error);
        throw error;
    }
}

// Функция отображения ручной настройки
async function showManualSetup(chatId, messageId = null) {
    try {
        console.log(`⚙️ Отображение ручной настройки для пользователя ${chatId}${messageId ? `, редактирование сообщения ${messageId}` : ''}`);
        
        // Получаем VLESS конфигурацию через 3x-ui API
        console.log(`👤 Получение профиля пользователя ${chatId}...`);
        const userInfo = await xuiApi.findUserByTelegramId(chatId);
        
        if (!userInfo) {
            console.log(`❌ Пользователь ${chatId} не найден в 3x-ui`);
            const errorMessage = "❌ **Ошибка получения конфигурации**\n\nПользователь не найден в системе. Возможно, подписка не была активирована или произошла ошибка при создании аккаунта.\n\nОбратитесь в поддержку для решения проблемы.";
            
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: errorMessage,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: errorMessage,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
            return;
        }
        
        // Генерируем VLESS конфигурацию
        const vlessConfig = xuiApi.generateVlessConfig(userInfo.user);
        
        if (!vlessConfig) {
            console.error(`❌ Не удалось сгенерировать VLESS конфигурацию для пользователя ${chatId}`);
            const errorMessage = "❌ **Ошибка генерации конфигурации**\n\nНе удалось создать конфигурацию VPN. Обратитесь в поддержку для решения проблемы.";
            
            if (messageId) {
                await bot.editMessageMedia({
                    type: 'photo',
                    media: IMAGES.WELCOME,
                    caption: errorMessage,
                    parse_mode: 'Markdown'
                }, {
                    chat_id: chatId,
                    message_id: messageId,
                    reply_markup: getBackKeyboard()
                });
            } else {
                await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                    caption: errorMessage,
                    parse_mode: 'Markdown',
                    reply_markup: getBackKeyboard()
                });
            }
            return;
        }
        
        console.log(`✅ VLESS конфигурация сгенерирована для пользователя ${chatId}`);
        console.log(`   Конфигурация: ${vlessConfig.substring(0, 50)}...`);
        
        // Формируем сообщение с конфигурацией
        const message = `*Настройка VPN вручную*\n\n1. Установи приложение для своего устройства по ссылке:**\n📱 **iOS:** [V2box](https://apps.apple.com/ru/app/v2box-v2ray-client/id6446814690)\n🤖 **Android:** [V2rayNG](https://play.google.com/store/apps/details?id=com.v2ray.ang&hl=ru)\n🪟 **Windows:** [Hiddify](https://hiddify.com/)\n🍎 **Mac:** [V2box](https://apps.apple.com/ru/app/v2box-v2ray-client/id6446814690)\n🐧 **Linux:** [V2rayA](https://github.com/v2rayA/v2rayA/releases)\n2. Скопируй свой уникальный код (нажми на код и выбери \"Копировать\")\n*Твой персональный код:*\n\`\`\`\n${vlessConfig}\`\`\`\n\n3. Открой приложение и выбери импорт конфигурации из буфера обмена или клавиатуры (в некоторых приложениях обозначено значком плюса)\n4. Вставь в приложение свой код и подключись к VPN\n\n Если возникли сложности или вопросы - обратись в нашу поддержку`;
        
        // Создаем клавиатуру
        const keyboard = getManualSetupKeyboard();
        console.log(`🔧 Клавиатура для ручной настройки:`, JSON.stringify(keyboard, null, 2));
        
        if (messageId) {
            await bot.editMessageMedia({
                type: 'photo',
                media: IMAGES.WELCOME,
                caption: message,
                parse_mode: 'Markdown'
            }, {
                chat_id: chatId,
                message_id: messageId,
                reply_markup: keyboard
            });
        } else {
            await bot.sendPhoto(chatId, IMAGES.WELCOME, {
                caption: message,
                parse_mode: 'Markdown',
                reply_markup: keyboard
            });
        }
        
        console.log(`✅ Ручная настройка отправлена пользователю ${chatId}`);
    } catch (error) {
        console.error('❌ Ошибка при отображении ручной настройки:', error);
        throw error;
    }
} 