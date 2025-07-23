/**
 * Модуль для работы с 3xui API
 */

const axios = require('axios');
const { REALITY_CONFIG } = require('../config/constants');

class XuiAPI {
    constructor(config) {
        this.baseUrl = config.baseUrl;
        this.email = config.email;
        this.password = config.password;
        this.session = null;
        this.cookies = [];
        
        this.axios = axios.create({
            baseURL: this.baseUrl,
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'VPN-Bot/1.0'
            },
            withCredentials: true
        });
        
        // Добавляем перехватчик для логирования всех запросов
        this.axios.interceptors.request.use((config) => {
            console.log(`🌐 CURL REQUEST TO 3XUI:`);
            console.log(`   URL: ${config.method?.toUpperCase()} ${config.baseURL}${config.url}`);
            console.log(`   Headers:`, JSON.stringify(config.headers, null, 2));
            if (config.data) {
                console.log(`   Body:`, JSON.stringify(config.data, null, 2));
            }
            console.log(`   Full curl command:`);
            let curlCmd = `curl -X ${config.method?.toUpperCase()} "${config.baseURL}${config.url}"`;
            
            // Добавляем заголовки
            Object.entries(config.headers).forEach(([key, value]) => {
                curlCmd += ` -H "${key}: ${value}"`;
            });
            
            // Добавляем тело запроса
            if (config.data) {
                curlCmd += ` -d '${JSON.stringify(config.data)}'`;
            }
            
            console.log(`   ${curlCmd}`);
            console.log(`🌐 END CURL REQUEST`);
            
            return config;
        });
        
