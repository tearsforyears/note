

# SpringCloud与微服务

---

springcloud是一种技术体系，和dubbo一样是微服务构建的核心体系之一



## CAP定理

---

CAP原则又称CAP定理,指的是在一个分布式系统中,一致性(Consistency),可用性(Availability),分区容错性(Partition tolerance).CAP 原则指的是,这三个要素最多只能同时实现两点,不可能三者兼顾.

C:即主从复制不够及时 A:熔断,顶替选举 P:延时

这是分布式系统必然会存在并解决的问题,要么满足AP,CP,CA.



## 微服务和SOA

---

微服务是SOA的扩展,SOA(Service-Oriented Architecture) 为面向服务的架构,其依赖xml为基础,其用来通信的系统是我们今天的消息队列 SOA 而我们今天使用的微服务架构是基于此发展而来把通信系统由消息队列改成了Restful+RPC 

微服务与SOA的本质不同在于微服务是真正分布式的 去中心化的(即在服务中没有真正的master节点)

微服务是把不同的服务拆分成各个模块 非常适合生产环境的高可用(维护某些特定的模块不用让全部系统一起下线 只用下线部分模块即可) 高度的解耦合,负载均衡更加有针对性 另外一点就是 有效的降低了分布式系统的构建成本(不用自己写每个模块的通信了,由统一RPC管理) 微服务也有利于代码的不同分工行程自己的自治区域 和其他微服务共同完成整个系统的协作

微服务的restful通信决定了不同语言之间可以进行协作,只要restful的参数规定好.比如我们用python写了一个小型的爬虫服务用于爬取不同的关键词,springboot即可向flask端的服务发起请求由flask完成爬虫的调度返回数据交付给springboot的服务这样就完成了双语言协作。其有一个明显的好处就是同时利用了springboot大架构的优势和python脚本的开发速度进而大大提高了工程师之间的协作性,且通信采用http/restful并不会损失多少性能而会大大提高解耦合,故此种开发方式被越来越广泛采用到现代架构中

### 微服务的优劣势和数据治理

微服务还有一个好处是每个服务都可以有自己相对独立的数据库可以独立投入生产环境，这就给熔断机制负载均衡等良好的部署环境

微服务有其弊端,某些业务要求数据的完整性多条件查询联合查询等,割裂的数据整合需要额外的逻辑,数据采集的时候需要分析全量的数据而不影响到现有的系统。两者都是数据整合问题前者是在线问题后者是离线问题(参考hadoop)

#### 在线处理

在线处理主要是通过给微服务加数据接口解决,而这第一是要花费额外逻辑去维护接口,第二是要注意不能影响业务的性能,而通过接口去处理势必会影响服务的性能

#### 离线处理

离线处理主要是对业务没有影响的数据进行采集分析,不同微服务之间的数据调配可以通过同步数据库去解决

## spingboot在微服务中

其相当于整合了一些技术成熟的组件的一个开发的脚手架

从14年开始发布之后便迅速成为热门技术 18年2.0发布之后更是成为了标准脚手架

其还能轻松结合docker成为微服务时代下必要的服务开发选项

自带的Actuator可以轻松监控服务的各项状态

另外其几乎原生实现了微服务的架构,是Java领域最优秀的微服务解决方案

springboot+mongodb集群曾是微服务架构下最好的数据治理方案

## 微服务的扩展

微服务的相对独立性 每个微服务具有同一套数据库

其实和服务的扩展类似 主要分为水平扩展和垂直扩展

### 水平扩展

类似负载均衡多台机器处理同一服务,利用集群来处理问题

或者如同我们的微服务架构利用调度能力和分布式锁去解决集群问题

### 垂直扩展

指提高单机处理能力 像缓存就是一种典型的提高方法

我们按照传统javaweb架构有如下扩展

### 扩展方法

-   站点扩展(控制器线程)

    **nginx反向代理** ip_hash发到各个站点的控制器上进行下一步操作

    又称**负载均衡** 水平扩展

-   服务层扩展

    **cache架构** 提升性能

    可以使用**服务连接池**来实现服务的水平扩展

    这中间用到RPC调用来实现

-   数据层扩展

    **简单的分库分表**

    分库指的是把不同服务对象的数据库放到不同服务(服务器上)

    分表是指按照主键或者某些字段根据大小或者hash分开成两张表方便索引

    比如主键为0-1kw的在一个表中1kw-2kw的在另一个表中

    或者奇数一个表偶数一个表(hash%2)

    **建立索引**

    通过索引sql去查询数据

    **读写分离**

    master-slave主从架构分离读写

