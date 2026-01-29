# Gateway JWT 鉴权 - 详细版

> 完整的20层递进结构，包含所有细节、问题解决、性能数据

---

## 📋 版本说明

- **Gateway-JWT鉴权.md** - 精简版（面试/快速查阅）
- **Gateway-JWT鉴权-详细版.md** - 本文件（深入学习/完整参考）

---

## 【版本A - 极简核心】终极版

### 第1层：主旨（核心中的核心）

```
Gateway JWT鉴权是微服务统一身份验证机制，解决重复鉴权、Session依赖、用户信息传递三大问题
通过GlobalFilter验证Token签名和有效期，解析用户信息传递给后端服务
```

### 第2层：核心价值

```
统一鉴权(一处验证全局生效) + 无状态验证(支持分布式) + 安全传递(Token包含用户信息)
```

### 第3层：实际案例（你的项目）

**场景：用户查询订单列表**

```
流程：
1. 用户登录：生成Token返回前端
2. 前端请求：带Token访问/order/list
3. Gateway验证：检查Token签名和过期
4. Gateway解析：提取userId=123
5. Gateway传递：添加Header(userId=123)
6. orderservice处理：从Header取userId，查询订单
7. 返回数据：只返回该用户的订单
```

### 第4层：问题解决

**问题1：每个服务都要验证Token，代码重复100遍**
```
解决：Gateway统一验证，后端服务从Header取userId即可
```

**问题2：Token过期时间太短用户频繁登录，太长安全性差**
```
解决：Access Token(2小时) + Refresh Token(7天)，自动刷新
```

**问题3：Token被盗用，无法主动失效**
```
解决：Redis黑名单 + Token版本号，可主动失效
```

**问题4：登录接口也被拦截，无法访问**
```
解决：白名单放行登录、注册等接口
```

**问题5：Token太长，浪费带宽**
```
解决：只放userId和username，其他信息后端查询
```

### 第5层：关键配置

```java
// Gateway全局过滤器
@Component
public class AuthFilter implements GlobalFilter, Ordered {
    private static final List<String> WHITE_LIST = Arrays.asList("/user/login", "/user/register");
    
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // 白名单放行
        if (WHITE_LIST.contains(path)) return chain.filter(exchange);
        
        // 验证Token
        Claims claims = JwtUtil.parseToken(token);
        Long userId = claims.get("userId", Long.class);
        
        // 传递userId
        ServerHttpRequest request = exchange.getRequest().mutate()
            .header("userId", userId.toString()).build();
        
        return chain.filter(exchange.mutate().request(request).build());
    }
}
```

---

## 【版本B - 技术准确】终极版

### 第1层：主旨（核心中的核心）

```
Gateway JWT鉴权基于JSON Web Token无状态身份验证机制
核心功能：Token验证、用户信息解析、Header传递、白名单放行
通过GlobalFilter在网关层统一验证Token签名和有效期，解析userId和username传递给后端服务
```

### 第2层：核心价值

```
解决问题1：重复鉴权 → 统一验证(Gateway一处验证，100个服务无需重复写)
解决问题2：Session依赖 → 无状态验证(不依赖Session，支持分布式部署)
解决问题3：用户信息传递 → Token包含信息(后端无需查库，直接从Header取)
解决问题4：安全性 → 签名验证(防止Token篡改，过期自动失效)
```

### 第3层：实际案例（你的项目）

**场景：用户下单流程**

```
1. 用户登录：
   - POST /user/login {username:"张三", password:"123456"}
   - userservice验证密码
   - 生成Token: JwtUtil.createToken(userId=123, username="张三")
   - 返回Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

2. 前端请求订单：
   - POST /order/create {productId:1, quantity:2}
   - Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

3. Gateway接收请求：
   - AuthFilter拦截
   - 检查路径：/order/create 不在白名单
   - 需要验证Token

4. Gateway验证Token：
   - 提取Token：去掉"Bearer "前缀
   - 验证签名：HMACSHA256(header+payload, secret) == signature
   - 验证过期：exp=1738195200 > 当前时间
   - 解析Payload：userId=123, username="张三"

5. Gateway传递用户信息：
   - 添加Header: userId=123
   - 添加Header: username=张三
   - 转发到orderservice

6. orderservice处理：
   - 从Header取userId=123
   - 创建订单：INSERT INTO orders (user_id, product_id, quantity) VALUES (123, 1, 2)
   - 返回订单号

7. 原路返回：orderservice → Gateway → 前端
```

