# [SpringBoot](https://start.spring.io/)

---

springboot其解决了spring大部分配置的问题 解放了spring需要大量配置的问题

使得程序员专注于java的业务逻辑而非过于纠结配置本身的事情

基于云计算意味着docker和微服务架构

其特性如下

-   快速创建独立的Spring项目
-   嵌入式servlet 无需war
-   大量自动配置
-   无需配置xml
-   准生产环境 运行时监控
-   天然适合云计算环境
-   在微服务下 天生适合与SpringCloud等RPC框架结合

---

## 使用感受

---

用的就两字 顺滑 不用过多乱七八糟的配置服务器 专注于业务逻辑的编写

真的是约定大于配置的典型 默认的配置可以更改 但是默认的配置会使得项目顺滑程度提高了很多倍

---

[TOC]

## spring-springmvc注解review

-   **@RequestMapping @GetMapping @HeadMapping**

-   **@Controller @Component @Repositroy @Configuration**

-   **@PathVariable**("name") **@GetMapping**("{name:[a-zA-Z]}{1,}")

-   **@RequestParam**("url param")

-   **@RestController** // restful标准支持 json格式的返回

-   **@Bean**(name="")注解 spring的注解非mvc的 标注在方法上 用于构造对象

    可以指定initMethod,destroyMethod用于加载或者销毁类

-   **@Scope @Description** // 用于指定bean的作用范围和描述

-   **@Transactional** 事务注解 此注解标注在方法上(不要标记在接口上) 用于事务处理 发生异常时回滚 因为是 基于类代理和接口代理实现的 所以标注在接口上基本会在别的组件代理接口时失去效果 另外类内调用该方法也是不起作用的 只有当创建类的时候 该注解才会注入事务

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

## 创建项目

[Spring initializr](http://start.spring.io/)用于创建springboot项目选择web-springweb 当然idea可以自己选

一堆依赖可以通过选择配置上去 springboot采用默认配置简化了很多其他框架的配置

## 项目目录结构

是准的web项目结构 有SpringMVC javaweb任意一知识理解此架构不难

```tree
├── HELP.md
├── mvnw
├── mvnw.cmd
├── pom.xml
├── spboottest.iml
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       └── example 典型的web结构目录
│   │   │           ├── Application.java 项目的启动配置,在其同级下的包才会被扫描
│   │   │           ├── controller
│   │   │           │   └── IndexController.java 典型的controller
|   |   |           ├── DAO 放接口
│   │   │           ├── model
│   │   │           └── service
│   │   └── resources
│   │       ├── application.properties 全局配置文件
│   │       ├── static
│   │       └── templates
│   └── test
│       └── java
│           └── com
│               └── example
│                   └── demo
│                       └── DemoApplicationTests.java

```

## 快速运行的demo

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

## 配置依赖环境pom.xml

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

## application.properties

这个文件在resource下是全局配置文件 我们约定这个文件里面一些值可以直接被项目的各个组件所引用

```properties
# 配置log的的输出地址和输出级别
logging.path=/user/local/log
logging.level.com.favorites=DEBUG
logging.level.org.springframework.web=INFO
logging.level.org.hibernate=ERROR
# 自定义变量
com.example.name=z3 # @Value(${com.example.name})
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

## 自定义Filter的配置类

```java
@Configuration // 相当于一个独立的beans.xml注入整体的xml中
public class WebConfiguration {
    @Bean // 相当于bean标签 配置 原生的过滤器
    public RemoteIpFilter remoteIpFilter() {
        return new RemoteIpFilter();
    }
    
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

## JPA的简单使用

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
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
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

## 连接redis

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

---

## **springboot-jpa(hibernate)**

jpa是Java Persistence API 指的是一套持久化的规范,springboot-jpa是基于jpa在spring上的一套实现,我们可以不再编写传统的CRUD操作

普通Pojo类得标注@Entity 被JPA 引用 可以添加@Column

标注@Repositroy被spring引用

DAO等接口标注 @Component 用以被 @Autowried注入

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

-   创建结果集接口接收数据

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

## springboot-mybatis

orm框架发展到现在就剩以mybatis/mybatis-plus的灵活sql和不用写一句sql,jpa-hibernate为顶层的两大框架,hibernate经过jpa优化已经开发难度已经很低了,而mybatis经过注解等优化之后基本也是非常完善的技术体系了 按照经验而言mybatis给了DBA存在的理由 优化可以做的特别好

按照经验而言 互联网公司一般用mybaits 非互联网公司用hibernate

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

复杂查询

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

## 文件上传



## 登录认证



---

## RabbitMQ





## springboot-spring web原理应用相关

组件/服务/实体类的单例和多例 首先毫无疑问的web处理请求是多例实现的(NIO) 因为要复用各种请求加速访问进度 其次服务是单例的 因为都是用相同的函数 不存在同时执行会有线程安全的问题 实体类是多例的 (难道你实体类就一个?) 其实是多个实体类 不会存在线程安全问题 单例则会有线程安全问题**单例和多例和线程同步是基于状态进行分类的 也就是说 单例是类中没有可改变的状态则不会引发安全问题 多例是类中有可改变的状态避免线程安全问题 而线程同步则是当多例会额外分配内存(或者有些功能无法实现) 的时候 用单例去实现制约的一种方式** 

为什么要使用redis来保存会话参数 那是因为session本质上要开启磁盘IO 放redis中服务器关闭的时候进行初始化 设置销毁时间会比存内存来的更加实际 redis里存放的对性能要求十分高的数据(热点数据) 尤其是dict型的数据 会很高 访问数据库相当于访问文件效率不会高

