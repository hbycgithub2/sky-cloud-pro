# Windows 环境部署指南

> Sky Cloud Pro 微服务组件在 Windows 系统上的部署方案
> 
> 生成时间: 2026-01-28

---

## 📊 组件 Windows 兼容性分析

| 组件 | Windows 支持 | 推荐方式 | 难度 | 说明 |
|------|-------------|---------|------|------|
| **Sentinel** | ✅ 完美支持 | 直接运行 JAR | ⭐ | Java 应用,跨平台 |
| **SkyWalking** | ✅ 完美支持 | 直接运行 JAR | ⭐ | Java 应用,跨平台 |
| **Prometheus** | ✅ 完美支持 | 下载 Windows 版本 | ⭐ | 官方提供 Windows 版本 |
| **Grafana** | ✅ 完美支持 | 下载 Windows 版本 | ⭐ | 官方提供 Windows 版本 |
| **Elasticsearch** | ✅ 完美支持 | 下载 Windows 版本 | ⭐⭐ | 官方提供 Windows 版本 |
| **Kibana** | ✅ 完美支持 | 下载 Windows 版本 | ⭐ | 官方提供 Windows 版本 |
| **Logstash** | ✅ 完美支持 | 下载 Windows 版本 | ⭐⭐ | 官方提供 Windows 版本 |
| **Filebeat** | ✅ 完美支持 | 下载 Windows 版本 | ⭐ | 官方提供 Windows 版本 |
| **RocketMQ** | ⚠️ 有限支持 | Docker Desktop | ⭐⭐⭐ | 官方推荐 Linux,Windows 需要 Docker |
| **Seata** | ✅ 完美支持 | 直接运行 JAR | ⭐ | Java 应用,跨平台 |
| **Nacos** | ✅ 完美支持 | 直接运行 JAR | ⭐ | 你已经在用了 |
| **MySQL** | ✅ 完美支持 | 下载 Windows 版本 | ⭐ | 你已经在用了 |
| **Redis** | ⚠️ 有限支持 | Docker Desktop | ⭐⭐ | 官方不支持 Windows,推荐 Docker |

---

## 🎯 Windows 部署方案

### 方案一: 纯 Windows 原生部署 (推荐学习阶段)

**适用场景**: 学习、开发、测试

**优点**:
- 无需虚拟化,性能最好
- 配置简单,易于调试
- 资源占用少

**缺点**:
- RocketMQ 需要 Docker
- Redis 需要 Docker 或第三方版本

#### 部署清单

```yaml
✅ 可以直接在 Windows 运行:
  1. Sentinel Dashboard (JAR)
  2. SkyWalking OAP + UI (JAR)
  3. Prometheus (Windows 版本)
  4. Grafana (Windows 版本)
  5. Elasticsearch (Windows 版本)
  6. Kibana (Windows 版本)
  7. Logstash (Windows 版本)
  8. Filebeat (Windows 版本)
  9. Seata Server (JAR)
  10. Nacos (JAR) - 你已经在用
  11. MySQL (Windows 版本) - 你已经在用

⚠️ 需要 Docker Desktop:
  1. RocketMQ (官方推荐 Linux)
  2. Redis (官方不支持 Windows)
```

---

### 方案二: Docker Desktop 混合部署 (推荐)

**适用场景**: 开发、测试、接近生产环境

**优点**:
- 环境一致性好
- 接近生产环境
- 易于迁移到 Linux

**缺点**:
- 需要安装 Docker Desktop
- 资源占用较多 (需要 WSL2)

#### 部署清单

```yaml
✅ Docker 容器运行 (推荐):
  1. RocketMQ (必须)
  2. Redis (必须)
  3. Elasticsearch (可选,也可以用 Windows 版本)
  4. Kibana (可选,也可以用 Windows 版本)
  5. Prometheus (可选,也可以用 Windows 版本)
  6. Grafana (可选,也可以用 Windows 版本)

✅ Windows 原生运行:
  1. Sentinel Dashboard (JAR)
  2. SkyWalking OAP + UI (JAR)
  3. Seata Server (JAR)
  4. Nacos (JAR)
  5. MySQL (Windows 版本)
  6. 你的微服务应用 (JAR)
```

---

## 🚀 详细部署步骤

### 1. Sentinel Dashboard (Windows 原生)

