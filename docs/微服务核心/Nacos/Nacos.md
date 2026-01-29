# Nacos（服务注册与配置中心）

---

## 🎯 10秒版 - 面试快答

**核心亮点：**
```
Nacos微服务注册中心+配置中心，解决三大问题：
1. 服务发现(不用硬编码服务地址)
2. 动态配置(配置变更无需重启)
3. 健康检查(自动剔除故障实例)
```

**一句话：** Nacos服务注册与配置中心(8848)，微服务的"通讯录+配置管理器"，负责服务注册发现、配置管理、健康检查

**更接地气：** Nacos就是微服务的"114查号台+云盘"，服务启动时自动登记地址，其他服务要调用时来查地址，配置文件统一存储随时修改

---

## 📋 技术要点 - 工作使用

### 定义
Alibaba Nacos（Dynamic Naming and Configuration Service），服务注册中心+配置中心，端口8848

### 核心功能
- **服务注册与发现**：服务启动时注册到Nacos，其他服务从Nacos查询服务实例列表
- **配置管理**：统一管理配置文件，支持动态刷新，配置变更无需重启
- **健康检查**：定时心跳检测服务健康状态，自动剔除故障实例
- **负载均衡**：提供服务实例列表，配合LoadBalancer实现负载均衡

### 核心价值
```
解决问题1：服务地址硬编码 → 服务注册发现(动态获取服务地址)
解决问题2：配置文件分散 → 统一配置管理(一处修改全局生效)
解决问题3：配置变更要重启 → 动态刷新(配置变更自动生效)
解决问题4：故障实例无法剔除 → 健康检查(自动剔除故障节点)
```

### 和其他技术关系
```
Nacos(8848) - 注册中心+配置中心，服务注册发现、配置管理
Gateway(10010) - 应用网关，从Nacos获取服务列表进行路由
Feign - HTTP客户端，从Nacos获取服务实例进行调用
```

### 关键配置
```yaml
# application.yml
spring:
  application:
    name: userservice              # 服务名
  cloud:
    nacos:
      server-addr: localhost:8848  # Nacos地址
      discovery:
        namespace: dev               # 命名空间
        group: DEFAULT_GROUP         # 分组
      config:
        file-extension: yaml         # 配置文件格式
        namespace: dev
        group: DEFAULT_GROUP
```

---

## 🔧 深度解析 - 问题解决

### 实际案例（sky-cloud-pro项目）

**场景：orderservice调用userservice查询用户信息**

```
完整流程：
1. userservice启动：
   - 读取配置：spring.application.name=userservice
   - 注册到Nacos：POST http://localhost:8848/nacos/v1/ns/instance
   - 注册信息：{serviceName: "userservice", ip: "192.168.1.1", port: 8001}
   - 开启心跳：每5秒发送一次心跳到Nacos

2. orderservice启动：
   - 同样注册到Nacos：{serviceName: "orderservice", ip: "192.168.1.2", port: 8081}
   - 开启心跳

3. orderservice调用userservice：
   - Feign调用：userClient.getUserById(123)
   - 查询Nacos：GET http://localhost:8848/nacos/v1/ns/instance/list?serviceName=userservice
   - Nacos返回：[{ip: "192.168.1.1", port: 8001, healthy: true}]
   - LoadBalancer负载均衡：选择192.168.1.1:8001
   - 发送请求：GET http://192.168.1.1:8001/user/123

4. Nacos健康检查：
   - userservice每5秒发送心跳
   - 如果15秒未收到心跳，标记为不健康
   - 如果30秒未收到心跳，从实例列表剔除

5. 配置动态刷新：
   - orderservice从Nacos读取配置：dataId=orderservice-dev.yaml
   - 配置变更：在Nacos控制台修改配置
   - Nacos推送变更：通知orderservice配置已更新
   - orderservice刷新配置：@RefreshScope注解的Bean自动刷新
```

### 问题解决（真实踩坑）

**问题1：服务地址硬编码，服务迁移要改代码**

问题流程：
```
硬编码地址 → 服务迁移 → 修改代码 → 重新发布
```

解决方案：使用Nacos服务注册与发现

解决流程：
```
问题前：
orderservice → 硬编码 http://192.168.1.1:8001/user/123
userservice迁移到192.168.1.2:8002 → orderservice要改代码重新发布

问题后：
orderservice → Nacos查询userservice → 返回最新地址192.168.1.2:8002
userservice迁移 → 只需重启注册到Nacos → orderservice自动获取新地址
```

关键代码：
```yaml
# orderservice配置
spring:
  cloud:
    nacos:
      server-addr: localhost:8848

# Feign客户端
@FeignClient(value = "userservice")  # 服务名，不是地址
public interface UserClient {
    @GetMapping("/user/{id}")
    User getUserById(@PathVariable("id") Long id);
}
```

---

**问题2：配置文件分散在各个服务，修改配置要改100个地方**

问题流程：
```
配置分散 → 修改配置 → 改100个服务 → 重启100个服务
```

解决方案：使用Nacos配置中心统一管理

解决流程：
```
问题前：
数据库地址配置在100个服务的application.yml → 数据库迁移 → 改100个文件 → 重启100个服务

问题后：
配置统一存储在Nacos → 数据库迁移 → 只改Nacos一处配置 → 自动推送到100个服务 → 无需重启
```

关键代码：
```yaml
# bootstrap.yml（优先级高于application.yml）
spring:
  application:
    name: orderservice
  cloud:
    nacos:
      config:
        server-addr: localhost:8848
        file-extension: yaml
        namespace: dev
        group: DEFAULT_GROUP

# Nacos配置中心创建配置文件：orderservice-dev.yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/order_db
    username: root
    password: 123456
```

---

**问题3：配置变更要重启服务，影响业务**

问题流程：
```
修改配置 → 重启服务 → 服务不可用 → 影响业务
```

解决方案：使用@RefreshScope动态刷新配置

解决流程：
```
问题前：
修改配置 → 重启服务 → 服务不可用5分钟 → 用户无法下单

问题后：
修改Nacos配置 → Nacos推送变更 → @RefreshScope自动刷新 → 无需重启 → 用户无感知
```

关键代码：
```java
@RestController
@RefreshScope  // 支持动态刷新
public class OrderController {
    
    @Value("${order.max-count}")
    private Integer maxCount;  // 从Nacos读取，支持动态刷新
    
    @GetMapping("/order/create")
    public String createOrder() {
        if (orderCount > maxCount) {
            return "超过最大订单数：" + maxCount;
        }
        // 创建订单
        return "订单创建成功";
    }
}
```

### 性能数据

```
单机Nacos：
- 服务注册：1000+ TPS
- 服务查询：10000+ QPS
- 配置读取：5000+ QPS
- 支持服务数：1000+

Nacos集群（3节点）：
- 服务注册：3000+ TPS
- 服务查询：30000+ QPS
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
