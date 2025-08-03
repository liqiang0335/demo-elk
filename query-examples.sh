#!/bin/bash

echo "=== IoT 数据查询示例 ==="

echo -e "\n1. 查询所有数据（按时间排序）："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "sort": [{"@timestamp": {"order": "desc"}}],
    "size": 3
  }'

echo -e "\n\n2. 查询特定网关的数据："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": {
        "device.gatewaySn": "MA250201"
      }
    },
    "size": 2
  }'

echo -e "\n\n3. 查询心跳数据："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "exists": {
        "field": "heartbeat"
      }
    }
  }'

echo -e "\n\n4. 查询传感器数据（包含 dataList）："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "exists": {
        "field": "payload.dataList"
      }
    },
    "size": 1
  }'

echo -e "\n\n5. 统计不同数据类型的数量："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 0,
    "aggs": {
      "data_types": {
        "terms": {
          "field": "payload.dataType"
        }
      }
    }
  }'

echo -e "\n\n6. 查询特定时间范围的数据："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "range": {
        "@timestamp": {
          "gte": "2025-08-03T11:24:00",
          "lte": "2025-08-03T11:25:00"
        }
      }
    }
  }'

echo -e "\n\n7. 查询电池电量低于 90 的设备："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "range": {
        "payload.bat": {
          "lt": 90
        }
      }
    }
  }'

echo -e "\n\n8. 嵌套查询：查询特定传感器序列号的数据："
curl -X GET "localhost:9200/iot-data-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "nested": {
        "path": "payload.dataList",
        "query": {
          "bool": {
            "must": [
              {
                "term": {
                  "payload.dataList.channelState": [1, 1, 1, 1]
                }
              }
            ]
          }
        }
      }
    },
    "size": 1
  }'

echo -e "\n\n查询示例完成！" 