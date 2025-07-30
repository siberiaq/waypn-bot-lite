#!/bin/bash

# Скрипт установки мониторинга Grafana + Loki
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

log "🚀 Установка системы мониторинга Grafana + Loki..."

# Обновление системы
log "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка Docker
log "🐳 Установка Docker..."
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Установка Docker Compose
log "📋 Установка Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Создание директории для мониторинга
log "📁 Создание директорий..."
mkdir -p /opt/monitoring
cd /opt/monitoring

# Создание docker-compose.yml для Grafana + Loki
log "📝 Создание конфигурации Docker Compose..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  loki:
    image: grafana/loki:2.9.0
    container_name: loki
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml
    restart: unless-stopped

  grafana:
    image: grafana/grafana:10.1.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=waypn2024
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    depends_on:
      - loki

  promtail:
    image: grafana/promtail:2.9.0
    container_name: promtail
    command: -config.file=/etc/promtail/config.yml
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    restart: unless-stopped
    depends_on:
      - loki

volumes:
  grafana-storage:
EOF

# Создание конфигурации Loki
log "⚙️ Создание конфигурации Loki..."
cat > loki-config.yaml << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    finalize_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  retention_period: 744h

ruler:
  alertmanager_url: http://localhost:9093
EOF

# Создание конфигурации Promtail
log "📊 Создание конфигурации Promtail..."
cat > promtail-config.yml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  - job_name: waypn-bot
    static_configs:
      - targets:
          - localhost
        labels:
          job: waypn-bot
          __path__: /var/log/syslog
    pipeline_stages:
      - match:
          selector: '{job="waypn-bot"}'
          stages:
            - regex:
                expression: '.*waypn-bot.*'
            - labels:
                app: waypn-bot
                service: telegram-bot

  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*log
    pipeline_stages:
      - json:
          expressions:
            stream: stream
            attrs: attrs
            tag: attrs.tag
            time: time
      - labels:
          stream:
          tag:
      - timestamp:
          source: time
          format: RFC3339Nano
      - output:
          source: log
EOF

# Создание директории для Grafana provisioning
log "📋 Создание конфигурации Grafana..."
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards

# Создание datasource для Loki
cat > grafana/provisioning/datasources/loki.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: true
EOF

# Создание dashboard для бота
cat > grafana/provisioning/dashboards/waypn-bot.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "WAYPN Bot Monitoring",
    "tags": ["waypn", "bot", "telegram"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Bot Logs",
        "type": "logs",
        "targets": [
          {
            "expr": "{app=\"waypn-bot\"}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "vis": false
              }
            }
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "User Activity",
        "type": "stat",
        "targets": [
          {
            "expr": "count_over_time({app=\"waypn-bot\"} [1h])",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "hideFrom": {
                "legend": false,
                "tooltip": false,
                "vis": false
              }
            }
          }
        },
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 12,
          "y": 0
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {},
    "templating": {
      "list": []
    },
    "annotations": {
      "list": []
    },
    "refresh": "5s",
    "schemaVersion": 27,
    "version": 0,
    "links": []
  }
}
EOF

# Создание dashboard provisioning
cat > grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Запуск сервисов
log "🚀 Запуск сервисов мониторинга..."
docker-compose up -d

# Ожидание запуска
log "⏳ Ожидание запуска сервисов..."
sleep 30

# Проверка статуса
log "🔍 Проверка статуса сервисов..."
docker-compose ps

log "✅ Мониторинг успешно установлен!"
echo ""
echo "📊 Доступ к сервисам:"
echo "   🌐 Grafana: http://89.110.81.79:3000"
echo "   👤 Логин: admin"
echo "   🔑 Пароль: waypn2024"
echo ""
echo "📈 Loki: http://89.110.81.79:3100"
echo ""
echo "💡 Команды управления:"
echo "   cd /opt/monitoring"
echo "   docker-compose logs -f grafana"
echo "   docker-compose logs -f loki"
echo "   docker-compose restart"
echo "" 