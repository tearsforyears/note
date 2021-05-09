# Zookeeper

---

zookeeper是著名的分布式协调组件,所谓的协调组件即是提供一致性信息的服务组件,zookeeper内在使用了Paxos算法,Paxos需要2N+1个节点构成,最多能保证N个节点出现故障.

zookeeper最主要解决的问题就是为分布式系统提供**最终一致性**服务,单纯的javaapi能在单机环境下保证线程安全,而对于分布式系统我们就需要分布式锁用来完成各种需求



## 基于其他一致性系统分布式锁的设计

---

分布式锁有几种设计方案

-   基于数据库/缓存(mysql,redis,memcache)实现
-   基于zookeeper实现
-   自己完成分布式系统的构建

这把锁的特性最好有以下几个

-   可重入锁(避免死锁)
-   该锁最好是阻塞锁

其实分布式锁的设计理念对于程序员而言很简单,就是操作某些单点(或者分布式)系统的数据结构,只要这些数据结构是线程安全的(比如mysql的表(InnoDB的行级锁),redis中的list),那么就可以争抢这些资源即分布式锁的实现.



### 基于mysql实现

我们看下mysql实现的分布式锁,有如下表

其思路是直接使用InnoDB的行级锁实现数据一致性,即数据库插入是线程安全的这一特性,以及InnoDB行级锁仅会在索引时启动.

```sql
CREATE TABLE `methodLock` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `method_name` varchar(64) NOT NULL DEFAULT '' COMMENT '锁定的方法名',
  `desc` varchar(1024) NOT NULL DEFAULT '备注信息',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '保存数据时间，自动生成',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uidx_method_name` (`method_name `) USING BTREE
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='锁定中的方法';
```

我们每次使用锁的时候就是操纵上面的数据结构,`method_name`是一个不可重复的字段,并且加上了BTREE的索引.

我们用下面方法加锁

```sql
insert into methodLock(method_name,desc) values (‘method_name’,‘desc’)
```

用下面方法释放锁

```sql
delete from methodLock where method_name ='method_name'
```

我们可以看到其借助了InnoDB的行级锁实现的分布式锁.

这种锁缺点很大

-   单点依赖性,即数据库挂了系统不可用
-   该锁无失效时间.如果解锁失败,其他线程无法获得
-   该锁非阻塞,insert失败不会进入排队队列
-   该锁非重入

其解决方案如下 [参考](https://www.hollischuang.com/archives/1716)

-   数据库是单点？搞两个数据库，数据之前双向同步。一旦挂掉快速切换到备库上。
-   没有失效时间？只要做一个定时任务，每隔一定时间把数据库中的超时数据清理一遍。
-   非阻塞的？搞一个while循环，直到insert成功再返回成功。
-   非重入的？在数据库表中加个字段，记录当前获得锁的机器的主机信息和线程信息，那么下次再获取锁的时候先查询数据库，如果当前机器的主机信息和线程信息在数据库可以查到的话，直接把锁分配给他就可以了。

我们用`for update`排它锁进行改进,下面伪代码

```java
public boolean lock(){
    connection.setAutoCommit(false)
    while(true){
        try{
            result = 
              select * from methodLock where method_name=xxx for update;
            if(result==null){
                return true;
            }
        }catch(Exception e){

        }
        sleep(1000); // 对应挂起操作
    }
    return false;
}

public void unlock(){
    connection.commit();
}
```

这里有几个点,`for update`会自动提交,当他执行成功的时候是自动返回,但执行失败其就一直阻塞,服务器宕机的时候会自动释放掉锁.

这个方法其实还是有一些弊端的,比如mysql加锁逻辑要看执行计划是否真的对索引使用行级锁(表过小也是不会触发排它锁的),另外其消耗的是数据库连接这种资源



### 基于redis实现

我们来看基于缓存实现的分布式锁,显然基于缓存实现的性能比基于数据库实现的性能要高(参考存储读取数据存放的介质)实现思路和上面类似,都是基于分布式数据库系统本身的一致性来实现的.

redis提供了一函数setnx(set not exist)来实现一致性的操作.且redis作为缓存系统能够设置过期时间,相比于mysql其能提供能够实现分布式锁的功能相对较全.

我们利用RedisTemplate来实现,其中一方法叫**setIfAbsent**对应**setnx**

```java
@Component
public class DistributedLock {
    @Autowired
    private StringRedisTemplate redisTemplate;
  
