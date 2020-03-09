# tomcat

---

[toc]

## 目录结构

### /bin 

Tomcat命令在此 startup.sh shutdown.sh 用于启动和关闭

修改catalina可以设置tomcat内存

### /conf

server.xml 设置端口号 域名 IP 默认加载项目 请求编码

web.xml 设置支持的文件类型 无需配置(注解配置)

context.xml 配置数据源

tomcat-users.xml 配置tomcat的用户全新啊

/conf/Catalina 加载默认项目

### /lib

jar包支持类 

### /logs

catalina.out 输出日志

### /temp

临时文件

### /webapps

用于存放webapp程序 war包jar包会在启动的时候加载

### /work

编译缓存存放

## 运行模式

BIO:tomcat7.0以下版本 阻塞IO版本

NIO: 非阻塞IO版本 基于NIO去实现的机制

APR:基于JNI的文件和网络读写模式 8以上版本都默认是tomcat默认使用

## NIO

这是tomcat实现基础之一

## 实现原理

本质上就是通过内部维护的一个线程池去处理各种请求

其具体架构如下

![tomcat架构](https://img2018.cnblogs.com/blog/1079203/201903/1079203-20190304103855819-1799065168.png)

其Container的结构如下 我们就可以看到平常的context,servlet处于结构的那一层

![](https://img2018.cnblogs.com/blog/1079203/201903/1079203-20190304103948369-1849108030.png)