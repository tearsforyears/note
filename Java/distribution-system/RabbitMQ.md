# RabbitMQ

[TOC]

---

## 概述

顾名思义其为一开源消息队列中间件,与之等同的还有RocketMQ和ActiveMQ等

主要是通过RabbitMQ来确定

### 其主要特性是

-   提供可靠性消息投递模式 返回模式
-   API丰富
-   集群模式丰富,表达式配置,HA模式,镜像队列配置
-   高可靠性,可用性

### 应用场景

-   异步处理
-   流量削峰
-   日志处理(参考appendonlyfile)
-   应用解耦 (服务不在把通信的东西写死 交给或是从消息队列中获取)

### 应用实现思路

应用解耦合 有点类似springcloud里面的bus

![解耦合](https://img-blog.csdnimg.cn/201812131955530.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjMyMzgwMg==,size_16,color_FFFFFF,t_70)

异步系统 提高响应速度

![](https://img-blog.csdnimg.cn/20181213200152733.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjMyMzgwMg==,size_16,color_FFFFFF,t_70)

流量削峰

mysql一般一秒处理2000个左右的请求 5000直接宕机

一般秒杀系统用mq直接削峰 存着sql不执行 在上游拦截请求 后续慢慢执行

![](https://img-blog.csdnimg.cn/20181213201130379.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjMyMzgwMg==,size_16,color_FFFFFF,t_70)

流量削峰的话 mq只是一个相对简单的应用

我们这里展开讨论下高并发数据处理方法

**优化思路**

1.  尽量把请求拦截在上游,尽量不要落到数据库里面去,读写锁高时延
2.  充分利用缓存 读多写少尽量不碰数据库(比如买票)

其实对于限流系统来说限流这个事得分级来做 单一级的限流不能解决问题

-   前端 禁止用户请求太快 按钮 缓存结果(过了若干秒之后才能更新缓存)
-   站点 缓存请求来的数据 比如5s内怎么访问都是同一部分数据 站点层能完成大部分限流
-   服务层 站点层如果真的防不住如此之大的请求 请求队列 异步执行数据更新

如果有库存数据的时候 根据库存量限制队列长度 redis中存请求数据等

-   业务优化 比如分时段放票
-   恶意请求 爬虫等直接ban id

### AMPQ协议

![AMPQ协议模型](https://img2018.cnblogs.com/blog/1538609/201907/1538609-20190720105435977-1170222541.png)

其模型如上图 Publicsher 推送/生产消息 Consumer消费消息 Server服务端提供消息队列服务

其中间的几个重要的概念

-   Server:提供服务
-   Connection:TCP连接,Server和application之间的通信
-   Channel:通道,本质上就是个文件,读写在此中进行
-   Message:application和server传送的数据
-   Virtual Host:虚拟主机,一个虚拟主机里面可以有若干队列
-   **Exchange**:交换器，接收消息，按照路由规则将消息路由到一个或者多个队列。如果路由不到，或者返回给生产者，或者直接丢弃。RabbitMQ常用的交换器常用类型有direct、topic、fanout、headers四种，后面详细介绍。
-   Binding:指Exchange和队列之间的绑定,Exchange可以绑定多个队列(根据RoutingKey)
-   RoutingKey:唯一标定一个队列的key
-   Queue:MQ队列本身

### RabbitMQ对AMPQ协议的实现

![RabbitMQ架构](https://img2018.cnblogs.com/blog/1538609/201907/1538609-20190720105508727-442219527.png)

可以看到Exchange是消息队列中的核心部分

### Exchange

routingkey我们一般 用`.`隔开 比如com.example.mail

有4种模式direct、topic、fanout、headers

**direct**: routing key直接进行匹配

**Topic**: `*`和`#`通配符用于匹配一个或多个字符 区别在于`*`用来匹配`.`与`.`之间此,#相当于全匹配

**Fanout**: 不处理路由键,全分发效率最高

**Headers**: 根据消息中的Headers进行转发 一般不常用

Exchange还可以设置其持久化属性

### 持久化

消息队列是在内存中的数据结构 如果不设置持久化的 会因为掉电而消失 而持久化比较影响性能所以持久化的开启与否要根据业务去斟酌

### ACK机制

因为如果消息没有处理完就宕机那么就有必要有一个ACK机制在消息处理完之后给消息队列发送一个ACK回执消息队列再把消息移除出消息队列

而ACK机制有好处也有坏处 好处是这种机制保证了消息正确被消费完毕 坏处是ACK由于逻辑错误或者实在过高的并发下会造成消息队列的处理速度变慢(可能由大sql造成)

### 消息分发机制

1.  轮询分发
2.  公平分发

轮询分发不管消费者的速度直接等量分发,公平分发得需要手动确认需要ACK才能拿到下一条数据

### 消息堆积问题

-   对于一些数据采用非持久化加direct模式(非持久化与持久化性能差10倍)

-   增大消费者分配到的资源

-   修改参数 修改池的属性来限制消费速度和生产速度

    ```properties
    # spring.rabbitmq.listener.simple.concurrency: 最小的消费者数量
    # spring.rabbitmq.listener.simple.max-concurrency: 最大的消费者数量
    # spring.rabbitmq.listener.simple.prefetch: 指定一个请求能处理多少个消息，如果有事务的话，必须大于等于transaction数量.
    
    # 三个参数类似于池的扩展性 可动态调控 最后一个参数过大意味着延时过小意味着消费慢
    ```

-   设置过期时间TTL

---

## docker部署rabbitmq

docker 下拉镜像

```shell
docker pull rabbitmq:management # 这个后缀是带管理后台的意思
```

运行后台服务

```shell
docker run -d --hostname my-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:management
```

访问127.0.0.1:15672就可以了

```shell
rabbitmqctl list_users
rabbitmqctl change_password guest 'pass'
```

修改用户名和密码

---

## rabbitmq的端口

rabbitmq的默认端口是5672

-   4369 erlang发现口 
-   5672 client端通信口 
-   15672 管理界面ui端口 
-   25672 server间内部通信口

## springboot中配置rabbitmq

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

```properties
spring.application.name=Spring-boot-rabbitmq
spring.rabbitmq.host=192.168.0.86
spring.rabbitmq.port=5672
spring.rabbitmq.username=admin
spring.rabbitmq.password=123456

# spring.rabbitmq.listener.simple.acknowledge-mode: 表示消息确认方式，其有三种配置方式，分别是none、manual和auto；默认auto

# spring.rabbitmq.listener.simple.concurrency: 最小的消费者数量
# spring.rabbitmq.listener.simple.max-concurrency: 最大的消费者数量
# spring.rabbitmq.listener.simple.prefetch: 指定一个请求能处理多少个消息，如果有事务的话，必须大于等于transaction数量.
```

基本api的使用移步springboot

## rabbitmq的镜像集群

待后续