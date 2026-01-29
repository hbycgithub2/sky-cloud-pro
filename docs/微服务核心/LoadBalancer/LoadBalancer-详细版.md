# LoadBalancer（负载均衡器）- 详细版

> 完整的5层递进结构，包含所有细节、问题解决、性能数据

---

## 📋 版本说明

- **LoadBalancer.md** - 精简版（面试/快速查阅）
- **LoadBalancer-详细版.md** - 本文件（深入学习/完整参考）

---

## 【版本A - 极简核心】终极版

### 第1层：主旨（核心中的核心）

```
LoadBalancer客户端负载均衡器，从Nacos获取实例列表，按策略选择一个实例进行调用
替代Ribbon，集成在Feign和RestTemplate中，支持轮询、随机、权重等策略
```

### 第2层：核心价值

```
多实例分流(流量均匀分配) + 智能选择(按策略自动选择) + 故障转移(自动剔除故障实例)
```

### 第3层：实际案例（你的项目）

**场景：orderservice调用userservice，userservice有3个实例**

```
流程：
1. userservice启动3个实例：192.168.1.1:8001, 192.168.1.2:8001, 192.168.1.3:8001
2. 都注册到Nacos
3. orderservice调用：userClient.getUserById(123)
4. Feign查询Nacos：获取userservice实例列表[实例1, 实例2, 实例3]
5. LoadBalancer轮询：第1次选实例1，第2次选实例2，第3次选实例3
6. 发送请求：GET http://192.168.1.1:8001/user/123
7. 故障转移：实例2挂了，Nacos标记不健康，LoadBalancer只选[实例1, 实例3]
```

### 第4层：问题解决

**问题1：所有请求都打到一台服务器，其他服务器闲置**
```
解决：LoadBalancer轮询策略，流量均匀分配到3台服务器
```

**问题2：性能好的服务器和性能差的服务器处理相同请求**
```
解决：使用权重策略，性能好的服务器权重高，处理更多请求
```

**问题3：某台服务器挂了，还往那台发请求**
```
解决：Nacos健康检查，LoadBalancer只选健康实例
```

### 第5层：关键配置

```yaml
# application.yml
spring:
  cloud:
    loadbalancer:
      ribbon:
        enabled: false
      cache:
        enabled: true
        ttl: 35s
```

---

## 【版本B - 技术准确】终极版

### 第1层：主旨（核心中的核心）

```
Spring Cloud LoadBalancer客户端负载均衡器，基于Reactor响应式编程
核心功能：实例选择、负载均衡策略、健康检查、缓存机制
替代Netflix Ribbon，集成在Feign和RestTemplate中，支持轮询、随机、权重等策略
```

### 第2层：核心价值

```
解决问题1：单实例压力大 → 多实例分流(流量均匀分配到多台服务器)
解决问题2：手动选择实例 → 自动选择(按策略智能选择最优实例)
解决问题3：故障实例影响调用 → 自动剔除(只选择健康实例)
解决问题4：频繁查询Nacos → 缓存机制(减少对Nacos的查询)
```

### 第3层：实际案例（你的项目）

**场景：订单服务调用用户服务，用户服务有3个实例**