        // Добавляем перехватчик для логирования всех ответов
        this.axios.interceptors.response.use(
            (response) => {
                console.log(`✅ 3XUI RESPONSE:`);
                console.log(`   Status: ${response.status}`);
                console.log(`   Headers:`, JSON.stringify(response.headers, null, 2));
                console.log(`   Data:`, JSON.stringify(response.data, null, 2));
                console.log(`✅ END 3XUI RESPONSE`);
                return response;
            },
            (error) => {
                console.log(`❌ 3XUI ERROR:`);
                console.log(`   Status: ${error.response?.status}`);
                console.log(`   Message: ${error.message}`);
                if (error.response) {
                    console.log(`   Response Headers:`, JSON.stringify(error.response.headers, null, 2));
                    console.log(`   Response Data:`, JSON.stringify(error.response.data, null, 2));
                }
                console.log(`❌ END 3XUI ERROR`);
                return Promise.reject(error);
            }
        );
    }

    /**
     * Извлечение куки из заголовков ответа
     */
    extractCookies(response) {
        const setCookieHeaders = response.headers['set-cookie'];
        if (setCookieHeaders) {
            this.cookies = setCookieHeaders.map(cookie => {
                return cookie.split(';')[0];
            });
        }
    }

    /**
     * Формирование строки куки для запросов
     */
    getCookieString() {
        return this.cookies.join('; ');
    }

    /**
     * Авторизация в 3xui
     */
    async login() {
        try {
            console.log('🔐 Авторизация в 3xui...');
            
            const response = await this.axios.post('/login', {
                username: this.email,
                password: this.password
            });

            // Извлекаем куки из ответа
            this.extractCookies(response);

            if (response.data.success) {
                this.session = response.data.obj;
                console.log('✅ Авторизация в 3xui успешна');
                console.log('🍪 Куки получены:', this.cookies.length);
                return true;
            } else {
                console.error('❌ Ошибка авторизации в 3xui:', response.data.msg);
                return false;
            }
        } catch (error) {
            console.error('❌ Ошибка подключения к 3xui:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return false;
        }
    }

    /**
     * Получение списка всех inbound'ов
     */
    async getInbounds() {
        try {
            if (!this.session) {
                const loggedIn = await this.login();
                if (!loggedIn) return null;
            }

            console.log('📡 Получение списка inbound\'ов...');
            
            const response = await this.axios.get('/panel/api/inbounds/list', {
                headers: {
                    'Cookie': this.getCookieString()
                }
            });

            if (response.data.success) {
                console.log('✅ Список inbound\'ов получен');
                return response.data.obj;
            } else {
                console.error('❌ Ошибка получения inbound\'ов:', response.data.msg);
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка получения inbound\'ов:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return null;
        }
    }

    /**
     * Получение информации о конкретном inbound
     */
    async getInbound(id) {
        try {
            if (!this.session) {
                const loggedIn = await this.login();
                if (!loggedIn) return null;
            }

            console.log(`📡 Получение информации о inbound ${id}...`);
            
            const response = await this.axios.get(`/panel/api/inbounds/get/${id}`, {
                headers: {
                    'Cookie': this.getCookieString()
                }
            });

            if (response.data.success) {
                console.log('✅ Информация о inbound получена');
                return response.data.obj;
            } else {
                console.error('❌ Ошибка получения inbound:', response.data.msg);
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка получения inbound:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return null;
        }
    }

    /**
     * Получение полной конфигурации inbound с параметрами для VLESS
     */
    async getInboundConfig(id) {
        try {
            if (!this.session) {
                const loggedIn = await this.login();
                if (!loggedIn) return null;
            }

            console.log(`📡 Получение конфигурации inbound ${id}...`);
            
            const response = await this.axios.get(`/panel/api/inbounds/get/${id}`, {
                headers: {
                    'Cookie': this.getCookieString()
                }
            });

            if (response.data.success) {
                console.log('✅ Конфигурация inbound получена');
                return response.data.obj;
            } else {
                console.error('❌ Ошибка получения конфигурации inbound:', response.data.msg);
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка получения конфигурации inbound:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return null;
        }
    }

    /**
     * Генерация VLESS конфигурации для пользователя
     */
    generateVlessConfig(user) {
        try {
            // Используем статические настройки Reality
            const vlessConfig = `vless://${user.id}@${REALITY_CONFIG.server}?type=tcp&security=reality&pbk=${REALITY_CONFIG.publicKey}&fp=random&sni=${REALITY_CONFIG.serverName}&sid=${REALITY_CONFIG.shortId}&spx=%2F&flow=${user.flow}#waypn.com-${user.email}`;
            
            console.log('✅ VLESS конфигурация сгенерирована');
            console.log(`   UUID: ${user.id}`);
            console.log(`   Public Key: ${REALITY_CONFIG.publicKey}`);
            console.log(`   Server Name: ${REALITY_CONFIG.serverName}`);
            console.log(`   Short ID: ${REALITY_CONFIG.shortId}`);
            console.log(`   Flow: ${user.flow}`);
            
            return vlessConfig;
        } catch (error) {
            console.error('❌ Ошибка генерации VLESS конфигурации:', error.message);
            return null;
        }
    }

    /**
     * Поиск пользователя по email
     */
    async findUserByEmail(email) {
        try {
            const inbounds = await this.getInbounds();
            if (!inbounds) return null;

            for (const inbound of inbounds) {
                const inboundDetails = await this.getInbound(inbound.id);
                if (!inboundDetails) continue;

                // Парсим JSON строку из settings
                let settings;
                try {
                    settings = JSON.parse(inboundDetails.settings);
                } catch (error) {
                    console.error(`❌ Ошибка парсинга settings для inbound ${inbound.id}:`, error.message);
                    continue;
                }

                // Ищем пользователя в clients
                if (settings && settings.clients) {
                    const user = settings.clients.find(client => 
                        client.email === email || client.email === `${email}@waypn.com`
                    );
                    
                    if (user) {
                        console.log(`✅ Пользователь ${email} найден в inbound ${inbound.id}`);
                        return {
                            inboundId: inbound.id,
                            inboundName: inbound.remark,
                            user: user,
                            inboundDetails: inboundDetails,
                            settings: settings
                        };
                    }
                }
            }

            console.log(`❌ Пользователь ${email} не найден`);
            return null;
        } catch (error) {
            console.error('❌ Ошибка поиска пользователя:', error.message);
            return null;
        }
    }

    /**
     * Создание нового пользователя в inbound
     */
    async createUser(inboundId, userData) {
        try {
            if (!this.session) {
                const loggedIn = await this.login();
                if (!loggedIn) return null;
            }

            console.log(`👤 Создание пользователя ${userData.email} в inbound ${inboundId}...`);

            // Сначала получаем текущие настройки inbound
            const inbound = await this.getInbound(inboundId);
            if (!inbound) {
                console.error('❌ Не удалось получить настройки inbound');
                return null;
            }

            // Парсим JSON строку из settings
            let settings;
            try {
                settings = JSON.parse(inbound.settings);
            } catch (error) {
                console.error('❌ Ошибка парсинга settings:', error.message);
                return null;
            }

            // Добавляем нового пользователя
            if (!settings.clients) {
                settings.clients = [];
            }

            settings.clients.push(userData);

            // Обновляем settings в inbound
            inbound.settings = JSON.stringify(settings, null, 2);

            // Обновляем inbound
            const response = await this.axios.post(`/panel/api/inbounds/update/${inboundId}`, inbound, {
                headers: {
                    'Cookie': this.getCookieString()
                }
            });

            if (response.data.success) {
                console.log('✅ Пользователь успешно создан');
                return response.data.obj;
            } else {
                console.error('❌ Ошибка создания пользователя:', response.data.msg);
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка создания пользователя:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return null;
        }
    }

    /**
     * Генерация UUID для пользователя
     */
    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c == 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    /**
     * Создание или обновление VPN пользователя на основе данных из Tribute
     */
    async createVpnUser(telegramUserId, expiresAt, subscriptionData) {
        try {
            console.log(`🚀 Обработка VPN пользователя для ${telegramUserId}...`);

            // Сначала проверяем, существует ли пользователь
            const existingUser = await this.findUserByTelegramId(telegramUserId);
            
            if (existingUser) {
                console.log(`🔄 Пользователь ${telegramUserId} уже существует. Обновляем подписку...`);
                
                // Обновляем подписку существующего пользователя
                const updateResult = await this.updateUserSubscription(existingUser, expiresAt, subscriptionData);
                
                if (updateResult) {
                    console.log(`✅ Подписка пользователя ${telegramUserId} обновлена`);
                    
                    // Генерируем VLESS конфигурацию для обновленного пользователя
                    const vlessConfig = this.generateVlessConfig(updateResult.user);
                    
                    return {
                        success: true,
                        action: 'updated',
                        user: updateResult.user,
                        inbound: updateResult.inbound,
                        subscription: updateResult.subscription,
                        vlessConfig: vlessConfig,
                        oldExpiryTime: updateResult.oldExpiryTime,
                        newExpiryTime: updateResult.newExpiryTime
                    };
                } else {
                    console.error('❌ Не удалось обновить подписку пользователя');
                    return null;
                }
            }

            // Если пользователь не существует, создаем нового
            console.log(`👤 Пользователь ${telegramUserId} не найден. Создаем нового...`);

            // Получаем список inbound'ов
            const inbounds = await this.getInbounds();
            if (!inbounds || inbounds.length === 0) {
                console.error('❌ Нет доступных inbound\'ов');
                return null;
            }

            // Используем inbound с ID 4 (waypn.com Friends&Family)
            const inbound = inbounds.find(inbound => inbound.id === 4);
            
            if (!inbound) {
                console.error('❌ Не найден inbound с ID 4');
                console.log('📋 Доступные inbound\'ы:');
                inbounds.forEach(inbound => {
                    console.log(`   - ${inbound.remark} (ID: ${inbound.id})`);
                });
                return null;
            }

            console.log(`📡 Используем inbound: ${inbound.remark} (ID: ${inbound.id})`);

            // Получаем полную конфигурацию inbound
            const inboundConfig = await this.getInboundConfig(inbound.id);
            if (!inboundConfig) {
                console.error('❌ Не удалось получить конфигурацию inbound');
                return null;
            }

            // Создаем данные пользователя
            const userData = {
                id: this.generateUUID(),
                email: `${telegramUserId}_a`, // Без постфикса @waypn.com
                flow: "xtls-rprx-vision",
                limitIp: 3, // Лимит устройств
                totalGB: 0, // 0 = безлимит
                expiryTime: new Date(expiresAt).getTime(),
                enable: true,
                tgId: "",
                subId: `sub_${subscriptionData.subscription_id}`,
                reset: 0
            };

            // Создаем пользователя
            const result = await this.createUser(inbound.id, userData);
            
            if (result) {
                console.log(`✅ VPN пользователь создан: ${userData.email}`);
                
                // Генерируем VLESS конфигурацию
                const vlessConfig = this.generateVlessConfig(userData);
                
                return {
                    success: true,
                    action: 'created',
                    user: userData,
                    inbound: inbound,
                    subscription: subscriptionData,
                    vlessConfig: vlessConfig
                };
            } else {
                console.error('❌ Не удалось создать VPN пользователя');
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка обработки VPN пользователя:', error.message);
            return null;
        }
    }

    /**
     * Поиск пользователя по Telegram ID
     */
    async findUserByTelegramId(telegramUserId) {
        try {
            const inbounds = await this.getInbounds();
            if (!inbounds) return null;

            const email = `${telegramUserId}_a`;

            for (const inbound of inbounds) {
                const inboundDetails = await this.getInbound(inbound.id);
                if (!inboundDetails) continue;

                // Парсим JSON строку из settings
                let settings;
                try {
                    settings = JSON.parse(inboundDetails.settings);
                } catch (error) {
                    console.error(`❌ Ошибка парсинга settings для inbound ${inbound.id}:`, error.message);
                    continue;
                }

                // Ищем пользователя в clients
                if (settings && settings.clients) {
                    const user = settings.clients.find(client => 
                        client.email === email || client.email === `${email}@waypn.com`
                    );
                    
                    if (user) {
                        console.log(`✅ Пользователь с Telegram ID ${telegramUserId} найден в inbound ${inbound.id}`);
                        return {
                            inboundId: inbound.id,
                            inboundName: inbound.remark,
                            user: user,
                            inboundDetails: inboundDetails,
                            settings: settings
                        };
                    }
                }
            }

            console.log(`❌ Пользователь с Telegram ID ${telegramUserId} не найден`);
            return null;
        } catch (error) {
            console.error('❌ Ошибка поиска пользователя по Telegram ID:', error.message);
            return null;
        }
    }

    /**
     * Получение информации о профиле пользователя по Telegram ID
     */
    async getUserProfile(telegramUserId) {
        try {
            console.log(`👤 Получение профиля пользователя ${telegramUserId}...`);
            
            // Используем существующую функцию поиска пользователя
            const userInfo = await this.findUserByTelegramId(telegramUserId);
            
            if (!userInfo) {
                console.log(`❌ Пользователь ${telegramUserId} не найден`);
                return null;
            }
            
            const user = userInfo.user;
            const now = Date.now();
            
            // Проверяем, активна ли подписка
            const isActive = user.enable && user.expiryTime > now;
            
            if (!isActive) {
                console.log(`❌ Подписка пользователя ${telegramUserId} неактивна или истекла`);
                return {
                    found: true,
                    active: false,
                    user: user,
                    inbound: userInfo.inboundName
                };
            }
            
            // Вычисляем израсходованный трафик
            // В 3xui API трафик может храниться в разных полях
            let usedTraffic = 0;
            let trafficLimit = 'Безлимит';
            
            if (user.totalGB && user.totalGB > 0) {
                // Если есть лимит трафика
                trafficLimit = `${user.totalGB} GB`;
                // Израсходованный трафик обычно хранится в поле up + down
                if (user.up && user.down) {
                    usedTraffic = Math.round((user.up + user.down) / (1024 * 1024 * 1024) * 100) / 100; // Конвертируем в GB
                }
            } else {
                // Безлимитный тариф
                trafficLimit = 'Безлимит';
                if (user.up && user.down) {
                    usedTraffic = Math.round((user.up + user.down) / (1024 * 1024 * 1024) * 100) / 100; // Конвертируем в GB
                }
            }
            
            // Форматируем даты
            const startDate = new Date(user.expiryTime - (30 * 24 * 60 * 60 * 1000)); // Примерно 30 дней назад
            const endDate = new Date(user.expiryTime);
            
            const profile = {
                found: true,
                active: true,
                user: user,
                inbound: userInfo.inboundName,
                startDate: startDate,
                endDate: endDate,
                usedTraffic: usedTraffic,
                trafficLimit: trafficLimit,
                limitIp: user.limitIp || 3
            };
            
            console.log(`✅ Профиль пользователя ${telegramUserId} получен:`, {
                active: profile.active,
                startDate: profile.startDate.toLocaleDateString('ru-RU'),
                endDate: profile.endDate.toLocaleDateString('ru-RU'),
                usedTraffic: profile.usedTraffic,
                trafficLimit: profile.trafficLimit
            });
            
            return profile;
            
        } catch (error) {
            console.error('❌ Ошибка получения профиля пользователя:', error.message);
            return null;
        }
    }

    /**
     * Обновление подписки существующего пользователя
     */
    async updateUserSubscription(userInfo, newExpiresAt, subscriptionData) {
        try {
            if (!this.session) {
                const loggedIn = await this.login();
                if (!loggedIn) return null;
            }

            console.log(`🔄 Обновление подписки пользователя ${userInfo.user.email}...`);

            // Получаем текущие настройки inbound
            const inbound = await this.getInbound(userInfo.inboundId);
            if (!inbound) {
                console.error('❌ Не удалось получить настройки inbound');
                return null;
            }

            // Парсим JSON строку из settings
            let settings;
            try {
                settings = JSON.parse(inbound.settings);
            } catch (error) {
                console.error('❌ Ошибка парсинга settings:', error.message);
                return null;
            }

            // Находим пользователя в списке
            const userIndex = settings.clients.findIndex(client => 
                client.email === userInfo.user.email || 
                client.email === `${userInfo.user.email}@waypn.com`
            );

            if (userIndex === -1) {
                console.error('❌ Пользователь не найден в settings');
                return null;
            }

            // Обновляем дату окончания подписки
            const currentExpiryTime = settings.clients[userIndex].expiryTime;
            const newExpiryTime = new Date(newExpiresAt).getTime();
            
            // Если текущая подписка еще активна, добавляем новый период к существующей дате
            // Если подписка истекла, устанавливаем новую дату
            const now = Date.now();
            let finalExpiryTime;
            
            if (currentExpiryTime > now) {
                // Подписка активна - добавляем новый период к текущей дате
                const currentExpiryDate = new Date(currentExpiryTime);
                const newPeriodMs = newExpiryTime - now; // Длительность нового периода
                finalExpiryTime = currentExpiryDate.getTime() + newPeriodMs;
                console.log(`📅 Подписка активна. Добавляем ${newPeriodMs / (1000 * 60 * 60 * 24)} дней к текущей дате`);
            } else {
                // Подписка истекла - устанавливаем новую дату
                finalExpiryTime = newExpiryTime;
                console.log(`📅 Подписка истекла. Устанавливаем новую дату окончания`);
            }

            // Обновляем данные пользователя
            settings.clients[userIndex].expiryTime = finalExpiryTime;
            settings.clients[userIndex].subId = `sub_${subscriptionData.subscription_id}`;
            settings.clients[userIndex].enable = true; // Активируем пользователя

            // Обновляем settings в inbound
            inbound.settings = JSON.stringify(settings, null, 2);

            // Обновляем inbound
            const response = await this.axios.post(`/panel/api/inbounds/update/${userInfo.inboundId}`, inbound, {
                headers: {
                    'Cookie': this.getCookieString()
                }
            });

            if (response.data.success) {
                console.log('✅ Подписка пользователя успешно обновлена');
                return {
                    success: true,
                    user: settings.clients[userIndex],
                    inbound: userInfo.inboundName,
                    subscription: subscriptionData,
                    oldExpiryTime: currentExpiryTime,
                    newExpiryTime: finalExpiryTime
                };
            } else {
                console.error('❌ Ошибка обновления подписки:', response.data.msg);
                return null;
            }
        } catch (error) {
            console.error('❌ Ошибка обновления подписки:', error.message);
            if (error.response) {
                console.error('   Статус:', error.response.status);
                console.error('   Данные:', error.response.data);
            }
            return null;
        }
    }
}

module.exports = XuiAPI; 