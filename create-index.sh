#!/bin/bash

# 删除旧的模板（如果存在）
echo "删除旧的索引模板..."
curl -X DELETE "localhost:9200/_index_template/iot-data-template" 2>/dev/null || true

# 创建新的索引模板
echo "创建索引模板..."
curl -X PUT "localhost:9200/_index_template/iot-data-template" \
  -H "Content-Type: application/json" \
  -d @config/elasticsearch/iot-data-template.json

echo -e "\n检查模板是否创建成功..."
curl -X GET "localhost:9200/_index_template/iot-data-template?pretty"

echo -e "\n创建今天的索引..."
TODAY=$(date +%Y.%m.%d)
curl -X PUT "localhost:9200/iot-data-${TODAY}"

echo -e "\n检查索引是否创建成功..."
curl -X GET "localhost:9200/iot-data-${TODAY}?pretty"

echo -e "\n查看所有索引..."
curl -X GET "localhost:9200/_cat/indices?v"

echo -e "\n查看索引模板..."
curl -X GET "localhost:9200/_index_template?pretty"

echo -e "\n索引设置完成！" 