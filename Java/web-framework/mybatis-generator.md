# Mybatis-Generator

---

[TOC]

Mybatis-Generator是一个根据数据库生成sql和Mapper的插件.其能够根据原有数据库来进行Java代码和xml文件的生成,以下简称MBG,可参考[官方文档](http://mybatis.org/generator/running/running.html)

### 配置pom.xml

其需要在pom文件中配置


```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
 
  <groupId>com.mybatis.generator</groupId>
  <artifactId>mybatis-generator</artifactId>
  <version>1.0-SNAPSHOT</version>
 
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>
 
  <dependencies>
      ...
  </dependencies>
 
  <build>
        <plugin>
          <groupId>org.mybatis.generator</groupId>
          <artifactId>mybatis-generator-maven-plugin</artifactId>
          <version>1.3.7</version>
          <configuration>
            <configurationFile>src/main/resources/mybatis-generator/generatorConfig.xml</configurationFile>
              <!--指定config文件位置-->
            <verbose>true</verbose>
            <overwrite>true</overwrite>
          </configuration>
          <executions>
            <execution>
              <id>Generate MyBatis Artifacts</id>
              <goals>
                <goal>generate</goal>
              </goals>
            </execution>
          </executions>
          <dependencies>
            <dependency>
              <groupId>org.mybatis.generator</groupId>
              <artifactId>mybatis-generator-core</artifactId>
              <version>1.3.7</version>
            </dependency>
          </dependencies>
        </plugin>
      </plugins>
  </build>
</project>
```

上面我们指定了一个路径在pom.xml,指向该插件的配置文件.想要使用的时候执行该插件就行,或者是使用下面依赖

或者我们可以手动指定pom的依赖

```xml
<!--mybatis生成器-->
<dependency>
    <groupId>org.mybatis.generator</groupId>
    <artifactId>mybatis-generator-core</artifactId>
    <version>1.4.0</version>
</dependency>
```

```java
package com.zhigongbang.generator.generator;

import org.mybatis.generator.api.MyBatisGenerator;
import org.mybatis.generator.config.Configuration;
import org.mybatis.generator.config.xml.ConfigurationParser;
import org.mybatis.generator.internal.DefaultShellCallback;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class Generator {
    public static void main(String[] args) throws Exception {
        //MBG 执行过程中的警告信息
        List<String> warnings = new ArrayList<String>();
        //当生成的代码重复时，覆盖原代码
        boolean overwrite = true;
        //读取我们的 MBG 配置文件
        InputStream is = Generator.class.getResourceAsStream("/generatorConfig.xml");
        ConfigurationParser cp = new ConfigurationParser(warnings);
        Configuration config = cp.parseConfiguration(is);
        is.close();

        DefaultShellCallback callback = new DefaultShellCallback(overwrite);
        //创建 MBG
        MyBatisGenerator myBatisGenerator = new MyBatisGenerator(config, callback, warnings);
        //执行生成代码
        myBatisGenerator.generate(null);
        //输出警告信息
        for (String warning : warnings) {
            System.out.println(warning);
        }
    }
}

```

甚至也可以下命令行使用.

generatorConfig.xml文件.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
        PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">

<generatorConfiguration>
<!--    <properties resource="generator.properties"/>-->
    <context id="MySqlContext" targetRuntime="MyBatis3" defaultModelType="flat">
        <property name="beginningDelimiter" value="`"/>
        <property name="endingDelimiter" value="`"/>
        <property name="javaFileEncoding" value="UTF-8"/>
        <!-- 为模型生成序列化方法-->
        <plugin type="org.mybatis.generator.plugins.SerializablePlugin"/>
        <!-- 为生成的Java模型创建一个toString方法 -->
        <plugin type="org.mybatis.generator.plugins.ToStringPlugin"/>
        <!--配置数据库连接-->
        <jdbcConnection driverClass="com.mysql.jdbc.Driver"
                        connectionURL="jdbc:mysql://192.168.0.55:3306/worker_agent_dev?useUnicode=true"
                        userId="root"
                        password="root">
            <!--解决mysql驱动升级到8.0后不生成指定数据库代码的问题-->
            <property name="nullCatalogMeansCurrent" value="true" />
        </jdbcConnection>
        <!--指定生成model的路径-->
        <javaModelGenerator targetPackage="com.zhigongbang.generator.generator.model" targetProject="zhigongbang-service/generator-service/src/main/java"/>
        <!--指定生成mapper.xml的路径-->
        <sqlMapGenerator targetPackage="com.zhigongbang.generator.generator.mapper" targetProject="zhigongbang-service/generator-service/src/main/resources"/>
        <!--指定生成mapper接口的的路径-->
        <javaClientGenerator type="XMLMAPPER" targetPackage="com.zhigongbang.generator.generator.mapper"
                             targetProject="zhigongbang-service/generator-service/src/main/java"/>
        <!--生成全部表tableName设为%-->
        <table tableName="%" enableCountByExample="false" enableUpdateByExample="false" enableDeleteByExample="false"
               enableSelectByExample="false">
            <generatedKey column="id" sqlStatement="MySql" identity="true"/>
        </table>
    </context>
</generatorConfiguration>
```

然后我们需要把这些生成的类配置到spring里

```java
package com.macro.mall.tiny.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

/**
 * MyBatis配置类
 * Created by macro on 2019/4/8.
 */
@Configuration
@MapperScan("com.macro.mall.tiny.mbg.mapper")
public class MyBatisConfig {
}
```