### 第4层：问题解决

**问题1：每个服务都要验证Token，代码重复100遍**

问题流程：
```
前端请求 → userservice验证Token → orderservice验证Token → payservice验证Token
问题：100个服务重复验证100次，代码重复，维护困难
```

解决：Gateway统一验证，后端服务只需从Header取userId

解决流程：
```
[问题前]
前端请求 → userservice验证Token → 解析userId → 处理业务
         → orderservice验证Token → 解析userId → 处理业务
         → payservice验证Token → 解析userId → 处理业务
问题：重复验证100次，代码重复100份

[问题后]
前端请求 → Gateway验证Token → 解析userId → 添加Header(userId)
                                           ↓
         userservice ← Header(userId) → 直接使用，无需验证
         orderservice ← Header(userId) → 直接使用，无需验证
         payservice ← Header(userId) → 直接使用，无需验证
优势：只验证1次，代码只写1份
```

关键代码：
```java
// Gateway统一验证
@Component
public class AuthFilter implements GlobalFilter {
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        Claims claims = JwtUtil.parseToken(token);
        Long userId = claims.get("userId", Long.class);
        
        ServerHttpRequest request = exchange.getRequest().mutate()
            .header("userId", userId.toString())
            .build();
        
        return chain.filter(exchange.mutate().request(request).build());
    }
}

// 后端服务直接使用
@GetMapping("/order/list")
public List<Order> list(@RequestHeader("userId") Long userId) {
    return orderService.listByUserId(userId);
}
```

---

**问题2：Token过期时间太短，用户频繁登录；太长，安全性差**

问题流程：
```
短过期时间(30分钟) → 用户频繁登录 → 体验差
长过期时间(7天) → Token泄露风险高 → 安全性差
```

解决：Access Token(2小时) + Refresh Token(7天)

解决流程：
```
[问题前]
用户登录 → 生成Token(30分钟) → 30分钟后过期 → 用户重新登录
问题：用户体验差

[问题后]
用户登录 → 生成Access Token(2小时) + Refresh Token(7天)
         ↓
Access Token过期 → 前端用Refresh Token刷新 → 获取新Access Token
                                              ↓
Refresh Token过期 → 用户重新登录
优势：2小时内无感刷新，7天内无需登录
```

关键代码：
```java
// 登录返回双Token
@PostMapping("/login")
public LoginVO login(@RequestBody LoginDTO dto) {
    String accessToken = JwtUtil.createToken(userId, username, 2 * 60 * 60);
    String refreshToken = JwtUtil.createToken(userId, username, 7 * 24 * 60 * 60);
    return new LoginVO(accessToken, refreshToken);
}

// 刷新Token接口
@PostMapping("/refresh")
public String refresh(@RequestHeader("Refresh-Token") String refreshToken) {
    Claims claims = JwtUtil.parseToken(refreshToken);
    return JwtUtil.createToken(userId, username, 2 * 60 * 60);
}
```

---

**问题3：Token被盗用，无法主动失效**

问题流程：
```
Token泄露 → 攻击者使用Token → Token有效期内一直可用 → 无法阻止
```

解决：Redis黑名单 + Token版本号

解决流程：
```
[问题前]
用户登出 → Token仍然有效 → 攻击者可继续使用
问题：无法主动失效Token

[问题后 - 方案1：黑名单]
用户登出 → Token加入Redis黑名单 → Gateway验证时检查黑名单 → 拒绝访问

[问题后 - 方案2：版本号]
用户修改密码 → 数据库version+1 → Gateway验证时对比version → 旧Token失效
优势：可以主动失效Token
```

关键代码：
```java
// 黑名单方案
@PostMapping("/logout")
public void logout(@RequestHeader("Authorization") String token) {
    Claims claims = JwtUtil.parseToken(token);
    long expireTime = claims.getExpiration().getTime() - System.currentTimeMillis();
    redisTemplate.opsForValue().set("blacklist:" + token, "1", expireTime, TimeUnit.MILLISECONDS);
}

// Gateway验证时检查黑名单
if (redisTemplate.hasKey("blacklist:" + token)) {
    return unauthorized(exchange);
}

// 版本号方案
@PostMapping("/changePassword")
public void changePassword(@RequestHeader("userId") Long userId) {
    user.setTokenVersion(user.getTokenVersion() + 1);
    userService.updateById(user);
}
```

