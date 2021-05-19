# Maven

---

[TOC]

### 项目基本结构和创建

创建项目一般有三种模板(项目骨架)

-   cocoon-22-archetype-webapp(springboot)
    包含applicationContext.xml log4j.xml web.xml pom.xml
    
-   maven-archetype-quickstart
    包含main/test两个包 pom.xml
    
-   maven-archetype-webapp

    web.xml index.jsp 等3.0基本的web组件 springMVC用这个建立项目

-   原生
  

就是简单的maven项目

基本结构

-   src
    -   main
    -   test
-   pom.xml

### 项目基本配置

```xml
<groupId>com.company</groupId> 
<artifactId>demo</artifactId><!--project name-->
<version>0.0.1-SNAPSHOT</version>
<packaging>jar</packaging><!-- war for web project-->
```

### 镜像(源)配置

```xml
<mirror>
	<id>alimaven</id>
	<name>aliyun maven</name>
	<url>http://maven.aliyun.com/nexus/content/groups/public/</url>
	<mirrorOf>central</mirrorOf>
</mirror>
```

### 中央仓库私服本地仓库repository

中央仓库对应于配置源的仓库 即公网的仓库 默认连接到maven项目的仓库(国外源)

私服配置在局域网下 公司内部搭建的maven仓库

本地仓库 ~/.m2/reprository/ 为本地仓库可添加环境变量添加引用

### 依赖

```xml
<dependencies>
	<dependency>
  	<groupId></groupId>
    <artifactId></artifactId>
    <version></version>
    <scope>test</scope>
  </dependency>
</dependencies>
```

#### dependency <scope>的取值

compile 默认值 编译执行的时候都会使用该依赖

test junit编译测试时会使用该依赖,运行时不会使用该依赖

provided 编译测试时依赖 运行时由环境提供依赖

runtime 编译测试时不依赖,运行时依赖

### 依赖传递

A依赖于B B依赖于C 则A依赖于C

只有complie和runtime依赖会传递下去

### 依赖冲突解决办法

[参考文档](https://blog.csdn.net/noaman_wgs/article/details/81137893)

1.最小深度依赖(最短路径优先)

2.最先配置优先

### 排除依赖传递

```xml
<dependency>
	<groupId>org.glassfish.web</groupId>
	<artifactId>jstl-impl</artifactId>
	<version>1.2</version>
	<exclusions>
		<exclusion>
			<groupId>javax.servlet</groupId>
			<artifactId>servlet-api</artifactId>
		</exclusion>
		<exclusion>
			<groupId>javax.servlet.jsp</groupId>
			<artifactId>jsp-api</artifactId>
		</exclusion>
	</exclusions>
</dependency>
<!--在exclusions中排除依赖-->
<exclusions>
	<exclusion>
  	<groupId></groupId>
    <artifactId></artifactId>
  </exclusion>
</exclusions>
```

除此之外可以在父项目中指定依赖版本,子项目就会沿用父项目的依赖(子项目不用指定版本)这样就可以解决依赖冲突的问题.

### 指定JDK的版本

```xml
<build>
	<plugins>
		<!-- 指定JDK编译版本 -->
		<plugin>
			<groupId>org.apache.maven.plugins</groupId>
			<artifactId>maven-compiler-plugin</artifactId>
			<version>3.1</version>  
			<configuration>  
			  <source>1.8</source>
			  <target>1.8</target>
			</configuration> 
		</plugin>
	</plugins>
</build>
<!--同理还可以指定项目缓存的清理等一些常用的maven原生功能-->
```

### 聚合Maven子项目

在父项目pom.xml中指定模块的名字

```xml
<modules>
	<module>module1_name</module>
  <module>module2_name</module>
</modules>
```

