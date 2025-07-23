/**
 * Константы и настройки бота
 */

// URL для оплаты через Tribute
const TRIBUTE_PAYMENT_URL = process.env.TRIBUTE_PAYMENT_URL || 'https://t.me/tribute/app?startapp=sy4h';

// Ссылка на поддержку
const SUPPORT_LINK = process.env.SUPPORT_LINK || '@your_support_username';

// Изображения (включены с новой ссылкой)
const IMAGES = {
    PAYMENT: 'http://vuzappf7.bget.ru/waypn/bot/resources/logo.jpg',
    SUPPORT: 'http://vuzappf7.bget.ru/waypn/bot/resources/logo.jpg',
    WELCOME: 'http://vuzappf7.bget.ru/waypn/bot/resources/logo.jpg'
};

// Статические настройки Reality для VLESS конфигураций
const REALITY_CONFIG = {
    publicKey: 'KKPXarv8v8jFdfZGxqa3pFg6N0YLrLStCGkhGhoQfzg',
    serverName: 'nu.nl',
    shortId: '5a8d7361945cf53c',
    server: 'waypn.com:443',
    flow: 'xtls-rprx-vision'
};

// Тексты сообщений
const MESSAGES = {
    WELCOME: '*Быстрый VPN для Instagram и YouTube 🚀*\n\n⚡ Для получения доступа к VPN мы направим тебя на оплату подписки на наш закрытый новостной канал. После оплаты бот пришлет твой персональный код и инструкцию для настройки на твоем устройстве.\n\n🛡️ Платежи осуществляются через официальный сервис Tribute и полностью безопасны\n\n👇 Доступны варианты подписки на 1, 3 и 6 месяцев. Для выбора тарифа и оплаты нажми кнопку "Оплатить доступ"',
    PAYMENT: '**Быстрый VPN для Instagram и YouTube 🚀**\n\n⚡ Для получения доступа к VPN мы направим тебя на оплату подписки на наш закрытый новостной канал. После оплаты бот пришлет твой персональный код и инструкцию для настройки VPN на твоем устройстве.\n\n 🛡️ Платежи осуществляются через официальный сервис Tribute и полностью безопасны.',
    VPN_SETUP: '⚙️ **Настройка VPN**\n\nИспользуй нашего цифрового помощника для настройки VPN на своем устройстве или сделай настройку вручную (для опытных пользователей)',
    SUPPORT: '**Заботливая поддержка на связи с 10 до 20 МСК**\n\nВаши вопросы по настройке VPN можно задать в сообщениях аккаунта поддержки: ',
    PROFILE_NO_SUBSCRIPTION: 'Для просмотра профиля у вас должен быть оплачен доступ\n\n⚡ Для получения доступа к VPN мы направим тебя на оплату подписки на наш закрытый новостной канал. После оплаты бот пришлет твой персональный код и инструкцию для настройки на твоем устройстве.',
    ASSISTANT_UNAVAILABLE: '🤖 **Помощник настройки временно недоступен**\n\nМы работаем над улучшением нашего цифрового помощника для более удобной настройки VPN.\n\n📢 **Анонс запуска** можно будет увидеть в нашем закрытом Telegram канале.\n\n💳 **Для вступления в канал** нажми кнопку ниже и оплати подписку.'
};

// Команды бота
const COMMANDS = {
    START: '/start',
    PAY_VPN: '💳 Оплатить VPN',
    SETUP_VPN: '⚙️ Настроить VPN',
    SUPPORT: '🆘 Поддержка'
};

// Callback данные
const CALLBACK_DATA = {
    BACK_TO_MAIN: 'back_to_main',
    PAYMENT: 'payment',
    VPN_SETUP: 'vpn_setup',
    SUPPORT: 'support',
    PROFILE: 'profile'
};

// Новые константы для улучшенного процесса настройки
const SETUP_MESSAGES = {
    SUCCESS: "🎉 *Оплата прошла успешно!*\n\nТеперь ты можешь перейти к настройке VPN на своем устройстве.",
    CHOOSE_DEVICE: "На каком устройстве ты хочешь настроить доступ?",
    ALMOST_DONE: "Осталось еще чуть чуть\n\nТеперь используй кнопку \"Настроить автоматически\" для автоматической настройки или сделай настройку вручную\n\nЕсли у тебя возникли трудности при настройке обратись в поддержку"
};