---

**问题4：登录、注册接口也被拦截，无法访问**

问题流程：
```
用户访问登录接口 → Gateway拦截验证Token → Token不存在 → 返回401 → 无法登录
```

解决：白名单放行

解决流程：
```
[问题前]
用户访问/user/login → Gateway验证Token → Token不存在 → 返回401
问题：无法登录

[问题后]
用户访问/user/login → Gateway检查白名单 → 在白名单中 → 直接放行
用户访问/order/list → Gateway检查白名单 → 不在白名单 → 验证Token
优势：登录接口可以正常访问
```

关键代码：
```java
private static final List<String> WHITE_LIST = Arrays.asList(
    "/user/login", "/user/register", "/user/code", "/doc.html"
);

@Override
public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
    String path = exchange.getRequest().getPath().toString();
    
    // 白名单放行
    if (WHITE_LIST.stream().anyMatch(path::startsWith)) {
        return chain.filter(exchange);
    }
    
    // 其他接口验证Token
    // ...
}
```

---

**问题5：Token太长，每次请求都传输，浪费带宽**

问题流程：
```
Token包含大量信息 → Token长度500+字符 → 每次请求都传输 → 浪费带宽
```

解决：压缩Payload，只放必要信息

解决流程：
```
[问题前]
Token Payload包含：userId, username, phone, email, roles, permissions, department...
Token长度：500+字符
每次请求传输：500字节
1万QPS传输：5MB/s

[问题后]
Token Payload只包含：userId, username
Token长度：150字符
每次请求传输：150字节
1万QPS传输：1.5MB/s
优势：节省70%带宽
```

关键代码：
```java
// ❌ 错误做法：放太多信息
{"userId":123,"username":"张三","phone":"13800138000","email":"zhangsan@example.com",...}

// ✅ 正确做法：只放必要信息
{"userId":123,"username":"张三"}

// 其他信息后端根据userId查询
@GetMapping("/user/info")
public UserInfo info(@RequestHeader("userId") Long userId) {
    return userService.getById(userId);
}
```

### 第5层：关键配置

**完整配置文件：**

```java
// JwtUtil.java - JWT工具类
public class JwtUtil {
    private static final String SECRET = "sky-cloud-pro-jwt-secret-key-2026";
    private static final Key KEY = Keys.hmacShaKeyFor(SECRET.getBytes());
    private static final long EXPIRE_TIME = 2 * 60 * 60 * 1000; // 2小时
    
    public static String createToken(Long userId, String username) {
        return Jwts.builder()
            .claim("userId", userId)
            .claim("username", username)
            .setExpiration(new Date(System.currentTimeMillis() + EXPIRE_TIME))
            .signWith(KEY, SignatureAlgorithm.HS256)
            .compact();
    }
    
    public static Claims parseToken(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(KEY)
            .build()
            .parseClaimsJws(token)
            .getBody();
    }
}

// AuthFilter.java - Gateway全局过滤器
@Component
public class AuthFilter implements GlobalFilter, Ordered {
    private static final List<String> WHITE_LIST = Arrays.asList(
        "/user/login", "/user/register", "/user/code", "/doc.html"
    );
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().toString();
        
        // 白名单放行
        if (WHITE_LIST.stream().anyMatch(path::startsWith)) {
            return chain.filter(exchange);
        }
        
        // 获取Token
        String token = exchange.getRequest().getHeaders().getFirst("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            return unauthorized(exchange, "Token不存在");
        }
        
        token = token.substring(7);
        
        // 验证Token
        try {
            Claims claims = JwtUtil.parseToken(token);
            Long userId = claims.get("userId", Long.class);
            String username = claims.get("username", String.class);
            
            // 传递用户信息给后端
            ServerHttpRequest request = exchange.getRequest().mutate()
                .header("userId", userId.toString())
                .header("username", username)
                .build();
            
            return chain.filter(exchange.mutate().request(request).build());
        } catch (Exception e) {
            return unauthorized(exchange, "Token无效或已过期");
        }
    }
    
    private Mono<Void> unauthorized(ServerWebExchange exchange, String message) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
    
    @Override
    public int getOrder() {
        return -100; // 优先级最高
    }
}
```

