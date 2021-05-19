## SpringCloud-Alibaba

---

[TOC]

---

## Gateway网关

Gateway提供了一种简单而有效的方式来对API进行路由,以及提供一些强大的过滤器功能,如熔断,限流,重试等.Gateway的底层用到了响应式编程,有机会补上.

三个概念

- Route（路由）：路由是构建网关的基本模块，它由ID，目标URI，一系列的断言和过滤器组成，如果断言为true则匹配该路由；
- Predicate（断言）：指的是Java 8 的 Function Predicate。 输入类型是Spring框架中的ServerWebExchange。 这使开发人员可以匹配HTTP请求中的所有内容，例如请求头或请求参数。如果请求与断言相匹配，则进行路由；
- Filter（过滤器）：指的是Spring框架中GatewayFilter的实例，使用过滤器，可以在请求被路由前后对请求进行修改。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
</dependency>
```

我们可以使用application.yml进行配置

```yml
server:
  port: 9201
service-url:
  user-service: http://localhost:8201
spring:
  cloud:
    gateway:
      routes:
        - id: path_route # 路由的ID
          uri: ${service-url.user-service}/user/{id} #匹配后路由地址
          predicates: # 断言，路径相匹配的进行路由
            - Path=/user/{id}
```

除此之外,我们还可以用配置类的方式来进行配置

```java
@Configuration
public class GatewayConfig {
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("path_route2", r -> r.path("/user/getByUsername")
                        .uri("http://localhost:8201/user/getByUsername"))
                .build();
    }
}
```

基于配置文件我们介绍下不同的断言器

### [After Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=after-route-predicate)

在指定时间之后的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: after_route
          uri: ${service-url.user-service}
          predicates:
            - After=2019-09-24T16:30:00+08:00[Asia/Shanghai]
```

### [Before Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=before-route-predicate)

在指定时间之前的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: before_route
          uri: ${service-url.user-service}
          predicates:
            - Before=2019-09-24T16:30:00+08:00[Asia/Shanghai]
```

### [Between Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=between-route-predicate)

在指定时间区间内的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: before_route
          uri: ${service-url.user-service}
          predicates:
            - Between=2019-09-24T16:30:00+08:00[Asia/Shanghai], 2019-09-25T16:30:00+08:00[Asia/Shanghai]
```

### [Cookie Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=cookie-route-predicate)

带有指定Cookie的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: cookie_route
          uri: ${service-url.user-service}
          predicates:
            - Cookie=username,macro
```

### [Header Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=header-route-predicate)

带有指定请求头的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: header_route
        uri: ${service-url.user-service}
        predicates:
        - Header=X-Request-Id, \d+
```

使用curl工具发送带有请求头为`X-Request-Id:123`的请求可以匹配该路由。

```bash
curl http://localhost:9201/user/1 -H "X-Request-Id:123" 
```

### [Host Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=host-route-predicate)

带有指定Host的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: host_route
          uri: ${service-url.user-service}
          predicates:
            - Host=**.macrozheng.com
```

使用curl工具发送带有请求头为`Host:www.macrozheng.com`的请求可以匹配该路由。

```bash
curl http://localhost:9201/user/1 -H "Host:www.macrozheng.com" 
```

### [Method Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=method-route-predicate)

发送指定方法的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: method_route
        uri: ${service-url.user-service}
        predicates:
        - Method=GET
```

使用curl工具发送GET请求可以匹配该路由。

```bash
curl http://localhost:9201/user/1
```

使用curl工具发送POST请求无法匹配该路由。

```bash
curl -X POST http://localhost:9201/user/1
```

### [Path Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=path-route-predicate)

发送指定路径的请求会匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: ${service-url.user-service}/user/{id}
          predicates:
            - Path=/user/{id}
```

使用curl工具发送`/user/1`路径请求可以匹配该路由。

```bash
curl http://localhost:9201/user/1
```

使用curl工具发送`/abc/1`路径请求无法匹配该路由。

```bash
curl http://localhost:9201/abc/1
```

### [Query Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=query-route-predicate)

带指定查询参数的请求可以匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: query_route
        uri: ${service-url.user-service}/user/getByUsername
        predicates:
        - Query=username
```