```powershell
# 下载 Sentinel Dashboard
# 访问: https://github.com/alibaba/Sentinel/releases
# 下载: sentinel-dashboard-1.8.6.jar

# 启动 Sentinel Dashboard
java -Dserver.port=8080 `
     -Dcsp.sentinel.dashboard.server=localhost:8080 `
     -Dproject.name=sentinel-dashboard `
     -jar sentinel-dashboard-1.8.6.jar

# 访问: http://localhost:8080
# 账号密码: sentinel/sentinel
```

**✅ Windows 完美支持,无需任何修改**

---

### 2. SkyWalking (Windows 原生)

```powershell
# 下载 SkyWalking
# 访问: https://skywalking.apache.org/downloads/
# 下载: apache-skywalking-apm-9.3.0.tar.gz

# 解压
tar -xzf apache-skywalking-apm-9.3.0.tar.gz
cd apache-skywalking-apm-9.3.0

# 启动 OAP (Windows 批处理)
bin\oapService.bat

# 启动 UI (Windows 批处理)
bin\webappService.bat

# 访问: http://localhost:8080
```

**✅ Windows 完美支持,官方提供 .bat 脚本**

---

### 3. Prometheus (Windows 原生)

```powershell
# 下载 Prometheus Windows 版本
# 访问: https://prometheus.io/download/
# 下载: prometheus-2.45.0.windows-amd64.zip

# 解压
Expand-Archive prometheus-2.45.0.windows-amd64.zip

# 配置 prometheus.yml
cd prometheus-2.45.0.windows-amd64
notepad prometheus.yml

# 启动 Prometheus
.\prometheus.exe --config.file=prometheus.yml

# 访问: http://localhost:9090
```

**✅ Windows 完美支持,官方提供 Windows 版本**

---

### 4. Grafana (Windows 原生)

```powershell
# 下载 Grafana Windows 版本
# 访问: https://grafana.com/grafana/download?platform=windows
# 下载: grafana-10.2.3.windows-amd64.zip

# 解压
Expand-Archive grafana-10.2.3.windows-amd64.zip

# 启动 Grafana
cd grafana-10.2.3\bin
.\grafana-server.exe

# 访问: http://localhost:3000
# 默认账号密码: admin/admin
```

**✅ Windows 完美支持,官方提供 Windows 版本**

---

### 5. Elasticsearch (Windows 原生)

```powershell
# 下载 Elasticsearch Windows 版本
# 访问: https://www.elastic.co/downloads/elasticsearch
# 下载: elasticsearch-7.17.9-windows-x86_64.zip

# 解压
Expand-Archive elasticsearch-7.17.9-windows-x86_64.zip

# 启动 Elasticsearch
cd elasticsearch-7.17.9\bin
.\elasticsearch.bat

# 访问: http://localhost:9200
```

**✅ Windows 完美支持,官方提供 Windows 版本**

---

### 6. Kibana (Windows 原生)

```powershell
# 下载 Kibana Windows 版本
# 访问: https://www.elastic.co/downloads/kibana
# 下载: kibana-7.17.9-windows-x86_64.zip

# 解压
Expand-Archive kibana-7.17.9-windows-x86_64.zip

# 启动 Kibana
cd kibana-7.17.9\bin
.\kibana.bat

# 访问: http://localhost:5601
```

**✅ Windows 完美支持,官方提供 Windows 版本**

---

### 7. Filebeat (Windows 原生)

```powershell
# 下载 Filebeat Windows 版本
# 访问: https://www.elastic.co/downloads/beats/filebeat
# 下载: filebeat-7.17.9-windows-x86_64.zip

# 解压
Expand-Archive filebeat-7.17.9-windows-x86_64.zip

# 配置 filebeat.yml
cd filebeat-7.17.9-windows-x86_64
notepad filebeat.yml

# 启动 Filebeat
.\filebeat.exe -e -c filebeat.yml
```

**✅ Windows 完美支持,官方提供 Windows 版本**

---

### 8. RocketMQ (Docker Desktop - 必须)

**⚠️ RocketMQ 官方推荐 Linux,Windows 必须使用 Docker**

#### 安装 Docker Desktop

```powershell
# 1. 下载 Docker Desktop for Windows
# 访问: https://www.docker.com/products/docker-desktop/

# 2. 安装 Docker Desktop
# 双击安装包,按提示安装

# 3. 启动 Docker Desktop
# 确保 WSL2 已启用