**性能数据：**

```
Token验证性能：
- 验证速度: 0.1ms（纯内存计算）
- QPS: 10万+（单台Gateway）
- 无数据库查询，性能极高

对比Session验证：
- Session验证: 需要查询Redis，1-2ms
- JWT验证: 纯内存计算，0.1ms
- 性能提升: 10-20倍
```

---

## 【版本C - 实战场景】终极版

### 第1层：主旨（核心中的核心）

```
Gateway JWT鉴权：验证Token签名和过期，解析userId，传递给后端
```

### 第2层：核心价值

```
统一鉴权 + 无状态验证 + 安全传递
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
1. Nginx(8005)接收 → 去掉/api/ → 转发到Gateway(10010)
2. Gateway验证Token → 解析userId=123
3. Gateway添加Header(userId=123) → 转发到orderservice
4. orderservice查询userId=123的订单 → 返回数据
5. 原路返回 → 前端显示订单列表
```

### 第4层：问题解决（真实踩坑）

**坑1：Token验证每个服务都写，改一次改100处**
```
解决：Gateway统一验证，后端服务只需从Header取userId
```

**坑2：Token过期时间太短用户频繁登录，太长安全性差**
```
解决：Access Token(2小时) + Refresh Token(7天)，自动刷新
```

**坑3：Token被盗用，无法主动失效**
```
解决：Redis黑名单 + Token版本号，可主动失效
```

**坑4：登录接口也被拦截，无法访问**
```
解决：白名单放行登录、注册等接口
```

**坑5：Token太长，浪费带宽**
```
解决：只放userId和username，其他信息后端查询
```

### 第5层：关键配置（拿来就用）

```java
// 最简配置
@Component
public class AuthFilter implements GlobalFilter, Ordered {
    private static final List<String> WHITE_LIST = Arrays.asList("/user/login", "/user/register");
    
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().toString();
        if (WHITE_LIST.contains(path)) return chain.filter(exchange);
        
        String token = exchange.getRequest().getHeaders().getFirst("Authorization");
        Claims claims = JwtUtil.parseToken(token.substring(7));
        
        ServerHttpRequest request = exchange.getRequest().mutate()
            .header("userId", claims.get("userId", Long.class).toString())
            .build();
        
        return chain.filter(exchange.mutate().request(request).build());
    }
    
    public int getOrder() { return -100; }
}
```

---

## 🔄 完整请求流程图

```
用户浏览器
  ↓ 点击"我的订单"按钮
  ↓ axios.get('/api/order/list', {headers: {Authorization: 'Bearer ' + token}})
  
Nginx (8005)
  ↓ 匹配 location /api/
  ↓ 去掉 /api/ 前缀
  ↓ proxy_pass http://gateway_backend/
  ↓ 转发到 http://localhost:10010/order/list
  ↓ Header: Authorization: Bearer eyJhbGc...
  
Gateway (10010)
  ↓ GlobalFilter: AuthFilter
  ↓ 检查路径：/order/list 不在白名单
  ↓ 提取Token：去掉"Bearer "前缀
  ↓ 验证签名：HMACSHA256(header+payload, secret) == signature ✓
  ↓ 验证过期：exp=1738195200 > 当前时间 ✓
  ↓ 解析Payload：userId=123, username="张三"
  ↓ 添加Header：userId=123, username=张三
  ↓ 转发请求
  
orderservice (8081)
  ↓ 从Header取userId=123
  ↓ 查询数据库：SELECT * FROM orders WHERE user_id=123
  ↓ 返回订单列表：[{orderId:1, amount:100}, {orderId:2, amount:200}]
  
原路返回
  ↓ orderservice → Gateway → Nginx → 用户浏览器
  ↓ 前端显示订单列表
```

---

## 📊 性能对比

### 没有JWT vs 有JWT