  	/**
  	* 获取锁
  	**/
    public boolean getLock(String lockId, long millisecond) {
      Boolean success = redisTemplate.opsForValue()
        .setIfAbsent(lockId,"lock",millisecond, TimeUnit.MILLISECONDS);
      return success != null && success;
    }
  	/**
  	* 释放锁
  	**/
   	public void releaseLock(String lockId) {
      redisTemplate.delete(lockId);
    }
}
```

上面还有个问题就是可重入锁的问题,这个只要换成不同的数据结构存储线程的信息可以解决.该方法唯一的弊端是不是阻塞的锁,我们可以用while循环来让其一致循环等待.

但需要注意的是redis数据系统会出现非常极端的数据不一致的情况

```note
客户端A从master获取到锁，在master将锁同步到slave之前，master宕掉了。slave节点被晋级为master节点，客户端B取得了同一个资源被客户端A已经获取到的另外一个锁。安全失效！
```

其归根结底是redis对分布式的保证是AP而不是CP,其会

redis因为其线程安全特性还能够在多线程程序中进行以下两种重要的应用

-   同理因为其数据一致性,我们可以直接把list当成阻塞队列来用
-   还可以通过对channel的publish和subscribe实现订阅和发布的消息队列的数据一致性

关于publish和subscribe和rabbitmq中的不同点是,rabbitmq有可靠的机制会保证消息会被消费而redis则是没有这种机制



## zookeeper简介

---

上面的分布式锁同样可以用zookeeper实现,更进一步说zookeeper就是专门处理分布式系统的数据一致性问题而存在的.分布式系统提供了顺序一致性,原子性,单一视图,可靠性,实时性等.

-   顺序一致性 客户端的更新顺序与他们被发送的顺序相一致
-   原子性
-   单一试图 无论客户端连接到哪一个服务器,都可以看到相同的ZooKeeper视图
-   可靠性 一旦一个更新操作被应用,那么在客户端再次更新它之前,其值将不会被改变
-   实时性 在特定的一段时间内,系统的任何变更都将被客户端检测到

![](https://zookeeper.apache.org/doc/r3.1.2/images/zkservice.jpg)

刚启动集群的时候,会从集群中选举出Leader,然后其他节点称为Follower,和Leader建立长连接进行数据同步和请求转发,当访问Follower的时候,会把请求转发到Leader,由Leader处理该请求,比如写请求在Leader写完后会同步给所有的Server.

![](https://www.hollischuang.com/wp-content/uploads/2015/12/cap.jpg)

需要注意分布式系统里面几个特性,BASE理论指的是有中间状态的最终一致性的数据系统.ACID是数据库事务的特性.CAP定理指出一个系统不可能同时完成上面三个特性.

### zookeeper和cap

Zookeeper满足的特性是CP,任何时刻对外,zookeeper都能得到同样的结果,但是zookeeper不保证系统的可用性,在极端情况下其会丢失一部分数据,zookeeper使用zab算法实现的.但是zookeeper主打的是协调服务,只管理一些配置文件的数据,状态数据(锁).或者说处于这种提供协调服务的目的,zookeeper才设计成CP的,因为可用性的要求没有那么高.**因此,当master发生宕机整个系统在后续选举中将不能提供服务**



### zookeeper的节点角色

-   leader 负责投票的发起和决议

-   learner 包括跟随者(follower)和观察者(observer)

    follower接受客户端的请求并返回数据,在选主过程中参与投票

    observer可以接受客户端连接,但不参与选主.

-   client 请求发起方

![](https://images2015.cnblogs.com/blog/183233/201603/183233-20160316222444771-1363762533.png)

![](https://images2015.cnblogs.com/blog/183233/201603/183233-20160316222520584-1877673765.jpg)

zookeeper的核心是原子广播,即Zab,Zab有两种模式,恢复模式(选主)和广播模式(同步).为了保证事务的唯一性,使用zxid来标识事务.

zxid用来标识事务,zxid小的肯定是先于大的发生,任何创建节点,删除节点都会让zookeeper状态发生改变,从而让zxid增大.zxid是一个64位的数字,高32位是epoch用来标识leader关系是否改变,低32位是个递增计数.



每个节点在工作时有三种状态

-   LOOKING: 当前Server不知道leader是谁,正在搜寻
-   LEADING: 当前Server即为选举出来的leader
-   FOLLOWING: leader已经选举出来,当前Server与之同步

![](https://images2015.cnblogs.com/blog/183233/201603/183233-20160316223234865-1124736424.png)

如上即是数据请求和同步的流程.可以看到其结构是典型的master-slave模式,该集群的每个节点都是一个原数据的副本.因为zookeeper设计出来的时候只是用于保存配置信息或者是分布式锁等.和所有的master-slave一样,这样的架构还是Leader节点写,follower节点读,遇到写请求,follower节点就把请求**转发到主节点**上.



### Zab协议

zab协议(zookeeper atomic boardcast)又叫原子广播,其实现了上图的主从架构,Leader节点写,follower节点读.原子广播有两种不同的形式

-   恢复模式 (用于选主)
-   广播模式 (用于同步数据)

广播模式

一旦leader和大多数follower状态同步之后就可以进入广播模式了,直到leader失去了绝大多数的follower之后或是leader崩溃才停止.广播模式需要保持proposer按顺序处理,即通过zxid来进行处理.zxid的产生是每次写操作之后会自增.

恢复模式

当leader崩溃或者失去大多数follower支持时,会进入此状态,该状态需要重新选举出一个leader,用来让所有server都恢复到正确的状态.

其主要分为下面几个阶段的过程

-   选举election
-   发现discovery,同步sync 
-   广播boardcast

其角色有三种

-   Leader
-   Follower
-   Observer

其节点状态如下

-   Looking: 正在选举状态
-   Leading 负责写
-   Following 不需要写,参与投票
-   Observing 不需要写,不参与投票

其各节点的服务器架构如下

![](https://images2015.cnblogs.com/blog/183233/201603/183233-20160316223234865-1124736424.png)

每次**写成功**的消息,都有一个全局唯一的标识.叫 zxid,是 64 bit 的正整数,高 32 为叫 epoch 表示选举纪元,低 32 位是自增的 id,每写一次加一.每换一次leader,epoch自增一次,每写一次id自增一次.

#### 选举

选举有多种算法

-   0 基于UDP的LeaderElection
-   1 基于UDP的FastLeaderElection
-   2 基于UDP和认证的FastLeaderElection
-   3 基于TCP的FastLeaderElection **(默认)**

且后续zookeeper以3的FastLeaderElection为主,后面介绍也以FastLeaderElection为例.选举流程如下

-   每个进入Looking状态的节点会清空投票箱,然后通过广播投票给自己,在把投票信息发给其他节点,投票信息包括: 轮数,被投票节点的zxid(轮数,写的次数),被投票节点的编号
-   每个节点和本地存储的轮数进行对比,小于就丢弃
-   如果大于就证明本地过期,更新轮数和收到的内容然后通知其他节点.
-   如果轮数相等,就比较投票的优先级,如果收到的票优先级更高就投优先级更高的,如果相等则更新对应节点的投票
-   每次收到投票后,更新结果列表,如果达到半数以上,则终止投票,宣布自己称为Leader.

选举时使用的详细数据结构

-   **logicClock**  维护投票轮数
-   **state** 当前服务器的状态
-   **self_id** 当前服务器的id
-   **self_zxid** 当前服务器上所保存的数据的最大zxid
-   **vote_id** 被推举的服务器的id
-   **vote_zxid** 被推举的服务器上所保存的数据的最大zxid

每个服务器投票结果会发送到所投服务器的投票箱里,每一票的有效性会基于(self_id, self_zxid)与(vote_id, vote_zxid)的对比,但如上所言,先进行的是logicClock的比较

-   先对比两者的vote_zxid,则更新voie_id和vote_zxid
-   若两者一致,则把自己票中vote_id最大的一个更新,然后广播



#### 主从同步

和所有的master-slave结构一样,master主要负责写,其他slave节点负责读.slave节点如果收到写请求会转发到master节点进行写.

master的处理过程如下

-   Leader收到写操作时,生成zxid然后发给所有follower节点.
-   follower会把提议的事务写到本地磁盘,成功后返回Leader,Leader收到半数以上反馈在对所有Follower确认,让所有的Follower进行提交,Follower收到事务后进行提交,整个过程就就完成了.

### 选主过程

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9tbWJpei5xcGljLmNuL21tYml6X3BuZy85VFBuNjZIVDkzMm9pY0tSNGdzaWNrcEZwMEN6dHpFVEtVZUlCWVpyaWFlM3hkZmQydEg3M1VoN0tSZXVNcVRIc3dGakxsNlR5QmZnZTZROURTRGhheExvZy82NDA?x-oss-process=image/format,png)

三台zookeeper节点如上.

2台ZooKeeper进行投票选举的时候，第一次都是推荐自己为Leader，投票包含的信息是：服务器本身的myid和ZXID。比如第一台投自己的话，它会发送给第二台机器的投票是(0,0)，第一个0代表的是机器的myid，第二个0代表是的ZXID.故两台机器收到的投票情况如下

-   第一台(1,0)
-   第二台(0,0)

两台服务器在接收到投票后，将别人的票和自己的投票进行PK。PK的是规则是：

-   优先对比ZXID,ZXID大的优先作为Leader(ZXID大的表示数据多)
-   如果ZXID一样的话,那么就比较myid,让myid大的作为Leader服务器。



### 实例

我们来举几个例子

#### 集群启动

![](http://www.jasongj.com/img/zookeeper/1_architecture/start_election_1.png)

![](http://www.jasongj.com/img/zookeeper/1_architecture/start_election_2.png)

![](http://www.jasongj.com/img/zookeeper/1_architecture/start_election_3.png)

可以看到在(3,3)进行广播自己的投票之后,有半数节点同意该票,即更新为两个节点Follow节点3

#### follower重启

![](http://www.jasongj.com/img/zookeeper/1_architecture/follower_restart_election_1.png)

如上Server2告诉Server1,3是master,3告诉1自己是master,所以1就会认定是3是master.这个其实是和上面Looking状态的选主一样的.1在把票投给自己之后,2把票投给了3,3也给1发送了选票状态,节点1由Looking状态变成Following状态.

#### Leader重启

![](http://www.jasongj.com/img/zookeeper/1_architecture/leader_restart_election_1.png)

![](http://www.jasongj.com/img/zookeeper/1_architecture/leader_restart_election_2.png)

如上server1状态zxid更加大(表明其是同步了最多server3的写)所以server2的状态同步到zxid=11,根据上面选举算法,服务器2会把选票投给服务器1,因此服务器1称为了新的节点.

![](http://www.jasongj.com/img/zookeeper/1_architecture/leader_restart_election_3.png)

等到server3上线了就变成Follower了

![](http://www.jasongj.com/img/zookeeper/1_architecture/leader_restart_election_4.png)

![](http://www.jasongj.com/img/zookeeper/1_architecture/leader_restart_election_5.png)

zab协议保证了在Leader选举的过程中,已经被commit的数据不会发生丢失



## 安装部署

去官网下载stable版本然后解压,不要用homebrew之类的工具,要下载stable版本,因为zookeeper是用java写的,所以还要jdk.

zookeeper有三种安装方式

-   单机模式
-   集群模式
-   伪集群模式

### 单机模式

在conf目录下配置zoo.cfg

```cfg
tickTime=2000
dataDir=/usr/local/zookeeper/data
dataLogDir=/usr/local/zookeeper/log
clientPort=2181
```

启动命令和关闭命令如下脚本

```shell
sh bin/zkServer.sh start
sh bin/zkServer.sh stop
```

可以通过往端口写数据来看其有没有成功启动

```shell
echo ruok | nc localhost 2181
```

### 集群模式/伪集群模式

在不同的机子上解压zookeeper,在每台机子上的data目录下创建myid文件内容是数字,代表每台机子的编号.(同一机子的伪集群在本机上创3个zookeeper的运行目录即可)

然后配置文件这么写

```conf
tickTime=2000
dataDir=/usr/local/zookeeper/server1/data
dataLogDir=/usr/local/zookeeper/server1/log            
clientPort=2181                      
initLimit=5                         
syncLimit=2                                 
server.1=server1:2888:3888                      
server.2=server2:2888:3888                      
server.3=server3:2888:3888 
# 等于号前面的3表示myid里面的内容,后面两个port第一个用于连接leader,第二个用于选举
```



### 数据模型Znode

![](https://zookeeper.apache.org/doc/r3.4.14/images/zknamespace.jpg)

zookeeper中数据是以类似linux目录形式进行存储的.每个存储的数据叫Znode,每个Znode都有唯一的路径标识,每个节点中可以存储信息,每个节点**可以配置Watcher(监视器)**用于监听节点中数据的变化,节点不支持部分读写.

#### 节点类型

Znode有四种类型

-   PERSISTENT 持久节点
-   PERSISTENT_SEQUENTIAL 连续持久节点
-   EPHEMERAL 临时节点
-   EPHEMERAL_SEQUENTIAL 连续临时节点

Znode在创建时就确定类型,并且之后不能修改.我们一般使用提供的zkClient.sh或者是Java api去操控.

其中临时节点不能有子节点,且临时节点会在会话结束时回收,也就是其生命周期是会话.



临时顺序节点

临时顺序节点和临时节点的生命周期一致,不同的是他会在节点后面自动带上编号.

**持久顺序节点**

该节点和临时顺序节点除了生命周期不一样之外,zookeeper的每个父节点会为其一级子节点维护一份时序.因此可以按照顺序产生连续编号的节点.其数字的范围和int的存储大小一致.

我们后续看到的分布式锁的设计要依赖于持久顺序节点的特性.



### ACL列表

每个节点都会带一个ACL列表用于决定每个节点的访问权限.



### 节点信息

根据Zab原子广播

```note
zxid用来标识事务,zxid小的肯定是先于大的发生,任何创建节点,删除节点都会让zookeeper状态发生改变,从而让zxid增大.zxid是一个64位的数字,高32位是epoch用来标识leader关系是否改变,低32位是个递增计数.
```

在每个节点有如下的信息

-   czxid. 节点创建时的zxid.
-   mzxid. 节点最新一次更新发生时的zxid.
-   ctime. 节点创建时的时间戳.
-   mtime. 节点最新一次更新发生时的时间戳.
-   dataVersion. 节点数据的更新次数.
-   cversion. 其子节点的更新次数.
-   aclVersion. 节点ACL(授权信息)的更新次数.
-   ephemeralOwner. 如果该节点为ephemeral节点, ephemeralOwner值表示与该节点绑定的session id. 如果该节点不是ephemeral节点, ephemeralOwner值为0. 至于什么是ephemeral节点, 请看后面的讲述.
-   dataLength. 节点数据的字节数.
-   numChildren. 子节点个数.

在ZookeeperClient中可以查看到上面的节点信息用于算法或者监测



### Watcher

watcher是zookeeper一个核心功能,其本质是个listener,可以监控某一目录节点的变化或是其子目录的变化.一旦发生变化,会通知所有在该路径下设置watcher的客户端

-   可以设置观察的操作 exists,getChildren,getData 
-   可以触发观察的操作 create,delete,setData

我们先来看其应用场景,用到的就是订阅发布模式

-   统一配置文件修改,集群所有节点生效
-   集群节点宕机通知其他节点

watcher的通知机制如下,我们先要去zookeeper集群注册一个watcher建立tcp长连接,接收订阅.

![](https://img-blog.csdn.net/20180915152334373?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3prcF9qYXZh/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

关于其具体操作在下面介绍,主要使用Javaapi来进行操作.在这里介绍下Zookeeper的Watcher机制.主要是以下过程,其客户端的源码有Java实现,可以直接看到其处理过程

-   客户端注册 Watcher
-   服务器处理 Watcher 
-   客户端回调 Watcher客户端

![](https://img2018.cnblogs.com/blog/1383365/201908/1383365-20190820101928955-908505489.png)





## api

### zkClient

用zkClient的操作方式需要先进入命令行,该程序在/bin下

```shell
# create [-e] [-s] path data

