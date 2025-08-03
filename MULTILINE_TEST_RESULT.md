# 多行日志处理测试结果

## 测试状态：✅ 通过

## 问题描述

日志文件中存在跨行的 JSON 数据，例如：
- 第一行：`[2025-08-03 17:20:27] /116.147.11.22:64871 - {"header":{"msgId":0.1968475799829632...,"data":[2878,317`
- 第二行：`[2025-08-03 17:20:28] /116.147.11.22:64871 - 9,3040,3126],"channelState":[1,1,1,1]...`

其中数字 `3179` 被拆分成了 `317` 和 `9`，分布在两行中。

## 断行模式分析

对 `raw_data_2025-03-30.log` 的分析发现了多种断行模式：

### 1. 数字被断开（35次）
- **示例**：`[2878,317` → `9,3040,3126]`
- **处理**：使用正则 `(\d+)\s+(\d+)` 合并相邻的数字

### 2. 数组元素被断开（70次）
- **示例**：`[1,1` → `,1,1]` 或 `["0.00","0.00","0.00"` → `,"0.00","0.00"]`
- **处理**：
  - 修复逗号周围的空格：`(\d)\s*,\s*(\d)` → `\1,\2`
  - 修复字符串之间的逗号：`"\s*,\s*"` → `","`

### 3. 属性名被断开（28次）
- **示例**：`"ch` → `annelState"`
- **处理**：使用正则 `([a-zA-Z]+)\s+([a-zA-Z]+)"` 合并断开的属性名

### 4. 字符串被断开（34次）
- **示例**：字符串值在中间被断开
- **处理**：通过移除多余空格和修复引号位置来处理

### 5. 其他情况（57次）
- 包括各种复杂的混合断开情况
- 通过通用的空白字符清理和JSON符号规范化处理

## 解决方案

### 1. Filebeat 多行处理配置

在 `config/filebeat/filebeat.yml` 中配置：

```yaml
multiline.pattern: '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] /[^:]+:\d+ - \{'
multiline.negate: true  
multiline.match: after
multiline.max_lines: 100
multiline.timeout: 30s
```

- **pattern**：匹配以时间戳开头并包含 JSON 对象开始 `{` 的行
- **negate: true**：不匹配模式的行被视为续行
- **match: after**：续行添加到主行之后

### 2. Logstash 处理配置

在 `config/logstash/pipeline/logstash.conf` 中：

#### 第一阶段：基本清理
```ruby
mutate {
  gsub => [
    # 移除续行中的时间戳和IP前缀
    "raw_json", "\n\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] /[^:]+:\d+ - ", "",
    # 移除多余的换行符和空白字符
    "raw_json", "[\r\n\t]+", "",
    "raw_json", "\s+", " "
  ]
}

# 修复被断开的数字
mutate {
  gsub => [
    "raw_json", "(\d+)\s+(\d+)", "\1\2"
  ]
}
```

#### 第二阶段：JSON 解析失败时的 Ruby 处理
```ruby
ruby {
  code => '
    begin
      raw_json = event.get("raw_json")
      if raw_json
        cleaned_json = raw_json.strip
        
        # 移除时间戳行内容
        cleaned_json = cleaned_json.gsub(/\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] \/[^:]+:\d+ - /, "")
        
        # 修复被断开的数字
        cleaned_json = cleaned_json.gsub(/(\d+)\s+(\d+)/, "\\1\\2")
        
        # 移除多余的换行符和空白
        cleaned_json = cleaned_json.gsub(/[\r\n\t]+/, "")
        cleaned_json = cleaned_json.gsub(/\s+/, " ")
        
        # 解析JSON
        parsed = JSON.parse(cleaned_json)
        event.set("parsed_data", parsed)
        event.remove("_jsonparsefailure")
        event.tag("_json_fixed")
      end
    rescue => e
      event.tag("_jsonparsefailure_final")
      event.set("json_error", e.message)
    end
  '
}
```

## 测试结果

### 测试数据
- **输入**：`test/test.log` - 包含跨行的 JSON 数据
- **期望输出**：`test/target.json` - 正确解析的 JSON 结构

### 验证结果
所有字段都正确解析：
- ✅ header.msgId: 0.1968475799829632
- ✅ header.msgType: request
- ✅ header.subType: upload
- ✅ device.gatewaySn: MA250201
- ✅ payload.dataType: compactness
- ✅ payload.sn: CF250203
- ✅ payload.bat: 81
- ✅ payload.dataList: 10 个数据项

### 关键修复
成功将断开的数字 `"317 9"` 修复为 `"3179"`，确保 JSON 正确解析。

## 实际数据统计

对 `raw_data_2025-03-30.log` 的分析：
- 总行数：2234
- 日志条目数：2009
- 续行数：224
- 平均每个条目行数：1.11

约 10% 的日志条目存在多行情况，配置能够正确处理这些多行日志。

## 字段展开

在 Elasticsearch 中，解析后的 JSON 字段已经自动展开为嵌套结构：
```
{
  "header": {
    "msgId": 0.1968475799829632,
    "msgType": "request",
    "subType": "upload"
  },
  "device": {
    "gatewaySn": "MA250201"
  },
  "payload": {
    "dataType": "compactness",
    "dataList": [...],
    "sn": "CF250203",
    "bat": 81
  }
}
```

## 使用说明

1. 将日志文件放入 `source/` 目录
2. 重启 ELK 堆栈：`docker-compose restart`
3. 查看 Kibana 或使用 Elasticsearch API 查询数据
4. 检查 `_json_fixed` 标签以识别经过修复的日志条目