## RPC

RPC:**Remote Procedure Call** 远程调用框架 SpringCloud中的组件充当RPC中的职责

RPC更像是个抽象 如下

![RPC](https://upload-images.jianshu.io/upload_images/6943526-1ce8749921dc6280)

RPC协议是区域系统自治用的通信协议传输数据的格式等 SpringCloud采用http/restful协议完成主要的网络传输

注册中心则是注册各种服务进行服务发现的 这个是RPC中比较重要的东西,至于负载均衡高可用容错等则是为了构建分布式系统的基础服务

## Springcloud

---

springcloud是一系列原生框架的集合,依赖SpringBoot脚手架快速开发微服务应用

其包含了**服务发现中心,配置中心,消息总线,负载均衡,熔断器,数据监控等**

springcloud并非重复造轮子而是把经得起考验的这些开源项目做了个集合

springcloud只是代为管理这些项目去完成微服务架构

其用在相对比较大的架构里面,小架构绝对不适合去使用springcloud

下面这些组件为springcloud的组件架构

![springcloud 组件架构](http://favorites.ren/assets/images/2017/springcloud/spring-cloud-architecture.png)

### springcloud技术汇总

Spring Cloud Config、Spring Cloud Netflix（Eureka、Hystrix、Zuul、Archaius…）、Spring Cloud Bus、Spring Cloud for Cloud Foundry、Spring Cloud Cluster、Spring Cloud Consul、Spring Cloud Security、Spring Cloud Sleuth、Spring Cloud Data Flow、Spring Cloud Stream、Spring Cloud Task、Spring Cloud Zookeeper、Spring Cloud Connectors、Spring Cloud Starters、Spring Cloud CLI

这些技术或者框架帮助我们完成微服务架构的构建



## SpringCloud-Netflix 基本组件

---

Netflix是网飞公司(就是那家纪录片的)用来实现内部自治的一个框架 其为微服务的核心

整个微服务的管理构建由此模块提供支持 其有一些基本组件

### **Spring Cloud Eureka**

/尤里卡/-服务中心,用于注册和调度微服务,基于restful进行微服务之间的通信,以及心跳等机制保持对于注册服务的监测,基于java-servlet实现,调度管理框架

### **Spring Cloud Hystrix**

/high-stress/-熔断器 提供对延迟和故障的容错能力 不稳定下线 或者直接熔断该服务直接调用失败防止过度阻塞

### **Spring Cloud Zuul**

Zuul是提供动态路由,监控,弹性,安全等边缘服务框架.后端请求的门户可以拦截一些非法请求.

### **Spring Cloud Ribbon**

客户端负载均衡

### Spring Cloud Config

配置中心,把配置放到远程服务器,集中化管理集群,支持本地git,Subversion.



## SpringCloud 高级组件

### Spring Cloud Bus

消息总线,和SpringCloud Config可以实现热部署

### Spring Cloud Cluster

代替Spring Integration,提供分布式集群的基础功能例如选举,分布式锁,集群状态的一致性,token等提供协调性服务

### Spring Cloud Stream

消息驱动的微服务

### Spring Cloud Sleuth

分布式服务跟踪



## 分布式服务协调框架的对比

| Feature              | Consul                 | zookeeper             | etcd              | euerka                       |
| -------------------- | ---------------------- | --------------------- | ----------------- | ---------------------------- |
| 服务健康检查         | 服务状态，内存，硬盘等 | (弱)长连接，keepalive | 连接心跳          | 可配支持                     |
| 多数据中心           | 支持                   | —                     | —                 | —                            |
| kv存储服务           | 支持                   | 支持                  | 支持              | —                            |
| 一致性               | raft                   | paxos                 | raft              | —                            |
| cap                  | cp                     | cp                    | cp                | ap                           |
| 使用接口(多语言能力) | 支持http和dns          | 客户端                | http/grpc         | http（sidecar）              |
| watch支持            | 全量/支持long polling  | 支持                  | 支持 long polling | 支持 long polling/大部分增量 |
| 自身监控             | metrics                | —                     | metrics           | metrics                      |
| 安全                 | acl /https             | acl                   | https支持（弱）   | —                            |
| spring cloud集成     | 已支持                 | 已支持                | 已支持            | 已支持                       |









