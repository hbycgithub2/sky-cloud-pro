# Nginx（反向代理服务器）

---

## 🎯 10秒版 - 面试快答

**核心亮点：**
```
Nginx反向代理，解决三大问题：
1. 隐藏内部端口（只暴露8005，Gateway的10010不对外）
2. 静态资源缓存（图片/CSS/JS直接返回，快10倍）
3. 安全防护（限流、黑名单、SSL卸载）
```

**一句话：** Nginx反向代理服务器，边缘网关层统一入口，负责安全防护、静态缓存、负载均衡，端口8005

**更接地气：** Nginx就是微服务的"大门"，所有请求从这进，内部服务藏起来，外面看不到，防护攻击

---

## 📋 技术要点 - 工作使用

### 定义
Nginx高性能反向代理服务器，C语言实现，边缘网关层统一入口，端口8005

### 核心功能
- **反向代理**：接收用户请求，转发到Gateway(10010)，隐藏内部服务
- **静态缓存**：图片/CSS/JS直接返回，不走后端，响应快10倍（50ms→5ms）
- **负载均衡**：多台Gateway分流，upstream配置，支持轮询/权重/IP哈希
- **安全防护**：限流防DDoS、IP黑白名单、SSL卸载、请求日志记录

### 核心价值
```
解决问题1：内部端口暴露 → 只暴露8005，Gateway(10010)不对外，提升安全
解决问题2：静态资源慢 → Nginx缓存30天，直接返回，快10倍
解决问题3：单点故障 → 负载均衡到多台Gateway，高可用
解决问题4：HTTPS性能差 → SSL卸载，Nginx处理加密，Gateway只处理HTTP
```

### 和Gateway关系
```
Nginx(8005) - 边缘网关层，负责安全防护、静态缓存、SSL卸载
Gateway(10010) - 业务网关层，负责服务路由、业务鉴权、负载均衡

请求流程：
用户 → Nginx(8005) → Gateway(10010) → 微服务
```

### 关键配置
```nginx
# nginx.conf

# 1. 定义Gateway地址
upstream gateway_backend {
    server localhost:10010;
    keepalive 32;
}

# 2. 监听8005端口
server {
    listen 8005;
    
    # 3. API请求转发到Gateway
    location /api/ {
        proxy_pass http://gateway_backend/;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 4. 静态资源缓存
    location ~* \.(jpg|png|css|js)$ {
        root html;
        expires 30d;
    }
}
```

---

## 🔧 深度解析 - 问题解决

### 实际案例（sky-cloud-pro项目）

**场景：用户访问订单列表**

```
完整流程：
1. 用户请求：http://localhost:8005/api/order/list (带Token)
2. Nginx接收：监听8005端口，接收请求
3. Nginx匹配：location /api/ 规则匹配成功
4. Nginx转发：
   - 去掉/api/前缀
   - 转发到upstream gateway_backend (localhost:10010)
   - 添加Header: X-Real-IP（用户真实IP）
   - 转发URL: http://localhost:10010/order/list
5. Gateway处理：验证Token，路由到orderservice
6. 返回数据：原路返回 Gateway → Nginx → 用户
7. Nginx记录：access.log记录请求日志
```

### 问题解决（真实踩坑）

**问题1：跨域问题，前端请求被浏览器拦截**

解决方案：Nginx配置全局跨域

```nginx
server {
    # 跨域配置
    add_header Access-Control-Allow-Origin * always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    
    # OPTIONS请求直接返回
    if ($request_method = 'OPTIONS') {
        return 204;
    }
}
```

**问题2：静态资源每次都走后端，慢**

解决方案：Nginx配置静态资源缓存

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
    root html;
    expires 30d;                          # 缓存30天
    add_header Cache-Control "public, immutable";
    access_log off;                       # 不记录日志
}
```

**问题3：Gateway单点故障，挂了全挂**

解决方案：Nginx负载均衡到多台Gateway

```nginx
upstream gateway_backend {
    server 192.168.1.1:10010 weight=1;    # 权重1
    server 192.168.1.2:10010 weight=1;
    server 192.168.1.3:10010 weight=1;
    keepalive 32;
}
```

**问题4：改配置要重启Nginx，服务中断**

解决方案：热重载，不中断服务

```bash
# 测试配置是否正确
nginx -t

# 热重载配置（不中断服务）
nginx -s reload
```

**问题5：Gateway不知道用户真实IP，只看到127.0.0.1**

解决方案：Nginx传递真实IP

```nginx
location /api/ {
    proxy_pass http://gateway_backend/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### 性能数据

```
单台Nginx：
- QPS: 10万+
- 响应时间: 1-2ms（静态资源）
- 并发连接: 10万+

静态资源缓存效果：
- 未缓存：50ms（走Gateway+后端）
- 已缓存：5ms（Nginx直接返回）
- 提升：10倍

3台Gateway负载均衡：
- QPS: 3万+（Gateway限制）
- 高可用：一台挂了，自动切换
```

---

## 📝 使用建议

- **面试场景**：只说"10秒版"，面试官追问再说"技术要点"
- **技术文档**：用"技术要点"，简洁专业
- **实际工作**：用"深度解析"，有案例有配置
- **快速查阅**：看"10秒版"和"关键配置"

---

**最后更新：** 2026-01-29  
**适用场景：** 面试、工作、学习  
**配套文件：** Nginx-详细版.md