```
1. userservice启动3个实例：
   - 实例1：192.168.1.1:8001，权重1.0
   - 实例2：192.168.1.2:8001，权重1.0
   - 实例3：192.168.1.3:8001，权重2.0（性能好）
   - 都注册到Nacos

2. orderservice调用userservice：
   - Feign调用：userClient.getUserById(123)
   - Feign触发LoadBalancer

3. LoadBalancer工作流程：
   - 查询缓存：检查本地缓存是否有userservice实例列表
   - 缓存未命中：从Nacos查询实例列表
   - Nacos返回：[
       {ip: "192.168.1.1", port: 8001, healthy: true, weight: 1.0},
       {ip: "192.168.1.2", port: 8001, healthy: true, weight: 1.0},
       {ip: "192.168.1.3", port: 8001, healthy: true, weight: 2.0}
     ]
   - 过滤不健康实例：保留healthy=true的实例
   - 缓存实例列表：缓存35秒（默认TTL）

4. 负载均衡策略（轮询）：
   - 第1次调用：选择实例1 (192.168.1.1:8001)
   - 第2次调用：选择实例2 (192.168.1.2:8001)
   - 第3次调用：选择实例3 (192.168.1.3:8001)
   - 第4次调用：选择实例1 (192.168.1.1:8001)
   - 循环往复，流量均匀分配

5. 负载均衡策略（权重）：
   - 实例1权重1.0：处理25%请求
   - 实例2权重1.0：处理25%请求
   - 实例3权重2.0：处理50%请求
   - 性能好的服务器处理更多请求

6. 故障转移：
   - 实例2挂了，停止发送心跳
   - Nacos 15秒后标记实例2为不健康
   - LoadBalancer下次查询时，Nacos返回：[实例1, 实例3]
   - LoadBalancer只在[实例1, 实例3]中选择
   - 第1次调用：选择实例1
   - 第2次调用：选择实例3
   - 第3次调用：选择实例1
   - 自动剔除故障实例，用户无感知

7. 缓存更新：
   - 缓存35秒后过期
   - 下次调用时重新从Nacos查询
   - 获取最新的实例列表
```

### 第4层：问题解决

**问题1：所有请求都打到一台服务器，其他服务器闲置**

解决：使用LoadBalancer轮询策略（默认）

```java
// 默认就是轮询策略，无需额外配置
@FeignClient(value = "userservice")
public interface UserClient {
    @GetMapping("/user/{id}")
    User getUserById(@PathVariable("id") Long id);
}

// 如果想自定义策略，可以配置
@Configuration
public class LoadBalancerConfig {
    
    @Bean
    public ReactorLoadBalancer<ServiceInstance> randomLoadBalancer(
        Environment environment,
        LoadBalancerClientFactory loadBalancerClientFactory
    ) {
        String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
        return new RandomLoadBalancer(
            loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class),
            name
        );
    }
}
```

**问题2：想让性能好的服务器多处理请求，性能差的少处理**

解决：使用Nacos权重策略

```yaml
# 性能好的服务器配置
spring:
  cloud:
    nacos:
      discovery:
        weight: 2.0  # 权重2.0，处理更多请求

# 性能差的服务器配置
spring:
  cloud:
    nacos:
      discovery:
        weight: 1.0  # 权重1.0，处理较少请求
```

```java
// 自定义权重负载均衡器
@Configuration
public class NacosWeightLoadBalancerConfig {
    
    @Bean
    public ReactorLoadBalancer<ServiceInstance> nacosWeightLoadBalancer(
        Environment environment,
        LoadBalancerClientFactory loadBalancerClientFactory
    ) {
        String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
        return new NacosLoadBalancer(
            loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class),
            name
        );
    }
}
```

**问题3：某台服务器挂了，还往那台发请求，报错**

解决：Nacos健康检查 + LoadBalancer过滤不健康实例

```yaml
# Nacos健康检查配置
spring:
  cloud:
    nacos:
      discovery:
        heart-beat-interval: 5000      # 5秒心跳
        heart-beat-timeout: 15000      # 15秒超时
        ip-delete-timeout: 30000       # 30秒删除
```

**问题4：频繁查询Nacos，增加Nacos压力**

解决：开启LoadBalancer缓存

```yaml
spring:
  cloud:
    loadbalancer:
      cache:
        enabled: true                  # 开启缓存
        ttl: 35s                       # 缓存35秒
        capacity: 256                  # 缓存容量
```

**问题5：想实现自定义负载均衡策略（如：同机房优先）**

解决：自定义LoadBalancer实现

