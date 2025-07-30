#!/bin/bash

# Комплексное исправление всех проблем с Loki
# Автор: WAYPN Team

set -e

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ $1${NC}"
}

log "🔧 Начинаем комплексное исправление Loki..."

# 1. Остановка всех контейнеров
log "🛑 Остановка всех контейнеров..."
ssh root@89.110.81.79 "cd /opt/monitoring && docker-compose down"

# 2. Очистка всех данных
log "🧹 Очистка всех данных..."
ssh root@89.110.81.79 "cd /opt/monitoring && docker system prune -f && docker volume prune -f"

# 3. Создание правильного docker-compose.yml
log "📝 Создание правильного docker-compose.yml..."
cat > /tmp/docker-compose.yml << 'EOF'
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
      - loki-data:/loki
    restart: unless-stopped
    user: "10001:10001"

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
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    restart: unless-stopped
    depends_on:
      - loki

volumes:
  grafana-storage:
  loki-data:
EOF

# 4. Создание правильного loki-config.yaml
log "📝 Создание правильного loki-config.yaml..."
cat > /tmp/loki-config.yaml << 'EOF'
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
    finalise_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

compactor:
  working_directory: /loki/compactor
  shared_store: filesystem

limits_config:
  retention_period: 744h

ruler:
  alertmanager_url: http://localhost:9093
EOF

# 5. Создание правильного promtail-config.yml
log "📝 Создание правильного promtail-config.yml..."
cat > /tmp/promtail-config.yml << 'EOF'
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
          job: waypn-bot
          __path__: /var/log/syslog
    pipeline_stages:
      - match:
          selector: '{job="waypn-bot"}'
          stages:
            - regex:
                expression: '.*waypn-bot.*'
            - labels:
                level: error
      - match:
          selector: '{job="waypn-bot"}'
          stages:
            - regex:
                expression: '.*npm.*'
            - labels:
                component: npm
      - match:
          selector: '{job="waypn-bot"}'
          stages:
            - regex:
                expression: '.*"username":\s*"([^"]+)".*'
            - labels:
                username: '{{.Value}}'

  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: 'waypn-bot'
        action: keep
    pipeline_stages:
      - json:
          expressions:
            log: log
            stream: stream
            time: time
      - labels:
          stream:
      - timestamp:
          source: time
          format: RFC3339Nano
EOF

# 6. Создание директорий и копирование файлов
log "📁 Создание директорий..."
ssh root@89.110.81.79 "mkdir -p /opt/monitoring/grafana/provisioning/dashboards"

# Копирование файлов на сервер
log "📤 Копирование конфигураций на сервер..."
scp /tmp/docker-compose.yml root@89.110.81.79:/opt/monitoring/
scp /tmp/loki-config.yaml root@89.110.81.79:/opt/monitoring/
scp /tmp/promtail-config.yml root@89.110.81.79:/opt/monitoring/

# 7. Создание provisioning для Grafana
log "📝 Создание provisioning для Grafana..."
ssh root@89.110.81.79 "mkdir -p /opt/monitoring/grafana/provisioning/datasources"
ssh root@89.110.81.79 "mkdir -p /opt/monitoring/grafana/provisioning/dashboards"

# Datasource
cat > /tmp/loki-datasource.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: true
EOF

# Dashboard
cat > /tmp/dashboard-provider.yml << 'EOF'
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

scp /tmp/loki-datasource.yml root@89.110.81.79:/opt/monitoring/grafana/provisioning/datasources/
scp /tmp/dashboard-provider.yml root@89.110.81.79:/opt/monitoring/grafana/provisioning/dashboards/

# 8. Настройка прав доступа
log "🔐 Настройка прав доступа..."
ssh root@89.110.81.79 "cd /opt/monitoring && chmod 644 *.yml *.yaml && chmod 755 grafana/provisioning -R"

# 9. Запуск контейнеров
log "🚀 Запуск контейнеров..."
ssh root@89.110.81.79 "cd /opt/monitoring && docker-compose up -d"

# 10. Проверка статуса
log "🔍 Проверка статуса..."
sleep 10
ssh root@89.110.81.79 "cd /opt/monitoring && docker-compose ps"

# 11. Проверка логов
log "📋 Проверка логов..."
ssh root@89.110.81.79 "cd /opt/monitoring && docker-compose logs --tail=20 loki"

log "✅ Комплексное исправление завершено!"
echo ""
echo "🌐 Доступ к сервисам:"
echo "   Grafana: http://89.110.81.79:3000 (admin/waypn2024)"
echo "   Loki: http://89.110.81.79:3100"
echo ""
echo "📊 Дашборд будет доступен автоматически"
echo "" 