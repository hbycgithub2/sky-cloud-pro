# Nginx（反向代理服务器）- 详细版

> 完整的5层递进结构，包含所有细节、问题解决、性能数据

---

## 📋 版本说明

- **Nginx.md** - 精简版（面试/快速查阅）
- **Nginx-详细版.md** - 本文件（深入学习/完整参考）

---

## 【版本A - 极简核心】终极版

### 第1层：主旨（核心中的核心）

```
Nginx反向代理服务器，边缘网关层统一入口，解决内部端口暴露和静态资源性能问题
端口8005，配置upstream定义后端，location转发规则，静态资源缓存30天
```

### 第2层：核心价值

```
隐藏内部端口(只暴露8005) + 静态缓存(快10倍) + 负载均衡(高可用) + SSL卸载(性能提升)
```

### 第3层：实际案例（你的项目）

**场景：用户访问订单列表**

```
流程：
1. 用户请求：localhost:8005/api/order/list (带Token)
2. Nginx接收：监听8005端口
3. Nginx匹配：location /api/ 规则
4. Nginx转发：去掉/api/，转到Gateway(10010)
5. Nginx传递：X-Real-IP（用户真实IP）
6. Gateway处理：验证Token，路由到orderservice
7. 返回数据：Gateway → Nginx → 用户
8. Nginx记录：access.log记录请求日志
```

### 第4层：问题解决

**问题1：跨域问题，前端请求被拦截**
```
解决：Nginx配置全局跨域
add_header Access-Control-Allow-Origin * always;
```

**问题2：静态资源每次都走后端，慢**
```
解决：Nginx缓存静态资源30天
location ~* \.(jpg|png|css|js)$ {
    expires 30d;
}
```

**问题3：Gateway单点故障**
```
解决：Nginx负载均衡到多台Gateway
upstream gateway_backend {
    server 192.168.1.1:10010;
    server 192.168.1.2:10010;
    server 192.168.1.3:10010;
}
```

### 第5层：关键配置

```nginx
# nginx.conf
upstream gateway_backend {
    server localhost:10010;
}
server {
    listen 8005;
    location /api/ {
        proxy_pass http://gateway_backend/;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location ~* \.(jpg|png|css|js)$ {
        expires 30d;
    }
}
```

---

## 【版本B - 技术准确】终极版

### 第1层：主旨（核心中的核心）

```
Nginx高性能反向代理服务器，C语言实现，基于事件驱动异步非阻塞架构
边缘网关层统一入口，核心功能：反向代理、静态缓存、负载均衡、SSL卸载、安全防护
端口8005，通过upstream定义后端服务，location匹配转发规则，支持热重载
```

### 第2层：核心价值

```
解决问题1：内部端口暴露 → 只暴露8005，Gateway(10010)不对外，提升安全性
解决问题2：静态资源性能差 → Nginx缓存30天，直接返回，响应快10倍(50ms→5ms)
解决问题3：单点故障 → 负载均衡到多台Gateway，一台挂了自动切换，高可用
解决问题4：HTTPS性能差 → SSL卸载，Nginx处理加密解密，Gateway只处理HTTP，性能提升2倍
解决问题5：配置变更要重启 → 热重载(nginx -s reload)，不中断服务
```

### 第3层：实际案例（你的项目）

**场景：用户访问订单列表（完整流程）**

