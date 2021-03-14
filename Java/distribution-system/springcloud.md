

# SpringCloud与微服务

---

springcloud是一种技术体系，和dubbo一样是微服务构建的核心体系之一

[TOC]

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

RPC:**Remote Procedure Call** 远程调用框架 SpringCloud中的组件使用Restful通信充当SOA中RPC的职责

![RPC](https://upload-images.jianshu.io/upload_images/6943526-1ce8749921dc6280)

RPC协议是区域系统自治用的通信协议传输数据的格式等,SpringCloud采用http/restful协议完成主要的网络传输

RPC例如google的rpc,能够让用户不加感知的像调用本地方法一样使用远程方法

### RPC和Restful

两者都是通信手段,出现的时代不同应用的场景也不同.RPC用于自治系统里面的服务调用,其特点就是速度快,但是缺点就是不能跨语言协作,但Restful接口可以跨越不同的服务去进行调用,只要所有服务都符合注册中心的规范并且注册,那各个服务间就能够通过restful进行通信.restful相比RPC是慢,但是其这种跨越语言面向服务的优点使得更多的公司愿意采用Restful来完成架构间的耦合.



## Springcloud简介

---

springcloud是一系列原生框架的集合,依赖SpringBoot脚手架快速开发微服务应用

其包含了**服务发现中心,配置中心,消息总线,负载均衡,熔断器,数据监控等**

springcloud并非重复造轮子而是把经得起考验的这些开源项目做了个集合

springcloud只是代为管理这些项目去完成微服务架构

其用在相对比较大的架构里面,小架构绝对不适合去使用springcloud

下面这些组件为springcloud的组件架构

![springcloud 组件架构](http://favorites.ren/assets/images/2017/springcloud/spring-cloud-architecture.png)

![](https://img-blog.csdnimg.cn/2020030717544472.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTIxNzU0MQ==,size_16,color_FFFFFF,t_70)

从上面这个图我们能够大致了解各组件的功能流程.



### springcloud技术汇总

Spring Cloud Config、Spring Cloud Netflix（Eureka、Hystrix、Zuul、Archaius…）、Spring Cloud Bus、Spring Cloud for Cloud Foundry、Spring Cloud Cluster、Spring Cloud Consul、Spring Cloud Security、Spring Cloud Sleuth、Spring Cloud Data Flow、Spring Cloud Stream、Spring Cloud Task、Spring Cloud Zookeeper、Spring Cloud Connectors、Spring Cloud Starters、Spring Cloud CLI

这些技术或者框架帮助我们完成微服务架构的构建,其技术多且杂,我们需要关注于Netflix,这是SpringCloud的基础功能.

![](https://img-blog.csdnimg.cn/20200307175817680.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTIxNzU0MQ==,size_16,color_FFFFFF,t_70)







## SpringCloud-Netflix 核心组件

---

Netflix是网飞公司(就是那家纪录片的)用来实现内部自治的一个框架 其为微服务的核心

整个微服务的管理构建由此模块提供支持 其有一些基本组件



### **Eureka集群**

拥有服务中心的集群,用于注册和调度微服务,基于restful进行微服务之间的通信,以及心跳等机制保持对于注册服务的监测,基于java-servlet实现,调度管理框架.

可以说Eureka集群是整个SpringCloud的核心所在,其他所有的组件都得围绕着Eureka集群进行集成.对于Eureka而言,zookeeper也可以充当服务中心,但Eureka强调ap,zookeeper强调cp,对于一个服务而言,可以容忍返回几分钟前的配置信息(对一致性要求没有那么严格)但不能不返回信息(zookeeper会在选举的时候停止提供服务).

![](https://pic4.zhimg.com/80/v2-ddb398e19d3b3eb0cd035b72fcd94d72_1440w.jpg?source=1940ef5c)

#### 节点角色

在Eureka中一般有如下角色

-   Eureka注册中心(服务端)
-   Eureka客户端
    -   服务消费者
    -   服务提供者



##### Eureka Server 注册中心

他们可以通过配置文件来进行切换,我们把服务注册到Eureka的注册中心,四个服务不再通过ip地址调用而通过服务名,注册中心相当于zookeeper一类的协调服务.我们把注册中心称之为Eureka服务端,服务称为Eureka客户端.

-   Eureka注册中心集中管理配置文件,各个服务首先向注册中心注册

所以我们在注册中心(Eureka Server)一般会使用以下配置

```yml
server:
	port: 8761 # Eureka的默认端口
register-with-eureka: false     # false表示不向注册中心注册自己
    fetch-registry: false     # false表示自己端就是注册中心，我的职责就是维护服务实例，并不需要去检索服务
```

```java
@EnableEurekaServer
@SpringBootApplication
public class SpringcloudApplication {
         public static void main(String[] args) {                 SpringApplication.run(SpringcloudApplication.class,args);
         }
}
```

在整个系统中Eureka客户端分为服务消费者和服务提供者,也可以二者兼具.其配置如下,其中`register-with-eureka`属性可以标识其是否注册到注册中心中,对于服务中心而言,不需要注册到服务中心.

```yml
eureka:
  client:
    register-with-eureka: false  # 当前微服务不注册到eureka中(消费端)
    service-url: 
      defaultZone:      http://localhost:8761/eureka/,http://localhost:8762/eureka/,http://localhost:8763/eureka/
      # 这个后面的/eureka/是固定写法
```



##### Eureka Client

对于Eureka Client而言还可以细分为一下角色.

-   服务消费者,指使用**(消费)其他模块的服务**
-   服务提供者,对系统外提供服务

自然在微服务中,一个服务模块可能得需要其他服务模块做联合数据查询,而像中台技术等则是专门对这些模块进行查询中转.所以一个服务模块可能同时是服务消费者和服务提供者.

```yml
eureka:
  client:
    service-url: 
      defaultZone:
      	http://localhost:8761/eureka/
```

```java
@EnableEurekaClient
@SpringBootApplication
public class SpringcloudApplication {
         public static void main(String[] args) {                 SpringApplication.run(SpringcloudApplication.class,args);
         }
}
```





#### 治理机制

Eureka是强调AP的,服务中心在丢失心跳的时候会保留那些死亡心跳的注册信息不过期,这些机制表明了Eureka是强调高可用性的,即允许信息非及时性但一定是高可用的,如下服务中心的自我保护

##### 服务提供者

-   服务注册: 服务启动的时候会发Restful请求把自己注册到Eureka Server上
-   服务续约: 向注册中心发送心跳
-   服务下线: 当服务进行正常关闭时,发送Restful请求给注册中心

##### 服务消费者

-   获取服务: 发送Resultful给服务中心,获取服务清单
-   服务调用: 获取清单后,通过服务名和服务中心的元数据信息调用服务提供方.

##### 服务中心

-   提供注册服务: 接受各个服务的心跳,并更新服务元数据
-   **服务剔除**: 服务超过timeout(默认为90)没心跳时,就剔除相关服务数据
-   **自我保护**: EurekaServer 在运行期间,会统计心跳失败的比例在15分钟之内是否低于85%,Eureka Server会将当前的**实例注册信息保护起来**,让这些实例不会过期,尽可能**保护这些注册信息**.

![](https://pic1.zhimg.com/80/v2-22ac91d35e2f2da97c6e8fd70c359f84_1440w.jpg?source=1940ef5c)

如上图所示,服务中心可以不止有一个,服务中心们进行数据的同步(类似单独的zookeeper集群)下面我们要来研究服务注册中心这一集群.

###### 服务中心的数据同步

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231180735216-687244939.png)

如上图可以看到,其集群同步没有采用master-slave模式,而是更像采用了cluster模式去在每个Eureka Server上维护一个队列,并且进行同步.一般我们会像如下一样部署Eureka集群,即通过每个区域部署不同的Eureka Server来维护集群的高可用性.

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231181224974-1888513472.png)





#### 服务发现

服务发现分为两种

-   服务端发现服务实例
-   客户端发现服务

##### 服务端发现服务实例

服务端发现指的是提供对外服务(接口)的服务器,发现服务实例的过程,如下

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231174248145-2024756306.png)

服务端通过某一路由器进行负载均衡,并且根据路由器去发现服务实例.服务端发现客户端并且检查心跳.且如上图,服务端要维护各个注册实例的注册表

像nginx之类的前端路由不能称之为服务发现,因为前端路由只有负载均衡的功能而没有服务发现的功能

这么做有一些弊端,中途需要经过一个路由转发请求且必然会有负载均衡.且消费服务实例是不需要向服务端发送心跳的,即只需要拉取列表不需要走额外的流量,所以平均下来就会浪费掉很多的网络流量时间),且还有一个致命缺点,如果要访问不同服务实例就意味着可能要使用多种语言的接口去访问这些服务的实例,维护起来极其麻烦.



##### 客户端发现服务

客户端发现服务是更为普遍的,比如Eureka的服务发现,就是由各个服务提供实例向服务客户端发送心跳以维护自己的注册信息,各个服务向注册中心发送心跳维护各个服务的接口信息,这样一来扩展服务或是扩展服务实例变得可以动态控制.且只有服务提供者会发送心跳(消费者不会)提高了效率.

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231174630054-1606050852.png)

如上图,服务实例利用服务端提供的注册api访问服务端,并发送心跳,服务端维护这些注册信息,如果超时没收到心跳,便可以对服务实例进行下线处理.服务端可以通过维护的数据实例进行负载均衡处理.相比于服务端发现服务,这种做法去中心化(中心可由一个集群比如服务中心来保证其高可用性),且Service Client更容易做集群处理.



##### Eureka集群的服务发现

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231174818346-855663706.png)

