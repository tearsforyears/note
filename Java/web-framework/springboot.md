# [SpringBoot](https://start.spring.io/)

---

springboot其解决了spring大部分配置的问题 解放了spring需要大量配置的问题

使得程序员专注于java的业务逻辑而非过于纠结配置本身的事情

基于云计算意味着docker和微服务架构

其特性如下

-   快速创建独立的Spring项目
-   嵌入式servlet 无需war即可运行
-   大量自动配置
-   无需配置xml(也可以使用)
-   准生产环境 运行时监控
-   天然适合云计算环境
-   在微服务下 天生适合与SpringCloud等RPC框架结合

---

## 使用感受

---

其主要优点如下

-   不用配置乱七八糟的beans.xml/web.xml 改用配置更好的properties和yaml并行配置
-   配置上还采用了一堆默认配置 使得开箱即用非常厉害 spring.io直接集成文件速度起飞
-   集成服务器debug速度和只用运行jar速度快如闪电的boot
-   集成服务器 部署微服务更快
-   集成各种各样的组件 却没有提高耦合度 从某种意义上讲配置的另一个好处
-   集成监控并有springboot-admin等开源监控实现(微服务和单项目监控)
-   和docker无缝贴合,springcloud的基础环境

---

## 目录

[TOC]

---

## spring-springmvc注解review

-   **@RequestMapping @GetMapping @HeadMapping**

-   **@Controller @Component @Repositroy @Configuration** 默认名字为类名小写

-   **@PathVariable**("name") **@GetMapping**("{name:[a-zA-Z]}{1,}")

-   **@RequestParam**("url param")

-   **@RestController** // restful标准支持 json格式的返回

-   **@Bean**(name="")注解 spring的注解非mvc的 标注在方法上 用于构造对象

    可以指定initMethod,destroyMethod用于加载或者销毁类

    默认的name为方法名字本身

-   **@Scope ** 用于指定bean的作用范围

-   **@Transactional** 事务注解 此注解标注在方法上(不要标记在接口上) 用于事务处理 发生异常时回滚 因为是 基于类代理和接口代理实现的 所以标注在接口上基本会在别的组件代理接口时失去效果 另外类内调用该方法也是不起作用的 只有当创建类的时候 该注解才会注入事务

-   **@Autowired @Resource** 根据类型 根据名字给Bean注入spring中创建好的对象

-   @ImportResource @Import 导入类或者资源文件

## ***springboot重要注解***

-   **@SpringBootApplication** 标注为springboot启动类

-   **@ComponentScan**(basePackages = {"com.xxx.service1.*","com.xxx.service2.**"})// 标注在SpringBootApplication的类上 进行包的扫描

-   **@Value**(${com.example.demo.name}) 这是spring的注解 在springboot中是提取application.properties的字段值

-   **@ConfigurationProperties**(prefix = "com.example") 相当注入整个命名空间 用于配置类的属性 省略一堆@Value

-   **@Configuration** 这个注解和上面的注解不一样 这个完全是充当beans.xml文件的作用了 里面的所有类会配置到文件里面去 用于配置filter之类的

    ---

-   @Entity hibernate注解标注在实体类上

    -   @Id
    -   @Column
    -   @GeneratedValue
    -   @ManyToOne
    -   @OneToMany

-   @MapperScan 标注在启动类上
-   @Mapper
    -   @Select
    -   @Results
    -   @Result
    -   @One
    -   @Many
    -   @Insert
    -   @Delete
    -   @Update

## tourist

### 创建项目