```
1. 用户浏览器：
   - 发起请求：http://localhost:8005/api/order/list
   - Header: Authorization: Bearer eyJhbGc...
   - Method: GET

2. Nginx接收(8005端口)：
   - worker进程接收连接
   - 解析HTTP请求
   - 匹配server块(listen 8005)

3. Nginx匹配location：
   - 匹配规则：location /api/
   - 匹配成功，执行proxy_pass

4. Nginx转发处理：
   - 去掉/api/前缀
   - 目标URL：http://localhost:10010/order/list
   - 添加Header：
     * Host: localhost
     * X-Real-IP: 192.168.1.100（用户真实IP）
     * X-Forwarded-For: 192.168.1.100
   - 从upstream gateway_backend选择一台Gateway

5. Nginx转发到Gateway：
   - 建立连接：localhost:10010
   - 发送请求：GET /order/list
   - 传递所有Header（包含Token）

6. Gateway处理：
   - 验证Token
   - 匹配路由/order/**
   - 转发到orderservice

7. 数据返回：
   - orderservice → Gateway → Nginx → 用户
   - Nginx记录access.log：
     * 请求时间
     * 响应状态码
     * 响应时间
     * 上游响应时间

8. Nginx日志示例：
192.168.1.100 - - [29/Jan/2026:10:30:45 +0800] "GET /api/order/list HTTP/1.1" 
200 1024 "-" "Mozilla/5.0" "-" rt=0.050 uct="0.001" uht="0.002" urt="0.047"
```

### 第4层：问题解决

**问题1：跨域问题，前端请求被浏览器拦截**

解决：Nginx配置全局跨域

```nginx
server {
    listen 8005;
    
    # 跨域配置
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization" always;
    
    # OPTIONS请求直接返回204
    if ($request_method = 'OPTIONS') {
        return 204;
    }
}
```

**问题2：静态资源每次都走后端，响应慢**

解决：Nginx配置静态资源缓存

```nginx
# 静态资源缓存
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    root html;                                    # 静态资源目录
    expires 30d;                                  # 缓存30天
    add_header Cache-Control "public, immutable"; # 浏览器缓存
    access_log off;                               # 不记录日志
}
```

效果对比：
```
未缓存：
- 请求 → Nginx → Gateway → 后端服务 → 返回
- 响应时间：50ms

已缓存：
- 请求 → Nginx直接返回
- 响应时间：5ms
- 提升：10倍
```

**问题3：Gateway单点故障，挂了全挂**

解决：Nginx负载均衡到多台Gateway

```nginx
upstream gateway_backend {
    server 192.168.1.1:10010 weight=1 max_fails=3 fail_timeout=30s;
    server 192.168.1.2:10010 weight=1 max_fails=3 fail_timeout=30s;
    server 192.168.1.3:10010 weight=1 max_fails=3 fail_timeout=30s;
    keepalive 32;  # 保持32个长连接
}
```

负载均衡策略：
```
1. 轮询（默认）：1→2→3→1→2→3
2. 权重：weight=2的处理2倍请求
3. IP哈希：同一IP永远访问同一台（保持会话）
4. 最少连接：选择连接数最少的
```

**问题4：改配置要重启Nginx，服务中断**

解决：热重载，不中断服务

```bash
# 1. 修改nginx.conf

# 2. 测试配置是否正确
nginx -t

# 3. 热重载配置（不中断服务）
nginx -s reload

# 4. 查看Nginx进程
ps aux | grep nginx
```

热重载原理：
```
1. master进程收到reload信号
2. 加载新配置，启动新worker进程
3. 新请求由新worker处理
4. 旧worker处理完当前请求后退出
5. 平滑过渡，用户无感知
```

**问题5：Gateway不知道用户真实IP，只看到127.0.0.1**

解决：Nginx传递真实IP

```nginx
location /api/ {
    proxy_pass http://gateway_backend/;
    
    # 传递用户真实IP
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Gateway获取真实IP：
```java
// Gateway Filter中获取
String realIp = exchange.getRequest().getHeaders().getFirst("X-Real-IP");
```

**问题6：请求超时，Gateway处理慢**

解决：Nginx配置超时时间

```nginx
location /api/ {
    proxy_pass http://gateway_backend/;
    
    # 超时设置
    proxy_connect_timeout 60s;  # 连接超时
    proxy_send_timeout 60s;     # 发送超时
    proxy_read_timeout 60s;     # 读取超时
}
```

**问题7：需要限流，防止DDoS攻击**

解决：Nginx配置限流

```nginx
# 定义限流规则（每秒100个请求）
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;

