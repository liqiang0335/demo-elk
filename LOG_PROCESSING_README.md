# ELK 日志处理配置说明

## 概述

此配置用于处理 IoT 网关的 raw_data 日志，具备以下功能：

- 读取 raw_data 日志文件
- 过滤掉 heartbeat 信息
- 处理多行 JSON 数据
- 展开嵌套的传感器数据
- 按数据类型分类存储到不同的 Elasticsearch 索引

## 日志格式

原始日志格式：

```
[2025-03-30 00:00:00] /116.147.11.22:64871 - {"header":{"msgId":1743264000000,"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"temperature",...}}
[2025-03-30 00:00:04] /101.205.189.206:54094 - {"heartbeat":"MA250102"}
```

## 配置文件说明

### Filebeat 配置 (`config/filebeat/filebeat.yml`)

- **多行处理**: 使用正则表达式 `^\[20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]` 识别新日志行
- **文件路径**: 监控 `/usr/share/filebeat/source/raw_data*.log` 文件
- **字段标识**: 添加 `log_type: "raw_data"` 和 `service: "iot_gateway"` 标识

### Logstash 配置 (`config/logstash/pipeline/logstash.conf`)

#### 数据处理流程

1. **基础解析**: 使用 Grok 解析时间戳、IP 地址和 JSON 数据
2. **心跳过滤**: 直接丢弃包含 `heartbeat` 字段的消息
3. **JSON 解析**: 解析消息体的 JSON 结构
4. **数据展开**:
   - 温度数据：展开为 `temperature_ch0`, `temperature_ch1` 等字段
   - 密实度数据：展开为 `datapoint_0_ch0`, `datapoint_0_ch1` 等字段
5. **索引分类**:
   - 温度数据 → `iot-temperature-YYYY.MM.dd`
   - 密实度数据 → `iot-compactness-YYYY.MM.dd`
   - 其他数据 → `iot-general-YYYY.MM.dd`

#### 提取的字段

**通用字段**:

- `@timestamp`: 日志时间戳
- `client_ip`: 客户端 IP 地址
- `client_port`: 客户端端口
- `msg_id`: 消息 ID
- `msg_type`: 消息类型
- `sub_type`: 子类型
- `gateway_sn`: 网关序列号
- `device_sn`: 设备序列号
- `data_type`: 数据类型 (temperature/compactness)
- `battery_level`: 电池电量

**温度数据特有字段**:

- `sensor_time`: 传感器时间戳
- `channel_num`: 通道数量
- `temperature_ch0` ~ `temperature_ch7`: 各通道温度值
- `ch0_state` ~ `ch7_state`: 各通道状态

**密实度数据特有字段**:

- `total_datapoints`: 数据点总数
- `datapoint_N_chM`: 第 N 个数据点的第 M 通道值
- `datapoint_N_chM_state`: 第 N 个数据点的第 M 通道状态
- `datapoint_N_time`: 第 N 个数据点的时间戳

## 使用方法

### 启动服务

```bash
# 启动所有服务
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f filebeat
docker compose logs -f logstash
```

### 验证数据处理

```bash
# 运行测试脚本
./test-logs.sh

# 手动检查索引
curl "http://localhost:9200/_cat/indices?v"

# 查看温度数据
curl "http://localhost:9200/iot-temperature-*/_search?size=5&pretty"

# 查看密实度数据
curl "http://localhost:9200/iot-compactness-*/_search?size=5&pretty"
```

### Kibana 可视化

1. 访问 http://localhost:5601
2. 创建索引模式：
   - `iot-temperature-*`
   - `iot-compactness-*`
3. 在 Discover 中查看和分析数据

## 故障排除

### 常见问题

1. **Filebeat 无法读取文件**: 检查文件权限和路径挂载
2. **Logstash 解析失败**: 查看 `_grokparsefailure` 标签的日志
3. **数据未出现在 Elasticsearch**: 检查 Logstash 日志中的错误信息

### 调试命令

```bash
# 查看 Filebeat 配置是否正确
docker compose exec filebeat filebeat test config

# 查看 Logstash 管道状态
curl "http://localhost:9600/_node/stats/pipelines?pretty"

# 检查 Elasticsearch 集群健康状态
curl "http://localhost:9200/_cluster/health?pretty"
```

## 性能优化建议

1. **Logstash 性能**:

   - 调整 `pipeline.workers` 和 `pipeline.batch.size`
   - 对于大量数据，考虑增加内存分配

2. **Elasticsearch 索引**:

   - 设置合适的分片和副本数
   - 使用索引模板定义字段映射

3. **Filebeat 优化**:
   - 调整 `scan_frequency` 和 `harvester_buffer_size`
   - 使用 `close_inactive` 管理文件句柄

## 扩展功能

可以进一步添加：

- 数据质量检查和清洗
- 异常检测和告警
- 数据聚合和统计
- 更复杂的 Kibana 仪表板