[Spring initializr](http://start.spring.io/)用于创建springboot项目选择web-springweb 当然idea可以自己选

一堆依赖可以通过选择配置上去 springboot采用默认配置简化了很多其他框架的配置

### 项目目录结构

是准的web项目结构 有SpringMVC javaweb任意一知识理解此架构不难.

```tree
.
├── HELP.md
├── mansystem.iml
├── mvnw
├── mvnw.cmd
├── pom.xml
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       └── example
│   │   │           └── demo
│   │   │               ├── DemoApplication.java
│   │   │               ├── configs # 存放配置
│   │   │               │   ├── AspectConfig.java
│   │   │               │   ├── RabbitConfig.java
│   │   │               │   ├── RedisConfig.java
│   │   │               │   ├── SessionConfig.java
│   │   │               │   └── WebConfiguration.java
│   │   │               ├── controller # 存放控制器
│   │   │               │   ├── GlobalExceptionController.java
│   │   │               │   ├── InfoController.java
│   │   │               │   ├── LoginController.java
│   │   │               │   ├── ManageController.java
│   │   │               │   ├── RegisterController.java
│   │   │               │   ├── StatisticsController.java
│   │   │               │   └── TestController.java
│   │   │               ├── handler # 存放异步处理任务
│   │   │               │   ├── AlertSchedulerTaskHandler.java
│   │   │               │   ├── SqlHandler.java
│   │   │               │   └── StatisticsSchedulerTaskHandler.java
│   │   │               ├── mapper # 存放mapper由mybatis/jpa实现
│   │   │               │   ├── CommunityMapper.java
│   │   │               │   ├── InOutMapper.java
│   │   │               │   ├── MessageMapper.java
│   │   │               │   └── UserMapper.java
│   │   │               ├── repositroy # 存放数据实体类
│   │   │               │   ├── AlertInfo.java
│   │   │               │   ├── Community.java
│   │   │               │   ├── In.java
│   │   │               │   ├── InOut.java
│   │   │               │   ├── InOutInfo.java
│   │   │               │   ├── Message.java
│   │   │               │   ├── Out.java
│   │   │               │   ├── Permission.java
│   │   │               │   ├── TPSInfo.java
│   │   │               │   └── User.java
│   │   │               ├── service # 存放service
│   │   │               │   ├── CommunityService.java
│   │   │               │   ├── InOutService.java
│   │   │               │   ├── MessageService.java
│   │   │               │   ├── NoticeService.java
│   │   │               │   └── UserService.java
│   │   │               └── utils # 存放常用的工具类
│   │   │                   ├── HttpUtils.java
│   │   │                   ├── IOUtils.java
│   │   │                   ├── JsonReponseBuilder.java
│   │   │                   ├── JwtUtil.java
│   │   │                   ├── MD5.java
│   │   │                   ├── PhoneCodeUtil.java
│   │   │                   └── SpringContextUtil.java
│   │   └── resources
│   │       ├── application.properties
│   │       ├── application.yml
│   │       ├── static
│   │       └── templates
│   └── test
│       └── java
│           └── com
│               └── example
│                   └── demo
│                       └── DemoApplicationTests.java
├── startup-dependences.sh
└── target
    ├── classes
    │   ├── application.properties
    │   ├── application.yml
    │   └── com
    │       └── example
    │           └── demo
    │               ├── DemoApplication.class
    │               ├── configs
    │               │   ├── AspectConfig.class
    │               │   ├── RabbitConfig.class
    │               │   ├── RedisConfig.class
    │               │   ├── SessionConfig.class
    │               │   ├── WebConfiguration$TokenFilter.class
    │               │   └── WebConfiguration.class
    │               ├── controller
    │               │   ├── GlobalExceptionController.class
    │               │   ├── InfoController.class
    │               │   ├── LoginController.class
    │               │   ├── ManageController.class
    │               │   ├── RegisterController.class
    │               │   ├── StatisticsController.class
    │               │   └── TestController.class
    │               ├── handler
    │               │   ├── AlertSchedulerTaskHandler.class
    │               │   ├── SqlHandler.class
    │               │   └── StatisticsSchedulerTaskHandler.class
    │               ├── mapper
    │               │   ├── CommunityMapper.class
    │               │   ├── InOutMapper.class
    │               │   ├── MessageMapper.class
    │               │   └── UserMapper.class
    │               ├── repositroy
    │               │   ├── AlertInfo.class
    │               │   ├── Community.class
    │               │   ├── In.class
    │               │   ├── InOut.class
    │               │   ├── InOutInfo.class
    │               │   ├── Message.class
    │               │   ├── Out.class
    │               │   ├── Permission.class
    │               │   ├── TPSInfo.class
    │               │   └── User.class
    │               ├── service
    │               │   ├── CommunityService.class
    │               │   ├── InOutService.class
    │               │   ├── MessageService.class
    │               │   ├── NoticeService.class
    │               │   └── UserService.class
    │               └── utils 
    │                   ├── HttpUtils.class
    │                   ├── IOUtils.class
    │                   ├── JsonReponseBuilder.class
    │                   ├── JwtUtil.class
    │                   ├── MD5.class
    │                   ├── PhoneCodeUtil.class
    │                   └── SpringContextUtil.class
    ├── generated-sources
    │   └── annotations
    ├── generated-test-sources
    │   └── test-annotations
    ├── mansystem.jar
    ├── mansystem.jar.original
    ├── maven-archiver
    │   └── pom.properties
    ├── maven-status
    │   └── maven-compiler-plugin
    │       └── compile
    │           └── default-compile
    │               ├── createdFiles.lst
    │               └── inputFiles.lst
    └── test-classes
        └── com
            └── example
                └── demo
                    └── DemoApplicationTests.class


```

### 快速运行的demo

```java
package com.example.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author zhanghaoyang
 */
@RestController
public class IndexController {
    @GetMapping("/index")
    public String index() {
        return "{'msg':'index'}";
    }
}
```

### 配置依赖环境pom.xml

pom.xml的配置简化了非常多 demo项目很容易可以跑出来 而且基本不用自己动手

```xml
	<dependencies>
        <!--开发工具 热部署-->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <optional>true</optional>
        </dependency>
        <!--springboot 基本依赖-->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
            <exclusions>
                <exclusion>
                    <groupId>org.junit.vintage</groupId>
                    <artifactId>junit-vintage-engine</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
```

### application.properties

这个文件在resource下是全局配置文件 我们约定这个文件里面一些值可以直接被项目的各个组件所引用

```properties
# 配置log的的输出地址和输出级别
logging.path=/user/local/log
logging.level.com.favorites=DEBUG
logging.level.org.springframework.web=INFO
logging.level.org.hibernate=ERROR
# 自定义变量
com.example.name=z3 
# @Value(${com.example.name})

database.engine=innodb
database.username=root
database.password=root
database.port=3306
database.host=127.0.0.1
# 定义数据库配置 默认使用JPA 下面配置hibernate
# 自动创建和更新数据库的值 值可选如下
# create 每次都删除原表自己新建
# create-drop 相当于临时表 每次关闭sqlSession的时候自动删除表
# update 第一次加载hibernate的时候根据model类自动建立表结构 以后更新表结构
# validate 每次加载 hibernate 时，验证创建数据库表结构，只会和数据库中的表进行比较，不会创建新表，但是会插入新值。
spring.jpa.properties.hibernate.hbm2ddl.auto=update 
# 数据库方言
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL5InnoDBDialect
spring.jpa.show-sql= true
```

### properties和yml配置文件

springboot里面有两种配置文件 application.properties`和`application.yml

这两种配置文件如果不设置优先级的话.yml先于.properties (.yml是yaml文件)

这里介绍下yml的格式比起.properties 用成员运算符带来的冗余 yml倾向python那种以空格为命名空间分界的方法

```properties
name=hello
server.port=8080
server.url=localhost
# list 集合
servers[0]=dev.bar.com
servers[1]=foo.bar.com
# map 集合本身就是上面这些属性
```

```yml
name: hello
server:
    port: 8080
    url: localhost 
server: {port: 8080,url: localhost}# map单行写法
servers: # list集合
  - dev.bar.com
  - foo.bar.com
servers: - dev.bar.com,- foo.bar.com # 单行这么写可以
```

这很json 值和冒号中间必须有空格 例如 name:mysql(错的) name: mysql(对的)

这个map解析老出问题可以使用spel解决问题

解决的思路是 把集合存成python的字符串#{${map}} 让spel来解决解析问题



### springboot配置文件加载顺序

-   先去项目根目录(./)再去资源文件目录(./resources)下寻找
-   文件类型properties > xml > yml > yaml
-   文件名application > application-default

```note
file:./config/application.properties
file:./config/application.xml
file:./config/application.yml
file:./config/application.yaml

file:./application.properties
file:./application.xml
file:./application.yml
file:./application.yaml

classpath:/config/application.properties
classpath:/config/application.xml
classpath:/config/application.yml
classpath:/config/application.yaml

classpath:/application.properties
classpath:/application.xml
classpath:/application.yml
classpath:/application.yaml

file:./config/application-default.properties
file:./config/application-default.xml
file:./config/application-default.yml
file:./config/application-default.yaml

file:./application-default.properties
file:./application-default.xml
file:./application-default.yml
file:./application-default.yaml

classpath:/config/application-default.properties
classpath:/config/application-default.xml
classpath:/config/application-default.yml
classpath:/config/application-default.yaml

classpath:/application-default.properties
classpath:/application-default.xml
classpath:/application-default.yml
classpath:/application-default.yaml
```



### 自定义Filter的配置类

```java
@Configuration // 相当于一个独立的beans.xml注入整体的xml中
public class WebConfiguration {
    
    @Bean // 自己注册过滤器的生成方法
    public FilterRegistrationBean testFilterRegistration() {

        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setFilter(new MyFilter());
        registration.addUrlPatterns("/*");
        registration.addInitParameter("paramName", "paramValue");
        registration.setName("MyFilter");
        registration.setOrder(1);
        return registration;
    }
    // 自己写的过滤器
    public class MyFilter implements Filter { // 内部类
		@Override
		public void destroy() {
			// TODO Auto-generated method stub
		}

		@Override
		public void doFilter(ServletRequest srequest, ServletResponse sresponse, FilterChain filterChain)
				throws IOException, ServletException {
			// TODO Auto-generated method stub
			HttpServletRequest request = (HttpServletRequest) srequest;
			System.out.println("this is MyFilter,url :"+request.getRequestURI());
			filterChain.doFilter(srequest, sresponse);
		}

		@Override
		public void init(FilterConfig arg0) throws ServletException {
			// TODO Auto-generated method stub
		}
    }
}
```

### springmvc拦截器的配置

暂略

### JPA的简单使用

---

JPA:Java Persistence API  持久层的一些列api 是sun整合orm技术的一套api

其最大的支持项就是hibernate(有必要深究此技术)

我们先来看下spring基本的数据库操作

@javax.persistence.Entity //JPA实体类对象

@Id @Column // 和数据库交互

@GeneratedValue // 和id一样标注在主键上 详细看hibernate注解

增加数据库连接的依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
 <dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
```

数据库连接配置参数

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/test
spring.datasource.username=root
spring.datasource.password=root
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.properties.hibernate.hbm2ddl.auto=update
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL5InnoDBDialect
spring.jpa.show-sql= true
```

标准javabean

```java
package com.example.model;
import lombok.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.validation.constraints.NotNull;
import java.io.Serializable;
@Entity
@Repository
@ToString
@Getter
@Setter
public class User implements Serializable {
    public User(){

    }
    public User(String userName,String passWord){
        this.userName = userName;
        this.passWord = passWord;
    }
    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue
    Long id;

    @Column(unique = false)
    @NotNull
    String userName;

    @Column(unique = false)
    @NotNull
    String passWord;
}
```

神奇的东西来了 我们编写个DAO类继承JpaRepository<User,Long> // 数据类型 主键类型

```java
package com.example.DAO;
import com.example.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Component;
import java.util.List;
@Component
public interface UserDAO extends JpaRepository<User, Long> {
    @Override
    List<User> findAll();
    User findUserByUserName(String userName); // 这里方法名要和类的字段对上
    User findUserById(Long id);
    boolean existsUserByUserNameAndPassWord(String username, String password);
}
```

执行下测试 和mybatis-Mapper的实现类似 spingboot帮我们实现了上面方法 以及另一部分方法

```java
@Autowired
UserDAO userDAO; // 从注入能看出来了吧 spring帮我们实现了上面的方法
public static void main(String[] args){
  System.out.println(userDAO.findAll().toString());
}
```

JpaRepository的api前缀和方法命名规则 后续会进一步讲述

-   find 

-   exists

-   count

-   命名规则

    findUserByUserName // findaaaBybbb aaa是类名可省略bbb是字段名首字母大写

    // 如上就对应着userName

    findUserByUserNameAndPassWord // And 或者 Or 字段名和或者与查询

### 重定向和转发

转发和重定向在springboot中变得很简单

```java
@GetMapping("/redirect")
String func(){
  return "forward:/red.html"; // redirect:/red.html
}
```

而且forward不能携带url参数

另外需要注意 这些事在标注@Controller的类上而不是@RestController

### 统一异常处理

常规错误处理方式有很多种 基于spring各个层次的体系 而下面这个在前后端分离比较通用点

使用 `@ControllerAdvice` + `@ExceptionHandler` 注解处理全局异常

```java
@ControllerAdvice
public class GlobalExceptionController {
		// 用来处理自己的运行时异常 或者有什么其他需要捕获的类型可以自己写
    @ExceptionHandler(value = {RuntimeException.class})
    public String runtimeExceptionHandle(ServletResponse response, Exception e) throws IOException, ServletException, InterruptedException {
        response.setCharacterEncoding("UTF-8");
        return "redirect:/error.html?msg="+e.getMessage();
    }
}
```

处理错误码

/static/error/404.html 可以直接放置静态html页面进行处理

---

## 集成redis

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
<!--托管session 弄了这部之后就正常调用session就行了 
应该是AOP给拦截代理HttpSession了 也就是说细节我们不用关心如何实现-->
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

```properties
# Redis数据库索引（默认为0）
spring.redis.database=0  
# Redis服务器地址
spring.redis.host=localhost
# Redis服务器连接端口
spring.redis.port=6379  
# Redis服务器连接密码（默认为空）
spring.redis.password=
# 连接池最大连接数（使用负值表示没有限制） 默认 8
spring.redis.lettuce.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制） 默认 -1
spring.redis.lettuce.pool.max-wait=-1
# 连接池中的最大空闲连接 默认 8
spring.redis.lettuce.pool.max-idle=8
# 连接池中的最小空闲连接 默认 0
spring.redis.lettuce.pool.min-idle=0
```

redis的配置缓存注册

```java
package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.interceptor.KeyGenerator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.*;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

/**
 * @author zhanghaoyang
 */
@Configuration
public class RedisConfig {


    @Autowired
    private LettuceConnectionFactory lettuceConnectionFactory; // lettuce客户端连接工厂


    private Jackson2JsonRedisSerializer<Object> jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer(Object.class); // json序列化器

    private Duration timeToLive = Duration.ofDays(1); // 缓存生存时间

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        // redis缓存配置
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(this.timeToLive)
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(keySerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(valueSerializer()))
                .disableCachingNullValues();
        // 缓存配置map
        Map<String, RedisCacheConfiguration> cacheConfigurationMap = new HashMap<>();
        // 自定义缓存名，后面使用的@Cacheable的CacheName
        cacheConfigurationMap.put("users", config);
        cacheConfigurationMap.put("default", config);
        // 根据redis缓存配置和reid连接工厂生成redis缓存管理器
        RedisCacheManager redisCacheManager = RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(config)
                .transactionAware()
                .withInitialCacheConfigurations(cacheConfigurationMap)
                .build();
        return redisCacheManager;
    }

    // redisTemplate模板提供给其他类对redis数据库进行操作
    @Bean(name = "redisTemplate")
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory redisConnectionFactory) {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory);
        redisTemplate.setKeySerializer(keySerializer());
        redisTemplate.setHashKeySerializer(keySerializer());
        redisTemplate.setValueSerializer(valueSerializer());
        redisTemplate.setHashValueSerializer(valueSerializer());
        return redisTemplate;
    }

    // redis键序列化使用StrngRedisSerializer
    private RedisSerializer<String> keySerializer() {
        return new StringRedisSerializer();
    }

    // redis值序列化使用json序列化器
    private RedisSerializer<Object> valueSerializer() {
        return new GenericJackson2JsonRedisSerializer();
    }


    // 缓存键自动生成器
    @Bean
    public KeyGenerator myKeyGenerator() {
        return (target, method, params) -> {
            StringBuilder sb = new StringBuilder();
            sb.append(target.getClass().getName());
            sb.append(method.getName());
            for (Object obj : params) {
                sb.append(obj.toString());
            }
            return sb.toString();
        };
    }
}
```

在service层使用lettuce的api

```java
@Autowired
private StringRedisTemplate stringRedisTemplate;
@Autowired
private RedisTemplate redisTemplate;
// 普通操作
stringRedisTemplate.opsForValue().set("aaa", "111");
System.out.println(stringRedisTemplate.opsForValue().get("aaa"));

// 缓存序列化对象
User user = new User("ready", "perfect");
ValueOperations<String, User> operations = redisTemplate.opsForValue();
operations.set("user", user);
System.out.println(operations.get("user"));
```

### redis-api

```java
@Autowired
private StringRedisTemplate stringRedisTemplate; 
// 只是操作string类型时候用 本质是序列化的工具不同
@Autowired
private RedisTemplate redisTemplate;

// 以下方法提供操作redis的对象
StringRedisTemplate.opsForValue().* // 操作String字符串类型
StringRedisTemplate.delete(key/collection) // 根据key/keys删除
StringRedisTemplate.opsForList().*  // 操作List类型
StringRedisTemplate.opsForHash().*  // 操作Hash类型
StringRedisTemplate.opsForSet().*  // 操作set类型
StringRedisTemplate.opsForZSet().*  // 操作有序set

// string
stringRedisTemplate.opsForValue().set("aaa", "111");
System.out.println(stringRedisTemplate.opsForValue().get("aaa"));
System.out.println(stringRedisTemplate.opsForValue().size("aaa"));
stringRedisTemplate.opsForValue().append("aaa"," 222");

// list
redisTemplate.opsForList().leftPush()
redisTemplate.opsForList().rightPush()
redisTemplate.opsForList().rightPop()
redisTemplate.opsForList().leftPop()
List<String> ls =  redisTemplate.opsForList().range("list",0,redisTemplate.opsForList().size("list")-1); // 读取的结果就是List

// hash
Map<String,String> dict = new HashMap<String, String> ();
dict.put("hello","world");
dict.put("redis","json");
stringRedisTemplate.opsForHash().putAll("testMap",dict);       System.out.println(stringRedisTemplate.opsForHash().entries("testMap"));

// set
redisTemplate.opsForSet().add("testSet", "1", "2", "3");
redisTemplate.opsForSet().members("testSet").forEach((item) -> {
  System.out.println(item);
});

// object
// 本质就是操作序列化字符串
// 当然可以存json都是没问题的 Fastjson为例
User user = new User(11L, "redis", "redisPass");
ValueOperations<String, User> operations = redisTemplate.opsForValue();
String user_str = JSON.toJSONString(user);
redisTemplate.opsForValue().set("user_json", user_str);
String json_user = (String) redisTemplate.opsForValue().get("user_json");
System.out.println(JSON.parseObject(json_user, User.class));

// 利用配置好的序列化解析器我们也可以像这样子dump
// 下面这种官方推荐
User user = new User("ready", "perfect");
ValueOperations<String, User> operations = redisTemplate.opsForValue();
operations.set("user", user);
System.out.println(operations.get("user"));
```

---

## **springboot-jpa(hibernate)**

jpa是Java Persistence API 指的是一套持久化的规范,springboot-jpa是基于jpa在spring上的一套实现,我们可以不再编写传统的CRUD操作,**JPA 适用于开发后台程序**,对sql不需要特别多的精准控制,**其核心特点就是开发速度极快,但tkmybatis等框架也让Jpa优势没有那么大**

关键注解

- @Entity @Table 两者都是用于关联表和pojo,前者标准,后者自定义映射规则
- @EnableJpaAuditing @EntityListeners 在持久化时进行监听
- @Enumerated 用于表示枚举类型在数据库中的存储形式,一般是在数据库中存的数字,这里可以转化成存String类型
- @Temporal(TemporalType.TIME) 用于指定时间格式
- @LastModifiedDate , @CreatedDate 对应数据库两个字段
- @DynamicUpdate @DynamicInsert 自动生成更新和插入语句
- @Convert

```java
@Data
@Entity
@Table(name = "PushQueue",
    indexes = {@Index(name = "uniq_region_name", columnList = "region,name")})
@EntityListeners(AuditingEntityListener.class) // 指定监听类回调监控持久化
public class PushQueue {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private long id;

  @Convert(converter = LongListToStringConverter.class)
  private List<Long> relatedUserGroup;

  private String timezone;

  @Convert(converter = StringListToStringConverter.class)
  private List<String> scheduleTime;

  @Convert(converter = StringListToStringConverter.class)
  private List<String> subRegions;

  @Temporal(TemporalType.TIMESTAMP)
  @CreatedDate
  private Date createTime;
}
```



添加自定义方法与高级条件查询

原生查询,一般不会多使用,因为其涉及到表明等问题

```java
@Query(value = "select * from book b where b.name=?1", nativeQuery = true) // ?1 表示一个参数
List<Book> findByName(String name); // List<Book> findByName(@Param("name") String name);

@Query(value = "select name,author,price from Book b where b.name like %:name%") // 注入属性
List<Book> findByNameMatch(@Param("name") String name);
```

specification提供了更加复杂的条件查询,其整体可以理解为一个条件

```java
public interface PushVideoRepository extends JpaRepository<PushVideo, Long>,
JpaSpecificationExecutor<PushVideo> {

}

static Specification<PushVideo> sourceKey(String sourceKey) {
  return (root, query, cb) -> cb.equal(root.get("sourceKey"), sourceKey);
  // 这三个参数形式固定
  // Root<T> root, CriteriaQuery<?> query, CriteriaBuilder cb
  // 其实就是生成查询条件,上面的形式比较固定,用于生产Specification
  // 上述代码的作用就是生成 sourceKey == sourceKey的条件
  // 这三个处理如下
}
```

- root
  Root接口，主要用于处理实体和字段、实体与实体之间的关系。除了上述例子中的取字段的操作以外，还可以做join操作。
- query
  CriteriaQuery接口，主要用于对查询结果的处理，包括groupBy、orderBy、having、distinct等操作。
- criteriaBuilder
  CriteriaBuilder接口，主要用于各种条件查询、模拟sql函数等。

### 基本查询

基本查询分两种 一种是Spring Data已经默认实现了 另一种则是根据方法名解析SQL(大杀器)

实现JPA需要我们的接口继承 JpaRepository

```java
public interface UserRepository extends JpaRepository<User, Long> {}
// 这个Long是一个主键 JpaRepostitory已经实现了一些方法 我们可以开箱即用
// 除此之外如果自己需要加方法的话 可以自己加 SpringBoot会帮助我们实现这些方法
```

下面为一个示例

```java
@Component
public interface UserDAO extends JpaRepository<User, Long> {
    @Override
    List<User> findAll(); // 原有方法 springboot-jpa预实现方法
    /**
     * find a user by his name
     *
     * @param userName username
     * @return a user entity
     */
    User findUserByUserName(String userName); // 这里方法名要和类的字段对上
    /**
     * find a user by his id
     *
     * @param id id
     * @return a user entity
     */
    User findUserById(Long id);
    /**
     * @param username username
     * @param password password
     * @return is user exist
     */
    boolean existsUserByUserNameAndPassWord(String username, String password);

}
```

或者我们可以直接调用springboot-jpa的方法

```java
@Autowired
UserRespository userRespository;
// test code
User user=new User();
userRepository.findAll();
userRepository.findOne(1L);
userRepository.save(user);
userRepository.delete(user);
userRepository.count();
userRepository.exists(1L);
```

自定义方法名

```java
User findByUserName(String userName); // User里面的一属性叫userName
User findByUserNameOrEmail(String username, String email); 
// Or可以用作或查询
// 一些比较复杂的查询
List<User> findByEmailLike(String email);
User findByUserNameIgnoreCase(String userName);
// select * from table where userName = #{userName} order by email desc
List<User> findByUserNameOrderByEmailDesc(String userName);
```

另外还有如下方法被编译成sql语句

| Keyword           | Sample                                  | JPQL snippet                                                 |
| :---------------- | :-------------------------------------- | :----------------------------------------------------------- |
| And               | findByLastnameAndFirstname              | … where x.lastname = ?1 and x.firstname = ?2                 |
| Or                | findByLastnameOrFirstname               | … where x.lastname = ?1 or x.firstname = ?2                  |
| Is,Equals         | findByFirstnameIs,findByFirstnameEquals | … where x.firstname = ?1                                     |
| Between           | findByStartDateBetween                  | … where x.startDate between ?1 and ?2                        |
| LessThan          | findByAgeLessThan                       | … where x.age < ?1                                           |
| LessThanEqual     | findByAgeLessThanEqual                  | … where x.age ⇐ ?1                                           |
| GreaterThan       | findByAgeGreaterThan                    | … where x.age > ?1                                           |
| GreaterThanEqual  | findByAgeGreaterThanEqual               | … where x.age >= ?1                                          |
| After             | findByStartDateAfter                    | … where x.startDate > ?1                                     |
| Before            | findByStartDateBefore                   | … where x.startDate < ?1                                     |
| IsNull            | findByAgeIsNull                         | … where x.age is null                                        |
| IsNotNull,NotNull | findByAge(Is)NotNull                    | … where x.age not null                                       |
| Like              | findByFirstnameLike                     | … where x.firstname like ?1                                  |
| NotLike           | findByFirstnameNotLike                  | … where x.firstname not like ?1                              |
| StartingWith      | findByFirstnameStartingWith             | … where x.firstname like ?1 (parameter bound with appended %) |
| EndingWith        | findByFirstnameEndingWith               | … where x.firstname like ?1 (parameter bound with prepended %) |
| Containing        | findByFirstnameContaining               | … where x.firstname like ?1 (parameter bound wrapped in %)   |
| OrderBy           | findByAgeOrderByLastnameDesc            | … where x.age = ?1 order by x.lastname desc                  |
| Not               | findByLastnameNot                       | … where x.lastname <> ?1                                     |
| In                | findByAgeIn(Collection ages)            | … where x.age in ?1                                          |
| NotIn             | findByAgeNotIn(Collection age)          | … where x.age not in ?1                                      |
| TRUE              | findByActiveTrue()                      | … where x.active = true                                      |
| FALSE             | findByActiveFalse()                     | … where x.active = false                                     |
| IgnoreCase        | findByFirstnameIgnoreCase               | … where UPPER(x.firstame) = UPPER(?1)                        |

### 复杂查询

#### 分页查询

传入一个Pageable参数即可

```java
Page<User> findByUserName(String userName,Pageable pageable);
```

```java
Pageable pageable = PageRequest.of(0, 3);
Page<User> pages = userDAO.findAll(pageable);
System.out.println(pages.getTotalPages());
pages.forEach((user) -> {
  System.out.println(((User) user).toString());
});
```

#### 自定义sql

-   @Query 自己写sql
-   @Modifying 标注已经修改的字段

@Query注解

```java
@Modifying
@Query("update user u set u.userName = ?1 where u.id = ?2")
int modifyByIdAndUserId(String  userName, Long id);
	
@Transactional // 支持事务
@Modifying // 写语句要加上注解
@Query("delete from user where id = ?1")
void deleteByUserId(Long id);

// ?1 ?2 分别代表方法第一第二个参数 大大简化了思考过程
// 这里有个注意的点 这里的User并不是数据库里实际存的表 而是 JPA的POJO类名和字段名
@Query("select phoneNumber from User where userName=?1")
String findUserPhoneNumberByUserName(String username);
// 或者用命名参数:username 本质上讲就是HQL(hibernate sql)
@Query("select phoneNumber from User where userName=:username")
String findUserPhoneNumberByUserName(@String username);

// 不使用hql 原生的sql进行查询的时候要把nativeQuery标记为true
@Query("select phone_number from user where user_+name=:username",nativeQuery = true)
String findUserPhoneNumberByUserName(@String username);
```

#### ***多表查询***

-   hibernate的级联查询

    模型是User和Question 一个User有多个问题 一个问题只有一个User

    @OneToMany(mapperBy="",fetch = FetchType.EAGER) 标注在Many上 会产生中间表 但是可以用joincolumn来不生成中间表

    @ManyToOne(fetch = FetchType.LAZY) 标注在One上 不会产生中间表

    ```java
    // pojo
    @AllArgsConstructor
    @Entity
    @Repository
    @ToString
    @Getter
    @Setter
    public class Question implements Serializable {
        public Question() {}
        @Id
        @GeneratedValue
        Long id;
        String questionName;
        String questionDescribe;
        @ManyToOne(fetch = FetchType.LAZY)
        User user; // 用于留下引用
    }
    
    @AllArgsConstructor
    @Entity
    @Repository
    @ToString
    @Getter
    @Setter
    public class User implements Serializable {
        public User(String userName, String passWord) {
            this.userName = userName;
            this.passWord = passWord;
        }
        public User() {}
    
        private static final long serialVersionUID = 1L;
        @Id
        @GeneratedValue
        Long id;
        @NotNull
        String userName;
        @NotNull
        String passWord;
        // 对应Question里面的属性 用于标志引用
        @OneToMany(mappedBy = "user",fetch = FetchType.LAZY)
        List<Question> questions;
    }
    ```

-   创建结果集接口

    ```java
    // DAO
    @Query(value = "select u.userName as username,q.questionName as name,q.questionDescribe as describe from Question q left join User u on u.id=q.user.id")
    List<QuestionInfo> findAllQuestionInfo();
    // QuestionInfo
    @Component
    public interface QuestionInfo {
        String getName(); // JPA会注入name属性
        String getUsername();
        String getDescribe();
    }
    ```

## springboot-mybatis(推荐使用)

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/test
spring.datasource.username=root
spring.datasource.password=root
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

```xml
<dependency>
  <groupId>mysql</groupId>
  <artifactId>mysql-connector-java</artifactId>
</dependency>
<dependency>
  <groupId>org.mybatis.spring.boot</groupId>
  <artifactId>mybatis-spring-boot-starter</artifactId>
  <version>2.1.2</version>
</dependency>
```

orm框架发展到现在就剩以mybatis/mybatis-plus的灵活sql和不用写一句sql,jpa-hibernate为顶层的两大框架,hibernate经过jpa优化已经开发难度已经很低了,而mybatis经过注解等优化之后基本也是非常完善的技术体系了 按照经验而言mybatis给了DBA存在的理由 优化可以做的特别好

-   @Mapper 标注在Mapper上 
-   @MapperScan("com.example.mapper") 标注在启动类上

用过Mapper的注解之后 相比于JPA-HQL实现的 其灵活性是无与伦比的

-   @Select @Insert @Delete @Update
-   @Results @Result

```java
@Component
public interface UserMapper {
    @Select("SELECT * FROM user")
    @Results({
            @Result(property = "userName", column = "user_name"),
            @Result(property = "passWord", column = "pass_word")
    })
    List<User> findAll(); 
  	// 虽然jpa有原生实现但是 注解的注入远不如mybatis来的和谐
  	// 而且对于pojo类 因为不用对应关系的表 所以从某种意义上来说 只是用来承载数据完全不用去维护关系
  	// 另外 select 除非字段名一致 都要手动标注结果集
  	@Select("select count(id) from user")
    int countUsers();
}
// Pojo 
@NoArgsConstructor
@AllArgsConstructor
@ToString
@Repository
@Getter
@Setter
public class User implements Serializable {
    private static final long serialVersionUID = 1L;
    Long id;
    String userName;
    String passWord;
}
```

### 复杂查询

mybatis的Pojo比较自由 没有hibernate那样的约束 只是用于保存结果而已 用于维护的表关系的注解如下

-   @One 返回一个查询的对象注入结果集
-   @Many 返回一组查询的对象注入结果集

```java
// Question Mapper
@Component
public interface QuestionMapper {
  
  @Select("select * from question q left join user u on q.user_id=u.id where user_name=#{username}")
  @Results({
    @Result(property = "questionName", column = "question_name"),
    @Result(property = "questionDescribe", column = "question_describe"),
    @Result(property = "user", column = "user_id", one = @One(select = "com.example.mbttest.mapper.UserMapper.findUserById")) // 指定方法
  }) 
  // @One 直接找对应方法根据参数user_id直接注入字段 相当于执行2次sql
  // 虽然是并发执行的 但是对于大规模的数据时候仍需要慎重考虑
  List<Question> findQuestionInfoByUsername(String username);

  // 省略结果集 为@Many查询提供api
  @Select("select * from question where user_id=#{id}")
  List<Question> findQuestionsByUserId(Long id);
}

// User Mapper
@CacheNamespace
@Component
public interface UserMapper {
		// 省略结果集 为@One方法提供api
    @Select("select * from user where id=#{id}")
    User findUserById(Long id);

  @Results({
    @Result(property = "userName", column = "user_name"),
    @Result(property = "passWord", column = "pass_word"),
    @Result(property = "questions", column = "id", many = @Many(select = "com.example.mbttest.mapper.QuestionMapper.findQuestionsByUserId")) })
  @Select("select * from user where id=#{id}")
  User findUserQuestionInfoById(Long id);
  // @Many 指定api获取questions 本质上也是查询两次
  // 和上面类似 所有涉及了集合的查询都是并发执行的
}
```

我们还可以用xml文件像以前一样配置mybatis-mapper

```properties
mybatis.config-location=classpath:mybatis/mybatis-config.xml
mybatis.mapper-locations=classpath:mybatis/mapper/*.xml
```

开启某个包的mybatis的日志

```properties
logging.level.com.fourspring.springtest.mapper=debug
```

### mybatis plus

是国人写的一个增强mybatis的工具 也就是增强使用 原生sql一样可以实现

可以写入语句导入 后续在研究此插件

```xml
<dependency>
  <groupId>com.baomidou</groupId>
  <artifactId>mybatis-plus-boot-starter</artifactId>
  <version>3.1.1</version>
</dependency>
```

```java
package com.example.mbttest;

import com.baomidou.mybatisplus.extension.plugins.PaginationInterceptor;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("com.example.mbttest.mapper")
public class MybatisPlusConfig {
  
    @Bean
    public PaginationInterceptor paginationInterceptor() {
        return new PaginationInterceptor();
    }
}
```

```java
public interface UserMapper extends BaseMapper<User> {
  // 这种写法就可以 继承mybatis plus写的一些基本crud方法
  // 和springboot-jpa写法类似 不过封装的代码相对比较少
  // 如果需要类jpa的查询方式可以使用 不过用mybatis原生查询会比较好
}
```

mybatis 少了 jpa 的部分创建语句多了部分 sql,除了 原生的 mybatis,mybatis 之外,还可以使用 tkmybatis 进行更加优化查询的方式



```xml
 <dependency>
   <groupId>tk.mybatis</groupId>
   <artifactId>mapper-spring-boot-starter</artifactId>
   <version>2.1.5</version>
</dependency>
```

```java
public interface HouseMapper extends Mapper<House>,MySqlMapper<House> {
}
```

除此之外可以使用 Example 动态拼接 sql 进行查询和删除等

```java
@Override
  public DataPage<Experiment> search(Integer limit, Integer offset, Long id, Long parentId,
      String name, Integer status) {
    Example example = new Example(Experiment.class);
    example.and()
        .andEqualTo("id", id)
        .andEqualTo("parentId", parentId)
        .andEqualTo("status", status)
        .andLike("name", StringUtil.isEmpty(name) ? null : "%" + name + "%")
    ;
    int total = experimentMapper.selectCountByExample(example);
    List<Experiment> data = experimentMapper.selectByExample(example);
    return DataPage.<Experiment>builder()
        .data(data)
        .total(total)
        .nextOffset(Math.min(offset + limit, total))
        .build();
  }
```

自动建表可以使用下面的方法

```xml
<dependency>
    <groupId>com.gitee.sunchenbin.mybatis.actable</groupId>
    <artifactId>mybatis-enhance-actable</artifactId>
    <version>1.0.3</version>
</dependency>
```

```properties
mybatis.table.auto=update
mybatis.model.pack=com.example.entity
mybatis.database.type=mysql
```



## spring缓存

- 在介绍SpringCache之前.我们先来说说缓存的作用,一般对于后端程序而言,耗时操作有两个地方

  - 查询数据库
  - 调用其他服务的API(其他的服务也会最终去调用数据库的查询).

  重复查询的如果每次都使用数据库那么其就有非常大的流量进入.缓存的框架大概分为以下的几类

  - redis
  - memcached
  - guava
  - caffeine

  spring就提供了一种缓存技术用于缓存本地的key-value对,其有如下特性

  - 支持SpEL
  - 支持注解
  - 支持自己定义key和定义缓存池

  我们来介绍其使用,配置好一缓存池,比如spring自带的缓存池,可以用

  ```xml
  <bean id="cacheManager" class="org.springframework.cache.support.SimpleCacheManager">
    <property name="caches">
      <set>
        <bean class="org.springframework.cache.concurrent.ConcurrentMapCacheFactoryBean">
          <property name="name" value="default"/>
        </bean>
        <bean class="org.springframework.cache.concurrent.ConcurrentMapCacheFactoryBean">
          <property name="name" value="accountCache"/>
        </bean>
      </set>
    </property>
  </bean>
  ```

  ```java
  @Cacheable(value="accountCache") // 使用了accountCache这个缓存池.
  public Account getAccountByName(String accountName) {
    // 方法内部实现不考虑缓存逻辑，直接实现业务
    logger.info("real querying account... {}", accountName);
    Optional<Account> accountOptional = getFromDB(accountName);
    if (!accountOptional.isPresent()) {
      throw new IllegalStateException(String.format("can not find account by account name : [%s]", accountName));
    }
    return accountOptional.get();
  }
  ```

  这个注解的意思没有的话使用下面的代码段获取数据,否则就把数据加载到缓存.顶层还是用到了一个cacheManager.除此之外我们还需要清空缓存的逻辑.

  ```java
  // 使用了一个缓存名叫 accountCache
  @Cacheable(value="accountCache")
  public Account getAccountByName(String accountName) {
    // 方法内部实现不考虑缓存逻辑，直接实现业务
    logger.info("real querying account... {}", accountName);
    Optional<Account> accountOptional = getFromDB(accountName);
    if (!accountOptional.isPresent()) {
      throw new IllegalStateException(String.format("can not find account by account name : [%s]", accountName));
    }
    return accountOptional.get();
  }
  
  @CacheEvict(value="accountCache",key="#account.getName()") // 清空缓存,以Account的name作为key去标识缓存的不同
  public void updateAccount(Account account) {
    updateDB(account);
  }
  
  @CacheEvict(value="accountCache",allEntries=true) //
  public void reload() {
    
  }
  ```

  可以做条件缓存,如下.给`accountName.length() < 4`,这condition指定一个boolean值返回就可以.指定可以是SpEL.

  ```java
  @Cacheable(value="accountCache",condition="#accountName.length() <= 4") // 缓存名叫 accountCache 
  public Account getAccountByName(String accountName) {
      // 方法内部实现不考虑缓存逻辑，直接实现业务
      return getFromDB(accountName);
  }
  ```

  强制更新缓存

  ```java
   // 更新 accountCache 缓存
   @CachePut(value="accountCache",key="#account.getName()")
   public Account updateAccount(Account account) { 
     return updateDB(account); 
   }
  
   private Account updateDB(Account account) { 
     logger.info("real updating db..."+account.getName()); 
     return account; 
   }
  ```

  一般使用的就是以下三个注解

  - @Cacheable 设置缓存,**一般用在查询方法上**
  - @CachePut 没次都会触发方法调用,**一般用在新增方法上**
  - @CacheEvict 根据一定条件对缓存进行清空,**一般用在修改或是删除方法上**

  因为查询用的比较多我们通过一些SpEL来看看@Cacheable的其他用法

  ```java
  @Cacheable(value = "user-group", cacheManager = "redisCacheManager", // value是用来指定组件的名字
        key = "#groupId + ':amount'", // #groupId代表了参数,SpEL这句话的含义即是字符串拼接,key代表了含义是缓存里的key
             unless = "#result < 0") // #result代表了方法执行后的返回值,这句话的含义是一个条件表达式
  public long getGroupUserAmount(String queryId, String groupId) {}
  ```

  注意到上面注解还有unless属性

  - unless属性是这个条件为true的时候,方法的返回值就不会被缓存
  - 同理还有condition属性,即只有condition为true的时候该方法才会被缓存

  

  spring的缓存有一些缺点,我们可以通过第三方缓存来解决这个问题

  - 不支持高可用
  - 不支持分布式

  spring给我们提供了一个cache接口

  ```java
  import org.springframework.cache.support.AbstractCacheManager;
  ```

  我们可以实现其中一些方法让他拥有使用,我们实现其管理器和自己的缓存

  ```java
   public class MyCacheManager extends AbstractCacheManager { 
     private Collection<? extends MyCache> caches;
     /** 
     * Specify the collection of Cache instances to use for this CacheManager. 
     */ 
     public void setCaches(Collection<? extends MyCache> caches) { 
       this.caches = caches; 
     } 
     @Override 
     protected Collection<? extends MyCache> loadCaches() { 
       return this.caches; 
     } 
   }
  
   public class MyCache implements Cache { 
     private String name; 
     private Map<String,Account> store = new HashMap<String,Account>();; 
  
     public MyCache() { 
     } 
  
     public MyCache(String name) { 
       this.name = name; 
     } 
  
     @Override 
     public String getName() { 
       return name; 
     } 
  
     public void setName(String name) { 
       this.name = name; 
     } 
  
     @Override 
     public Object getNativeCache() { 
       return store; 
     } 
  
     @Override 
     public ValueWrapper get(Object key) { 
       ValueWrapper result = null; 
       Account thevalue = store.get(key); 
       if(thevalue!=null) { 
         thevalue.setPassword("from mycache:"+name); 
         result = new SimpleValueWrapper(thevalue); 
       } 
       return result; 
     } 
  
     @Override 
     public void put(Object key, Object value) { 
       Account thevalue = (Account)value; 
       store.put((String)key, thevalue); 
     } 
  
     @Override 
     public void evict(Object key) { 
     } 
  
     @Override 
     public void clear() { 
     } 
   }
   
  ```

  我们可以用以下两种高性能缓存库

  - guava
  - caffeine

  ```xml
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-cache</artifactId>
  </dependency>
  <dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
    <version>2.7.0</version>
  </dependency>
  ```

  ```java
  @Configuration
  public class CacheManagerConfig {
    @Bean
    public CacheManager localCacheManager() {
      CaffeineCacheManager cacheManager = new CaffeineCacheManager();
      cacheManager.setCaffeine(Caffeine.newBuilder().expireAfterWrite(2, TimeUnit.HOURS));
      return cacheManager;
    }
  }
  ```

  然后我们在springboot上标注相应的注解,就可以使用了

  ```java
  @EnableCaching
  ```

  

## AOP

使用强制代理方法,我们知道在初始化类的过程时才会完成代理,但有些时候我们需要在本类调用其内部方法,又要其发生代理,我们可以直接这么写其方法,可以强制其代理invokeMethod

```java
public void method(){
	((ThisServiceImpl) AopContext.currentProxy()).invokeMethod(url);
}
```

我们对注解进行拦截就可以使其实现一定的功能如下

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface TimerLog {
  String name() default "";
}

@Component
@Aspect
@Slf4j
public class TimeLogAspect {

  @PostConstruct
  public void init() {
    log.info("[TimerLogAspect] init in spring context");
  }

  @Pointcut("@annotation(com.dayuwuxian.plugin.annotation.TimerLog)")
  public void TimerLog() {
  }

  @Around("TimerLog()")
  public Object toTimerLog(ProceedingJoinPoint pjp) throws Throwable {
    MethodSignature signature = (MethodSignature) pjp.getSignature();
    TimerLog annotation = signature.getMethod().getAnnotation(TimerLog.class);
    long start = System.currentTimeMillis();
    Object o = pjp.proceed();
    log.info("{} cost {} ms ", annotation.name(), System.currentTimeMillis() - start);
    return o;
  }
}

```



## Bean生命周期的控制方法

- @PostConstruct
- @PreDestory
- @Autowired
- InitializingBean接口
- DisposableBean接口

```java
@Component
public class InitSequenceBean implements InitializingBean,DisposableBean {
    public InitSequenceBean() {
       System.out.println("constructor");
    }
  	
  	@Autowired
  	public static InitClass initClass; 
  	// class InitClass{ static{ System.out.println("invoke");} }  
      
    @PostConstruct
    public void postConstruct() {
       System.out.println("postConstruct");
    }
  
  	@PreDestroy
  	public void preDestory(){
      System.out.println("preDestory");
    }
  
  	@Override
  	public void destory(){
      System.out.println("destory");
    }
    @Override
    public void afterPropertiesSet() throws Exception {
       System.out.println("afterPropertiesSet");
    }
}
```

代理之后的输出结果

```shell
constructor
postConstruct
invoke
afterPropertiesSet
# init method
preDestory
destory
```





## RestTemplate

一个请求的通用接口,可以通过 setClientHttpRequestFactory 指定底层的请求库,默认使用了 java.net.HttpUrlConnection 包实现了Http请求,就和 python 的 requests 库一样,我们可以用来实现爬虫等,其在项目中的整体作用就是用于实现远程调用

- RestTemplate用于发送Http请求时,如果是Get请求参数直接拼接到url上,如果是Post请求的话要用`postForObject`要拼接map用于注入.
- 经过测试其发送的报文可能会和想象中的不一样,熟悉报文的请研究好报文体在发送请求

关键方法

```java
```





## 定时调度

- @Scheduler

我们这里讨论定时任务的一些细节,假设一个定时任务每5s执行一次,但任务本身耗时6s.

- Cron默认处理是等待上一个任务执行完成之后再去执行下一个任务,**且在执行任务时间过长的时候会进行判断跳到下一个时间段**,即**默认单线程**
- 指定fixedDelay,即上一任务执行完成之后多久才执行下一任务
- 指定fixedRate,上一任务和下一任务开始时间的间隔,**当上一次任务没有执行完执行上次完成后再去执行下一个**

使用场景

- fixedDelay用于两个任务之间延迟时间的指定
- fixedRate是两次任务开始之间的间隔,不会跳过,顺序执行
- cron配置了哪一刻执行任务,如果不能执行则会跳过

强调任务间隔的定时任务,使用fixedRate和fixedDelay,强调某时某刻某分执行的任务使用cron表达式

### 定时调度的多线程配置

因为@Scheduler的默认配置是单线程实现的,某些场景会造成堵塞,对于每个任务都新起一个线程去执行的情况,可以使用`@Async`注解.

```java
@Scheduled(cron = "0/2 * * * * ?")
@Async("threadPoolBean")
public void doTask() throws InterruptedException {
  logger.info(Thread.currentThread().getName()+"===task run");
  Thread.sleep(6*1_000);
  logger.info(Thread.currentThread().getName()+"===task end");
}
```

这样就完成了我们的需求.@Async的默认线程池数量是100,我们可以把线程池的一些核心参数自己配置.



## 其他语法相关

@Autowired

```java
@Autowired
List<Job> ls; // spring语法,可以把所有的实现了Job接口的Bean都导入进来

BeanUtils.copyProperties(source,target); // 浅拷贝复制相同的属性

@Value("${val:default_val}") // spel表达式的默认值
String value;

/**利用构造方法一并 autowired **/
private final TopicRepository topicRepository;
private final TopicVideoRelRepository tvRepository;

@Autowired
public TopicServiceImpl(TopicRepository topicRepository,
                        RedisTopicCache redisTopicCache) {
  this.topicRepository = topicRepository;
  this.redisTopicCache = redisTopicCache;
}

```

实现ApplicationContextAware接口获取上下文

```java
private static ApplicationContext context;
private transient AutowireCapableBeanFactory beanFactory;
@Override
public void setApplicationContext(ApplicationContext ctx) throws BeansException {
  beanFactory = ctx.getAutowireCapableBeanFactory();
  context = ctx;
}
```

### enum类

所有的枚举类都继承于`java.lang.Enum`,枚举是一种常见形式的常量定义,避免我们书写过多的final static的一种特殊类型

简单使用,其实就相当于一个常量的存储库

```java
public enum TestEnum{
  VAL1,VAL2
}

@Test
public void test(){
  TestEnum val = TestEnum.VAL1;
  System.out.println(val);
  System.out.println(val instanceof java.lang.Enum);
}
```

枚举类的基本实现原理

编译器会生成一个相关的类,这个类继承抽象类`java.lang.Enum`,除此之外还有两个static方法,`valuesOf`和`values`方法.我们可以通过该方法遍历到其所有属性,其内部还有一方法叫`ordinal`用于标注其顺序,如下所以本质上其内部使用的是int作为顺序去进行传递,同时其实现了compareable接口,也是根据此来进行比较的

```java
public final int ordinal() {
  return ordinal;
}
```

我们观察期代码还会发现一个全量构造器

```java
protected Enum(String name, int ordinal) {
  this.name = name;
  this.ordinal = ordinal;
}
```

然后我们可以利用如下进行定义和声明

```java
public enum Day{
  MONDAY("周一",1),
  TUESDAY("周二",2),
  WEDNESDAY("周三",3); // 这里要用分号结束
  
  // 成员变量和方法定义
  private String desc;
  public String getDesc(){
    return desc;
  }
  public String setDesc(String desc){
    this.desc = desc;
  }
}
```

扩展枚举类不能使用继承,因为其继承自`java.lang.Enum`,但可以实现其他接口,我们可以用接口组织枚举

```java
public interface Food {  
    enum Coffee implements Food{  
        BLACK_COFFEE,DECAF_COFFEE,LATTE,CAPPUCCINO  
    }  
    enum Dessert implements Food{  
        FRUIT, CAKE, GELATO  
    }  
}

System.out.println(Food.Coffee.BLACK_COFFEE); // 如此形式调用
```

然后再调用的时候我们就可以把接口当做类去调用其内部属性了,另外要注意的是,枚举类型本身不是int类型,所以无法直接比较

```java
System.out.println(Food.Coffee.BLACK_COFFEE == Food.Dessert.FRUIT); // 如下代码会出错
```

另外其有一多态的功能（面向接口编程牛逼）

```java
Food food = Food.Coffee.BLACK_COFFEE;
food = Food.Dessert.CAKE; // also ok
```

可以扩充的enum写法,如果是上面的类型就直接自己new一种然后指定.

```java
public enum VideoSource {
  OPS_VIDEO("OPS_Video"),
  RANK_TOP_DOWNLOAD("Rank_Top_Download"),
  RANK_TOP_5S_PLAY("Rank_Top_5s_Play"),
  RANK_TOP_5S_PLAY_RATE("Rank_Top_5s_Play_Rate"),
  YOUTUBE_CHANNEL("Youtube_channel");

  private String value;

  VideoSource(String value) {
    this.value = value;
  }

  public String getValue() {
    return value;
  }
}
```



## 集成spring-security

spring-security是一个准们用来处理安全的框架 其处理XSS攻击,跨站伪造等,同时其具备集成相应登录框架授权框架的能力.

总的来说spring-security的功能如下

1.  简单的登录(自己携带)
2.  RBAC授权给不同接口(这个很常用)
3.  集成jwt 对token进行管理
4.  集成OAuth2.0
5.  csrf跨站攻击防御

我们下面进行RBAC授权管理和OAuth2.0后面一些功能得开新坑去写

至于spring-security有自己实现的一套登录机制 基于前后端分离加jwt而言 我们并不需要完成这些逻辑 代码也相对比较复杂 可以参考下面的blog

-   [spring-security集成jwt鉴权](https://www.jianshu.com/p/54603b9933ca)

---

添加依赖即可使用 使用之后项目所有接口需要登录才能够访问和使用

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

导入则连接到该站点都需要进行登录验证

-   可以通过表单的形式post请求验证
-   可以通过HttpBasic Auth把信息放到请求头请求验证 api测试工具都有

配置用户名和密码,默认用户名是user,密码则是在启动时候生成打印在log里面

```properties
spring.security.user.name = admin
spring.security.user.password = 123
# 如果不想启动spring-security的话 可以把下面属性改成false
spring.security.basic.enabled = true
```

我们可以看到其有一个默认的提交窗口 被称为`httpBasicLogin`但绝大多数情况下我们需要自定定义登录的逻辑(这里有个坑就是同时自己定义登录界面和接口)

前后端分离的时候我们只选择定义一个页面 接口登录给隐藏了

```java
@Configuration
public class BrowerSecurityConfig extends WebSecurityConfigurerAdapter {

    /**
     * 配置认证登录方式等
     * @param auth
     * @throws Exception
     */
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        super.configure(auth);
    }

    /**
     * 配置登入登出接口权限等
     * @param http
     * @throws Exception
     */
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.formLogin()
                .loginPage("/login.html")
          			// 之前同时配置了页面和接口老出错 给前后端没分离的设计的
                .and()
                .authorizeRequests()
                .antMatchers("/login.html","/login","/").permitAll()
                // 初始暴露接口 任何人都可以访问 其他接口得需要权限
                .antMatchers("/others").hasRole("admin")
                .anyRequest()
                .authenticated()
                .and()
                .csrf().disable();
    }
}
```



### RBAC

`Role Basic Access Control`是一种权限设计方式

其是一种控制模式 我们数据库的设计一般也使用到了RBAC 就数据库而言我们讲一下RBAC权限设计 其本质上就是下面的对象 许可又作权限

![权限架构图](https://upload-images.jianshu.io/upload_images/10215580-77adebfa6af4da13.png)

总而言之呢 是多对多的关系维护,一个用户拥有多种角色,一个角色拥有多个权限

### 基于RBAC的接口授权

未完待续

### 集成OAuth2.0

我们来集成OAuth2.0实现QQ第三方登录(微信注册需要300/year)

QQ登录OAuth2.0总体处理流程如下：

```note
QQ登录OAuth2.0总体处理流程如下：
Step1：申请接入，获取appid和apikey；
Step2：开发应用，并设置协作者帐号进行测试联调；
Step3：放置QQ登录按钮；
Step4：通过用户登录验证和授权，获取Access Token；
Step5：通过Access Token获取用户的OpenID；
Step6：调用OpenAPI，来请求访问或修改用户授权的资源。
```

未完待续

### 一些不常用的功能简介

---

#### 登录的简单配置和csrf

虽然是自定义登录逻辑 但其实后续处理相对麻烦 尤其是对于前后端分离项目而言 所以一般用的很少 我们是把后端当成api去完成token处理,登录错误提示等一般放在前端(client)去处理(App和h5的逻辑不同)

```java
@Configuration
public class BrowerSecurityConfig extends WebSecurityConfigurerAdapter {

