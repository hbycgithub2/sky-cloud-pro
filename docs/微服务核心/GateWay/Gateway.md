# Gateway（应用网关）

---

## 🎯 10秒版 - 面试快答

**核心亮点：**
```
Gateway微服务统一入口，解决三大问题：
1. 前端统一地址(不用记100个服务地址)
2. 统一鉴权(一处验证全局生效)
3. 动态路由(Nacos自动发现，无需重启)
```

**一句话：** Gateway应用网关(10010)，微服务业务层统一入口，负责服务路由、统一鉴权、负载均衡

**更接地气：** Gateway就是微服务的"总机接线员"，前端说找谁，它自动转接到对应服务，还检查你有没有权限

---

## 📋 技术要点 - 工作使用

### 定义
Spring Cloud Gateway应用网关，微服务业务层统一入口，端口10010

### 核心功能
- **服务路由分发**：通过predicates(Path=/user/**)匹配请求路径
- **统一鉴权**：Gateway Filter验证JWT Token，统一拦截未授权请求
- **负载均衡**：uri配置lb://serviceName，结合Nacos实现动态负载均衡
- **限流熔断**：集成Sentinel实现流量控制和服务降级

### 核心价值
```
解决问题1：前端多地址 → 统一入口(一个地址访问所有服务)
解决问题2：重复鉴权 → 统一鉴权(一处验证，100个服务生效)
解决问题3：地址硬编码 → 动态路由(Nacos自动发现，服务上下线无需重启)
解决问题4：单点故障 → 负载均衡(多实例自动切换)
```

### 和Nginx关系
```
Nginx(8005) - 边缘网关层，负责安全防护、静态缓存
Gateway(10010) - 业务网关层，负责服务路由、业务鉴权
```

### 关键配置
```yaml
# gateway/application.yml
server:
  port: 10010

spring:
  application:
    name: gateway
  cloud:
    nacos:
      server-addr: localhost:8848
    gateway:
      routes:
        - id: user-service
          uri: lb://userservice          # lb=负载均衡
          predicates:
            - Path=/user/**               # 路径匹配
        - id: order-service
          uri: lb://orderservice
          predicates:
            - Path=/order/**
```

---

## 🔧 深度解析 - 问题解决

### 实际案例（sky-cloud-pro项目）

**场景：用户查询订单列表**

```
完整流程：
1. 前端请求：localhost:8005/api/order/list (带Token)
2. Nginx接收：去掉/api/前缀，转发到Gateway(10010)
3. Gateway鉴权：
   - 验证Token签名和过期时间
   - 解析userId=123
   - 将userId放入Header传递给后端
4. Gateway路由：
   - 匹配predicates: Path=/order/**
   - 找到routes配置的orderservice
5. Nacos服务发现：
   - 查询orderservice的所有健康实例
   - 返回：[192.168.1.1:8081, 192.168.1.2:8082, 192.168.1.3:8083]
6. 负载均衡：
   - 使用轮询策略选择192.168.1.1:8081
7. 转发请求：
   - 转发到orderservice(8081)
   - Header带上userId=123
8. orderservice处理：
   - 从Header取userId
   - 查询该用户的订单
   - 返回订单列表
9. 原路返回：Gateway → Nginx → 前端
```

### 问题解决（真实踩坑）

**问题1：Token验证逻辑每个服务都要写，代码重复**

解决方案：Gateway写一个GlobalFilter，统一验证Token

```java
@Component
public class AuthFilter implements GlobalFilter {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // 1. 获取Token
        String token = exchange.getRequest().getHeaders().getFirst("Authorization");
        
        // 2. 验证Token
        if (token == null || !JwtUtil.verify(token)) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        
        // 3. 解析userId，传递给后端
        Long userId = JwtUtil.getUserId(token);
        ServerHttpRequest request = exchange.getRequest().mutate()
            .header("userId", userId.toString())
            .build();
        
        // 4. 放行
        return chain.filter(exchange.mutate().request(request).build());
    }
}
```

**问题2：orderservice从8082改到9092，Gateway配置要改**

解决方案：不要写固定地址，用lb://serviceName，Nacos自动发现

```yaml
# ❌ 错误配置（硬编码地址）
uri: http://192.168.1.1:8082

# ✅ 正确配置（动态发现）
uri: lb://orderservice
```

**问题3：某台orderservice挂了，Gateway还往那台发请求**

解决方案：Nacos健康检查，自动剔除故障实例

```yaml
spring:
  cloud:
    nacos:
      discovery:
        heart-beat-interval: 5000      # 5秒心跳
        heart-beat-timeout: 15000      # 15秒超时
```

**问题4：跨域问题，前端请求被拦截**

解决方案：Gateway配置全局跨域

```yaml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
            allowed-origins: "*"
            allowed-methods: "*"
            allowed-headers: "*"
```

**问题5：高并发时Gateway成为瓶颈**

解决方案：部署多台Gateway，Nginx负载均衡

```nginx
# nginx.conf
upstream gateway_backend {
    server 192.168.1.1:10010;
    server 192.168.1.2:10010;
    server 192.168.1.3:10010;
}
```

### 性能数据

```
单台Gateway：
- QPS: 1万+
- 响应时间: 5-10ms（不含后端服务处理时间）
- 并发连接: 1万+

3台Gateway集群：
- QPS: 3万+
- 高可用：一台挂了，自动切换
```

---

## 📝 使用建议

- **面试场景**：只说"10秒版"，面试官追问再说"技术要点"
- **技术文档**：用"技术要点"，简洁专业
- **实际工作**：用"深度解析"，有案例有代码
- **快速查阅**：看"10秒版"和"关键配置"

---

**最后更新：** 2026-01-29  
**适用场景：** 面试、工作、学习