```java
public class SameZoneLoadBalancer implements ReactorServiceInstanceLoadBalancer {
    
    private final ObjectProvider<ServiceInstanceListSupplier> serviceInstanceListSupplierProvider;
    private final String serviceId;
    
    @Override
    public Mono<Response<ServiceInstance>> choose(Request request) {
        ServiceInstanceListSupplier supplier = serviceInstanceListSupplierProvider
            .getIfAvailable(NoopServiceInstanceListSupplier::new);
        
        return supplier.get(request).next()
            .map(serviceInstances -> processInstanceResponse(serviceInstances));
    }
    
    private Response<ServiceInstance> processInstanceResponse(
        List<ServiceInstance> instances
    ) {
        if (instances.isEmpty()) {
            return new EmptyResponse();
        }
        
        // 获取当前服务所在机房
        String currentZone = getCurrentZone();
        
        // 优先选择同机房的实例
        List<ServiceInstance> sameZoneInstances = instances.stream()
            .filter(instance -> currentZone.equals(instance.getMetadata().get("zone")))
            .collect(Collectors.toList());
        
        if (!sameZoneInstances.isEmpty()) {
            // 同机房有实例，从同机房中随机选择
            int index = ThreadLocalRandom.current().nextInt(sameZoneInstances.size());
            return new DefaultResponse(sameZoneInstances.get(index));
        }
        
        // 同机房没有实例，从所有实例中随机选择
        int index = ThreadLocalRandom.current().nextInt(instances.size());
        return new DefaultResponse(instances.get(index));
    }
}
```

### 第5层：关键配置

**完整配置文件：**

```yaml
# application.yml
spring:
  application:
    name: orderservice
  cloud:
    nacos:
      server-addr: localhost:8848
      discovery:
        namespace: dev
        weight: 1.0                    # 实例权重
        cluster-name: DEFAULT          # 集群名称
    loadbalancer:
      ribbon:
        enabled: false                 # 禁用Ribbon
      cache:
        enabled: true                  # 开启缓存
        ttl: 35s                       # 缓存时间
        capacity: 256                  # 缓存容量
      health-check:
        initial-delay: 0               # 健康检查初始延迟
        interval: 25s                  # 健康检查间隔
```

**自定义负载均衡策略：**

```java
// 1. 轮询策略（默认）
@Bean
public ReactorLoadBalancer<ServiceInstance> roundRobinLoadBalancer(
    Environment environment,
    LoadBalancerClientFactory loadBalancerClientFactory
) {
    String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
    return new RoundRobinLoadBalancer(
        loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class),
        name
    );
}

// 2. 随机策略
@Bean
public ReactorLoadBalancer<ServiceInstance> randomLoadBalancer(
    Environment environment,
    LoadBalancerClientFactory loadBalancerClientFactory
) {
    String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
    return new RandomLoadBalancer(
        loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class),
        name
    );
}

// 3. Nacos权重策略
@Bean
public ReactorLoadBalancer<ServiceInstance> nacosWeightLoadBalancer(
    Environment environment,
    LoadBalancerClientFactory loadBalancerClientFactory
) {
    String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
    return new NacosLoadBalancer(
        loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class),
        name
    );
}
```

**性能数据：**

```
LoadBalancer性能：
- 实例选择：微秒级（从缓存中选择）
- 缓存查询：纳秒级（内存查询）
- 缓存更新：35秒（默认TTL）
- 支持实例数：1000+
- 并发调用：10000+ QPS

负载均衡效果：
- 轮询策略：流量1:1:1均匀分配
- 随机策略：流量接近1:1:1分配
- 权重策略：按权重比例分配（1:1:2 = 25%:25%:50%）
- 故障转移：15秒内自动剔除故障实例
```

---

## 【版本C - 实战场景】终极版

### 第1层：主旨（核心中的核心）

```
LoadBalancer从Nacos获取实例列表，按策略选择一个实例，支持轮询、随机、权重
```

### 第2层：核心价值

```
多实例分流 + 智能选择 + 故障转移
```

### 第3层：实际案例（你的项目完整流程）

**用户操作：点击"立即下单"按钮**

**前端代码：**
```javascript
axios.post('http://localhost:8005/api/order/create', {
  userId: 123,
  productId: 456,
  quantity: 2
}, {
  headers: { Authorization: 'Bearer ' + token }
})
```