   @Override
protected void configure(HttpSecurity http) throws Exception {
    http.formLogin()  //  定义当需要用户登录时候，转到的登录页面。
      .loginPage("/login.html") // 设置登录页面 所有login接口全部转发到
      .loginProcessingUrl("/login")  // 自定义的登录接口
      .and()
      .authorizeRequests()  // 定义哪些URL需要被保护、哪些不需要被保护
      .antMatchers("/login.html").permitAll() 
      // 设置所有人都可以访问登录页面 前后端分离还要暴露接口给最开始的登录
      .anyRequest() // 任何请求,登录后可以访问
      .authenticated()
      .csrf().disable() // 这里先关闭跨域请求 其实使用token就没必要了
      ;
	}
}
```

这个配置可以当你访问/user/login的时候给你forward到login.html

`.and()`用于接力每一组链式编程,把所有其他类型的返回值变成HttpSecurity

>   ### csrf跨站请求防御
>
>   所谓的跨站请求 其实是别人在诱导你访问 比如钓鱼广告中重定向api C的浏览器中运行A转钱给B的api 携带C的session 自然而然的就悲剧了 虽然A没有C的session但是可以借用C浏览器的cookie 
>
>   1.  可以通过**HTTP Referer** 查看访问路径 如果不对直接refuse掉(现在比较少勇)
>   2.  使用jwt(token)解决这个问题 在敏感请求上添加关键参数到payload(spring security利用token来实现csrf的防御)

登录的跨站请求基本不需要防御 我们这里就直接关了 不关的话登录会失败 上面配置好之后就可以走登录的逻辑了 需要注意的是 端口的所有post请求都会最先被spring-security拦截下来 所以接口名字得另起 或者登录接口不用 `/login`

我们在自己登陆页面没有spring的token如下 在spring自己的登录页面有这么一个字段

`<input name="_csrf" type="hidden" value="635780a5-6853-4fcd-ba14-77db85dbd8bd" />`

所以我们登录的时候就出错了

#### 登录失败跳转

实际上前后端分离登录成功不是跳转页面 而是返回用户信息(token) 在次请求页面附带token

而失败的话我们如果在请求页面也可以 就是会消耗负载 因此我们一般可以做两种处理

1.  把登录错误视为异常(后端直接统一错误页) 静态页带参数+js取出消息即可 或者统一后端返回页面(很小的负载压力)
2.  前端弹出对话框说明登录失败(用的比较多)

**注意:多端app处理一般是由前端去完成部分路由跳转 后端只负责返回参数而已**

---

### Spring-Security原理

其是基于filter实现的 (先于springmvc的拦截器),其认证流程如下

![](https://upload-images.jianshu.io/upload_images/15200008-545f402fe2355967.png)

可以看到其本质是拿filter链去实现的 先验证表单 在验证报文头

---

## 功能实现相关

### 定时调度

springboot集成了定时调度框架

@EnableScheduling 注解在启动类开启定时调度

@Scheduled 注解在方法上启动定时调度

支持 crontab 表达式 支持参数化调用

```java
@Component
public class SchedulerTask {
    private int count=0;
    @Scheduled(cron="*/6 * * * * ?")
    private void process(){
        System.out.println("this is scheduler task runing  "+(count++));
    }
}
@Component
public class Scheduler2Task {
    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");
    @Scheduled(fixedRate = 6000)
    public void reportCurrentTime() {
        System.out.println("现在时间：" + dateFormat.format(new Date()));
    }

}
```

### 邮件

springboot集成了javamail并且封装了代码

```xml
<dependencies>
	<dependency> 
	    <groupId>org.springframework.boot</groupId>
	    <artifactId>spring-boot-starter-mail</artifactId>
	</dependency> 
