#!/bin/bash

echo "🔍 测试 ELK 日志处理配置"
echo "================================"

# 检查服务状态
echo "1. 检查 Docker Compose 服务状态..."
docker compose ps

echo ""
echo "2. 检查 Filebeat 日志..."
docker compose logs filebeat --tail=20

echo ""
echo "3. 检查 Logstash 日志..."
docker compose logs logstash --tail=20

echo ""
echo "4. 检查 Elasticsearch 索引..."
curl -s "http://localhost:9200/_cat/indices?v" | grep -E "(iot-|filebeat-)"

echo ""
echo "5. 查看温度数据样例..."
curl -s "http://localhost:9200/iot-temperature-*/_search?size=1&pretty" | jq .

echo ""
echo "6. 查看密实度数据样例..."
curl -s "http://localhost:9200/iot-compactness-*/_search?size=1&pretty" | jq .

echo ""
echo "7. 统计各类型数据数量..."
echo "温度数据: $(curl -s "http://localhost:9200/iot-temperature-*/_count" | jq .count)"
echo "密实度数据: $(curl -s "http://localhost:9200/iot-compactness-*/_count" | jq .count)"
echo "heartbeat数据应该被过滤掉了"
