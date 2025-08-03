# 多行数据处理流程详解

## 处理逻辑位置

多行数据的合并处理逻辑主要分布在两个地方：

### 1. Filebeat 多行处理（第 1 阶段）

**位置：** `config/filebeat/filebeat.yml`

```yaml
# 多行处理配置
multiline.pattern: '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] /[^:]+:\d+ - \{'
multiline.negate: true
multiline.match: after
multiline.max_lines: 20
multiline.timeout: 5s
```

**处理逻辑：**

1. **读取日志文件**：Filebeat 逐行读取日志文件
2. **模式匹配**：使用正则表达式判断每行是否匹配新模式
3. **多行合并**：
   - 匹配模式的行 = 新日志条目开始
   - 不匹配模式的行 = 延续前一个日志条目
4. **发送到 Logstash**：合并后的完整消息发送给 Logstash

### 2. Logstash JSON 解析（第 2 阶段）

**位置：** `config/logstash/pipeline/logstash.conf`

```ruby
# JSON 解析和错误处理
if [raw_json] {
  json {
    source => "raw_json"
    target => "parsed_data"
    skip_on_invalid_json => true
  }

  # 如果JSON解析失败，尝试清理和重新解析
  if "_jsonparsefailure" in [tags] {
    mutate {
      replace => { "raw_json" => "%{[raw_json]}" }
    }

    # 尝试修复常见的JSON格式问题
    ruby {
      code => '
        begin
          raw_json = event.get("raw_json")
          if raw_json
            # 移除可能的换行符和多余空格
            cleaned_json = raw_json.gsub(/\s+/, " ").strip
            # 尝试解析JSON
            parsed = JSON.parse(cleaned_json)
            event.set("parsed_data", parsed)
            event.remove("_jsonparsefailure")
          end
        rescue => e
          event.tag("_jsonparsefailure_final")
        end
      '
    }
  }
}
```

## 详细处理流程

### 阶段 1：Filebeat 多行处理

```
原始日志文件：
[2025-03-30 00:00:00] /116.147.11.22:64871 - {"header":{"msgId":1743264000000,"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2874,3174,3042,3127],"channelState":[1,1,1,1],"time":1743263941000},{"data":[2872,3174,3038,3125],"channelState":[1,1,1,1],"time":1743263943000},{"data":[2883,3187,3047,3139],"channelState":[1,1,1,1],"time":1743263945000},{"data":[2878,3178,3041,3127],"channelState":[1,1,1,1],"time":1743263947000},{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263949000},{"data":[2881,3180,3041,3126],"channelState":[1,1,1,1],"time":1743263951000}],"sn":"CF250203","bat":81}}

Filebeat 处理过程：
1. 读取第1行：
   - 匹配模式：✅ (以 {" 开头)
   - 动作：开始新日志条目

2. 读取第2行：
   - 匹配模式：❌ (不以 {" 开头)
   - 动作：延续第1行

3. 合并结果：
   [2025-03-30 00:00:00] /116.147.11.22:64871 - {"header":{"msgId":1743264000000,"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2874,3174,3042,3127],"channelState":[1,1,1,1],"time":1743263941000},{"data":[2872,3174,3038,3125],"channelState":[1,1,1,1],"time":1743263943000},{"data":[2883,3187,3047,3139],"channelState":[1,1,1,1],"time":1743263945000},{"data":[2878,3178,3041,3127],"channelState":[1,1,1,1],"time":1743263947000},{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263949000},{"data":[2881,3180,3041,3126],"channelState":[1,1,1,1],"time":1743263951000}],"sn":"CF250203","bat":81}}
```

### 阶段 2：Logstash 解析处理

```
Logstash 接收到的消息：
[2025-03-30 00:00:00] /116.147.11.22:64871 - {"header":{"msgId":1743264000000,"msgType":"request","subType":"upload"},"device":{"gatewaySn":"MA250201"},"payload":{"dataType":"compactness","dataList":[{"data":[2874,3174,3042,3127],"channelState":[1,1,1,1],"time":1743263941000},{"data":[2872,3174,3038,3125],"channelState":[1,1,1,1],"time":1743263943000},{"data":[2883,3187,3047,3139],"channelState":[1,1,1,1],"time":1743263945000},{"data":[2878,3178,3041,3127],"channelState":[1,1,1,1],"time":1743263947000},{"data":[2878,3179,3040,3126],"channelState":[1,1,1,1],"time":1743263949000},{"data":[2881,3180,3041,3126],"channelState":[1,1,1,1],"time":1743263951000}],"sn":"CF250203","bat":81}}

Logstash 处理步骤：
1. Grok 解析：
   - log_timestamp: "2025-03-30 00:00:00"
   - client_ip: "116.147.11.22"
   - client_port: "64871"
   - raw_json: 完整的JSON字符串

2. JSON 解析：
   - 尝试解析 raw_json 字段
   - 成功：设置 parsed_data 字段
   - 失败：触发 Ruby 清理逻辑

3. 字段提取：
   - msg_id: "1743264000000"
   - msg_type: "request"
   - sub_type: "upload"
   - gateway_sn: "MA250201"
   - data_type: "compactness"
   - device_sn: "CF250203"
   - battery_level: 81
```

## 关键配置参数说明

### Filebeat 多行处理参数

```yaml
multiline.pattern: '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] /[^:]+:\d+ - \{'
# 正则表达式：匹配新JSON开始的行

multiline.negate: true
# true = 不匹配模式的行作为延续
# false = 匹配模式的行作为延续

multiline.match: after
# after = 延续行添加到主行之后
# before = 延续行添加到主行之前

multiline.max_lines: 20
# 最大合并行数，防止无限合并

multiline.timeout: 5s
# 多行处理超时时间
```

### Logstash 错误处理参数

```ruby
skip_on_invalid_json: true
# JSON解析失败时不丢弃事件，而是添加标签

# Ruby 清理逻辑
cleaned_json = raw_json.gsub(/\s+/, " ").strip
# 移除多余空白字符和换行符
```

## 处理逻辑的优势

1. **分层处理**：Filebeat 负责多行合并，Logstash 负责数据解析
2. **容错机制**：多层错误处理确保数据不丢失
3. **精确匹配**：新模式确保只有真正的 JSON 开始才被识别为新条目
4. **自动清理**：Ruby 脚本自动修复常见的 JSON 格式问题

## 监控和调试

### 检查多行处理效果

```bash
# 查看 Filebeat 日志
docker logs filebeat

# 查看 Logstash 日志
docker logs logstash

# 检查 Elasticsearch 数据
curl -X GET "localhost:9200/iot-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "msg_id": "1743264000000"
    }
  }
}'
```

### 常见问题排查

1. **多行未合并**：检查 `multiline.pattern` 是否正确
2. **JSON 解析失败**：检查 `_jsonparsefailure` 标签
3. **数据丢失**：检查 `multiline.timeout` 和 `multiline.max_lines`
4. **性能问题**：调整 `multiline.max_lines` 和超时时间