使用curl工具发送带`username=macro`查询参数的请求可以匹配该路由。

```bash
curl http://localhost:9201/user/getByUsername?username=macro
```

使用curl工具发送带不带查询参数的请求无法匹配该路由。

```bash
curl http://localhost:9201/user/getByUsername
```

### [RemoteAddr Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=remoteaddr-route-predicate)

从指定远程地址发起的请求可以匹配该路由。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: remoteaddr_route
        uri: ${service-url.user-service}
        predicates:
        - RemoteAddr=192.168.1.1/24
```

使用curl工具从192.168.1.1发起请求可以匹配该路由。

```bash
curl http://localhost:9201/user/1
```

### [Weight Route Predicate](http://www.macrozheng.com/#/cloud/gateway?id=weight-route-predicate)

使用权重来路由相应请求，以下表示有80%的请求会被路由到localhost:8201，20%会被路由到localhost:8202。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: weight_high
        uri: http://localhost:8201
        predicates:
        - Weight=group1, 8
      - id: weight_low
        uri: http://localhost:8202
        predicates:
        - Weight=group1, 2
```

### [PrefixPath GatewayFilter](http://www.macrozheng.com/#/cloud/gateway?id=prefixpath-gatewayfilter)

与StripPrefix过滤器恰好相反，会对原有路径进行增加操作的过滤器。

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: prefix_path_route
        uri: http://localhost:8201
        predicates:
        - Method=GET
        filters:
        - PrefixPath=/user
```

以上配置会对所有GET请求添加`/user`路径前缀，通过curl工具使用以下命令进行测试。

```bash
curl http://localhost:9201/1
```

相当于发起该请求：

```bash
curl http://localhost:8201/user/1
```



### [Hystrix GatewayFilter](http://www.macrozheng.com/#/cloud/gateway?id=hystrix-gatewayfilter)

Hystrix 过滤器允许你将断路器功能添加到网关路由中，使你的服务免受级联故障的影响，并提供服务降级处理。

- 要开启断路器功能，我们需要在pom.xml中添加Hystrix的相关依赖：

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>
```

- 然后添加相关服务降级的处理类：

```java
/**
 * Created by macro on 2019/9/25.
 */
@RestController
public class FallbackController {

    @GetMapping("/fallback")
    public Object fallback() {
        Map<String,Object> result = new HashMap<>();
        result.put("data",null);
        result.put("message","Get request fallback!");
        result.put("code",500);
        return result;
    }
}
```

- 在application-filter.yml中添加相关配置，当路由出错时会转发到服务降级处理的控制器上：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: hystrix_route
          uri: http://localhost:8201
          predicates:
            - Method=GET
          filters:
            - name: Hystrix
              args:
                name: fallbackcmd
                fallbackUri: forward:/fallback
```

- 关闭user-service，调用该地址进行测试：http://localhost:9201/user/1 ，发现已经返回了服务降级的处理信息。

![img](http://www.macrozheng.com/images/springcloud_gateway_03.png)

### [RequestRateLimiter GatewayFilter](http://www.macrozheng.com/#/cloud/gateway?id=requestratelimiter-gatewayfilter)

RequestRateLimiter 过滤器可以用于限流，使用RateLimiter实现来确定是否允许当前请求继续进行，如果请求太大默认会返回HTTP 429-太多请求状态。

- 在pom.xml中添加相关依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
</dependency>
```

- 添加限流策略的配置类，这里有两种策略一种是根据请求参数中的username进行限流，另一种是根据访问IP进行限流；

```java
/**
 * Created by macro on 2019/9/25.
 */
@Configuration
public class RedisRateLimiterConfig {
    @Bean
    KeyResolver userKeyResolver() {
        return exchange -> Mono.just(exchange.getRequest().getQueryParams().getFirst("username"));
    }

    @Bean
    public KeyResolver ipKeyResolver() {
        return exchange -> Mono.just(exchange.getRequest().getRemoteAddress().getHostName());
    }
}
```