| 对比项 | 没有JWT（Session） | 有JWT | 差异 |
|--------|-------------------|-------|------|
| 验证方式 | 查询Redis | 纯内存计算 | 快10-20倍 |
| 验证时间 | 1-2ms | 0.1ms | 快10-20倍 |
| 状态存储 | 需要Redis存储Session | 无需存储 | 节省内存 |
| 分布式支持 | 需要Session共享 | 天然支持 | 无需配置 |
| 扩展性 | 增加服务器需要同步Session | 无需同步 | 易扩展 |

### JWT性能数据

| 指标 | 单台Gateway | 3台Gateway集群 |
|------|------------|---------------|
| QPS | 10万+ | 30万+ |
| 验证时间 | 0.1ms | 0.1ms |
| CPU使用率 | 20% | 20% |
| 内存使用 | 无需存储 | 无需存储 |

---

## 🎯 使用建议

### 什么时候看精简版（Gateway-JWT鉴权.md）
- 面试前快速复习
- 日常快速查阅
- 只需要核心概念

### 什么时候看详细版（本文件）
- 深入学习JWT原理
- 实际项目开发配置
- 遇到问题需要解决方案
- 需要完整的代码示例

---

## 📝 补充说明

### JWT Token结构详解
```
完整Token：eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyMywidXNlcm5hbWUiOiLlvKDkuIkiLCJleHAiOjE3MzgxOTUyMDB9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

拆分：
Header: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
Payload: eyJ1c2VySWQiOjEyMywidXNlcm5hbWUiOiLlvKDkuIkiLCJleHAiOjE3MzgxOTUyMDB9
Signature: SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

Base64解码：
Header: {"alg":"HS256","typ":"JWT"}
Payload: {"userId":123,"username":"张三","exp":1738195200}
Signature: HMACSHA256(base64(header)+"."+base64(payload), secret)
```

### 和Session的对比
```
Session方案：
- 服务端存储Session（占用内存/Redis）
- 每次请求查询Session（1-2ms）
- 分布式需要Session共享
- 扩展性差

JWT方案：
- 服务端不存储（无状态）
- 每次请求验证签名（0.1ms）
- 天然支持分布式
- 扩展性好
```

### 技术栈
```
- Spring Cloud Gateway 3.x（网关）
- JJWT 0.11.5（JWT库）
- Redis（黑名单，可选）
- Nacos（服务注册与发现）
```

---

## 【第6-10层：深度解析】

### 第6层：JWT签名算法选择

**HS256（对称加密）：**
```
优势：速度快，实现简单
劣势：secret泄露风险
适用：内部微服务
```

**RS256（非对称加密）：**
```
优势：安全性高，私钥只有认证服务持有
劣势：速度慢（比HS256慢10倍）
适用：开放API
```

**选择建议：**
- 内部微服务：HS256（性能优先）
- 开放API：RS256（安全优先）

### 第7层：Token存储位置选择

**localStorage：**
```
优势：简单易用，持久化存储
劣势：容易被XSS攻击窃取
```

**HttpOnly Cookie：**
```
优势：防止XSS攻击（JavaScript无法访问）
劣势：容易被CSRF攻击
```

**选择建议：**
- 内部系统：localStorage（简单）
- 对外系统：HttpOnly Cookie（安全）

### 第8层：Token刷新机制

**滑动过期（不推荐）：**
```
每次请求自动延长Token过期时间
问题：Token泄露后永久有效
```

**双Token刷新（推荐）：**
```
Access Token(2小时) + Refresh Token(7天)
Access Token过期 → 用Refresh Token刷新
Refresh Token过期 → 重新登录
```

**无感刷新（最佳）：**
```
前端拦截器自动刷新：
1. 请求返回401
2. 用Refresh Token刷新Access Token
3. 重试原请求
4. 用户无感知
```

### 第9层：Token黑名单设计

**Redis黑名单：**
```
优势：实时生效，精确控制
劣势：需要Redis，每次请求都要查询
```

**Token版本号：**
```
优势：无需Redis，性能高
劣势：需要查询数据库，修改密码后所有设备都失效
```

**混合方案（推荐）：**
```
日常：使用版本号（性能优先）
紧急：使用黑名单（安全优先）
```

### 第10层：白名单设计

**硬编码白名单：**
```
优势：简单直接
劣势：修改需要重启
```

**配置文件白名单：**
```
优势：修改无需重启（@RefreshScope）
劣势：需要配置中心（Nacos）
```