create -e /tmp temp # 创建临时节点
create /per per # 创建持久节点
create -s /seq seq # 创建(持久)连续节点
```

查看根路径下的节点,可以看到我们之前创建的几个节点

```shell
ls /
```

查看节点信息

```shell
get /tmp
get / # 因为不是个节点,所以返回空
```

修改节点信息

```shell
set /tmp tmp # 就能把节点的temp改成tmp
```

我们查看其详细信息

```shell
[zk: localhost:2181(CONNECTED) 19] get -s /tmp
tmp
cZxid = 0x4
ctime = Mon Feb 22 15:26:19 CST 2021
mZxid = 0x7
mtime = Mon Feb 22 15:31:15 CST 2021
pZxid = 0x4
cversion = 0
dataVersion = 1 # 看到这里说明版本已经自增,zxid也会发生相应的改变
aclVersion = 0
ephemeralOwner = 0x1001561f5310001
dataLength = 3
numChildren = 0
```

删除节点

```shell
delete /tmp 
```

但其实我们不用删除在会话结束时该临时节点也会被删除,因为其是临时节点,另外如果该节点下还有子节点是不能够删除的.必须先把子节点全删光才能产出其父节点.

### Javaapi

我们再来看javaapi如何操作其

```xml
<dependency>
    <groupId>org.apache.zookeeper</groupId>
    <artifactId>zookeeper</artifactId>
    <version>3.4.8</version>
