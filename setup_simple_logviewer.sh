#!/bin/bash

# Простой веб-интерфейс для просмотра логов
# Автор: WAYPN Team
# Версия: 1.0

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

log "🚀 Установка простого веб-интерфейса для логов..."

# Обновление системы
log "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка nginx и php
log "📋 Установка nginx и php..."
apt install -y nginx php-fpm php-curl php-json

# Создание директории для веб-интерфейса
log "📁 Создание директорий..."
mkdir -p /opt/logviewer
mkdir -p /opt/logviewer/logs
mkdir -p /opt/logviewer/web

# Создание веб-интерфейса
log "🌐 Создание веб-интерфейса..."
cat > /opt/logviewer/web/index.php << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WAYPN Bot Logs Viewer</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background: #1a1a1a;
            color: #ffffff;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .header {
            background: #2d2d2d;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .controls {
            background: #2d2d2d;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .log-viewer {
            background: #2d2d2d;
            padding: 20px;
            border-radius: 10px;
            height: 600px;
            overflow-y: auto;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            line-height: 1.4;
        }
        .log-line {
            margin: 2px 0;
            padding: 2px 5px;
            border-radius: 3px;
        }
        .log-line:hover {
            background: #3d3d3d;
        }
        .error { color: #ff6b6b; }
        .warning { color: #ffd93d; }
        .info { color: #6bcf7f; }
        .debug { color: #4dabf7; }
        input, select, button {
            background: #3d3d3d;
            border: 1px solid #555;
            color: #fff;
            padding: 8px 12px;
            border-radius: 5px;
            margin: 5px;
        }
        button {
            background: #007acc;
            cursor: pointer;
        }
        button:hover {
            background: #005a9e;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: #2d2d2d;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
        }
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #007acc;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 WAYPN Bot Logs Viewer</h1>
            <p>Мониторинг и анализ логов Telegram бота</p>
        </div>

        <div class="stats">
            <div class="stat-card">
                <div class="stat-number" id="total-lines">0</div>
                <div>Всего строк</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="errors">0</div>
                <div>Ошибки</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="users">0</div>
                <div>Активных пользователей</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="uptime">0</div>
                <div>Время работы (ч)</div>
            </div>
        </div>

        <div class="controls">
            <form method="GET">
                <label>Период:</label>
                <select name="period">
                    <option value="1h" <?php echo ($_GET['period'] ?? '1h') === '1h' ? 'selected' : ''; ?>>Последний час</option>
                    <option value="6h" <?php echo ($_GET['period'] ?? '1h') === '6h' ? 'selected' : ''; ?>>6 часов</option>
                    <option value="24h" <?php echo ($_GET['period'] ?? '1h') === '24h' ? 'selected' : ''; ?>>24 часа</option>
                    <option value="7d" <?php echo ($_GET['period'] ?? '1h') === '7d' ? 'selected' : ''; ?>>7 дней</option>
                </select>

                <label>Фильтр:</label>
                <input type="text" name="filter" placeholder="Поиск в логах..." value="<?php echo htmlspecialchars($_GET['filter'] ?? ''); ?>">

                <label>Уровень:</label>
                <select name="level">
                    <option value="">Все</option>
                    <option value="error" <?php echo ($_GET['level'] ?? '') === 'error' ? 'selected' : ''; ?>>Ошибки</option>
                    <option value="warning" <?php echo ($_GET['level'] ?? '') === 'warning' ? 'selected' : ''; ?>>Предупреждения</option>
                    <option value="info" <?php echo ($_GET['level'] ?? '') === 'info' ? 'selected' : ''; ?>>Информация</option>
                </select>

                <button type="submit">Обновить</button>
                <button type="button" onclick="autoRefresh()">Автообновление</button>
            </form>
        </div>

        <div class="log-viewer" id="log-viewer">
            <?php
            $period = $_GET['period'] ?? '1h';
            $filter = $_GET['filter'] ?? '';
            $level = $_GET['level'] ?? '';

            // Команда для получения логов
            $cmd = "journalctl -u waypn-bot.service --since '$period ago' --no-pager";
            if ($filter) {
                $cmd .= " | grep -i '$filter'";
            }
            if ($level) {
                $cmd .= " | grep -i '$level'";
            }

            $logs = shell_exec($cmd);
            $lines = explode("\n", $logs);
            $totalLines = count($lines);
            $errors = 0;
            $users = 0;

            foreach ($lines as $line) {
                if (empty(trim($line))) continue;
                
                $cssClass = '';
                if (stripos($line, 'error') !== false || stripos($line, 'exception') !== false) {
                    $cssClass = 'error';
                    $errors++;
                } elseif (stripos($line, 'warning') !== false) {
                    $cssClass = 'warning';
                } elseif (stripos($line, 'info') !== false) {
                    $cssClass = 'info';
                } elseif (stripos($line, 'debug') !== false) {
                    $cssClass = 'debug';
                }

                if (stripos($line, 'username') !== false) {
                    $users++;
                }

                echo '<div class="log-line ' . $cssClass . '">' . htmlspecialchars($line) . '</div>';
            }
            ?>
        </div>
    </div>

    <script>
        // Обновление статистики
        document.getElementById('total-lines').textContent = '<?php echo $totalLines; ?>';
        document.getElementById('errors').textContent = '<?php echo $errors; ?>';
        document.getElementById('users').textContent = '<?php echo $users; ?>';

        // Автообновление
        let autoRefreshInterval = null;

        function autoRefresh() {
            if (autoRefreshInterval) {
                clearInterval(autoRefreshInterval);
                autoRefreshInterval = null;
                event.target.textContent = 'Автообновление';
                event.target.style.background = '#007acc';
            } else {
                autoRefreshInterval = setInterval(() => {
                    location.reload();
                }, 5000);
                event.target.textContent = 'Остановить';
                event.target.style.background = '#dc3545';
            }
        }

        // Поиск по логам
        document.addEventListener('keydown', function(e) {
            if (e.ctrlKey && e.key === 'f') {
                e.preventDefault();
                document.querySelector('input[name="filter"]').focus();
            }
        });
    </script>
</body>
</html>
EOF

# Создание nginx конфигурации
log "🌐 Создание nginx конфигурации..."
cat > /etc/nginx/sites-available/logviewer << 'EOF'
server {
    listen 80;
    server_name 89.110.81.79;

    root /opt/logviewer/web;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Активация nginx конфигурации
ln -sf /etc/nginx/sites-available/logviewer /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Настройка прав доступа
chown -R www-data:www-data /opt/logviewer
chmod -R 755 /opt/logviewer

# Перезапуск сервисов
log "🔄 Перезапуск сервисов..."
systemctl restart nginx
systemctl restart php8.1-fpm

# Создание скрипта для ротации логов
log "📝 Создание скрипта ротации логов..."
cat > /etc/logrotate.d/waypn-bot << 'EOF'
/var/log/syslog {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog
    endscript
}
EOF

# Проверка статуса
log "🔍 Проверка статуса сервисов..."
systemctl status nginx --no-pager
systemctl status php8.1-fpm --no-pager

log "✅ Веб-интерфейс успешно установлен!"
echo ""
echo "📊 Доступ к сервисам:"
echo "   🌐 Веб-интерфейс: http://89.110.81.79"
echo ""
echo "💡 Возможности:"
echo "   🔍 Поиск по логам (Ctrl+F)"
echo "   ⏰ Фильтр по времени"
echo "   🚨 Фильтр по уровню (ошибки, предупреждения)"
echo "   🔄 Автообновление каждые 5 секунд"
echo ""
echo "💡 Команды управления:"
echo "   systemctl status nginx"
echo "   systemctl restart nginx"
echo "   tail -f /var/log/nginx/error.log"
echo "" 