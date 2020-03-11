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

## springboot重要注解

-   **@SpringBootApplication** 标注为springboot启动类
-   **@ComponentScan**(basePackages = {"com.xxx.service1.*","com.xxx.service2.**"})// 标注在SpringBootApplication的类上 进行包的扫描
-   **@Value**(${com.example.demo.name}) 这是spring的注解 在springboot中是提取application.properties的字段值
-   **@ConfigurationProperties**(prefix = "com.example") 相当注入整个命名空间 用于配置类的属性 省略一堆@Value

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
@Configuration
public class WebConfiguration {
    @Bean
    public RemoteIpFilter remoteIpFilter() {
        return new RemoteIpFilter();
    }
    
    @Bean
    public FilterRegistrationBean testFilterRegistration() {

        FilterRegistrationBean registration = new FilterRegistrationBean();
        registration.setFilter(new MyFilter());
        registration.addUrlPatterns("/*");
        registration.addInitParameter("paramName", "paramValue");
        registration.setName("MyFilter");
        registration.setOrder(1);
        return registration;
    }
    
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

@GeneratedValue

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

## springboot-spring web原理应用相关

组件/服务/实体类的单例和多例 首先毫无疑问的web处理请求是多例实现的(NIO) 因为要复用各种请求加速访问进度 其次服务是单例的 因为都是用相同的函数 不存在同时执行会有线程安全的问题 实体类是多例的 (难道你实体类就一个?) 其实是多个实体类 不会存在线程安全问题 单例则会有线程安全问题**单例和多例和线程同步是基于状态进行分类的 也就是说 单例是类中没有可改变的状态则不会引发安全问题 多例是类中有可改变的状态避免线程安全问题 而线程同步则是当多例会额外分配内存(或者有些功能无法实现) 的时候 用单例去实现制约的一种方式** 

为什么要使用redis来保存会话参数 那是因为session本质上要开启磁盘IO 放redis中服务器关闭的时候进行初始化 设置销毁时间会比存内存来的更加实际 redis里存放的对性能要求十分高的数据(热点数据) 尤其是dict型的数据 会很高 访问数据库相当于访问文件效率不会高