</dependencies>
```

```properties
spring.mail.host=smtp.qiye.163.com //邮箱服务器地址
spring.mail.username=xxx@oo.com //用户名
spring.mail.password=xxyyooo    //密码
spring.mail.default-encoding=UTF-8
```

执行代码相比于自己写javamail简单了太多了

```java
SimpleMailMessage message = new SimpleMailMessage();
message.setFrom("from@qq.com");
message.setTo("to@qq.com");
message.setSubject("subject");
message.setText("content");
mailSender.send(message);
```

支持发送html格式的邮件

```java
MimeMessage message = mailSender.createMimeMessage();
MimeMessageHelper helper = new MimeMessageHelper(message, true);
helper.setFrom("from@qq.com");
helper.setTo("to@qq.com");
helper.setSubject("subject");
helper.setText("content", true);
mailSender.send(message);
```

还可以发送带附件的mail 具体看javamail的api了 基本一致

### 文件上传

配置启动类 是为了解决文件>10M时候出现的连接重置问题

```java
@SpringBootApplication
public class FileUploadWebApplication {

    public static void main(String[] args) throws Exception {
        SpringApplication.run(FileUploadWebApplication.class, args);
    }
    @Bean
    public TomcatServletWebServerFactory tomcatEmbedded() {
        TomcatServletWebServerFactory tomcat = new TomcatServletWebServerFactory();
        tomcat.addConnectorCustomizers((TomcatConnectorCustomizer) connector -> {
            if ((connector.getProtocolHandler() instanceof AbstractHttp11Protocol<?>)) {
                //-1 means unlimited
                ((AbstractHttp11Protocol<?>) connector.getProtocolHandler()).setMaxSwallowSize(-1);
            }
        });
        return tomcat;
    }
}
```

上传的代码相对简单就是接受file参数

```java
@PostMapping("/upload") 
public String singleFileUpload(@RequestParam("file") MultipartFile file) {
    if (file.isEmpty()) {
        return "{'state':'failed','msg':'Please select a file to upload'}";
    }

    try {
        // Get the file and save it somewhere
        byte[] bytes = file.getBytes();
        Path path = Paths.get(UPLOADED_FOLDER+file.getOriginalFilename());
        Files.write(path, bytes);
    } catch (IOException e) {
        e.printStackTrace();
    }

    return "{'state':'succes','msg':'success upload your file'}";
}
```

### 登录认证

我们常见的登录方式就以下几种

-   ####cookie-session登录 可以用redis做分布式处理

    -   web端处理尚可 android端如果不是h5就不能用session了
    -   cookie不能跨域
    -   CSRF(跨站请求伪造)
    -   Session同步问题 分布式锁

-   ####cookie-session改进

    不在使用基于cookie去存储数据了,session改用redis分布式

    web使用local storage(h5技术,类似数据库),android使用本地数据库

    改进之后的流程如下

    1.  用户通过传统验证
    2.  服务端把登录信息构造好放到redis中,返回给用户key
    3.  用户不在利用cookie存储key而采用local storage存储
    4.  下次请求的时候把key拿出来附带进请求

    关于localStorage的存储

    ```js
    // 存入
    var obj={"name":"ycyzharry","id":"30"};
    obj = JSON.stringify(obj); // 转成JSON格式的字符串。
    localStorage.setItem("temp",obj);
    // 获取
    console.log(localStorage.getItem("temp"));
    obj=JSON.parse(localStorage.getItem("temp")); 
    
    // 删除
    localStorage.clear(); 
    localStorage.removeItem("name"); 
    
    // 遍历数据
    for(var i=0;i<localStorage.length;i++){
       var key=localStorage.key(i);
       var v =localStorage.getItem(key);
       console.log(key+v);
     }
    ```

-   #### 基于JWT的token

    上面的cookie和session还有状态维系的信息 比如cookie换session,key换redis的value

    JWT(JSON Web Token)

    流程如下

    1.  用户登录
    2.  服务器端把认证信息利用指定算法(eg.HS256)非对称加密,加密私钥保存在服务器端,加密的东西称之为`用户签名`,头部和载荷信息进行base64加密,Token格式如下**`头部.载荷.签名`**,加密结果(Token)发送给客户端
    3.  客户端用cookie或者local storage存好token
    4.  下次请求时token放在报文头的authorization字段中
    5.  服务器端取得token解析确认是否走下面流程

---

-   #### OAuth2.0 令牌登录

    权威网站例如微博QQ开放api进行登录,等都是第三方站点服务器上的数据,我们需要获得这些数据进行本站点的注册等(不同于其他 这个相当于第三方登录)

    `OAuth允许用户提供一个令牌,而不是用户名和密码访问特定的数据,所以可以让用户可以授权给第三方网站访问第三方网站服务器上的特定数据`

    涉及以下角色:用户,用户终端(客户端),应用服务器端(app服务器),授权服务器端(微信服务器)

    微信是采用授权码的方式 流程如下

    1.  用户触发微信登录事件,引导至微信授权页面
    2.  授权完成之后会生成授权码(code),并发生页面跳转(redirect_url),把此授权码发送到应用服务器中
    3.  应用服务器端可以请求微信服务器获取令牌数据(access_token)
    4.  应用服务器用令牌向微信服务器获取头像等

    ![授权过程](http://www.ruanyifeng.com/blogimg/asset/2014/bg2014051204.png)

    这是一个授权码流程的抽象

### JWT

jwt这个规范不仅可以用在登录认证中也可以用在web间传递消息

Token格式:**`载荷.头部.签名`**

#### 载荷(payload)

```json
{
    "iss": "John Wu JWT", // jwt的签发者
    "iat": 1441593502, // 何时签发
    "exp": 1441594722, // token过期时间
    "aud": "www.example.com", // 接受jwt的用户
    "sub": "jrocket@example.com", // jwt面向的用户
  
  	// 用户自定义字段
    "from_user": "B",
    "target_user": "A"
}
```

以上为JWT中载荷信息,对其进行Base64编码则成为了token的一部分

node中对其进行编码可以用下面这种形式

```js
var base64url = require('base64url') // npm install base64url
var header = {
    "from_user": "B",
    "target_user": "A"
}
console.log(base64url(JSON.stringify(header)))
```

#### 头部header

```json
{
  "typ": "JWT",
  "alg": "HS256" // JWT签名使用HS256算法
}
```

base64进行编码

#### 签名

`= HS256(base64(荷载).base64(头部),秘钥)`

#### token

`= base64(载荷).base64(头部).签名`

如果token被人动过的话那么token将会被拒绝返回401

token信息会暴露,只用于传递一些非敏感信息,例如用户密码就绝对不能放到token中,token更多的是用于一种授权,或者携带一些非敏感数据用于完成程序,同时也可以让一些重复操作例如登录少去访问数据库 有一定的限流作用

### springboot集成jwt

```xml
<dependency>
    <groupId>com.auth0</groupId>
    <artifactId>java-jwt</artifactId>
    <version>3.5.0</version>