server {
    location /api/ {
        # 应用限流规则
        limit_req zone=api_limit burst=200 nodelay;
        proxy_pass http://gateway_backend/;
    }
}
```

### 第5层：关键配置

**完整配置文件：**

```nginx
# nginx.conf

# 用户和工作进程
worker_processes  auto;  # 自动检测CPU核心数

# 错误日志
error_log  logs/error.log  warn;
pid        logs/nginx.pid;

# 事件模块
events {
    worker_connections  10240;  # 每个worker最大连接数
    use epoll;                  # Linux使用epoll
}

# HTTP模块
http {
    include       mime.types;
    default_type  application/octet-stream;

    # 日志格式
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      'rt=$request_time uct="$upstream_connect_time" '
                      'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log  logs/access.log  main;

    # 性能优化
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;

    # Gzip压缩
    gzip  on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # 限流配置
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;

    # 上游服务器（Gateway）
    upstream gateway_backend {
        server localhost:10010 weight=1 max_fails=3 fail_timeout=30s;
        # server 192.168.1.2:10010 weight=1 max_fails=3 fail_timeout=30s;
        # server 192.168.1.3:10010 weight=1 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # HTTP服务器
    server {
        listen       8005;
        server_name  localhost;
        charset utf-8;
        access_log  logs/host.access.log  main;

        # 跨域配置
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization" always;

        # OPTIONS请求直接返回
        if ($request_method = 'OPTIONS') {
            return 204;
        }

        # 根路径
        location / {
            root   html;
            index  index.html index.htm;
        }

        # 静态资源缓存
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            root   html;
            expires 30d;
            add_header Cache-Control "public, immutable";
            access_log off;
        }

        # API请求转发到Gateway
        location /api/ {
            # 限流
            limit_req zone=api_limit burst=200 nodelay;
            
            # 转发
            proxy_pass http://gateway_backend/;
            
            # 代理头设置
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # 超时设置
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            # HTTP 1.1支持
            proxy_http_version 1.1;
            proxy_set_header Connection "";
        }

        # 健康检查
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # 错误页面
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

**性能数据：**

```
单台Nginx性能：
- QPS: 10万+
- 响应时间: 1-2ms（静态资源）
- 并发连接: 10万+
- CPU占用: 10-20%
- 内存占用: 50-100MB

静态资源缓存效果：
- 未缓存：50ms（走Gateway+后端）
- 已缓存：5ms（Nginx直接返回）
- 提升：10倍

3台Gateway负载均衡：
- QPS: 3万+（Gateway限制）
- 高可用：一台挂了，自动切换
- 响应时间：无明显增加
```

---

## 【版本C - 实战场景】终极版

### 第1层：主旨（核心中的核心）

```
Nginx(8005)接收请求 → 匹配location规则 → 转发到Gateway(10010) → 传递真实IP
```

### 第2层：核心价值

```
统一入口 + 静态缓存 + 负载均衡 + 安全防护
```

### 第3层：实际案例（你的项目完整流程）

**用户操作：点击"我的订单"按钮**

**前端代码：**
```javascript
axios.get('http://localhost:8005/api/order/list', {
  headers: { Authorization: 'Bearer ' + token }
})
```

**请求流程：**
```
1. 浏览器发起请求 → Nginx(8005)
2. Nginx匹配location /api/ → 去掉/api/前缀
3. Nginx转发到Gateway(10010) → 传递X-Real-IP
4. Gateway验证Token → 匹配路由/order/**
5. Gateway转发到orderservice(8081)
6. orderservice查询订单 → 返回数据
7. 原路返回 → 前端显示订单列表
```

### 第4层：问题解决（真实踩坑）

**坑1：跨域问题，前端请求被拦截**
```
解决：Nginx配置全局跨域
add_header Access-Control-Allow-Origin * always;
```

**坑2：静态资源每次都走后端，慢**
```
解决：Nginx缓存静态资源30天
location ~* \.(jpg|png|css|js)$ { expires 30d; }
```

**坑3：Gateway挂了，全部请求失败**
```
解决：Nginx负载均衡到多台Gateway
upstream gateway_backend {
    server 192.168.1.1:10010;
    server 192.168.1.2:10010;
    server 192.168.1.3:10010;
}
```

**坑4：改配置要重启，服务中断**
```
解决：热重载，不中断服务
nginx -s reload
```

### 第5层：关键配置（拿来就用）

```nginx
upstream gateway_backend {
    server localhost:10010;
}
server {
    listen 8005;
    location /api/ {
        proxy_pass http://gateway_backend/;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 🔄 完整请求流程图

```
用户浏览器
  ↓ http://localhost:8005/api/order/list
  ↓ Header: Authorization: Bearer xxx
  
Nginx (8005)
  ↓ worker进程接收连接
  ↓ 匹配server块(listen 8005)
  ↓ 匹配location /api/
  ↓ 去掉/api/前缀
  ↓ 添加Header: X-Real-IP
  ↓ 从upstream选择一台Gateway
  ↓ 转发到 http://localhost:10010/order/list
  
Gateway (10010)
  ↓ 验证Token
  ↓ 匹配路由/order/**
  ↓ 从Nacos查询orderservice
  ↓ 负载均衡选择一台
  ↓ 转发到orderservice(8081)
  
orderservice (8081)
  ↓ 从Header取userId
  ↓ 查询订单数据
  ↓ 返回订单列表
  
原路返回
  ↓ orderservice → Gateway → Nginx → 用户浏览器
  ↓ Nginx记录access.log
  ↓ 前端显示订单列表
```

---

## 📊 性能对比

### 没有Nginx vs 有Nginx

| 对比项 | 没有Nginx | 有Nginx | 差异 |
|--------|-----------|---------|------|
| 端口暴露 | Gateway(10010)暴露 | 只暴露Nginx(8005) | 更安全 |
| 静态资源 | 每次走Gateway(50ms) | Nginx缓存(5ms) | 快10倍 |
| SSL处理 | Gateway处理(慢) | Nginx处理(快) | 快2倍 |
| 负载均衡 | 需要Gateway集群 | Nginx+Gateway双层 | 更灵活 |
| 配置变更 | 重启服务 | 热重载 | 不中断 |

### Nginx性能数据

| 指标 | 单台Nginx | 3台Gateway集群 |
|------|-----------|---------------|
| QPS | 10万+ | 3万+（Gateway限制） |
| 响应时间 | 1-2ms（静态） | 5-10ms（动态） |
| 并发连接 | 10万+ | 3万+ |
| 可用性 | 单点 | 高可用 |

---

## 🎯 使用建议

### 什么时候看精简版（Nginx.md）
- 面试前快速复习
- 日常快速查阅
- 只需要核心概念

### 什么时候看详细版（本文件）
- 深入学习Nginx原理
- 实际项目配置Nginx
- 遇到问题需要解决方案
- 需要完整的配置示例

---

## 📝 补充说明

### 和Gateway的关系
```
Nginx(8005) - 边缘网关层
- 职责：安全防护、静态缓存、SSL卸载、负载均衡
- 位置：最外层，对外暴露
- 语言：C语言，高性能

Gateway(10010) - 业务网关层
- 职责：服务路由、业务鉴权、限流熔断
- 位置：内层，不对外暴露
- 语言：Java，Spring Cloud Gateway
```

### 技术栈
```
- Nginx 1.20+
- C语言实现
- 事件驱动异步非阻塞架构
- epoll（Linux）/ kqueue（BSD）
```

### 常用命令
```bash
# 启动
nginx

# 停止
nginx -s stop

# 热重载
nginx -s reload

# 测试配置
nginx -t

# 查看版本
nginx -v

# 查看进程
ps aux | grep nginx
```

---

**最后更新：** 2026-01-29  
**适用场景：** 深入学习、实际开发、问题解决  
**配套文件：** Nginx.md（精简版）