- 我们使用Redis来进行限流，所以需要添加Redis和RequestRateLimiter的配置，这里对所有的GET请求都进行了按IP来限流的操作；

```yaml
server:
  port: 9201
spring:
  redis:
    host: localhost
    password: 123456
    port: 6379
  cloud:
    gateway:
      routes:
        - id: requestratelimiter_route
          uri: http://localhost:8201
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 1 #每秒允许处理的请求数量
                redis-rate-limiter.burstCapacity: 2 #每秒最大处理的请求数量
                key-resolver: "#{@ipKeyResolver}" #限流策略，对应策略的Bean
          predicates:
            - Method=GET
logging:
  level:
    org.springframework.cloud.gateway: debug
```

- 多次请求该地址：http://localhost:9201/user/1 ，会返回状态码为429的错误；

![img](http://www.macrozheng.com/images/springcloud_gateway_04.png)

### [Retry GatewayFilter](http://www.macrozheng.com/#/cloud/gateway?id=retry-gatewayfilter)

对路由请求进行重试的过滤器，可以根据路由请求返回的HTTP状态码来确定是否进行重试。

- 修改配置文件：

```yaml
spring:
  cloud:
    gateway:
      routes:
      - id: retry_route
        uri: http://localhost:8201
        predicates:
        - Method=GET
        filters:
        - name: Retry
          args:
            retries: 1 #需要进行重试的次数
            statuses: BAD_GATEWAY #返回哪个状态码需要进行重试，返回状态码为5XX进行重试
            backoff:
              firstBackoff: 10ms
              maxBackoff: 50ms
              factor: 2
              basedOnPreviousValue: false
```

- 当调用返回500时会进行重试，访问测试地址：http://localhost:9201/user/111
- 可以发现user-service控制台报错2次，说明进行了一次重试。

```bash
2019-10-27 14:08:53.435 ERROR 2280 --- [nio-8201-exec-2] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed; nested exception is java.lang.NullPointerException] with root cause

java.lang.NullPointerException: null
    at com.macro.cloud.controller.UserController.getUser(UserController.java:34) ~[classes/:na]
```



## nacos

SpringCloud Alibaba中nacos作为配置中心使用.nacos是alibaba主导的一种开源生态,支持springcloud

[官方文档](https://nacos.io/zh-cn/docs/quick-start.html)

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2xhcnNjaGVuZy9teUltZy9tYXN0ZXIvYmxvZ0ltZy9OYWNvcy8yMDE5MDcwOTE1NTYwMC5wbmc)

将nacos-provide和nacos-consumer注册到nacos-server.

服务消费者**nacos-consumer**通过主动轮询获取他所订阅消费的服务信息列表 

nacos-consumer根据获取到的服务信息列表,进行服务调用.

### nacos特性

- 服务发现和服务健康检测,基于DNS和RPC,阻止向挂掉的主机/服务实例发送请求
- 动态 DNS 服务：动态 DNS 服务支持权重路由，让您更容易地实现中间层负载均衡、更灵活的路由策略、流量控制以及数据中心内网的简单DNS解析服务
- 服务及其元数据管理：支持从微服务平台建设的视角管理数据中心的所有服务及元数据。

### cap定理

同时支持CP和AP，根据注册的服务的永久性决定使用cp(永久服务)还是ap(临时服务)，nacos同时作为注册中心和配置中心.根据场景同时需要cp和ap的特性.nacos选举leader大概用4到5秒.

nacos使用raft作为选举算法,Eureka使用同步广播



### nacos 作为注册中心

#### 下载服务端

[下载地址@github.com](https://github.com/alibaba/nacos/releases/)

```shell
startup.cmd -m standalone
```

```shell
sh startup.sh -m standalone
```

访问启动地址`http://192.168.0.139:8848/nacos`,默认登陆账号是nacos/nacos

nacos默认的是嵌入式的数据库dery存储需要持久化的数据,支持改为使用mysql.改的方法是导入下载文件中的`conf/nacos-mysql.sql`修改同级目录的`application.properties`的配置文件来部署.

```properties
# mysql
spring.datasource.platform=mysql
db.num=1
db.url.0=jdbc:mysql://10.17.xx.xxx:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true
db.user=root
db.password=xxxxxx
```





#### 客户端配置

使用springcloud-alibaba的组件

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>

<dependencyManagement>
    <dependencies>
        <!--springcloud-alibaba的依赖-->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-alibaba-dependencies</artifactId>
            <version>2.1.0.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

```yml
server:
  port: 8206
spring:
  application:
    name: nacos-user-service
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848 #配置Nacos地址
management:
  endpoints:
    web:
      exposure:
        include: '*'
```

```java
package com.example.clientserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.web.client.RestTemplate;

@EnableDiscoveryClient  // 标注上这个注解
@SpringBootApplication
public class ClientServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ClientServerApplication.class, args);
    }
}
```

### nacos 作为配置中心

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
</dependency>
```

application.yml 添加如下配置

```yml
spring:
  profiles:
    active: dev
```

bootstrap.yml

```yml
server:
  port: 9101
spring:
  application:
    name: nacos-config-client
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848 #Nacos地址
      config:
        server-addr: localhost:8848 #Nacos地址
        file-extension: yaml #这里我们获取的yaml格式的配置
```

进行配置文件的注入,这个配置文件是要在nacos配置中心进行获取的

```java
@RestController
@RefreshScope // 支持热部署动态刷新
public class ConfigClientController {

    @Value("${config.info}") // 从nacos配置中心获取到这个配置文件的信息
    private String configInfo;

    @GetMapping("/configInfo")
    public String getConfigInfo() {
        return configInfo;
    }
}
```

nacos配置中心的命名规则

`${spring.application.name}-${spring.profiles.active}.${spring.cloud.nacos.config.file-extension}`

比如对上面的应用其命名就是`nacos-config-client-dev.yaml`,服务名-开发环境.文件后缀

然后我们在相应的nacos中创建配置文件,然后发布即可

```yml
config:
  info: "config info for dev"
```

nacos支持**动态刷新配置**,在传统的Eureka服务中使用Consul完成和nacos动态配置差不多的功能,但由于Eureka不在维护,这里不做过多介绍

### Nacos和Eureka的选型建议

采用Eureka方案的考虑

- 想用Spring Cloud原生全家桶
- 想用本地文件和Git作为配置管理的,将配置与服务分开管理
- 考虑短期的稳定性

采用Nacos方案的考虑

- 想在线对服务进行上下线和流量管理
- 不想采用MQ实现配置中心动态刷新
- 不想新增配置中心生产集群
- 考虑引入Spring Cloud Alibaba生态



## 分布式事务seata

seata为Simple Extensible Autonomous Transaction Architecture的简写.采用了2PC提交

如微服务中的三个独立的服务如下

![](https://p1-tt.byteimg.com/origin/pgc-image/7194fff34840449cb2bc358275180253)

### 分布式事务的几种实现方式

#### seata的处理方式

![](https://p6-tt.byteimg.com/origin/pgc-image/d5971366a40e4488a73d62e328df4de5)

TM指的是Transation Manager即事务管理者,通过一个注解标明其为全局事务.

事务执行流程

- business会请求TC(一个独立的服务),TC运行生成一个全局的事务id(XID)并返回给Business.
- Storage 会收到 XID，知道自己的事务属于这个全局事务。Storage 执行自己的业务逻辑，操作本地数据库。
- Storage 会把自己的事务注册到 TC，作为这个 XID 下面的一个**分支事务**，并且把自己的事务执行结果也告诉 TC。
- Business 如果发现各个微服务的本地事务都执行成功了，就请求 TC 对这个 XID 提交，否则回滚。
  - TC收到请求后对各个微服务发出提交命令
  - 各个微服务收到命令后,执行相应的指令,并把执行结果上交给TC

上面的服务过程和2PC类似,称之为AT即自动化事务,对业务代码没有侵入性.

关于分布式事务,这里进行研究其他分布式事务的实现方法.

Seata实现2PC与传统2PC的差别：

- 架构层次方面，传统2PC方案的 RM 实际上是在数据库层，RM本质上就是数据库自身，通过XA协议实现，而 Seata的RM是以jar包的形式作为中间件层部署在应用程序这一侧的。
- 两阶段提交方面，传统2PC无论第二阶段的决议是commit还是rollback，事务性资源的锁都要保持到Phase2完成才释放。而Seata的做法是在Phase1 就将本地事务提交，这样就可以省去Phase2持锁的时间，整体提高效率

其执行流程可能如下

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91cGxvYWQtaW1hZ2VzLmppYW5zaHUuaW8vdXBsb2FkX2ltYWdlcy8xMTQ3NDA4OC0xN2I5Y2JhMzZmYjMzZmJiLnBuZw?x-oss-process=image/format,png)



### seata-quickstart

[seata release下载](https://github.com/seata/seata/releases/v0.9.0/)，[官方文档](http://seata.io/zh-cn/docs/user/quickstart.html)

seata本身是个微服务,我们需要下载其server,下面我们结合nacos使用

- 启动nacos(如上文)
- seata-server需要使用到nacos注册中心的数据库
- 修改registry.conf的配置,这个配置文件和注册中心有关系

```conf
registry {
  type = "nacos"

  nacos {
    application = "seata-server" # 和在application.yml或者bootstrap.yml里面配置一样
    # 之前配置的nacos集群
    serverAddr = "192.168.1.181:9948"
    # 自定义命名空间
    namespace = ""
    # 自定义组
    group = "SEATA_GROUP"
    cluster = "default"
    username = "nacos"
    password = "nacos"
  }
}

config {
  type = "nacos"
  nacos {
    serverAddr = "192.168.1.181:9948"
    namespace = ""
    group = "SEATA_GROUP"
    username = "nacos"
    password = "nacos"
  }
}
```

修改conf/config.txt,至于建立数据库的语句在官方文档或者seata服务器的包中能看到

```txt
# 定义组，应用中也需要对应
service.vgroupMapping.nacos-demo-group=default
store.mode=db|redis
-----db-----
store.db.datasource=druid
store.db.dbType=mysql
store.db.driverClassName=com.mysql.jdbc.Driver
store.db.url=jdbc:mysql://127.0.0.1:3306/seata?useUnicode=true
store.db.user=root
store.db.password=123456
----redis----
store.redis.host=127.0.0.1
store.redis.port=6379
store.redis.maxConn=10
store.redis.minConn=1
store.redis.database=0
store.redis.password=null
store.redis.queryLimit=100
```
### 业务逻辑demo

### pom依赖

```xml
<dependency>
    <groupId>io.seata</groupId>
    <artifactId>seata-spring-boot-starter</artifactId>
</dependency>
```

#### 仓储服务

```java
public interface StorageService {

    /**
     * 扣除存储数量
     */
    void deduct(String commodityCode, int count);
}
```

#### 订单服务

```java
public interface OrderService {

    /**
     * 创建订单
     */
    Order create(String userId, String commodityCode, int orderCount);
}
```

#### 帐户服务

```java
public interface AccountService {

    /**
     * 从用户账户中借出
     */
    void debit(String userId, int money);
}
```

#### 主要全局事务业务逻辑

```java
public class BusinessServiceImpl implements BusinessService {

    private StorageService storageService;

    private OrderService orderService;

    /**
     * 采购
     */
    @GlobalTransactional // 利用该注解标识全局事务
    public void purchase(String userId, String commodityCode, int orderCount) {

        storageService.deduct(commodityCode, orderCount);

        orderService.create(userId, commodityCode, orderCount);
    }
}
public class OrderServiceImpl implements OrderService {

    private OrderDAO orderDAO;

    private AccountService accountService;

    public Order create(String userId, String commodityCode, int orderCount) {

        int orderMoney = calculate(commodityCode, orderCount);

        accountService.debit(userId, orderMoney);

        Order order = new Order();
        order.userId = userId;
        order.commodityCode = commodityCode;
        order.count = orderCount;
        order.money = orderMoney;

        // INSERT INTO orders ...
        return orderDAO.insert(order);
    }
}
```