</dependency>
```

```java
public class JwtUtil {
    private static final long EXPIRE_TIME = 24 * 60 * 60 * 1000;
    private static final String TOKEN_SECRET = "ssxxzyzybaba";

    public static String getJWTToken(Map<String, String> map) {
        // 过期时间
        Date date = new Date(System.currentTimeMillis() + EXPIRE_TIME);
        // 私钥及加密算法
        Algorithm algorithm = Algorithm.HMAC256(TOKEN_SECRET);
        // 标准头信息
        HashMap<String, Object> header = new HashMap<>(2);
        header.put("typ", "JWT");
        header.put("alg", "HS256");
        // 附带username和userID生成签名
        JWTCreator.Builder builder = JWT.create().withHeader(header);
        for (String key : map.keySet()) {
            builder = builder.withClaim(key, map.get(key));
        }
        return builder.sign(algorithm);
    }


    public static boolean verity(String token) {
        try {
            Algorithm algorithm = Algorithm.HMAC256(TOKEN_SECRET);
            JWTVerifier verifier = JWT.require(algorithm).build();
            DecodedJWT jwt = verifier.verify(token);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        } catch (JWTVerificationException e) {
            return false;
        }
    }

    public static String getTokenValue(String token, String key) {
        return JWT.decode(token).getClaim(key).asString();
    }
}
```

再看token的途中发现了些有趣的代码,比如用拦截器实现自己的注解的利用,原理解释preHandler的时候可检测注解是否有,这个整挺好. 对spring的启发是AOP的时候 利用自己定义的注解和spring本身的AOP进行代码的注入,同样的想法也可以在javaweb-filter/拦截器中使用





### 单点登录

单点登录指的是在多系统中 一个点登录了就可以在其他系统登录 不用重复登录

我们一般的登录流程是把user_id等参数封装到token中,client检查token签名,token是否过期,接收方是不是客户端等,并把token存在cookie或者local storage中

其设计思路有

1.  local storage存token,其他站点检查token决定重定向到首页还是继续登录
2.  分布式session完美解决单点登录问题

### 唯一登录

redis记录/token记录session_id,uid,然后进行session_id对比 如果发现不同则取消另一session_id登录的授权

---

### 监控springboot项目

在微服务时代监控项目显得尤为重要 因为区域自治 docker的大规模应用更是如此 轻量级自治意 味着耦合度降低 同时也意味着集中式监控特别难 所以监控变得尤为重要

#### Spring Boot Actuator

基于restful完成监控的一个组件

一般需要添加 `spring-boot-start-security` 依赖,访问监控端点的时候需要输入验证信息

一般用于监控两类端点,原生端点和用户自定义端点,自定义端点指扩展性指标,在运行时监控

-   原生端点

    应用配置类 加载的springbean yml 环境信息 请求映射信息

    度量指标类 **堆栈,请求连接,连接,metrics**

    操作控制类 操作控制 主要是shutdown关闭

-   自定义端点

一些重要的restful-api

-   GET /beans
-   GET /env GET /env/{name}
-   GET /flyway /liquidbase 数据库迁移信息
-   GET /heapdump 
-   GET /httptrace 最近100个HTTP request response
-   GET /logfile 显示logfile /loggers 显示和修改log
-   GET /metrics /metrics/{name} app的度量信息,内存用量,http请求计数
-   GET /scheduledtasks 显示定时任务
-   POST /shutdown 要把endpoints.shutdown.enabled=true带上 关闭监控
-   GET /threaddump 获取线程快照
-   GET /mappings 描述全部url路径

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```properties
management.endpoints.web.exposure.include=*
management.endpoints.web.base-path=/info
# 修改路径 如果不写的话默认是 /actuator
```

因为是restful接口所以返回的是json格式 对于用户可能不太好监控,而且需要不断调接口也影响集群性能,所以对此就有了另一个开源软件springboot-admin去实现监控,其基于actuator实现

#### springboot-admin

**每个应用都认为是一个客户端**,通过 HTTP 或者**使用 Eureka **注册到 admin server 中进行展示,Spring Boot Admin UI 部分使用 VueJs 将数据展示在前端。

##### 监控单体应用

新建一个单独的项目admin server端 主要如下

```xml
<dependency>
  <groupId>de.codecentric</groupId>
  <artifactId>spring-boot-admin-starter-server</artifactId>
  <version>2.2.0</version><!--2.1.0有问题-->