const CLIENT_APPS = {
    iOS: {
        name: "Shadowrocket",
        store_url: "https://apps.apple.com/app/shadowrocket/id932747118",
        setup_message: "📱 **Установка Shadowrocket для iOS**\n\n1️⃣ Установи приложение Shadowrocket из App Store\n2️⃣ После установки используй deep-link ниже для автоматической настройки\n\n💡 **Примечание:** Shadowrocket поддерживает автоматическую настройку через deep-link.",
        instructions: "📱 **Ручная настройка Shadowrocket:**\n\n1. Открой приложение Shadowrocket\n2. Нажми на значок \"+\" в правом верхнем углу\n3. Выберите \"Добавить конфигурацию\"\n4. Вставьте скопированную конфигурацию VLESS\n5. Нажми \"Сохранить\"\n6. Включите VPN переключателем в главном экране",
        supports_deeplink: true,
        deeplink_format: "shadowrocket://add/sub://{base64_config}"
    },
    Android: {
        name: "V2rayNG",
        store_url: "https://play.google.com/store/apps/details?id=com.v2ray.ang",
        setup_message: "🤖 **Установка V2rayNG для Android**\n\n1️⃣ Установи приложение V2rayNG из Google Play\n2️⃣ После установки используй deep-link ниже для автоматической настройки\n\n💡 **Примечание:** V2rayNG поддерживает автоматическую настройку через deep-link.",
        instructions: "🤖 **Ручная настройка V2rayNG:**\n\n1. Открой приложение V2rayNG\n2. Нажми на значок \"+\" в правом верхнем углу\n3. Выберите \"Импорт конфигурации\"\n4. Вставьте скопированную конфигурацию VLESS\n5. Нажми \"Сохранить\"\n6. Нажми на кнопку подключения в главном экране",
        supports_deeplink: true,
        deeplink_format: "v2rayng://install-config/{base64_config}"
    },
    Windows: {
        name: "V2rayN",
        download_url: "https://github.com/2dust/v2rayN/releases",
        setup_message: "🪟 **Установка V2rayN для Windows**\n\n1️⃣ Скачай V2rayN с GitHub по ссылке ниже\n2️⃣ Распакуй архив и запусти v2rayN.exe\n3️⃣ После установки нажми \"Далее\" для получения инструкции по настройке\n\n💡 **Примечание:** V2rayN - это портативное приложение, не требует установки.",
        instructions: "🪟 **Настройка V2rayN:**\n\n1. Запусти v2rayN.exe от имени администратора\n2. Нажми Ctrl+V для вставки конфигурации\n3. Или нажми правой кнопкой мыши на значок в трее → \"Добавить сервер\"\n4. Вставьте VLESS конфигурацию\n5. Нажми \"ОК\"\n6. Выберите сервер и нажми правой кнопкой → \"Подключиться\"",
        supports_deeplink: false
    },
    Mac: {
        name: "V2rayX",
        download_url: "https://github.com/Cenmrev/V2RayX/releases",
        setup_message: "🍎 **Установка V2rayX для macOS**\n\n1️⃣ Скачай V2rayX с GitHub по ссылке ниже\n2️⃣ Распакуй архив и перетащи V2rayX в папку Applications\n3️⃣ После установки нажми \"Далее\" для получения инструкции по настройке\n\n💡 **Примечание:** При первом запуске может потребоваться разрешить запуск в настройках безопасности.",
        instructions: "🍎 **Настройка V2rayX:**\n\n1. Запусти V2rayX из папки Applications\n2. Нажми на значок V2rayX в строке меню\n3. Выберите \"Configure...\"\n4. Нажми \"Import\" и вставьте VLESS конфигурацию\n5. Нажми \"OK\"\n6. Включите VPN через меню V2rayX",
        supports_deeplink: false
    },
    Linux: {
        name: "V2rayA",
        download_url: "https://github.com/v2rayA/v2rayA/releases",
        setup_message: "🐧 **Установка V2rayA для Linux**\n\n1️⃣ Скачай V2rayA с GitHub по ссылке ниже\n2️⃣ Установи пакет согласно инструкции в репозитории\n3️⃣ После установки нажми \"Далее\" для получения инструкции по настройке\n\n💡 **Примечание:** Для установки может потребоваться sudo права.",
        instructions: "🐧 **Настройка V2rayA:**\n\n1. Запусти V2rayA в браузере (обычно http://localhost:2017)\n2. Нажми \"Import\" в разделе серверов\n3. Вставьте VLESS конфигурацию\n4. Нажми \"Save\"\n5. Выберите сервер и нажми \"Connect\"\n6. Настройте автозапуск при необходимости",
        supports_deeplink: false
    }
};

const MANUAL_SETUP_MESSAGE = "*Настройка VPN вручную*\n\n**Конфигурация VLESS:**\n```\n{vless_config}\n```\n\n**Приложения для популярных ОС:**\n\n📱 **iOS:** [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118)\n🤖 **Android:** [V2rayNG](https://play.google.com/store/apps/details?id=com.v2ray.ang)\n🪟 **Windows:** [V2rayN](https://github.com/2dust/v2rayN/releases)\n🍎 **Mac:** [V2rayX](https://github.com/Cenmrev/V2RayX/releases)\n🐧 **Linux:** [V2rayA](https://github.com/v2rayA/v2rayA/releases)\n\n*Инструкция:*\n1. Установи клиент для своей ОС\n2. Скопируй конфигурацию выше (нажми на код и выбери \"Копировать\")\n3. Импортируй в приложение\n4. Подключись к VPN";

module.exports = {
    TRIBUTE_PAYMENT_URL,
    SUPPORT_LINK,
    IMAGES,
    REALITY_CONFIG,
    MESSAGES,
    COMMANDS,
    CALLBACK_DATA,
    SETUP_MESSAGES,
    CLIENT_APPS,
    MANUAL_SETUP_MESSAGE
}; 