# Gateway JWT 鉴权

---

## 🎯 10秒版 - 面试快答

**核心亮点：**
```
Gateway JWT鉴权解决三大问题：
1. 统一鉴权(一处验证，100个服务生效)
2. 无状态验证(不依赖Session，支持分布式)
3. 安全传递(Token包含用户信息，后端无需查库)
```

**一句话：** Gateway JWT鉴权是微服务统一身份验证机制，通过GlobalFilter验证Token签名和有效期，解析用户信息传递给后端服务

**更接地气：** Gateway JWT鉴权就是微服务的"门卫"，检查你的"通行证"(Token)是否有效，然后告诉后面的服务"这是123号用户"

---

## 📋 技术要点 - 工作使用

### 定义
Gateway JWT鉴权是基于JSON Web Token的无状态身份验证机制，通过GlobalFilter在网关层统一验证Token，解析用户信息并传递给后端服务

### 核心功能
- **Token验证**：验证JWT签名、过期时间、格式合法性
- **用户信息解析**：从Token中解析userId、username等信息
- **Header传递**：将用户信息放入Header传递给后端服务
- **白名单放行**：登录、注册等接口无需验证Token

### 核心价值
```
解决问题1：重复鉴权 → 统一验证(Gateway一处验证，100个服务无需重复写)
解决问题2：Session依赖 → 无状态验证(不依赖Session，支持分布式部署)
解决问题3：用户信息传递 → Token包含信息(后端无需查库，直接从Header取)
解决问题4：安全性 → 签名验证(防止Token篡改，过期自动失效)
```

### JWT Token结构
```
Header.Payload.Signature

Header: {"alg":"HS256","typ":"JWT"}
Payload: {"userId":123,"username":"张三","exp":1738195200}
Signature: HMACSHA256(base64(header)+"."+base64(payload), secret)
```

### 关键配置
```java
// AuthFilter.java - Gateway全局过滤器
@Component
public class AuthFilter implements GlobalFilter, Ordered {
    
    private static final List<String> WHITE_LIST = Arrays.asList(
        "/user/login", "/user/register"
    );
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().toString();
        
        // 白名单放行
        if (WHITE_LIST.contains(path)) {
            return chain.filter(exchange);
        }
        
        // 获取Token
        String token = exchange.getRequest().getHeaders().getFirst("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            return unauthorized(exchange);
        }
        
        token = token.substring(7); // 去掉"Bearer "
        
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
            return unauthorized(exchange);
        }
    }
    
    private Mono<Void> unauthorized(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
    
    @Override
    public int getOrder() {
        return -100; // 优先级最高
    }
}
```

---

## 🔧 深度解析 - 问题解决

### 实际案例（sky-cloud-pro项目）

**场景：用户查询订单列表**

```
完整流程：
1. 用户登录：
   - POST /user/login {username:"张三", password:"123456"}
   - userservice验证密码
   - 生成Token: JwtUtil.createToken(userId=123, username="张三")
   - 返回Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

2. 前端请求订单：
   - GET /order/list
   - Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

3. Gateway接收请求：
   - AuthFilter拦截
   - 检查路径：/order/list 不在白名单
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
   - 查询该用户的订单：SELECT * FROM orders WHERE user_id=123
   - 返回订单列表

7. 原路返回：orderservice → Gateway → 前端
```

### 问题解决（真实踩坑）

**问题1：每个服务都要验证Token，代码重复100遍**

问题流程：
```
前端请求 → userservice验证Token → orderservice验证Token → payservice验证Token
问题：100个服务重复验证100次，代码重复，维护困难
```

解决方案：Gateway统一验证，后端服务只需从Header取userId

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
        // 1. 验证Token
        Claims claims = JwtUtil.parseToken(token);
        Long userId = claims.get("userId", Long.class);
        
        // 2. 传递userId给后端
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

解决方案：Access Token(2小时) + Refresh Token(7天)

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

// 前端自动刷新
axios.interceptors.response.use(null, async error => {
    if (error.response.status === 401) {
        const newToken = await refreshAccessToken();
        return axios.request(error.config);
    }
});
```

---

**问题3：Token被盗用，无法主动失效**

问题流程：
```
Token泄露 → 攻击者使用Token → Token有效期内一直可用 → 无法阻止
```

解决方案：Redis黑名单 + Token版本号

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

解决方案：白名单放行

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
    "/user/login",
    "/user/register",
    "/user/code",
    "/doc.html"
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

解决方案：压缩Payload，只放必要信息

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
{
  "userId": 123,
  "username": "张三",
  "phone": "13800138000",
  "email": "zhangsan@example.com",
  "roles": ["admin", "user"],
  "permissions": ["order:create", "order:delete", ...]
}

// ✅ 正确做法：只放必要信息
{
  "userId": 123,
  "username": "张三"
}

// 其他信息后端根据userId查询
@GetMapping("/user/info")
public UserInfo info(@RequestHeader("userId") Long userId) {
    return userService.getById(userId);
}
```

### 性能数据

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

## 📝 使用建议

- **面试场景**：只说"10秒版"，面试官追问再说"技术要点"
- **技术文档**：用"技术要点"，简洁专业
- **实际工作**：用"深度解析"，有案例有代码
- **快速查阅**：看"10秒版"和"关键配置"

---

**最后更新：** 2026-01-29  
**适用场景：** 面试、工作、学习