**数据库白名单：**
```
优势：动态管理，可视化配置
劣势：性能开销（需要缓存）
```

---

## 【第11-15层：性能优化】

### 第11层：缓存策略

**无缓存：**
```
性能：QPS 5000，响应时间20ms，CPU 80%
```

**Redis缓存：**
```
性能：QPS 15000，响应时间8ms，CPU 40%
提升：3倍
```

**本地缓存（Caffeine）：**
```
性能：QPS 25000，响应时间4ms，CPU 25%
提升：5倍
```

**两级缓存（推荐）：**
```
性能：QPS 30000，响应时间3ms，CPU 20%
提升：6倍
```

### 第12层：限流策略

**全局限流：**
```
限制：Gateway总QPS 10万
优势：保护整体系统
```

**用户限流（推荐）：**
```
限制：每个用户100次/分钟
优势：公平，防止单个用户占用资源
```

**接口限流：**
```
限制：/order/create 1000次/分钟
优势：保护核心接口
```

### 第13层：降级熔断

**完全降级（不推荐）：**
```
Redis故障 → 直接放行所有请求
问题：安全性为0
```

**部分降级（推荐）：**
```
Redis故障 → 只验证Token签名和过期，不检查黑名单
优势：保证基本安全性
```

**智能降级（最佳）：**
```
正常：验证签名 + 过期 + 黑名单 + 版本号
Redis故障：验证签名 + 过期
数据库故障：验证签名 + 过期 + 黑名单
```

### 第14层：监控告警

**核心指标：**
```
1. Token验证成功率（目标：>99.9%）
2. Token验证响应时间（目标：<5ms）
3. Gateway QPS（目标：>30000）
4. Redis命中率（目标：>95%）
```

**告警规则：**
```
- 验证成功率<99% → P1告警
- 响应时间>50ms → P2告警
- QPS<10000 → P2告警
```

### 第15层：容量规划

**单台Gateway容量：**
```
- QPS: 10000
- 并发连接: 10000
- 内存: 2GB
- CPU: 4核
```

**集群容量计算：**
```
预期QPS: 50000
峰值系数: 2倍
冗余系数: 1.5倍
需要Gateway数量: 50000 * 2 * 1.5 / 10000 = 15台
```

---

## 【第16-20层：生产实战】

### 第16层：灰度发布

**按用户ID灰度：**
```
userId % 100 < 10 → 新版本（10%用户）
其他 → 旧版本（90%用户）
```

**按Header灰度：**
```
Header带上X-Gray-Version=v2 → 新版本
其他 → 旧版本
```

### 第17层：多租户支持

**Token中包含租户ID：**
```json
{
  "userId": 123,
  "username": "张三",
  "tenantId": "tenant_001"
}
```

**Gateway传递租户ID：**
```java
ServerHttpRequest request = exchange.getRequest().mutate()
    .header("userId", userId.toString())
    .header("tenantId", tenantId)
    .build();
```

### 第18层：权限控制（RBAC）

**Token中包含角色：**
```json
{
  "userId": 123,
  "username": "张三",
  "roles": ["admin", "manager"]
}
```

**Gateway验证权限：**
```java
List<String> requiredRoles = ROLE_MAP.get(path);
List<String> userRoles = getUserRoles(exchange);

if (!hasPermission(userRoles, requiredRoles)) {
    return forbidden(exchange);
}
```

### 第19层：审计日志

**记录内容：**
```
- 操作人：userId
- 操作时间：timestamp
- 操作接口：path
- 操作参数：requestBody
- 操作结果：responseBody
- 操作IP：clientIp
```

**存储方案：**
```
实时：Kafka → ES（查询分析）
归档：ES → 对象存储（长期保存）
```

### 第20层：安全加固

**密钥管理：**
```
- secret存储在配置中心（Nacos）
- 定期轮换（每季度）
- 不同环境使用不同secret
```

**传输加密：**
```
- 全站HTTPS
- TLS 1.2+
- 强制HSTS
```

**防暴力破解：**
```
- 登录失败5次锁定账号30分钟
- 验证码机制
- IP黑名单
```

---

**最后更新：** 2026-01-29  
**适用场景：** 深入学习、实际开发、问题解决  
**配套文件：** Gateway-JWT鉴权.md（精简版）
