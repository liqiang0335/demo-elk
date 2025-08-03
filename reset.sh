#!/bin/bash

# ELK Stack 清理和重置脚本

echo "正在清理 ELK Stack 环境..."

# 停止所有容器
echo "停止容器..."
docker compose down -v

# 清理数据目录
echo "清理数据目录..."
sudo rm -rf data/elasticsearch/*
sudo rm -rf data/kibana/*
sudo rm -rf data/logstash/*
sudo rm -rf data/filebeat/*

# 重新创建目录结构
echo "重新创建目录结构..."
sudo mkdir -p data/elasticsearch/logs
sudo mkdir -p data/kibana/logs  
sudo mkdir -p data/logstash/logs
sudo mkdir -p data/filebeat

# 设置正确的权限
echo "设置权限..."
sudo chown -R 1000:1000 data/elasticsearch
sudo chown -R 1000:1000 data/logstash
sudo chown -R 1000:1000 data/kibana
sudo chown -R root:root data/filebeat

# 确保配置文件权限正确
sudo chmod 644 config/elasticsearch/elasticsearch.yml
sudo chmod 644 config/kibana/kibana.yml
sudo chmod 666 config/logstash/logstash.yml
sudo chmod 644 config/logstash/pipeline/logstash.conf
sudo chmod 644 config/filebeat/filebeat.yml

echo "清理完成！现在可以运行 ./start.sh 重新启动服务"
