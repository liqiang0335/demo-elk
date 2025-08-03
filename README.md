# 测试 ELK

本项目用于在 macOS 上通过 Docker 快速部署 ELK Stack 进行本地测试。

## 版本信息

- elasticsearch:8.13.4
- kibana:8.13.4
- logstash:8.13.4
- filebeat:8.13.3

## 功能特性

- ✅ 禁用 SSL 证书验证
- ✅ 使用 Docker volumes 进行数据持久化
- ✅ 容器日志收集
- ✅ 单节点 Elasticsearch 配置
- ✅ 优化的内存设置
- ✅ 自动权限管理

## 快速启动

### 方法一: 使用启动脚本 (推荐)

```bash
./start.sh
```

### 方法二: 手动启动

1. 设置系统参数 (Elasticsearch 需要):

```bash
sudo sysctl -w vm.max_map_count=262144
```

2. 清理之前的容器和卷:

```bash
docker-compose down -v
```

3. 启动服务:

```bash
docker-compose up -d
```

## 服务访问

- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601
- **Logstash API**: http://localhost:9600

## 常用命令

### 查看服务状态

```bash
docker-compose ps
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
docker-compose logs -f logstash
docker-compose logs -f filebeat
```

### 停止服务

```bash
docker-compose down
```

### 重启服务

```bash
docker-compose restart
```

### 清理所有数据 (谨慎使用)

```bash
docker-compose down -v
docker volume prune -f
```

## 测试验证

### 1. 验证 Elasticsearch

```bash
curl http://localhost:9200
curl http://localhost:9200/_cluster/health
```

### 2. 验证 Kibana

访问 http://localhost:5601，等待初始化完成

### 3. 验证 Logstash

```bash
curl http://localhost:9600
```

### 4. 查看索引

```bash
curl http://localhost:9200/_cat/indices?v
```

## 配置说明

### 目录结构

```
.
├── docker-compose.yml          # Docker Compose 配置
├── start.sh                   # 启动脚本
├── config/                    # 配置文件目录
│   ├── elasticsearch/
│   │   └── elasticsearch.yml
│   ├── kibana/
│   │   └── kibana.yml
│   ├── logstash/
│   │   ├── logstash.yml
│   │   └── pipeline/
│   │       └── logstash.conf
│   └── filebeat/
│       └── filebeat.yml
└── data/                      # 数据持久化目录
    ├── elasticsearch/
    ├── logstash/
    └── filebeat/
```

### 安全设置

- 所有组件的 SSL/TLS 已禁用
- X-Pack 安全功能已禁用
- 适用于本地开发和测试环境

### 日志收集

- Filebeat 收集 Docker 容器日志
- 通过 Logstash 处理并存储到 Elasticsearch
- 在 Kibana 中可视化查看日志

## 故障排除

### 常见问题

1. **Elasticsearch 启动失败**

   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

2. **权限问题 - 使用 Docker volumes 自动管理**

   ```bash
   # 清理并重新创建 volumes
   docker-compose down -v
   docker-compose up -d
   ```

3. **内存不足**

   - 调整 `docker-compose.yml` 中的 `ES_JAVA_OPTS` 参数
   - 确保 Docker Desktop 分配足够内存 (建议 4GB+)

4. **端口冲突**

   - 检查端口 9200, 5601, 5044, 9600 是否被占用
   - 修改 `docker-compose.yml` 中的端口映射

5. **数据锁定问题**
   ```bash
   # 完全清理并重启
   docker-compose down -v
   docker volume prune -f
   ./start.sh
   ```

### 查看详细错误

```bash
docker-compose logs [服务名]
```

## 开发建议

- 生产环境请启用安全功能
- 根据实际需求调整 JVM 内存设置
- 定期备份 `data/` 目录
- 监控磁盘空间使用情况