**请求流程：**
```
1. Nginx(8005) → Gateway(10010) → orderservice(8081)

2. orderservice处理下单逻辑：
   - 需要调用userservice查询用户信息
   - Feign调用：userClient.getUserById(123)

3. LoadBalancer工作：
   - 检查缓存：查找userservice实例列表缓存
   - 缓存命中：直接使用缓存的实例列表
   - 缓存未命中：从Nacos查询实例列表并缓存

4. Nacos返回实例列表：
   - 实例1：192.168.1.1:8001，healthy=true，weight=1.0
   - 实例2：192.168.1.2:8001，healthy=true，weight=1.0
   - 实例3：192.168.1.3:8001，healthy=true，weight=2.0

5. LoadBalancer选择实例（轮询策略）：
   - 第1次调用：选择实例1
   - 第2次调用：选择实例2
   - 第3次调用：选择实例3
   - 第4次调用：选择实例1（循环）

6. Feign发送请求：
   - GET http://192.168.1.1:8001/user/123
   - 返回用户信息

7. orderservice继续处理：
   - 创建订单，保存到数据库
   - 返回订单信息

8. 故障转移场景：
   - 实例2挂了，停止心跳
   - Nacos 15秒后标记实例2为不健康
   - LoadBalancer缓存35秒后过期
   - 下次调用时从Nacos获取最新实例列表：[实例1, 实例3]
   - LoadBalancer只在[实例1, 实例3]中选择
   - 用户无感知，请求正常处理
```

### 第4层：问题解决（真实踩坑）

**坑1：所有请求都打到一台服务器**
```
解决：LoadBalancer轮询策略（默认），流量均匀分配
```

**坑2：性能好的服务器和性能差的服务器处理相同请求**
```
解决：Nacos权重策略
spring:
  cloud:
    nacos:
      discovery:
        weight: 2.0  # 性能好的服务器
```

**坑3：某台服务器挂了，还往那台发请求**
```
解决：Nacos健康检查 + LoadBalancer过滤不健康实例
```

**坑4：频繁查询Nacos，增加Nacos压力**
```
解决：开启LoadBalancer缓存
loadbalancer:
  cache:
    enabled: true
    ttl: 35s
```

### 第5层：关键配置（拿来就用）

```yaml
spring:
  cloud:
    loadbalancer:
      cache:
        enabled: true
        ttl: 35s
```

---

## 🔄 完整请求流程图

```
orderservice
  ↓ Feign调用：userClient.getUserById(123)
  
LoadBalancer
  ↓ 检查缓存：查找userservice实例列表
  ↓ 缓存未命中
  
Nacos (8848)
  ↓ 查询实例列表：GET /nacos/v1/ns/instance/list?serviceName=userservice
  ↓ 返回实例列表：[实例1, 实例2, 实例3]
  
LoadBalancer
  ↓ 缓存实例列表：缓存35秒
  ↓ 过滤不健康实例：保留healthy=true的实例
  ↓ 负载均衡策略：轮询
  ↓ 选择实例：实例1 (192.168.1.1:8001)
  
Feign
  ↓ 发送HTTP请求：GET http://192.168.1.1:8001/user/123
  
userservice (8001)
  ↓ 处理请求，返回用户信息
  
orderservice
  ↓ 获得用户信息，继续处理订单
  
下次调用
  ↓ LoadBalancer检查缓存
  ↓ 缓存命中：直接使用缓存的实例列表
  ↓ 负载均衡策略：轮询
  ↓ 选择实例：实例2 (192.168.1.2:8001)
  
故障转移
  ↓ 实例2挂了，停止心跳
  ↓ Nacos 15秒后标记实例2为不健康
  ↓ LoadBalancer缓存35秒后过期
  ↓ 下次调用时从Nacos获取最新实例列表：[实例1, 实例3]
  ↓ LoadBalancer只在[实例1, 实例3]中选择
  ↓ 用户无感知，请求正常处理
```

---

## 📊 性能对比

### 没有LoadBalancer vs 有LoadBalancer

