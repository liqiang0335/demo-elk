#!/bin/bash

# ELK Stack 启动脚本

echo "正在启动 ELK Stack..."

# 检查 Docker 是否运行
if ! docker info >/dev/null 2>&1; then
    echo "错误: Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

# 设置 vm.max_map_count (Elasticsearch 需要)
echo "设置 vm.max_map_count..."
sudo sysctl -w vm.max_map_count=262144

# 清理之前的容器和卷
echo "清理之前的容器和卷..."
docker compose down -v

# 删除现有的 volumes (如果存在)
docker volume rm demo-elk_elasticsearch_data 2>/dev/null || true
docker volume rm demo-elk_logstash_data 2>/dev/null || true  
docker volume rm demo-elk_filebeat_data 2>/dev/null || true

# 启动服务
echo "启动 ELK Stack 服务..."
docker compose up -d

echo ""
echo "ELK Stack 正在启动中..."
echo "请等待几分钟让所有服务完全启动"
echo ""
echo "监控启动状态:"
echo "docker compose ps"
echo "docker compose logs -f elasticsearch"
echo ""
echo "服务访问地址:"
echo "- Elasticsearch: http://localhost:9200"
echo "- Kibana: http://localhost:5601"
echo "- Logstash API: http://localhost:9600"
echo ""
echo "使用以下命令查看日志:"
echo "docker compose logs -f [服务名]"
echo ""
echo "停止服务:"
echo "docker compose down"