</dependency>
```

```java
DataWatcher watcher = new DataWatcher();
ZooKeeper zoo = new ZooKeeper(url, 100000, watcher); // 默认的watcher

@Test
public void test() throws Exception{
  try {
    
    // 获取所有子节点的名字
    List<String> ls = zoo.getChildren("/", true);
    
    // 创建节点
    zoo.create("/test", "test".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
    
    // 设置监听事件
    zoo.exists("/test", new DataWatcher("/test")); 

    // 获取节点的值
		System.out.println(new String(zoo.getData("/test", false, null)));
    
    // 更新节点值
    zoo.setData("/test","modify test".getBytes(),-1);
    // 这里第三个参数-1是无所谓,其他表示只有version对上的时候才更新
    
    // 删除节点
    zoo.delete("/test",-1);
    
    Thread.sleep(1000000);
  } finally {
    zoo.close();
  }
}

/**
	zookeeper实现cas操作
	
	以zookeeper的数据一致性实现的CAS乐观锁.中间可以嵌入真正计算部分的代码,然后把计算的结果传入给setData,如果版本号不对就会报错一直等下次可修改
	如下我们就可实现一个标准CAS的原子性操作,想要实现基于CAS的锁还得需要AQS队列,对此在另一节中说明
*/
@Test
public void cas() throws Exception {
  while (true) {
    try {
      Stat s = zoo.setData("/test", zoo.getData("/test", false, null), -1);
      int ver = s.getVersion();

      // compute
      System.out.println("compute");
      
      // 根据版本更新节点值
      zoo.setData("/test", "modify test".getBytes(), ver);
      break;
    } catch (KeeperException.BadVersionException e) {
    }
  }
  zoo.close();
}
```



## 应用

zookeeper的最佳应用场景就是协调了,对此hadoop等都是用了zookeeper作为其组件去使用,zookeeper的主要应用有几个

-   集中同步配置文件(配置中心)
-   分布式锁
-   分布式队列
-   分布式通知/协调
-   负载均衡

### 基于zookeeper实现分布式锁

我们可以基于zookeeper的临时有序节点实现分布式锁.其实现思想为

每个客户端对某个方法加锁时,在zookeeper上的与该方法对应的指定节点的目录下,生成一个唯一的瞬时有序节点.判断是否获取锁的方式很简单,只需要判断有序节点中序号最小的一个.当释放锁的时候,只需将这个瞬时节点删除即可.同时,其可以避免服务宕机导致的锁无法释放,而产生的死锁问题.

-   关于释放锁,对于使用锁的线程,如果挂掉,那么session断掉zookeeper就会回收临时节点
-   关于阻塞锁,因为有watcher的存在,zk绑上节点之后可以监听该节点是不是最小的.一旦是最小的,那么变可以获取锁
-   可重入和不可重入锁,把当前客户端的主机信息和线程信息直接写入到节点中,下次想要获取锁的时候和当前最小的节点中的数据比对一下就可以了.如果一样,那么自己直接获取锁,如果不一样就再创建一个临时的顺序节点,参与排队
-   单点问题,zookeeper集群基于AP和Zab的设计最多容忍N个节点出错,在现实环境中这种概率微乎其微

zookeeper锁的性能其实并不高,因为分发到各个节点上且只能在Leader节点上操作导致.我们平时使用的时候使用的是zookeeper第三方库[Curator](https://curator.apache.org/)客户端，这个客户端中封装了一个可重入的锁服务.

![](https://img-blog.csdn.net/201808261653399?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180826165357971?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180826165415677?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180826165440394?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180826165455142?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180826165509543?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmdtaW5fMTIz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

下面我们来用zookeeper实现分布式锁

```java
class ZooLock {
  Watcher watcher;
  ZooKeeper zoo;
  String path = "/lock";

  ZooLock() throws IOException {
    watcher = new zktest.DataWatcher();
    String url = "127.0.0.1:2181";
    zoo = new ZooKeeper(url, 3000, watcher);
    name = "/normal";
  }

  ZooLock(Watcher watcher, ZooKeeper zoo, String name) {
    this.watcher = watcher;
    this.zoo = zoo;
    this.name = name;
  }

  private ThreadLocal<String> nodeId = new ThreadLocal<>();
  private String name;

  public void lock() {
    lock(name);
  }

  static class DeleteWatcher implements Watcher {
    private CountDownLatch latch = null;

    public DeleteWatcher(CountDownLatch latch) {
      this.latch = latch;
    }

    @Override
    public void process(WatchedEvent event) {
      if (event.getType() == Event.EventType.NodeDeleted) {
        latch.countDown();
      }
    }
  }

  private void lock(String lock) {
    try {
      String curNode = zoo.create(path + lock, "".getBytes(), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
      List<String> subNodes = zoo.getChildren(path, false);

      TreeSet<String> sortedNodes = new TreeSet<>();
      for (String node : subNodes) {
        sortedNodes.add(path + "/" + node);
      }
      String minNode = sortedNodes.first();
      String preNode = sortedNodes.lower(curNode);

      this.nodeId.set(curNode); // 这句之前是有bug的,无论获得锁与否都得注册
      // 如果获得了锁就执行下面代码
      // 如果没有获得锁就等着,由CountDownLatch内部的AQS阻塞
      // 然后把前置节点注册上,
      if (minNode != null && minNode.equals(curNode)) {
        // 获得锁
        return;
      }

      // 没有获得锁的情况下,阻塞
      CountDownLatch latch = new CountDownLatch(1);
      Stat stat = zoo.exists(preNode, new DeleteWatcher(latch));

      if (stat != null) { // 如果前置节点不存在就直接走,销毁latch
        latch.await();// 等待，这里应该一直等待其他线程释放
        latch = null;
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void unlock() {
    try {
      if (null != nodeId) {
        zoo.delete(nodeId.get(), -1);
        nodeId.remove();
      }

    } catch (Exception e) {
      throw new RuntimeException("解锁失败");
    }
  }
}
```

其实通过上面的程序,我们也可以知道分布式的消息队列是如何去做的,入队操作即添加顺序节点,出队操作即删除最小的节点,