上面在介绍治理机制的时候就了解过其服务发现,依照各节点角色我们不难发现其使用如上方式去完成节点的同步

服务提供者

-   用JerseyClient向注册中心发送请求,如果有多个中心则发送多次直至成功为止,其一般不关心服务中心同步数据的过程,只要拉取到数据即可.
-   当实例信息有变更的情况下需要发送给服务中心相应的心跳

服务消费者

-   向注册中心发送拉取服务请求,其处理方式和服务提供者基本一致
-   当服务消费者的本地存档为空的时候全量获取服务,否则定期增量获取服务,逻辑在注册中心

注册中心

-   提供接口给服务发现客户端调用
-   维护服务实例信息集合
-   集群之间信息同步

从代码层次维护的数据结构如下,其是通过维护几个队列以及一个map来表示最近变动的信息以获取增量的查询,且会更新到缓存加速查询的过程.

![](https://img2018.cnblogs.com/blog/416838/201912/416838-20191231180627653-998736861.png)



#### 高可用

从上面我们也可以看到Eureka的高可用是通过部署多个服务中心去实现的.我们这里需要关注服务中心的配置,服务中心是Eureka集群的重心.我们必须保证Eureka Server的高可用.

原理很简单,就是Eureka Server把自己当成服务注册给其他的Eureka Server,以实现服务清单的同步.

关于Eureka的设计理念就是AP,且只用于服务中心.**Eureka节点没有选举算法,即去中心化(master)**.这是因为不会出现多个客户端线程抢占服务中心数据的情况,即不存在数据竞态条件.Eureka Server需要做的只是把其他节点的数据拉取过来更新自己的节点就行.

如果节点宕机连上了别的Eureka Client,那么就覆盖同步来的数据,系统会最终达成数据一致(即最终一致性).因为不需要复杂的选举算法,Eureka的性能也要远高于zookeeper等.





### Feign

一个在微服务间通信用的客户端封装接口.如上Eureka只是建立了以服务中心为协调的服务器集群,Eureka Client本身也可以是一个集群(例如多个Eureka实例提供相同服务,我们也把其看成一个Eureka Client).在Feign之前,一般是使用`RestTemplate`进行开发.

这个时候我们会遇到一个问题,如果说要进行其他服务的访问,我们就需要访问注册中心,获取服务本身的地址,然后向其他服务发起请求,采用传统的HttpClient.

和下面的Ribbin,Hystrix一样,Feign集成了下面的两个框架,简化了开发,除此之外,其还提供**声明式服务调用**,能够极大简化代码,下面主要使用Feign进行开发.

服务绑定

```java
// value --->指定调用哪个服务
// fallbackFactory--->熔断器的降级提示
@FeignClient(value = "MICROSERVICECLOUD-DEPT", fallbackFactory = DeptClientServiceFallbackFactory.class)
public interface DeptClientService {

    // 采用Feign我们可以使用SpringMVC的注解来对服务进行绑定！
    @RequestMapping(value = "/dept/get/{id}", method = RequestMethod.GET)
    public Dept get(@PathVariable("id") long id);

    @RequestMapping(value = "/dept/list", method = RequestMethod.GET)
    public List<Dept> list();

    @RequestMapping(value = "/dept/add", method = RequestMethod.POST)
    public boolean add(Dept dept);
}
```

使用熔断器

```java
@Component // 不要忘记添加，不要忘记添加
public class DeptClientServiceFallbackFactory 
  implements FallbackFactory<DeptClientService> {
  
  @Override
  public DeptClientService create(Throwable throwable) {
    return new DeptClientService() {
      
      @Override
      public Dept get(long id) {
        return new Dept()
          .setDeptno(id).setDname("该ID：" + id + "没有没有对应的信息,Consumer客户端提供的降级信息,此刻服务Provider已经关闭")
          .setDb_source("no this database in MySQL");
      }

      @Override
      public List<Dept> list() {
        return null;
      }

      @Override
      public boolean add(Dept dept) {
        return false;
      }
    };
  }
}
```

和上面的类配合使用,即在某些服务调用失败的时候返回什么,可以说是极大简化了开发,完全符合springboot的开发思路,减少用户的感知.

另外Fegin是绑定Ribbon的,使用Fegin就能够使用Ribbon完成负载均衡.



### **Ribbon (Eureka Client端负载均衡)**

**客户端(Eureka Client)**进行负载均衡,和Eureka紧密合作,负责横向服务的轮询发送,Ribbon会选择服务的Eureka Client获取列表得到所有服务的主机地址进行轮询,其默认使用RoundRobin轮询算法.如下流程

![](https://pic1.zhimg.com/80/v2-3cebcf81da382b55f4e9e740b48c727e_1440w.jpg?source=1940ef5c)

其节点内代码构造类似下面,需要注意的是Ribbon的负载均衡发生在客户端而不是服务端.

![](https://img-blog.csdnimg.cn/20200307181201362.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTIxNzU0MQ==,size_16,color_FFFFFF,t_70)

![](https://img2018.cnblogs.com/blog/416838/202001/416838-20200110145300746-701757299.png)

如上定时获取ServerList去Eureka Client取(在Eureka中也称为服务清单),由于Eureka Client会定时向Eureka Server发送心跳,所以没必要去ping,直接使用心跳信息即可.

我们看到Ribbon是选择的Eureka Client的轮询地址,而具体服务的接口由Feign去构建,从而对具体的socket发起请求.

![](https://img2018.cnblogs.com/blog/416838/202001/416838-20200110140218808-926961767.png)

每个服务提供者(多节点)一个负载均衡器,负载均衡器之间互相独立且互不干扰,这个负载均衡器由服务消费者(Eureka Client)维护.这个和Nginx的负载均衡不一样,如果服务端(Eureka Server)进行负载均衡.





### **Hystrix 熔断器**

熔断器,提供对延迟和故障的容错能力 不稳定下线 或者直接熔断该服务直接调用失败防止过度阻塞.从其用途我们可以看出来其是提高Eureka集群的可用性的服务组件.

从系统上来看,如果调用的组件挂掉了,就不响应请求,就会造成整个服务器系统的集体超时,引发雪崩.

![](https://img-blog.csdnimg.cn/20200307181334432.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTIxNzU0MQ==,size_16,color_FFFFFF,t_70)

但其他服务还需要去执行,只要核心业务没受到影响,那么就算部分系统挂了(例如上图的积分服务)也不应该影响,库存服务仓储服务的进行.

Hystrix是隔离,熔断,服务降级的一个框架.

所谓的**熔断**,就是指积分服务挂了之后,仓储库存等其他服务正常调用,对于出现问题的服务在第一次调用失败之后不再调用以节省网络流量和线程资源.

所谓的**服务降级**,就是指积分服务挂了之后,在其他服务能正常调用,对于出现问题的服务,不直接访问服务接口(**即不及时更新服务**),而把这些请求服务的数据保存在数据库或者保存在消息队列中,等服务恢复了在访问服务记录数据(**最终一致性**).这称之为服务降级.

![](https://img-blog.csdnimg.cn/20200307181500240.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTIxNzU0MQ==,size_16,color_FFFFFF,t_70)

如上,我们可以看到Hystrix熔断器,的工作流程,在出现故障之后防止多次调用故障服务,而缓存数据等待故障恢复.

Hystrix有两个重要机制实现短路的功能

-   Fallback快速失败返回,某个服务出现故障的时候直接返回一个错误响应,而不是线程占着资源等待响应
-   资源/依赖隔离(线程池隔离),如上,每个服务都会创建个独立的线程池,而不是一个线程池处理所有任务,这样就会有部分线程能够完成工作并且返回

Hystrix有几个关键参数

-   滑动窗口大小 20
-   熔断器开关间隔 5s
-   错误率 50%

当20个请求中有50%调用错误的时候,熔断器打开,全部返回失败不再进行网络请求.5s之后在次检测,根据检测结果要不要打开熔断器.

Hystrix Dashboard可以给我们提供可视化见面去查看熔断器的实时信息,及时给系统做出调整.可以通过`/hystrix.stream`来查看页面.`/turbine.stream`是查看整个集群的.



### **Zuul 网关**

Zuul是提供动态路由,监控,弹性,安全等边缘服务框架.后端请求的门户可以拦截一些非法请求.顾名思义和Nginx类似,做为前端服务器中转各类请求.其还可以实现服务的统一降级,限流,认证授权,安全等.

在没有zuul进行负载均衡之间我们的架构可能如下,其中负载均衡用的是nginx

为什么要使用zuul/nginx(api网关),为什么不用nginx?

-   为了防止服务中心崩溃,需要负载均衡,且对外而言不需要浏览器记住服务实例
-   微服务一般是弹性分布式系统,实例数量在动态变化,需要通过注册中心交互获取实例
-   zuul对于实现鉴权的逻辑比nginx和内部服务实现互相调用要简单

![](https://pic4.zhimg.com/80/v2-774958b647a594ffc310580c26f7ef33_1440w.jpg?source=1940ef5c)

**这里需要注意的是,Eureka Server只保存服务信息,不做前端网关进行负载均衡.**因为Eureka Server承受不起大数据量的冲击,还是得选用nginx等高性能连接转发工具.

除此之外,上面的架构还会遇到两种问题

-   nginx需要维护Open Service一众ip地址,即我们为何不把负载均衡的节点换成是服务发现机制的呢?(不换成Eureka Server集群是因为负载均衡的功能该不适宜去做)
-   签名校验冗余登录的问题,服务都是独立的如果网关不完成的话,每个服务就需要根据自己的特性去写一套鉴权接口,会变得很麻烦,如果采用调用服务的方式会显得很冗余

上面的问题,**api网关zuul**就提供了解决方案.

zuul因为和Eureka的集成关系,从Eureka Server获得服务信息就解决了需要自己维护Open Service的问题,zuul有线程隔离和断路器保护功能,以及对客户端的负载均衡,zuul是支持ribbon和hystrix的.

![](https://pic2.zhimg.com/80/v2-4979061b2ecb7230d0e4e0d91bbd0e81_1440w.jpg?source=1940ef5c)

zuul还可以实现以下功能

-   路由匹配(动态路由)
-   动态过滤器
-   默认会过滤掉Cookie与敏感的HTTP头信息(额外配置)



## 搭建集群组件

### maven构筑

不同版本的maven依赖很不相同,一般借助springboot自己构筑的工具包

下面基于springboot-2.3.9-RELEASE版本的pom描述,但都大同小异,下面依赖会在各个版本用上

```xml
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```



### 高可用注册中心(Eureka Server)

三台节点为peer1:8080,peer2:8081,peer3:8082.因为注册中心的代码都一样,我们只需要在上面写三份配置文件,然后按照不同的域使用不同的配置文件即可.三份文件名叫

-   application-peer1.properties
-   application-peer2.properties
-   application-peer3.properties

启动的时候使用`--spring.profiles.active=peer3`就能指定对应的配置文件.

这里需要注意,如果三台服务器域名一致,在本机测试的话,需要去修改hosts文件的域名重定向,不然Eureka集群会找不到副本

```properties
server.port=8080

eureka.instance.hostname=peer1
# 注册的话除了单一服务中心的自己是中心之外其他的都要开启
eureka.client.register-with-eureka = true
# 获取其他服务一般都要开启,只要是需要别的服务的话,单一配置中心不用开启
eureka.client.fetch-registry = true
eureka.client.serviceUrl.defaultZone=http://peer2:8081/eureka/,http://peer3:8082/eureka/
```

```properties
server.port=8081

eureka.instance.hostname=peer2
eureka.client.register-with-eureka = true
eureka.client.fetch-registry = true
eureka.client.serviceUrl.defaultZone=http://peer1:8080/eureka/,http://peer3:8083/eureka/
```

```properties
server.port=8082

eureka.instance.hostname=peer3
eureka.client.register-with-eureka = true
eureka.client.fetch-registry = true
eureka.client.serviceUrl.defaultZone=http://peer1:8080/eureka/,http://peer2:8081/eureka/
```

除此之外还需要标注`@EnableEurekaServer`

```shell
java -jar springcloud-0.0.1-SNAPSHOT.jar --spring.profiles.active=peer1
java -jar springcloud-0.0.1-SNAPSHOT.jar --spring.profiles.active=peer2
java -jar springcloud-0.0.1-SNAPSHOT.jar --spring.profiles.active=peer3
```

如果是本机测试应当使用不同的session去启动上面三个命令



### 常规服务(Eureka Client)

常规服务就比服务中心要好配置的多,在开启了服务中心后,我们重新建立个springboot项目,和上面类似

```properties
spring.application.name=spring-cloud-consumer
eureka.client.serviceUrl.defaultZone=http://localhost:8080/eureka/
```

```java
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
public class BasicserviceinvokerApplication {
    public static void main(String[] args) {
        SpringApplication.run(BasicserviceinvokerApplication.class, args);
    }
}
```

然后如果要在里面实现自己的web服务的话就和常规web的开发流程一样,当我们开发完成单点服务的时候就会通过Eureka Server完成服务间的调用.

关于多服务实例的高可用集群,只要**服务的名字一样,那么Eureka Server就会提供负载均衡**.



### Fegin实现服务调用

从上面的配置中我们看到了要标注`@EnableFeginClients`,这是一个调用服务的封装注解,这个注解会简化开发,事实上我们把这些remote方法当成是接口然后按照下面的逻辑书写就行

```java
@Component
@FeignClient("spring-cloud-producer") // 服务名
public interface BasicInvoker {
    @GetMapping("/ping") // 对应微服务接口
    String ping();

    @GetMapping("/getNews")
    public String getNews();
}
```

```java
@RestController
public class InfoController {
    @Autowired
    BasicInvoker basicInvoker;

    @GetMapping
    public String invoke() {
        return "ping to basic server " + basicInvoker.ping();
    }

    @GetMapping("/info")
    public String getInfo(){
        return basicInvoker.getNews();
    }
}
```

这样就能够实现不同微服务系统间的调用.



### Ribbon负载均衡器

![](https://img-blog.csdn.net/20180616090520708?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2NoZW5ncWl1bWluZw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

如图可以说明其功能,我们看如何去使用.一般来讲,调用服务的方式就两种

-   RestTemplate+Ribbon
-   Fegin (更加常用)

引入依赖后,我们在配置RestTemplate上注解`@LoadBalanced`

```java
@SpringBootApplication
@EnableFeignClients
public class OrderServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }
    @Bean
    @LoadBalanced
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

然后我们在调用RestTemplate上的时候就可以直接使用负载均衡器了

```java
@Service
public class ProductOrderServiceImpl implements ProductOrderService {
	
  @Autowired
  private RestTemplate restTemplate;

  @Override
  public ProductOrder save(int userId, int productId) {
    Map<String,Object> productMap = restTemplate.getForObject("http://product-service/api/v1/product/find?id="+productId, Map.class);
    ....
      return productOrder;
  }
}
```

Fegin集成了hystrix断路器和ribbon.如果想要配置ribbon或者是hystrix直接在配置文件里面配置即可.两者都实现了负载均衡,其不同点在

-   ribbon,是一个基于 HTTP 和 TCP 客户端的负载均衡器,它可以在客户端配置ribbonServerList(服务端列表)然后默认以轮询请求以策略实现均衡负载,他是使用可以用restTemplate+Ribbon 使用.
-   feign,Spring Cloud Netflix的微服务都是以 HTTP 接口的形式暴露的,所以可以用 Apache 的 HttpClient ,而 Feign 是一个使用起来更加方便的 HTTP 客戶端,使用起来就像是调用自身工程的方法,而感觉不到是调用远程方法

`spring-cloud-producer`指的是服务的名字,我们在`@FeignClient(name)`中配置的name


```properties
#以下配置对服务hello-service-provider有效
spring-cloud-producer.ribbon.eureka.enabled=true
#建立连接超时时间，原1000
spring-cloud-producer.ribbon.ConnectTimeout=60000
#请求处理的超时时间，5分钟
spring-cloud-producer.ribbon.ReadTimeout=60000
#所有操作都重试
spring-cloud-producer.ribbon.OkToRetryOnAllOperations=true
#重试发生，更换节点数最大值
spring-cloud-producer.ribbon.MaxAutoRetriesNextServer=10
#单个节点重试最大值
spring-cloud-producer.ribbon.MaxAutoRetries=1
```

如果想要改变策略,需要更改下面的配置,一共有七种策略可供配置

```properties
ribbon.NFLoadBalancerRuleClassName=com.netflix.loadbalancer.ZoneAvoidanceRule
```

```java
@EnableEurekaClient
@SpringBootApplication
@EnableFeignClients
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    @Bean
    public IRule feignRule() {
        return new ZoneAvoidanceRule();
    }
}
```





### Fegin配置Hystrix熔断器

因为SpringCloud的集成度很高,我们只要配置其回调函数和其配置文件即可

```properties
feign.hystrix.enabled=true
```

```java
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
@EnableHystrixDashboard // 显示统计 /hystrix 去访问
public class BasicserviceinvokerApplication {
  public static void main(String[] args) {
    SpringApplication.run(BasicserviceinvokerApplication.class, args);
  }
}
```

```java
@Component
@FeignClient(name = "spring-cloud-producer", 
             fallback = InfoCallback.class) // 这里配置了另一处理类
public interface BasicInvoker {
  @GetMapping("/ping")
  String ping();


  @GetMapping("/getNews")
  public String getNews();
}
```

我们只需要编写默认的处理便可让系统保证可用性,一个服务下线也没关系,在客户端做好提示,然后等服务上线即可.

```java
@Component
public class InfoCallback implements BasicInvoker {
  @Override
  public String ping() {
    // 发送短信给程序员及时处理服务下线的问题
    return "fail to ping";
  }

  @Override
  public String getNews() {
    return "fail to get news";
  }
}
```

除此之外,我们还可以用原生的hystrix进行配置,配置后的hystrix可以被hystrix dashboard检测到.先引入hystrix依赖.在同一个类中可以用下方法调用,需要注意的是两个方法的函数签名得一致.

```java
@HystrixCommand(
  fallbackMethod = "errMethod",
  ignoreExceptions = {ParamErrorException.class,BusinessTypeException.class})
public String myMethod(String param) throw Exception{
  throw new Exception("手动抛出异常");
}
private String errMethod(String param){
  logger.info("熔断,调用sendC1Data服务发生异常");
  return "";
}
```

启动类上注解

```java
@EnableCircuitBreaker
```



### 配置Zuul

zuul的配置相当简单,其只是一个重定向的负载均衡器,我们这里配置zuul并注册到Eureka Server里面实现.

```properties
server.port=80
# 对外的网关一般默认不使用端口.
spring.application.name=spring-cloud-consumer-zuul-gateway
eureka.client.serviceUrl.defaultZone=http://localhost:8080/eureka/

# zuul路由规则配置
zuul.routes.baidu.path=/baidu/**
zuul.routes.baidu.url=https://www.baidu.com/
# 这里配置的地址能够重定向

zuul.routes.api-a.path=/producer/**
zuul.routes.api-a.serviceId=spring-cloud-producer
# 这里配置的/producer/**的地址都会被转发到spring-cloud-producer对应的实例上

# zuul.routes.api-a.path=/spring-cloud-producer/**
# zuul.routes.api-a.serviceId=spring-cloud-producer
# 默认按所有服务名配置所有服务的地址
```

zuul通过服务名,实现了多个主机的负载均衡不需要我们手动配置,直接从EurekaServer中获取相应的地址.

-   我们可以利用自定义路由规则给url进行配置,配置的内容可以是地址,可以使服务名
-   zuul默认会对服务名进行配置,我们可以访问zuul网关的地址 `/serviceName/api?key=value`这样的形式去访问服务的id

```java
@SpringBootApplication
@EnableZuulProxy
public class SpringcloudgateApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringcloudgateApplication.class, args);
    }
}
```





## SpringCloud 高级组件

### Config

配置中心,把配置放到远程服务器,集中化管理集群,支持本地git,Subversion.和zookeeper所实现的功能一样,其补充了Eureka Server对于配置文件的管理.其和`Spring Cloud Bus`一起可以实现对整个项目热部署.

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