</dependency>
```

```java
@SpringBootApplication
@EnableAdminServer // 启动server
public class AdminApplication {
    public static void main(String[] args) {
        SpringApplication.run(AdminApplication.class, args);
    }
}
```

```properties
server.port=8000
# 把监控服务部署在8000端口
```

client端添加配置如下

```xml
<dependency>
  <groupId>de.codecentric</groupId>
  <artifactId>spring-boot-admin-starter-client</artifactId>
  <version>2.2.0</version>
</dependency>
```

```properties
management.endpoints.web.exposure.include=*
# management.endpoints.web.base-path=/info
# 恢复默认

# 指定admin的地址
spring.boot.admin.client.url=http://localhost:8000
```

##### 监控微服务

客户端和服务端都添加监控依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

```java
@Configuration
@EnableAutoConfiguration
@EnableDiscoveryClient
@EnableAdminServer
public class SpringBootAdminApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringBootAdminApplication.class, args);
    }

    @Configuration
    public static class SecurityPermitAllConfig extends WebSecurityConfigurerAdapter {
        @Override
        protected void configure(HttpSecurity http) throws Exception {
            http.authorizeRequests().anyRequest().permitAll()  
                .and().csrf().disable();
        }
    }
}
```

```yaml
eureka:   
  instance:
    leaseRenewalIntervalInSeconds: 10
    health-check-url-path: /actuator/health
    metadata-map:
      startup: ${random.int}    #needed to trigger info and endpoint update after restart
  client:
    registryFetchIntervalSeconds: 5
    serviceUrl:
      defaultZone: ${EUREKA_SERVICE_URL:http://localhost:8761}/eureka/

management:
  endpoints:
    web:
      exposure:
        include: "*"  
  endpoint:
    health:
      show-details: ALWAYS
```

### 编写文档 japidocs

japidocs属于一个无需用注解编写的api文档生成工具,参考[官方文档](https://japidocs.agilestudio.cn/#/zh-cn/)

```xml
<dependency>
  <groupId>io.github.yedaxia</groupId>
  <artifactId>japidocs</artifactId>
  <version>1.4.3</version>
</dependency>
```

-   未完待续



---

## 集成RabbitMQ

```shell
docker pull rabbitmq:management # 这个后缀是带管理后台的意思
docker run -d --hostname my-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:management
```

配置pom.xml

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

application.properties

```properties
spring.application.name=Spring-boot-rabbitmq
spring.rabbitmq.host=127.0.0.1
spring.rabbitmq.port=5672
spring.rabbitmq.username=admin
spring.rabbitmq.password=123456

# spring.rabbitmq.listener.simple.acknowledge-mode: 表示消息确认方式，其有三种配置方式，分别是none、manual和auto；默认auto

# spring.rabbitmq.listener.simple.concurrency: 最小的消费者数量
# spring.rabbitmq.listener.simple.max-concurrency: 最大的消费者数量
# spring.rabbitmq.listener.simple.prefetch: 指定一个请求能处理多少个消息，如果有事务的话，必须大于等于transaction数量.
```

rabbitmq-api

### 消息发送

```java
@Autowired
RabbitTemplate rabbitTemplate;

@Test
void test() throws Exception {
  String context = "this is time " + new Date() + " to send the msg";
  System.out.println("Sender : " + context);
  Thread.sleep(1000);
  rabbitTemplate.convertAndSend("testQueue", context); // 简单消息发送
}

// 路由键消息发送
@Test
void testTopic() {
  String context1 = "this is msg1";
  String context2 = "this is msg2";
  rabbitTemplate.convertAndSend("exchange", "topic.messages", context1);
  rabbitTemplate.convertAndSend("exchange", "topic.message", context2);
}
```

### rabbitmq handler

这个handler可以在任意springboot项目中 因为消息队列也是跨网络的

类的形式

```java
@Component
@RabbitListener(queues = "testQueue")
public class SimpleMessageHandler {
    @RabbitHandler
    public void process(String msg) {
        System.out.println("Receiver: get the msg at " + new Date() + " : " + msg);
    }
}
```

方法的形式 两者区别不大

```java
@Component
public class TopicMessageHandler {
    @RabbitListener(queues = "topic.message")
    public void process(String msg) {
        System.out.println("message queue:"+msg);
    }
    @RabbitListener(queues = "topic.messages")
    public void processes(String msg) {
        System.out.println("messages queue:"+msg);
    }
}

```

### 配置类

```java
@Configuration
public class RabbitConfig {
    @Bean
    public Queue TestQueue() {
        return new Queue("testQueue", true);
    }
}
```

```java
@Configuration
public class TopicRabbitConfig {

    final static String message = "topic.message";
    final static String messages = "topic.messages";

    @Bean
    public Queue queueMessage() {
        return new Queue(TopicRabbitConfig.message);
    }

    @Bean
    public Queue queueMessages() {
        return new Queue(TopicRabbitConfig.messages);
    }

    @Bean
    TopicExchange exchange() {
        return new TopicExchange("exchange");
    }
  
    @Bean
    Binding bindingExchangeMessage(Queue queueMessage, TopicExchange exchange) {
        return BindingBuilder.bind(queueMessage).to(exchange).with("topic.message");
    }

    @Bean
    Binding bindingExchangeMessages(Queue queueMessages, TopicExchange exchange) {
        return BindingBuilder.bind(queueMessages).to(exchange).with("topic.#");
    }
}
```

## springboot部署

### 传统项目部署

把根路径项目文件直接扔到tomcat的/webapps目录下直接运行就行

这种情况下 访问url的名字前要带项目名 如果想改变的话修改/conf/server.xml

war包直接扔到tomcat下也可完成 **如果要修改url的路径的话** 在server.xml/`<Host>`标签中加入路径doc映射 

```xml
<!--部署在其他的一些路径-->
<Context path="/test" docBase="/tomcat/apache-tomcat-7.0.73/webapps/myBlog" reloadable="false" allowLinking="true"></Context> 
<!--部署在根路径-->
<Context path="" docBase="springbootDeployTest" debug="0" reloadable="true" />
<!--如果是根路径的话什么都不要加 如果是普通的路径则可以加url例如path="/test"-->
```

path代表url docBase是war包的路径或者是web项目所在路径

### springboot部署

---

springboot不同于其他javaweb,其实对服务器容器进行了封装,运行于内嵌的服务器之上,这种集成给开发带来了便利,但是对于其他需要共同协作的项目springboot需要更改其部署方式

springboot提供了和传统项目一样的war包打包方式 但是我们要去除内置的容器以及

但是对于微服务的部署springboot是有天然优势的 因为内嵌服务器能够让springboot服务之间自治而不需要一个个部署到相应的tomcat 下面分别说明两种部署方式

#### springboot打包成war包

修改启动器

```java
@SpringBootApplication
@MapperScan("com.example.mbttest.mapper")
public class MbttestApplication extends SpringBootServletInitializer {
    
    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(MbttestApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(MbttestApplication.class, args);
    }

}
```

```xml
<!--部署相关去除内置tomcat依赖 provided不会被打包进去-->
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-tomcat</artifactId>
  <scope>provided</scope>
</dependency>
<!--或者使用下面这种方式去除-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- 移除嵌入式tomcat插件 -->
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

```xml
<packaging>war</packaging> <!--在project标签下修改打包方式-->
<finalName>springbootDeployTest</finalName><!--在build标签下写war的名字-->
<!--注释掉下面代码 要不该插件会让我们重复打包-->
<plugins>
  <!--            <plugin>-->
  <!--                <groupId>org.springframework.boot</groupId>-->
  <!--                <artifactId>spring-boot-maven-plugin</artifactId>-->
  <!--            </plugin>-->
</plugins>
```

```shell
mvn package -Dmaven.skip.test=true # maven 打包成war
```

如果不注释掉插件的话会打包成内嵌服务器依赖的war包(没必要) 注释掉该插件使用原生打包

然后在target/*.jar找到项目的路径扔到tomcat目录下就可以了,如果是单项目可以修改下路径

```xml
<Context path="" docBase="springbootDeployTest" debug="0" reloadable="true" />
```

#### springboot打包成jar包(推荐)

由于内嵌了服务器 当然可以打包成jar包然后直接执行jar包去运行项目 这很springboot

```xml
<plugin>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-maven-plugin</artifactId>
  <configuration>
    <mainClass>com.example.mbttest.MbttestApplication</mainClass>
  </configuration>
</plugin>
```

打包的时候指定下主类

```shell
mvn clean package -Dmaven.test.skip=true
```

直接打包就行了 和war类似,打完之后再target会生成两个jar包 `*.jar` 和`*.jar.original` 两者的不同在于 jar.original 是不包含依赖只包含用户类的代码的 如果是想给其他项目使用则用original 

```shell
java -jar Demo.jar --server.port=8080
```

这句话执行的时候会去找META-INF/MANIFEST.MF文件读取信息 在下文中有该文件简单格式

我们会发现对于小型的项目来说 springboot尤为适合 微服务架构也是如此 大型的项目并非臃肿而庞大的 应该是分而治之的 拆分成不同的服务器可能会需要多个服务器软件可是相对而言其可用性和并发性是大幅度的提高 相比于大的线程池 分散的小线程池线显然会更加细粒度的使用内存和cpu的性能

如果想后台运行用下面代码 nohup for no hang up

```shell
nohup java -jar target/spring-boot-scheduler-1.0.0.jar &
```

**我们这里展开说下jar包**

```note
 jar包一般有两类 普通的工具类的jar 可执行的有主类main方法的jar
 显然springboot打的jar包属于后者
 一般我们使用的jar都有不同的依赖 设有Lib.jar和Demo.jar其中Demo.jar主类叫DemoApp
 传统我们使用java -classpath 来运行jar
```

```shell
 java -classpath Demo.jar:Lib.jar com.example.test.DemoApp
 # 多个jar用:来分隔开 后面写的是主类的路径
```

```note
我们还可以使用MANIFEST.MF文件来组织类
```

```MF
Main-Class: com.example.test.DemoApp
Class-Path: Lib.jar
```

#### 普通项目部署到docker

其有两种方式 

1.  项目打包成了.jar送到服务器上 docker打包.jar
2.  项目在服务器上 docker打包的是工程目录

docker已经成为现代服务体系的刚需了,虽然这个体系还未到达成熟,确是代表了未来

1.Dockerfile 和打包好的jar同级目录

```dockerfile
FROM openjdk:8-jdk-alpine
VOLUME /tmp
ADD springbootDeployTest.jar app.jar
RUN sh -c 'touch /app.jar'
ENV JAVA_OPTS=""
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app.jar" ]
```

在Dockerfile和jar的同级目录下

```shell
docker build -t docker .
```

2.打包整个项目

${project.basedir}/src/main/docker/Dockerfile(对应上面pom的路径) 文件如下

```dockerfile
FROM openjdk:8-jdk-alpine
VOLUME /tmp
ADD springbootDeployTest.jar app.jar
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```

maven中配置插件

```xml
<properties>
  <java.version>1.8</java.version>
  <!--docker 镜像前缀-->
  <docker.image.prefix>springboot</docker.image.prefix>
</properties>
<!-- Docker maven plugin -->
<plugins>
		<plugin>
			<groupId>com.spotify</groupId>
			<artifactId>docker-maven-plugin</artifactId>
			<version>1.0.0</version>
			<configuration>
				<imageName>
          ${docker.image.prefix}/${project.artifactId}
        </imageName>
        <!--dockerfile的路径-->
				<dockerDirectory>
          ${project.basedir}/src/main/docker
        </dockerDirectory>
				<resources>
					<resource>
						<targetPath>/</targetPath>
						<directory>${project.build.directory}</directory>
						<include>${project.build.finalName}.jar</include>
					</resource>
				</resources>
			</configuration>
		</plugin>
</plugins>
```

执行maven打包插件

```shell
mvn package docker:build
```

### 热部署

热部署原理,好多web服务器都支持热部署,对于重新部署一个大型应用来说,这是灾难级别的,Java中热部署一致是一个难以解决的问题,Java虚拟机只能实现**方法修改**的热部署,如果要改变整个类的结构,仍然需要重启虚拟机.对于生产环境而言我们可以通过集群的兼容代码一部分一部分替换,直至新系统上限,所以springboot的热部署一般是用在测试环境.仅作为一个可选择的知识点,后续重点请参考集群操控.

这里介绍一种简单的热部署工具,在创建springboot项目的时候我们就可以选择devtools

devtools会监听classpath下的文件变动,并且会立即重启应用.配置了true之后java文件支持热启动.

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-devtools</artifactId>
  <scope>runtime</scope>
  <optional>true</optional>
</dependency>
```

我们还要开启自动编译

-   Preference->Compiler->Build Project Automatically 勾选
-   command+alt+shift+’/’ ->Registry->compiler.automake.allow.when.app.running 勾选

此时修改了代码就可以自动编译新文件了.

不过需要注意的是此种热部署属于项目重启,所以在一些情况下并不是特别好用,所以也会发生清空session等情况,务必要注意.



## springboot高级特性与实现原理

这一章节我们来剖析springboot的一些机制性的问题,以及完成一些高级的功能,这些特性大多都涉及内存分配与多线程,关于java的多线程基础请参考另一文档.本章节内容偏向原理性,包括web原理和spring原理多线程等知识的结合,本章的主要目的是提高springboot的系统性能,属于单springboot应用的优化,涉及基本功能的实现以及api的部分如上.

---

### websocket协议扩展springboot服务

我们都知道springboot是个优秀的rest请求处理库,其是基于http/https协议的请求处理,耦合tomcat/jetty等服务器可以完成处理http请求的功能.如果知道tomcat的线程结构和网络请求就会知道,springboot通常是用来完成一次请求一次应答的一锤子买卖,而分布式系统中有需要完全保持连接自己释放连接的需求.这些需求就用socket io去完成.我们可以自己写ServerSocket,但spring有其自己的封装就是WebSocket.这还可以实现一些特殊需求,比如客服在线聊天等.

WebSocket不但使用了新的api,其还使用了新的协议,由HTML5定义,其基于TCP协议建立可以理解为一种带连接的http协议,一般的socket工具`nc`或者是java自带的socket都无法连接上,我们在后文用的是html作为其测试.在分布式系统中,可以采用更加通用的TCP/Netty作为底层.

#### websocket协议

因为其基于tcp协议实现,所以三次握手都是必经

![](https://img2020.cnblogs.com/blog/1721320/202003/1721320-20200319084859071-1530751486.png)

如上,只需要经过一次http阶段的握手,两者就可以进行数据交流了,这样可以省去不断接受处理http请求的麻烦,其特点就是长连接的特点,且全双工通信.所以其相比更加原始的TCP,其要处理的信息就变少了

![](https://img2018.cnblogs.com/blog/722072/201905/722072-20190530002436087-2075657243.png)

我们只需要关注message的处理就可以实现我们自己想要的功能了.websocket使用80和443端口进行工作.其handshanke阶段发的报文和http基本一致.

HttpStreaming虽然也可以维持长时间连接但是Http建立通道的话就违背了Http的语义,且代理等会缓存数据流这很不利于响应.所以长轮询的ajax就成为了websocket以前的轮询数据,或者少部分客户端能够使用原生TCP进行数据交换.

#### 使用websocket

springboot对websocket协议进行了支持,进行配置之后就可以使用

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>
```

```java
@Component
public class WebSocketConfiguration {
    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
```

我们实现下websocket类

```java
@Component
@ServerEndpoint("/websocket/{name}")
public class WebSocket {


    private Session session;

    private String name;

    /**
     * 用于存所有的连接服务的客户端，这个对象存储是安全的
     */
    private static ConcurrentHashMap<String, WebSocket> webSocketSet = new ConcurrentHashMap<>();


    @OnOpen
    public void onOpen(Session session, @PathParam(value = "name") String name) {
        this.session = session;
        this.name = name;
        // name是用来表示唯一客户端，如果需要指定发送，需要指定发送通过name来区分
        webSocketSet.put(name, this);
        System.out.println("[WebSocket] 连接成功，当前连接人数为：" + webSocketSet.size());
    }


    @OnClose
    public void onClose() {
        webSocketSet.remove(this.name);
        System.out.println("[WebSocket] 退出成功，当前连接人数为：" + webSocketSet.size());
    }

    @OnMessage
    public void onMessage(String message) {
        System.out.println("[WebSocket] 收到消息：" + message);

        //判断是否需要指定发送，具体规则自定义
        String reg = "user ";
        if (message.indexOf(reg) == 0) {
            String name = message.substring(reg.length(), message.indexOf(";"));
            appointSending(name, "[" + this.name + " only says to you] =>" + message.substring(message.indexOf(";") + 1));
        } else {
            groupSending("[" + this.name + " says to all] => " + message);
        }

    }


    public void groupSending(String message) {
        for (String name : webSocketSet.keySet()) {
            try {
                webSocketSet.get(name).session.getBasicRemote().sendText(message);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }


    public void appointSending(String name, String message) {
        try {
            webSocketSet.get(name).session.getBasicRemote().sendText(message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

我们利用服务端写好一个程序非自动连接应为登录后才有,此处只做通信部分的演示

```html
<body>
  用户名:<input id="name" type="text"/><br>
  发送内容:<input id="text" type="text"/>
  <button onclick="send()">发送消息</button>
  <br/>
  <button onclick="closeWebSocket()">关闭WebSocket连接</button>
  <br/>
  <div id="message"></div>
  <script>
    var websocket = null;
    
    // 将消息显示在网页上
    function setMessageInnerHTML(innerHTML) {
      document.getElementById('message').innerHTML += innerHTML + '<br/>';
    }

    // 关闭WebSocket连接
    function closeWebSocket() {
      websocket.close();
    }
    // 发送消息
    function send() {
      if(websocket==null){
        if('WebSocket' in window) {
          websocket = new WebSocket("ws://localhost:8000/websocket/"+document.getElementById('name').value);
        } else if('MozWebSocket' in window) {
          websocket = new MozWebSocket("ws://localhost:8000/websocket/"+document.getElementById('name').value);
        } else {
          websocket = new SockJS("localhost:8000/websocket/"+document.getElementById('name').value);
        }

        //连接发生错误的回调方法
        websocket.onerror = function () {
          setMessageInnerHTML("WebSocket连接发生错误");
        };

        //连接成功建立的回调方法
        websocket.onopen = function () {
          setMessageInnerHTML("WebSocket连接成功,在次点击发送消息");
        }

        //接收到消息的回调方法
        websocket.onmessage = function (event) {
          setMessageInnerHTML(event.data);
        }

        //连接关闭的回调方法
        websocket.onclose = function () {
          setMessageInnerHTML("WebSocket连接关闭");
        }

        //监听窗口关闭事件，当窗口关闭时，主动去关闭websocket连接，防止连接还没断开就关闭窗口，server端会抛异常。
        window.onbeforeunload = function () {
          closeWebSocket();
        }
      }
      var message = document.getElementById('text').value;
      websocket.send(message);
    }

  </script>
</body>
```

这样我们就能实现基本的在线聊天程序,而前端只需要渲染出交换的数据即可



### springboot异步任务与线程池

开启异步任务有三种方式

-   自定义线程,直接开启`new Thread(()->{}).start();` 
-   自定义线程池,利用线程池的execute和submit方法
-   @Async 通过Spring定义的线程池进行任务开启

自定义线程和自定义线程池都是JDK给我们提供的方法,让我们在java中能够直接的调度线程,但这两种方法都十分不推荐,自定义线程的缺点是垃圾回收成谜,ThreadExecutor可以使用,但是就springboot的运行来看(要交由tomcat去执行),在组件中使用ThreadExecutor可能会带来线程池滥用.如果真的要使用的话需要在特定服务中指定static区域妥善存放保管.但如果存在多个服务需要使用到此线程池就不如使用spring来管理线程池,也就是我们说的注解方法@Async开启异步任务.

关于springboot管理线程池的方法,其实本质上就是spring管理线程池.其中就要利用到@Async注解和@EnableAsync注解

```java
@Configuration
@EnableAsync
public class ThreadPoolConfig {
    @Bean("pool")
    public TaskExecutor taskExecutor() {
        System.out.println(Thread.currentThread().getName());
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(20);
        executor.setKeepAliveSeconds(60);
        executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        return executor;
    }
}
```

如上我们配置自己的线程池,然后`@EnableAsync`会告诉Spring这是我们创建的线程池,遇到`@Async`的时候就去开启相应的线程池.而`@Async`是另一方法调用的异步注解,该方法仅能通过调用(实际上是增强了代理类的方式调用代理类)才可以发挥出其异步性能.

```java
@Service
public class AsyncService {
    @Async("pool")
    public void aynscTest(){
        System.out.println(Thread.currentThread().getName());
        // 相当于runnable接口的方法了
    }
    @Async("pool")
    public void aynscTest2(){
        System.out.println(Thread.currentThread().getName());
    }
    public void normalTest(){
        System.out.println(Thread.currentThread().getName());
    }
}
```

调用部分

```java
@Autowired
AsyncService asyncService;

@RequestMapping("/")
public String index(){
  System.out.println(Thread.currentThread().getName());
  asyncService.aynscTest();
  return "hello";
}
```



### ThreadPoolTaskExecutor与定时调度

ThreadPoolExecutor是原生线程池,继承自Executor接口.其是一个ExecutorService.`ThreadPoolTaskExecutor`是spring的线程池,我们一般先进行配置之后在使用

```java
@Configuration
public class ExecutorConfig {

  @Bean(name = "pushExecutor")
  public TaskExecutor pushExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(10);
    executor.setMaxPoolSize(200);
    executor.setQueueCapacity(10);
    executor.setKeepAliveSeconds(20);
    executor.setThreadNamePrefix("pushExecutor-");
    executor.initialize();
    return executor;
  }
}
```

定时调度,用的是`ThreadPoolTaskScheduler`,我们可以看到其执行的任务框架有两个

- ThreadPoolTaskScheduler
- ThreadPoolTaskExecutor



### springboot运行过程

---

整体的原理需要理解tomcat的nio以及tomcat的线程池架构才行,参考多线程文档中对tomcat的叙述.

通过对tomcat的理解我们可以知道,springboot的本质就是写servlet/socketProcessor,那么一个@Contoller对象就是被tomcat放到jvm堆内存中的.此时,因为tomcat启动时装载了spring(web.xml),所以spring的aop在此时动态代理的类的某些方法对其进行了增强,使得tomcat可以调用这些方法去处理相应的事件.tomcat在处理的时候找到了对应的路径,就把方法的执行封装成Runnable扔到线程池里.线程池再去执行我们的方法,封装成socket响应发送给服务端.所以我们看到了springboot的多线程模式,



#### 代理发生时机

tomcat启动的时候根据applicationContext启动了spring,spring就开始创建自己的对象池,并维护这些spring创建的对象,此时对他们进行代理.此时http请求还未到达,处于服务器初始阶段,但要注意的是自己new的话就不会发生这种代理,好多对象是创建的时候(服务器初始化)发生的值注入.



#### 实例对象

几乎所有有注解的对象都是无状态的单例程序.不会引发线程安全问题.



#### 线程安全

spring中如果会发生线程安全问题,一定是上述单例对象拥有了状态,比如servlet的成员变量(无论是普通还是static)被方法引用自增然后去打印,或者是要访问一些共有的数据结构.

解决方案有三个

-   加锁,但是这种方法一般会带来巨大锁开销,对于绝大多数不需要状态的controller性能下降
-   方法内分配使用状态的对象,这种方法如果在某一接口被调用过多的情况下对象就OOM了
-   ThreadLocal为每个线程的状态部分进行单独的处理

综上,如果是状态类的可以通过ThreadLocal进行处理,如果是要访问共有的数据建议直接JUC加锁

为什么要使用redis来保存会话参数 那是因为session本质上要开启磁盘IO 放redis中服务器关闭的时候进行初始化 设置销毁时间会比存内存来的更加实际 redis里存放的对性能要求十分高的数据(热点数据) 尤其是dict型的数据 会很高 访问数据库相当于访问文件效率不会高



### springboot启动原理

springboot整个启动过程还要包括tomcat的启动,部署的时候如果运行的jar那么首先启动的则是springcontext内部的东西,其内部在启动内嵌的tomcat服务器,这一过程在自动装配的时候完成

如果是运行的war,那么毫无疑问tomcat是优先启动的,那么在上面springcontext启动的过程中,忽略掉了tomcat启动的部分.

---

![](https://upload-images.jianshu.io/upload_images/6912735-51aa162747fcdc3d.png?imageMogr2/auto-orient/strip)

其初始化有三个部分

-   SpringApplication 配置一些基本的环境变量,资源,构造器,监听器
-   实现了具体的应用方案,包括启动流程的监听模块,加载环境配置模块,创建上下文模块
-   第三模块是自动化配置模块,为springboot自动配置的核心,

springboot的启动包括如下内容

-   配置环境(environment)
-   事件监听(listeners)
-   应用上下文(applicationContext)
-   并基于以上条件，在容器中开始实例化我们需要的Bean

@SpringBootApplication 是springboot应用的起点 其为以组合注解如下

```java
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration // 配置到IOC容器中
@EnableAutoConfiguration // 自动添加mvc和tomcat等基础依赖
@ComponentScan(excludeFilters = { // 扫描符合条件的注解
@Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
@Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication {}

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import(AutoConfigurationImportSelector.class) // 这个是重点
public @interface EnableAutoConfiguration {}
```

-   @EnableAutoConfiguration spring根据所声明的依赖对spring框架进行自动配置
-   @SpringBootConfiguration 装配所有的bean,提供spring上下文环境
-   @CompontentScan 组件扫描可以自动装配bean,默认扫描该.class文件所在的根目录

```java
public static ConfigurableApplicationContext run(Class<?>[] primarySources, String[] args) {
  return new SpringApplication(primarySources).run(args);
  // new SpringApplication的构造函数就有使用层级调用loadFactoriesNames
  // 装载的有三个类,Bootstrapper.class ApplicationContextInitializer.class
  // 和ApplicationListener.class 这三个类告诉了我们其功能启动spring
}
// 其run方法
public ConfigurableApplicationContext run(String... args) {
  StopWatch stopWatch = new StopWatch();
  stopWatch.start();
  // 创建bootstrapContext,启动spring
  DefaultBootstrapContext bootstrapContext = createBootstrapContext();
  
  // 设置headless模式(无头模式)
  ConfigurableApplicationContext context = null;
  configureHeadlessProperty();
  
  // 启动listener
  SpringApplicationRunListeners listeners = getRunListeners(args);
  listeners.starting(bootstrapContext, this.mainApplicationClass);
  
  try {
    ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
    // 配置环境模块,这里就开始创建配置环境,加载属性文件资源
    ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
    configureIgnoreBeanInfo(environment);
    
    // 创建Banner,这个banner就是那个springboot的logo
    Banner printedBanner = printBanner(environment);
    
    // 创建上下文对象,中间是加载配置环境
    context = createApplicationContext(); 
    context.setApplicationStartup(this.applicationStartup);
    prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
    
    // 更新上下文对象
    refreshContext(context);
    afterRefresh(context, applicationArguments);
    stopWatch.stop(); // 计时完毕结束监听
    
    // 日志启动
    if (this.logStartupInfo) {
      new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), stopWatch);
    }
    // 启动项目
    listeners.started(context);
    callRunners(context, applicationArguments);
  }
  catch (Throwable ex) {
    handleRunFailure(context, ex, listeners);
    throw new IllegalStateException(ex);
  }

  try {
    listeners.running(context);
  }
  catch (Throwable ex) {
    handleRunFailure(context, ex, null);
    throw new IllegalStateException(ex);
  }
  return context;
}
```

```java
// 其构造器
public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
  this.resourceLoader = resourceLoader;
  Assert.notNull(primarySources, "PrimarySources must not be null");
  
  this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
  
  this.webApplicationType = WebApplicationType.deduceFromClasspath();
  
  this.bootstrappers = new ArrayList<>(getSpringFactoriesInstances(Bootstrapper.class));
  
  // 设置初始化
  setInitializers((Collection) getSpringFactoriesInstances(ApplicationContextInitializer.class));
  // 设置listener
  setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
  // 设置主类
  this.mainApplicationClass = deduceMainApplicationClass();
}
```

其run方法中有几个关键

1.  SpringApplicationRunListeners创建了应用监听器
2.  加载springboot配置环境ConfigurableEnvironment
3.  应用配置上下文ConfigurableApplicationContext
4.  prepareContext方法将listeners、environment、applicationArguments、banner等重要组件与上下文对象关联
5.  refreshContext 实现自动装配,即spring-boot-starter-*的配置

### springboot自动装载

根据上面的图,如下,我们看到spring自己的启动也需要依赖自动配置的模块

![](https://upload-images.jianshu.io/upload_images/6912735-51aa162747fcdc3d.png?imageMogr2/auto-orient/strip)

自动配置的模块如下,我们从上图知其需要传入构造器工厂对象的集合.无论是在初始化还是在自动装配的过程中都有用到下面的模块结构.

![](https://upload-images.jianshu.io/upload_images/6912735-8f2374a500b07c6d.png?imageMogr2/auto-orient/strip)

该模块主要是用了Spring工厂加载器`SpringFactoriesLoader`其内部有一个字段表明了要去哪加载类,其有一方法loadFactoryNames加载所有springFactory名字,该方法在run里面被调用过

```java
public final class SpringFactoriesLoader {
	public static final String FACTORIES_RESOURCE_LOCATION = 
    "META-INF/spring.factories";
  // 该方法通过类和classloader加载所有的SpringFactories的名字
  public static List<String> loadFactoryNames(Class<?> factoryType, @Nullable ClassLoader classLoader) {
		ClassLoader classLoaderToUse = classLoader;
		if (classLoaderToUse == null) {
			classLoaderToUse = SpringFactoriesLoader.class.getClassLoader();
		}
		String factoryTypeName = factoryType.getName();
		return loadSpringFactories(classLoaderToUse).getOrDefault(factoryTypeName, Collections.emptyList());
	}
  
}
```

如上最开始对@EnableAutoConfiguration的分析我们知道其import了一个类,@EnableAutoConfiguration只对实现了ImportSelector接口的类有效

```java
public class AutoConfigurationImportSelector implements DeferredImportSelector, BeanClassLoaderAware,
ResourceLoaderAware, BeanFactoryAware, EnvironmentAware, Ordered {
  // 其内部方法如下selectImports等
} 
// 通过判断注解来加载类
@Override
public String[] selectImports(AnnotationMetadata annotationMetadata) {
  if (!isEnabled(annotationMetadata)) {
    return NO_IMPORTS;
  }
  AutoConfigurationEntry autoConfigurationEntry = getAutoConfigurationEntry(annotationMetadata);
  return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
}

// 自动配置类的实例
protected AutoConfigurationEntry getAutoConfigurationEntry(AnnotationMetadata annotationMetadata) {
  if (!isEnabled(annotationMetadata)) {
    return EMPTY_ENTRY;
  }
  
  AnnotationAttributes attributes = getAttributes(annotationMetadata);
  // 这个方法 完成了自己定义类的加载,可以直接往下跳转
  List<String> configurations = getCandidateConfigurations(annotationMetadata, attributes);
  
  configurations = removeDuplicates(configurations);
  Set<String> exclusions = getExclusions(annotationMetadata, attributes);
  checkExcludedClasses(configurations, exclusions);
  
  // 排除类
  configurations.removeAll(exclusions);
  configurations = getConfigurationClassFilter().filter(configurations);
  fireAutoConfigurationImportEvents(configurations, exclusions);
  return new AutoConfigurationEntry(configurations, exclusions);
  // 返回这里,然后就交付给spring加载,所以到头来我们在这只需要自己准备类名就好
}

// 获得候选的配置
protected List<String> getCandidateConfigurations(AnnotationMetadata metadata, AnnotationAttributes attributes) {
  // 加载META-INF/spring.factories文件
  List<String> configurations = SpringFactoriesLoader
    .loadFactoryNames(
    getSpringFactoriesLoaderFactoryClass(),getBeanClassLoader()
  );
  
  
  // 断言报错
  Assert.notEmpty(configurations, "No auto configuration classes found in META-INF/spring.factories. If you "
                  + "are using a custom packaging, make sure that file is correct.");
  return configurations;
}

// 这里反悔了一个注解对象
protected Class<?> getSpringFactoriesLoaderFactoryClass() {
		return EnableAutoConfiguration.class;
}
```

看下该文件,这些事默认加载的类,最终通过反射去创建出实例给spring

```properties
# Logging Systems
org.springframework.boot.logging.LoggingSystemFactory=\
org.springframework.boot.logging.logback.LogbackLoggingSystem.Factory,\
org.springframework.boot.logging.log4j2.Log4J2LoggingSystem.Factory,\
org.springframework.boot.logging.java.JavaLoggingSystem.Factory

# PropertySource Loaders
org.springframework.boot.env.PropertySourceLoader=\
org.springframework.boot.env.PropertiesPropertySourceLoader,\
org.springframework.boot.env.YamlPropertySourceLoader

# ConfigData Location Resolvers
org.springframework.boot.context.config.ConfigDataLocationResolver=\
org.springframework.boot.context.config.ConfigTreeConfigDataLocationResolver,\
org.springframework.boot.context.config.StandardConfigDataLocationResolver

# ConfigData Loaders
org.springframework.boot.context.config.ConfigDataLoader=\
org.springframework.boot.context.config.ConfigTreeConfigDataLoader,\
org.springframework.boot.context.config.StandardConfigDataLoader

# Run Listeners
org.springframework.boot.SpringApplicationRunListener=\
org.springframework.boot.context.event.EventPublishingRunListener

# Error Reporters
org.springframework.boot.SpringBootExceptionReporter=\
org.springframework.boot.diagnostics.FailureAnalyzers

# Application Context Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.context.ConfigurationWarningsApplicationContextInitializer,\
org.springframework.boot.context.ContextIdApplicationContextInitializer,\
org.springframework.boot.context.config.DelegatingApplicationContextInitializer,\
org.springframework.boot.rsocket.context.RSocketPortInfoApplicationContextInitializer,\
org.springframework.boot.web.context.ServerPortInfoApplicationContextInitializer

# Application Listeners
org.springframework.context.ApplicationListener=\
org.springframework.boot.ClearCachesApplicationListener,\
org.springframework.boot.builder.ParentContextCloserApplicationListener,\
org.springframework.boot.context.FileEncodingApplicationListener,\
org.springframework.boot.context.config.AnsiOutputApplicationListener,\
org.springframework.boot.context.config.DelegatingApplicationListener,\
org.springframework.boot.context.logging.LoggingApplicationListener,\
org.springframework.boot.env.EnvironmentPostProcessorApplicationListener,\
org.springframework.boot.liquibase.LiquibaseServiceLocatorApplicationListener

# Environment Post Processors
org.springframework.boot.env.EnvironmentPostProcessor=\
org.springframework.boot.cloud.CloudFoundryVcapEnvironmentPostProcessor,\
org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor,\
org.springframework.boot.env.RandomValuePropertySourceEnvironmentPostProcessor,\
org.springframework.boot.env.SpringApplicationJsonEnvironmentPostProcessor,\
org.springframework.boot.env.SystemEnvironmentPropertySourceEnvironmentPostProcessor,\
org.springframework.boot.reactor.DebugAgentEnvironmentPostProcessor

# Failure Analyzers
org.springframework.boot.diagnostics.FailureAnalyzer=\
org.springframework.boot.context.config.ConfigDataNotFoundFailureAnalyzer,\
org.springframework.boot.context.properties.IncompatibleConfigurationFailureAnalyzer,\
org.springframework.boot.context.properties.NotConstructorBoundInjectionFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.BeanCurrentlyInCreationFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.BeanDefinitionOverrideFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.BeanNotOfRequiredTypeFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.BindFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.BindValidationFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.UnboundConfigurationPropertyFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.ConnectorStartFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.NoSuchMethodFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.NoUniqueBeanDefinitionFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.PortInUseFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.ValidationExceptionFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.InvalidConfigurationPropertyNameFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.InvalidConfigurationPropertyValueFailureAnalyzer,\
org.springframework.boot.diagnostics.analyzer.PatternParseFailureAnalyzer,\
org.springframework.boot.liquibase.LiquibaseChangelogMissingFailureAnalyzer

# Failure Analysis Reporters
org.springframework.boot.diagnostics.FailureAnalysisReporter=\
org.springframework.boot.diagnostics.LoggingFailureAnalysisReporter

```

其他组件只需要在jar包里面定义一份该文件,在通过调用loadFactoriesNames加载该文件就可以了

![](https://upload-images.jianshu.io/upload_images/6912735-95d1af756cee57ad.png?imageMogr2/auto-orient/strip)

很显然如上图,springboot通过该种约定,定义了spring-web,spring-jdbc等一系列组件包,其可由springboot完成加载.仔细观察上图,各组件包还利用了@EnableAutoConfigurationImportSelector组件去自动收集配置文件的进行工厂类的加载.

![](https://upload-images.jianshu.io/upload_images/6912735-577bc78a48cea9ef.png?imageMogr2/auto-orient/strip)

从上面的关键代码中我们也能看到就是由`loadFactoryNames`去完成加载各个组件的配置文件.

自动装配的意义就是减少使用代码自己完成装配.我们看下其执行流程

![](https://img2018.cnblogs.com/blog/1216484/201907/1216484-20190715220743499-35910177.png)





#### spring.factories实现装配普通类

springboot利用了@EnableAutoConfiguration,完成了对其基本文件的装配,期间就会读取到reasources/META-INF/spring.factories文件,如果没有读到就是无类名,而在springboot-stater中也是利用了同样的方法加载了

所以我们可以直接在resources下创建一个spring.factories文件,直接指定我们想要装配的类就行

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.fourspring.springtest.conf.Hello1,\
org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.fourspring.springtest.conf.Hello2
```

这样子就会自动装配到springcontext里面.需要注意的是这个和注解@Component的装配顺序时,@Component会优先装入,这是在所有对象都装入之后才会去装入的其他对象,根据架构图我们可以知道其是更新上下文的时候实现的,而@Component则是在spring的bootstrap中启动的.

这个装配类可以是原本在spring中的对象即注有@Component注解,这个时候依然会发生装配但是类的初始化在spring初始化对象时就已经完成.



#### 自定义注解实现装配启动器

实现思路如下

-   @EnableAutoConfiguration标注在启动类,我们就可以使用spring.factories装配普通类
-   定义普通类xxxAutoConfiguration,定义普通类注解@EnablexxxAutoConfiguration
-   在@EnablexxxAutoConfiguration使用@Import其他configuration类
-   把xxxAutoConfiguration配置到spring.factories

```java
@EnableTestAutoConfiguration
public class TestAutoConfiguration {
  // 这个类配置在spring.factories中,由AutoConfiguration装载入spring
}

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Import({SubTestConfiguration.class})
public @interface EnableTestAutoConfiguration {
  // 注解上用了@Import的方法成功导入了SubTestConfiguration等其他子配置
}

public class SubTestConfiguration {
    static {
        System.out.println("子配置已经加载完毕");
    }
}
```

我们可以看到从@EnableAutoConfiguration开始时如何加载spring.factories到加载子配置最终完成自动装配的整个过程的.



#### 自定义启动器

有了前面的技术实现我们就可以实现启动器了.我们来实现下在yml的配置结构,用的是@ConfigurationProperties指定prefix,带着这前缀的yml里面的值全部值会注入.

```java
@ConfigurationProperties(prefix = "spring.userdef.model")
public class UserDefProperties {
    private String userName;
    private Integer age;
    private Double height;
  // getter setter
}
```

配置自动启动类,上面除了这么写之外,也可以利用注解@Import.

```java
@Configuration
@EnableConfigurationProperties(value = UserDefProperties.class) // 把上面的类加入到springcontext
public class UserDefAutoConfiguration {

    @Autowired
    private UserDefProperties userDefProperties;

  	@ConditionalOnMissingBean // 如果springcontext没有才需要加载
    @Bean
    public User user(){
        log.info("自定义自动装配UserDefAutoConfiguration.....");
        User user = new User();
        user.setAge(userDefProperties.getAge());
        user.setUserName(userDefProperties.getUserName());
        user.setHeight(userDefProperties.getHeight());
        return user;
    }
}
```

引入spring-boot-starter依赖

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-configuration-processor</artifactId>
  <!--为编译器配置的,可以配置直接配置里的类跳转-->
  <optional>true</optional>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-autoconfigure</artifactId>
  <!--自动配置的依赖-->
</dependency>
```

这样子只要我们发布自己的maven启动项目,在springboot中导入,那么我们就可以在springboot中写我们自己的类,并且可以在yml文件中完成一些属性的注入.

我们可以在application.yml或者application.properties中覆盖值,就可以快速配置合适的依赖了.从这就能知道springboot是如何加载如此繁杂的jar包了,其实就是spring-boot-start内去寻找其他spring-boot-autoconfigure的jar包的spring.factories然后去加载各种的类而已.这样子我们引入了jar包就相当于导入了依赖,甚至可以延迟加载(即判断yml中某一属性是否为空来看要不要给自己实现的组件初始化,除此之外还可用注解判断是否有自定义的某些类才进行注册)

### springboot与spring配置

我们很多时候会载入配置文件,而不全是使用配置类去解决问题,这个时候就用到以下部分的知识,创建一个配置类

```java
/**
 * ImportResource引入资源文件有三种方式：
 * 1.直接引入，该路径就是src/resources/下面的文件：file
 * 2.classpath引入：该路径就是src/java下面的配置文件：classpath:类的文件全路径
 * 3.引入本地文件：该路径是一种绝对路径：file:D://....
 */
@Configuration
@ImportResource(locations = {"spring.xml"}) // spinrg.xml为beans配置
public class ConfigClass {
}
```

如果是mybatis的配置可以从application.yml中读取

```yml
mybatis:
  config-location: classpath:mybatis/mybatis-config.xml
  mapper-locations: classpath:mybatis/mapper/*.xml
  type-aliases-package: com.mybatis.springboot_mybatis.model
```