# 4. 验证安装
docker --version
docker-compose --version
```

#### 部署 RocketMQ

```powershell
# 创建 docker-compose.yml
@"
version: '3.8'
services:
  namesrv:
    image: apache/rocketmq:4.9.4
    container_name: rmqnamesrv
    ports:
      - 9876:9876
    command: sh mqnamesrv
    networks:
      - rocketmq

  broker:
    image: apache/rocketmq:4.9.4
    container_name: rmqbroker
    ports:
      - 10911:10911
      - 10909:10909
    environment:
      - NAMESRV_ADDR=namesrv:9876
    command: sh mqbroker -n namesrv:9876 -c /opt/rocketmq/conf/broker.conf
    depends_on:
      - namesrv
    networks:
      - rocketmq

  console:
    image: styletang/rocketmq-console-ng
    container_name: rmqconsole
    ports:
      - 8180:8080
    environment:
      - JAVA_OPTS=-Drocketmq.namesrv.addr=namesrv:9876
    depends_on:
      - namesrv
    networks:
      - rocketmq

networks:
  rocketmq:
    driver: bridge
"@ | Out-File -FilePath docker-compose-rocketmq.yml -Encoding UTF8

# 启动 RocketMQ
docker-compose -f docker-compose-rocketmq.yml up -d

# 访问控制台: http://localhost:8180
```

**⚠️ 必须使用 Docker,但配置简单**

---

### 9. Redis (Docker Desktop - 推荐)

**⚠️ Redis 官方不支持 Windows,推荐使用 Docker**

```powershell
# 方式一: Docker 单机版 (推荐学习阶段)
docker run -d `
  --name redis `
  -p 6379:6379 `
  redis:7.0

# 方式二: Docker 哨兵模式 (推荐生产环境)
# 创建 docker-compose.yml
@"
version: '3.8'
services:
  redis-master:
    image: redis:7.0
    container_name: redis-master
    ports:
      - 6379:6379
    command: redis-server --appendonly yes

  redis-slave:
    image: redis:7.0
    container_name: redis-slave
    ports:
      - 6380:6379
    command: redis-server --slaveof redis-master 6379 --appendonly yes
    depends_on:
      - redis-master

  redis-sentinel:
    image: redis:7.0
    container_name: redis-sentinel
    ports:
      - 26379:26379
    command: redis-sentinel /etc/redis/sentinel.conf
    depends_on:
      - redis-master
      - redis-slave
"@ | Out-File -FilePath docker-compose-redis.yml -Encoding UTF8

# 启动 Redis 集群
docker-compose -f docker-compose-redis.yml up -d
```

**⚠️ 推荐使用 Docker,也可以用第三方 Windows 版本 (不推荐)**

---

### 10. Seata Server (Windows 原生)

```powershell
# 下载 Seata Server
# 访问: https://github.com/seata/seata/releases
# 下载: seata-server-1.6.1.zip

# 解压
Expand-Archive seata-server-1.6.1.zip

# 配置 application.yml
cd seata-server-1.6.1\conf
notepad application.yml

# 启动 Seata Server (Windows 批处理)
cd ..\bin
.\seata-server.bat

# 默认端口: 8091
```

**✅ Windows 完美支持,官方提供 .bat 脚本**

---

## 📋 推荐部署方案总结

### 学习阶段 (当前)

```yaml
Windows 原生运行:
  ✅ Sentinel Dashboard
  ✅ SkyWalking OAP + UI
  ✅ Prometheus
  ✅ Grafana
  ✅ Elasticsearch
  ✅ Kibana
  ✅ Filebeat
  ✅ Seata Server
  ✅ Nacos
  ✅ MySQL

Docker Desktop 运行:
  ⚠️ RocketMQ (必须)
  ⚠️ Redis (推荐)

总结:
  - 大部分组件可以直接在 Windows 运行
  - 只有 RocketMQ 和 Redis 需要 Docker
  - 安装 Docker Desktop 即可解决
```

### 生产阶段 (未来)

```yaml
建议:
  - 全部迁移到 Linux 服务器
  - 使用 Docker + Kubernetes
  - 但开发阶段在 Windows 完全没问题
```

---

## 🛠️ Docker Desktop 安装指南

### 系统要求

```yaml
Windows 10/11:
  - 64 位处理器
  - 4GB 内存 (推荐 8GB)
  - 启用 Hyper-V 和容器功能
  - 启用 WSL2

检查方法:
  1. 打开 PowerShell (管理员)
  2. 运行: systeminfo
  3. 查看 Hyper-V 要求
```

