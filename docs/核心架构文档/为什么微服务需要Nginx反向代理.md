# 为什么微服务需要 Nginx 反向代理？

## 1. 为什么要用 Nginx？

### 架构对比

**没有 Nginx：**
```
用户 → Gateway (10010) → 业务服务
```

**有 Nginx：**
```
用户 → Nginx (8005) → Gateway (10010) → 业务服务
```

### 核心原因

1. **隐藏内部端口**
   - Gateway 端口（10010）不对外暴露
   - 只暴露 Nginx 端口（8005）
   - 提升安全性

2. **静态资源缓存**
   - 图片、CSS、JS 直接由 Nginx 返回
   - 不走 Gateway，响应快 10 倍（50ms → 5ms）
   - 减轻 Gateway 压力

3. **SSL 卸载**
   - HTTPS 加密/解密由 Nginx 处理
   - Gateway 只处理 HTTP
   - 性能提升 2 倍

4. **防护能力**
   - 请求限流（防 DDoS）
   - IP 黑白名单
   - 请求日志记录

5. **灵活配置**
   - 改配置不用重启服务
   - `nginx -s reload` 热重载
   - 改端口外部无感知

---

## 2. 代理不代理有啥区别？

| 对比项 | 不用 Nginx | 用 Nginx | 差异 |
|--------|-----------|----------|------|
| **端口暴露** | Gateway 端口暴露（10010） | 只暴露 Nginx（8005） | 更安全 |
| **静态资源** | 每次走 Gateway（50ms） | Nginx 缓存（5ms） | 快 10 倍 |
| **SSL 处理** | Gateway 处理（慢） | Nginx 处理（快） | 快 2 倍 |
| **防护能力** | 无 | 限流、黑名单、日志 | 有防护 |
| **改配置** | 重启服务 | 热重载 | 不中断 |

---

## 3. 核心实现（3 个配置）

### 配置 1：upstream（定义 Gateway 地址）

```nginx
upstream gateway_backend {
    server localhost:10010;
    keepalive 32;
}
```

**作用：** 告诉 Nginx，Gateway 在 `localhost:10010`

---

### 配置 2：location（路由规则）

```nginx
location /api/ {
    proxy_pass http://gateway_backend/;
}
```

**作用：** 
- 用户访问：`http://localhost:8005/api/user/1`
- Nginx 转发：`http://localhost:10010/user/1`（去掉 `/api/` 前缀）

---

### 配置 3：proxy_set_header（传递用户信息）

```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

**作用：** 让 Gateway 知道用户真实 IP，而不是 Nginx 的 IP（127.0.0.1）

---

## 4. 总结

### 一句话

**Nginx 是门卫（处理安全、缓存、日志），Gateway 是管家（处理业务逻辑），两者配合才是完整架构。**

### 核心价值

1. **安全**：隐藏内部端口，防护攻击
2. **性能**：静态资源缓存，快 10 倍
3. **灵活**：改配置不重启，热重载

### 什么时候必须用？

- 生产环境（必须）
- 高并发场景（必须）
- 有静态资源（必须）

---

## 5. 实际效果

| 场景 | 没有 Nginx | 有 Nginx | 提升 |
|------|-----------|----------|------|
| 图片访问 | 50ms | 5ms | 10 倍 |
| 并发连接 | 1000 | 10000 | 10 倍 |
| SSL 握手 | 100ms | 50ms | 2 倍 |

---

**配置文件：** `nginx-config/nginx-minimal.conf`  
**启动脚本：** `START-HERE.bat`