| 对比项 | 没有LoadBalancer | 有LoadBalancer | 差异 |
|--------|-----------------|---------------|------|
| 实例选择 | 手动指定 | 自动选择 | 智能化 |
| 流量分配 | 不均匀 | 均匀分配 | 压力分散 |
| 故障处理 | 手动剔除 | 自动剔除 | 自动化 |
| 性能优化 | 无 | 缓存机制 | 减少查询 |

### LoadBalancer性能数据

| 指标 | 数值 | 说明 |
|------|------|------|
| 实例选择 | 微秒级 | 从缓存中选择 |
| 缓存查询 | 纳秒级 | 内存查询 |
| 缓存时间 | 35秒 | 默认TTL |
| 支持实例数 | 1000+ | 单服务 |
| 并发调用 | 10000+ QPS | 高性能 |

---

## 🎯 使用建议

### 什么时候看精简版（LoadBalancer.md）
- 面试前快速复习
- 日常快速查阅
- 只需要核心概念

### 什么时候看详细版（本文件）
- 深入学习LoadBalancer原理
- 实际项目开发配置
- 遇到问题需要解决方案
- 需要完整的代码示例

---

## 📝 补充说明

### LoadBalancer工作原理（10层深度解析）

#### 第1层：Feign调用触发
```
Feign调用userClient.getUserById(123)，触发LoadBalancer
```

#### 第2层：检查缓存
```
LoadBalancer检查本地缓存是否有userservice实例列表
```

#### 第3层：缓存未命中
```
如果缓存未命中或过期，从Nacos查询实例列表
```

#### 第4层：查询Nacos
```
发送HTTP请求到Nacos：GET /nacos/v1/ns/instance/list?serviceName=userservice
```

#### 第5层：Nacos返回实例列表
```
Nacos返回所有注册的userservice实例：
[
  {ip: "192.168.1.1", port: 8001, healthy: true, weight: 1.0},
  {ip: "192.168.1.2", port: 8001, healthy: true, weight: 1.0},
  {ip: "192.168.1.3", port: 8001, healthy: true, weight: 2.0}
]
```

#### 第6层：过滤不健康实例
```
LoadBalancer过滤掉healthy=false的实例，只保留健康实例
```

#### 第7层：缓存实例列表
```
将实例列表缓存到本地，缓存时间35秒（默认TTL）
```

#### 第8层：负载均衡策略
```
根据配置的策略（轮询/随机/权重）选择一个实例
轮询策略：依次选择实例1 → 实例2 → 实例3 → 实例1（循环）
```

#### 第9层：返回选中的实例
```
返回选中的实例：{ip: "192.168.1.1", port: 8001}
```

#### 第10层：Feign发送请求
```
Feign使用选中的实例发送HTTP请求：GET http://192.168.1.1:8001/user/123
```

### 和其他技术的关系
```
Nacos(8848) - 注册中心
- 提供服务实例列表
- LoadBalancer从Nacos获取实例

LoadBalancer - 负载均衡器
- 从实例列表中选择一个实例
- 支持多种负载均衡策略

Feign - HTTP客户端
- 集成LoadBalancer实现负载均衡
- 自动调用LoadBalancer选择实例

Gateway - 应用网关
- 也集成LoadBalancer实现负载均衡
- 路由转发时选择实例
```

### 技术栈
```
- Spring Cloud LoadBalancer 3.x
- Spring Cloud Alibaba Nacos
- Reactor（响应式编程）
- Caffeine（缓存）
```

### 负载均衡策略对比

| 策略 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| 轮询 | 流量均匀分配 | 不考虑实例性能 | 实例性能相同 |
| 随机 | 简单高效 | 流量可能不均匀 | 实例数量多 |
| 权重 | 考虑实例性能 | 配置复杂 | 实例性能不同 |
| 最少连接 | 考虑实例负载 | 需要维护连接数 | 长连接场景 |

---

**最后更新：** 2026-01-29  
**适用场景：** 深入学习、实际开发、问题解决  
**配套文件：** LoadBalancer.md（精简版）