### 安装步骤

```powershell
# 1. 启用 WSL2
wsl --install

# 2. 下载 Docker Desktop
# 访问: https://www.docker.com/products/docker-desktop/
# 下载: Docker Desktop Installer.exe

# 3. 安装 Docker Desktop
# 双击安装包,按提示安装
# 选择: Use WSL 2 instead of Hyper-V

# 4. 重启电脑

# 5. 启动 Docker Desktop
# 从开始菜单启动 Docker Desktop

# 6. 验证安装
docker --version
docker run hello-world
```

### 配置优化

```yaml
Docker Desktop 设置:
  Resources:
    - CPUs: 4 (根据你的 CPU 核心数)
    - Memory: 4GB (根据你的内存大小)
    - Swap: 1GB
    - Disk image size: 60GB

  General:
    - Start Docker Desktop when you log in: ✅
    - Use WSL 2 based engine: ✅
```

---

## 💡 最佳实践建议

### 开发阶段 (现在)

```yaml
推荐方案:
  1. 安装 Docker Desktop (一次性,30分钟)
  2. RocketMQ 用 Docker 运行
  3. Redis 用 Docker 运行
  4. 其他组件用 Windows 原生运行

优点:
  - 环境一致性好
  - 接近生产环境
  - 易于迁移

资源占用:
  - Docker Desktop: 2-4GB 内存
  - 其他组件: 4-6GB 内存
  - 总计: 6-10GB 内存 (你的电脑应该够用)
```

### 生产阶段 (未来)

```yaml
推荐方案:
  1. 购买 Linux 云服务器 (阿里云/腾讯云)
  2. 全部组件用 Docker 部署
  3. 使用 Kubernetes 编排

优点:
  - 生产级别
  - 高可用
  - 易于扩展
```

---

## ❓ 常见问题

### Q1: 必须安装 Docker Desktop 吗?

```yaml
A1: 
  - RocketMQ: 必须 (官方不支持 Windows)
  - Redis: 强烈推荐 (官方不支持 Windows)
  - 其他组件: 不需要 (都有 Windows 版本)

建议: 安装 Docker Desktop,一劳永逸
```

### Q2: Docker Desktop 占用资源多吗?

```yaml
A2:
  - 默认占用: 2GB 内存
  - 可以调整: 1-4GB 内存
  - 你的电脑应该够用

建议: 分配 2-4GB 内存给 Docker
```

### Q3: 可以不用 Docker 吗?

```yaml
A3:
  - RocketMQ: 不行,必须 Docker 或 Linux
  - Redis: 可以用第三方 Windows 版本,但不推荐

建议: 还是用 Docker,更接近生产环境
```

### Q4: WSL2 是什么?

```yaml
A4:
  - WSL2 = Windows Subsystem for Linux 2
  - 在 Windows 上运行 Linux 子系统
  - Docker Desktop 需要 WSL2

安装: wsl --install (自动安装)
```

### Q5: 性能会受影响吗?

```yaml
A5:
  - Windows 原生组件: 无影响
  - Docker 容器: 轻微影响 (5-10%)
  - 开发阶段: 完全可以接受

建议: 开发阶段用 Windows,生产阶段用 Linux
```

---

## 🎯 总结

### ✅ 可以在 Windows 上完成所有开发

```yaml
结论:
  - 90% 的组件可以直接在 Windows 运行
  - 只有 RocketMQ 和 Redis 需要 Docker
  - 安装 Docker Desktop 即可解决
  - 完全可以在 Windows 上完成所有开发和学习

下一步:
  1. 安装 Docker Desktop (如果还没安装)
  2. 开始集成 Sentinel (不需要 Docker)
  3. 逐步集成其他组件
  4. 遇到问题随时问我
```

### 🚀 立即行动

```powershell
# 1. 检查 Docker Desktop 是否已安装
docker --version

# 如果没安装,执行:
# 2. 启用 WSL2
wsl --install

# 3. 下载并安装 Docker Desktop
# 访问: https://www.docker.com/products/docker-desktop/

# 4. 重启电脑

# 5. 验证安装
docker run hello-world

# 6. 开始集成 Sentinel (不需要 Docker)
```

---

**准备好了吗? 我们可以开始集成第一个组件: Sentinel! 🚀**
