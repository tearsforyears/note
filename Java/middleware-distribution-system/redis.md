# Redis

---

nosql的一种 内存数据库 高效键值对的存储 优秀的持久化机制 构建分布式系统的组件

相比于大多数基于磁盘IO的数据库 redis显然速度要远高于mysql 适合存储需要高性能的数据

nosql满足下列分布式定理 并基于此定理构建系统

默认端口6379



## CAP定理

---

在计算机科学中, CAP定理(CAP theorem), 又被称作 布鲁尔定理(Brewer's theorem), 它指出对于一个分布式计算系统来说,不可能同时满足以下三点:

-   **一致性(Consistency)** (所有节点在同一时间具有相同的数据)
-   **可用性(Availability)** (保证每个请求不管成功或者失败都有响应)
-   **分隔容忍(Partition tolerance)** (系统中任意信息的丢失或失败不会影响系统的继续运作)

## redis支持的数据结构

---

-   string // 可存储任何序列化的结构 比如图片等
-   hash // dict/map
-   list
-   set
-   zset  // 有序集合

## redis-cli

```shell
keys * # 查看所有key

# stirng
set hello world
get hello
del hello

# hash
hmset dict key1 value1 key2 value2
hkeys dict
hvals dict
del dict

# list
lpush key
lrange key 0 10 #列表0到10

# set
sadd set value
smembers
scard # 获取成员数
```

进阶的一些命令

```shell
# list充当延时队列,获取左边或者右边的元素
blpop key1 timeout
brpop key1 timeout 
# 修剪list,保留指定区间的元素
ltrim key 0 -1

# set命令,集合key1中有,key2,key3没有的元素
sdiff key1 key2 key3

sinter key1 key2 # 求交集
spop key1 # 随机移除一个元素
srandmember key [count] # 随机取得count个成员
sunion # 求并集

# zset的一些命令
zcount key min max # 计算分数在min到max之间的成员数,可以用来限流判断
zrange key start end [WITHSCORES] # 计算从位置start到end的成员,可以显示他们的分数.这个命令可以用于做排行榜
zrangebyscore key min max [WITHSCORES] [LIMIT]
# 这个命令用来查看分数范围 limit的写法可以是下面
ZRANGEBYSCORE salary (5000 400000 WITHSCORES
ZRANGEBYSCORE salary -inf +inf

```

更多关于zset的命令可以[参考](https://www.runoob.com/redis/redis-sorted-sets.html)来获取帮助.



## redis.conf

```conf
# ./redis-server /path/to/redis.conf
# bind 127.0.0.1

protected-mode yes # 限制bending访问
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

daemonize no # 不在这里开启守护线程

supervised no

pidfile /var/run/redis_6379.pid

loglevel notice
logfile ""

databases 16
always-show-logo yes


#   save <seconds> <changes>
save 900 1 # 900秒内改变1次就存
save 300 10 # 300秒内改变10次就存
save 60 10000 # 60秒内改变10000次就存


stop-writes-on-bgsave-error yes
# 压缩RBD文件
rdbcompression yes

# Since version 5 of RDB a CRC64 checksum is placed at the end of the file.
rdbchecksum yes

# The filename where to dump the DB
dbfilename dump.rdb
rdb-del-sync-files no
# 工作目录,RDB文件在这
dir ./


replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-diskless-load disabled
repl-disable-tcp-nodelay no
replica-priority 100

acllog-max-len 128

lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no

# AOF
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes


lua-time-limit 5000

slowlog-log-slower-than 10000
slowlog-max-len 128

latency-monitor-threshold 0
notify-keyspace-events ""

hash-max-ziplist-entries 512
hash-max-ziplist-value 64

list-max-ziplist-size -2
list-compress-depth 0

set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

hll-sparse-max-bytes 3000

stream-node-max-bytes 4096
stream-node-max-entries 100

activerehashing yes

client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
```



## 使用场景

---

缓存Session 缓存小的数据(几百兆的就算了 内存压力大)

以下是类似**cache**的读机制 这个缓冲的主要是热点数据提高数据访问效率

![redis 的使用场景](https://upload-images.jianshu.io/upload_images/7896890-404e89059b6a96b5.png)

其次是处理高并发请求 也是缓冲请求数据本身 充当**缓冲队列**

也就是说对于临时高峰值业务(抢票 秒杀系统等) 我们直接存取redis集群 等待redis空闲时进行持久化



## 缓存更新

缓存更新策略.一般会有如下几种

- Cache aside
- Read/write Through
- Write behind

Cache Aside 

- 这种模式是我们平时使用的模式,如果缓存中没有数据则从缓存中加载数据,没命中则从数据库读数据
- 更新数据时先去更新数据库的数据,更新完成后通过指令让缓存Cache中数据失效,这是一种简单的模式

Read/Write Through

- 这种模式把缓存当成主要用途,数据库的服务只是供给同步,基本所有的请求都到缓存中去访问,数据库只充当持久化工具
- 新增缓存节点的时候会有问题,强依赖缓存的一种模式

Write Behind

- 和上面的区别仅在于同步导数据库的时候使用异步去更新数据到数据库,但数据库会导致一致性比较差

版本号控制

- todo



## redis持久化方式

redis有两种持久化的方式 rdb和aof (redis database和append only file)

rbd 是快照的方式持久化 可以手动触发 阻塞redis线程 可以创建子线程持久化(BGSAVE)

aof 是保存操作命令的  aof回复比较慢 适合保存增量数据

一般我们使用RDB/AOF混合方式做的持久化

redis默认开启rbd 要开启aof要在配置文件中写 appendonly yes

### RDB

以下两个指令可以完成RDB持久化

-   `SAVE` 阻塞完成请求,这段时间服务器不能处理 `SAVE 60 10000`如果60秒内执行了10000次那么RDB持久化,如果有多条指令那么满足其中一个就会执行持久化,在redis.conf里面可以设置
-   `BGSAVE` fork出一个子进程完成请求,执行的时候`SAVE`会被拒绝,`BGREWRITEAOF`指令会延后到`BGSAVE`之后执行,因为`BGSAVE`和`BGREWRITEAOF`都在同一子进程执行

而RDB的载入方式是自动的只要有RDB文件就会载入redis,AOF因为更新成本比较低,所以同时开启的时候,优先会载入AOF来还原数据库状态。

除此之外,服务器还维护着dirty计数器和lastsave属性.dirty记录了上一次SAVE之后进行了多少次修改(判定条件),lastsave是一个时间戳,记录着上一次SAVE的时间,用这两个数据结构去实现SAVE命令,多个save是利用链表结构去串成的,所以不宜写太多同样的SAVE

### AOF

aof持久化打开时,每当执行命令的时候,会以协议格式追加到服务器的aof_buf缓冲区.aof的文件写入分两部分

-   WRITE 根据条件,aof_buf中的缓存写入到AOF文件
-   SAVE 根据条件,调用 fsync 或 fdatasync 函数,将 AOF 文件保存到磁盘中

AOF有三种模式

-   AOF_FSYNC_NO 不保存

    执行WRITE不执行SAVE,SAVE部分只有在redis关闭,写缓存刷新,AOF功能被关闭的时候才执行SAVE

-   AOF_FSYNC_EVERYSEC 每秒存一次

    这个SAVE是子进程执行的,所以不会引起主线程的阻塞,根据在执行的状态有以下的情况

    ![](https://upload-images.jianshu.io/upload_images/11772383-e2517a5a90bfd170.png)

    实际上其的停机状况可能会引起来超过两秒的数据丢失

-   AOF_FSYNC_ALWAYS 每执行一个命令保存一次

    这个SAVE是主进程执行的,并非子进程执行,所以服务器会阻塞一段时间

AOF重写

​	如果不加以控制,AOF文件的大小将会变得无法控制。所以对一些命令进行了重写,AOF的重写程序放到子进程中执行,如果在重写的时候有新的命令进来会遗漏,所以设置AOF缓冲区.我们可以用`BGREWRITEAOF`来进行AOF重写.这期间父进程主要完成的工作如下

1.将AOF重写缓冲区中的所有内容写入新的AOF文件中,这时新AOF文件锁保存的数据库状态和服务器当前状态一致

2.对新的AOF文件进行改名,原子性操作地覆盖现有的AOF文件,完成新旧AOF文件的替换。



## redis的线程模型

redis是队列循环加单线程模型,其利主要利用了IO复用(请求注册,注册操作).

而在6.0(2019年)之后其采用了多线程的模型,我们来深究下

![](https://pic1.zhimg.com/80/v2-5cc79aa66caca62b3390d717270760c1_720w.jpg)

![](https://pic3.zhimg.com/80/v2-3197beffebd110fd15e38c40747a3983_720w.jpg)

我们可以看到单线程的优缺点

-   不会存在锁的问题
-   不需要cpu切换
-   因为操作是串行的一个操作阻塞会引发后续操作阻塞

后续换成了多线程模型,可以看到在处理请求并发的时候,依然是使用了epoll的I/O多路复用去选择了事件进行处理.我们依然可以看到写事件之间是串行的,但是对于读时间采用了队列和并发线程的方式去处理,等待写事件串行执行结束之后才会去放到队列里面等待来轮询.

redis以并发的方式(主线程+I/O线程)同时读取和解析多个请求,串行的方式(主线程)处理多个请求(减少并发带来的复杂度),最后是以并发的方式(主线程+I/O线程)同时返回多个响应,达到了单位时间内处理更多请求的目的,提高了吞吐量.

**所以从上面的结构来看,处理命令依然是单线程,只是网络数据的读由epoll(多线程),写由多线程来完成,其中间处理过程依然是单线程**



## Redis的过期策略

redis内存用完之后,写命令会返回错误,而读命令会继续,但实际上是由于多种过期策略的存在,redis实际上不太可能出现上面的情况.

redis里面如果有大量的key,我们看下其过期策略.其实际上使用了下面两种方式结合的删除策略.

### lazy删除

在访问某一key的时候才对其过期时间进行检查,如果过期了就删除.这种策略的弊病就是如果不进行检查的话,该key会一直留在内存中十分占有内存空间.

### 定期删除

redis会把所有设置了过期时间的key放到一个字典中,每隔10秒进行定期扫描.并且删除过期的key.其具体策略如下

1.  从过期字典中随机20个key
2.  删除这20个key中已过期的
3.  如果超过25%的key过期,则重复第一步

为了保证循环不会持续太长时间,循环的默认上限是25ms.

### 过期与命令

查看过期时间TTL

```shell
ttl key
```

设置过期时间(更新过期时间)

```java
expire key time
```

例如删除一个key,可以把其过期时间设置为-1

```shell
expire key -1
```

```java
redisTemplate.opsForValue().getOperations().getExpire(key);
```

-   清除过期时间 DEL/SET/GET/SET
-   不会清除过期时间 INCR/LPUSH/HSET



## redis内存淘汰策略

当key超过了使用最大的内存时就会触发内存淘汰机制,首先可以如下设置,对于32位系统来说只能使用3GB内存

```conf
maxmemory 100mb
```

redis淘汰策略大致如下

-   noeviction: 不删除策略, 达到最大内存限制时, 如果需要更多内存, 直接返回错误信息.大多数写命令都会导致占用更多的内存(有极少数会例外,如 DEL).
-   allkeys-lru: 所有key通用; 优先删除最近最少使用(less recently used ,LRU) 的 key。
-   volatile-lru: 只限于设置了expire 的部分; 优先删除最近最少使用(less recently used,LRU) 的 key.
-   allkeys-random: 所有key通用;随机删除一部分 key。
-   volatile-random: 只限于设置了expire的部分; 随机删除一部分 key。
-   volatile-ttl: 只限于设置了expire 的部分;优先删除剩余时间(time to live,TTL)短的key。

可以看到**volatile**针对于大部分设置了expire的key.如果没有设置expire那么这几这行为一致.





## redis缓存击穿和缓存雪崩

-   缓存穿透,数据库和缓存中没有数据
-   缓存击穿,数据库有数据缓存没有数据

缓存穿透是指访问不存在的数据,从缓存中取不到,从数据库中也没有取到,如果重复访问就会对数据库烤成很大的压力,解决方案就是设计短时间的key-null的结构.设计校验接口.(即通过访问不存在的缓存直接访问数据库了)

缓存击穿,缓存中没有但数据库中有的数据(缓存时间到期),同一时间并发数太高就会直接落到数据库,导致数据库崩溃,如下设计.即每隔一段时间刷新数据或设置数据永不过期.(访问存在的缓存失效了就直接访问数据)

![](https://img-blog.csdn.net/20180919143214879?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2tvbmd0aWFvNQ==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

缓存雪崩,即缓存在同一时间大范围失效,通常是缓存时间一致导致的,解决方案就是设置不同的缓存时间.和限流熔断机制.



## 和memcached的对比

-   线程模型是单线程
-   在数据类型上支持更多
-   比memcached可用性更高
-   Memcached采用LRU算法 而redis利用vm去管理虚拟内存
-   memcached的集群不如redis



## 如何在项目中使用写在springboot

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

```properties
# Redis数据库索引(默认为0)
spring.redis.database=0  
# Redis服务器地址
spring.redis.host=localhost
# Redis服务器连接端口
spring.redis.port=6379  
# Redis服务器连接密码(默认为空)
spring.redis.password=
# 连接池最大连接数(使用负值表示没有限制) 默认 8
spring.redis.lettuce.pool.max-active=8
# 连接池最大阻塞等待时间(使用负值表示没有限制) 默认 -1
spring.redis.lettuce.pool.max-wait=-1
# 连接池中的最大空闲连接 默认 8
spring.redis.lettuce.pool.max-idle=8
# 连接池中的最小空闲连接 默认 0
spring.redis.lettuce.pool.min-idle=0
```

具体api的使用

```java
@Autowired
private StringRedisTemplate stringRedisTemplate; 
// 只是操作string类型时候用 本质是序列化的工具不同
@Autowired
private RedisTemplate redisTemplate;

// 以下方法提供操作redis的对象
StringRedisTemplate.opsForValue().* // 操作String字符串类型
StringRedisTemplate.delete(key/collection) // 根据key/keys删除
StringRedisTemplate.opsForList().*  // 操作List类型
StringRedisTemplate.opsForHash().*  // 操作Hash类型
StringRedisTemplate.opsForSet().*  // 操作set类型
StringRedisTemplate.opsForZSet().*  // 操作有序set

// string
stringRedisTemplate.opsForValue().set("aaa", "111");
System.out.println(stringRedisTemplate.opsForValue().get("aaa"));
System.out.println(stringRedisTemplate.opsForValue().size("aaa"));
stringRedisTemplate.opsForValue().append("aaa"," 222");

// list
redisTemplate.opsForList().leftPush()
redisTemplate.opsForList().rightPush()
redisTemplate.opsForList().rightPop()
redisTemplate.opsForList().leftPop()
List<String> ls =  redisTemplate.opsForList().range("list",0,redisTemplate.opsForList().size("list")-1); // 读取的结果就是List

// hash
Map<String,String> dict = new HashMap<String, String> ();
dict.put("hello","world");
dict.put("redis","json");
stringRedisTemplate.opsForHash().putAll("testMap",dict);       System.out.println(stringRedisTemplate.opsForHash().entries("testMap"));

// set
redisTemplate.opsForSet().add("testSet", "1", "2", "3");
redisTemplate.opsForSet().members("testSet").forEach((item) -> {
  System.out.println(item);
});

// object
// 本质就是操作序列化字符串
// 当然可以存json都是没问题的 Fastjson为例
User user = new User(11L, "redis", "redisPass");
ValueOperations<String, User> operations = redisTemplate.opsForValue();
String user_str = JSON.toJSONString(user);
redisTemplate.opsForValue().set("user_json", user_str);
String json_user = (String) redisTemplate.opsForValue().get("user_json");
System.out.println(JSON.parseObject(json_user, User.class));

// 利用配置好的序列化解析器我们也可以像这样子dump
// 下面这种官方推荐
User user = new User("ready", "perfect");
ValueOperations<String, User> operations = redisTemplate.opsForValue();
operations.set("user", user);
System.out.println(operations.get("user"));
```



## redis集群

集群的三种模式

### 主从模式**master-slave(non-HA)**

![](https://img2018.cnblogs.com/blog/1350922/201910/1350922-20191006113347736-1579349638.png)

一个master多个slave slave读 master写

master挂了之后没有选举机制 也就没有写的功能

master修改之后会把命令同步到slave,维护backlog记录操作

参考另一文档对主从模式的描述,其同步过程如下

![](https://img2018.cnblogs.com/blog/1350922/201910/1350922-20191006113541904-1736285180.png)

可以看到是同步快照,写缓冲,然后才是同步增量的.



 配置上面的模式很简单,可以通过命令行启动时传入参数

```shell
redis-server --port 6380 --slaveof 127.0.0.1 6379
```

或者是配置redis.conf中传入参数

```conf
slaveof 127.0.0.1 6379
```



### **Sentinel(哨兵模式) 使用Raft算法**

既然主从模式可能会挂掉主节点,需要人手工去干预,那么为什么不把这个任务交给线程去做呢?于是就有了哨兵模式,同样的哨兵也会出现故障,那么就用多个哨兵就能解决问题了.

![](https://img2018.cnblogs.com/blog/1350922/201910/1350922-20191006122611921-809764078.png)

-   哨兵监测到master宕机,会自动把slave切换成master,通过发布订阅模式通知其他服务器
-   哨兵监控master和slave的状态,通过发送命令监测各个节点状态
-   哨兵节点监控其他哨兵节点

master每隔10s发送一次heartbeat slave每隔1s发送一次heartbeat

通过下面分布式选举可以确定新的master并更新到sentinel



故障切换过程

-   假设主服务器宕机,哨兵1先检测到这个结果,系统并不会马上进行 failover 过程,仅仅是哨兵1主观的认为主服务器不可用,这个现象成为**主观下线**.
-   当后面的哨兵也检测到主服务器不可用,并且数量达到一定值时,那么哨兵之间就会进行一次投票,投票的结果由一个哨兵发起,进行 failover 操作.切换成功后,就会通过发布订阅模式(修改配置文件),让各个哨兵把自己监控的从服务器实现切换主机,这个过程称为**客观下线**.



该模式的配置需要配置访问密码

-   主服务器为`192.168.11.128:6379`

master的配置是

```conf
# 使得Redis服务器可以跨网络访问
bind 0.0.0.0

# 设置密码
requirepass "123456"
```

slave的配置是

```conf
# 指定主服务器
slaveof 192.168.11.128 6379
# 主服务器密码
masterauth 123456
```

哨兵配置

```conf
# 禁止保护模式,标志了该属性之后,redis该节点不会被外网访问到
protected-mode no

# 配置监听的主服务器,这里sentinel monitor代表监控,mymaster代表服务器的名称,可以自定义,192.168.11.128代表监控的主服务器,6379代表端口,2代表只有两个或两个以上的哨兵认为主服务器不可用的时候,才会进行failover操作。
sentinel monitor mymaster 192.168.11.128 6379 2

# sentinel auth-pass <master-name> <password>
sentinel auth-pass mymaster 123456
```

启动时,先把主服务器启动,再把从服务器启动,在把哨兵服务器启动,哨兵模式的优点继承了主从模式的有点,并且提高了系统的可用性.缺点则是扩容复杂.



### **Cluster模式**

哨兵模式解决了集群高可用的问题,但并没有解决集群扩容问题. cluster支持动态扩容,并发很高的时候处理多个key的创建可能会发生不可预测的问题.

redis在上面的主从模式和哨兵模式基本已经实现了高可用的分布式数据系统,但上述系统有一缺点就是slave存储了太多的冗余数据,我们希望有一个系统是保存少量副本和更多的数据.redis在3.0之后提供了一个cluster模式.也就是说每个redis上存储不同内容.

![](https://upload-images.jianshu.io/upload_images/12185313-0f55e1cc574cae70.png)

上面的结构和主从模式不一样,其无中心节点(无master节点),**每个节点和其他节点都有连接**.至于分配数据的部分,利用分布式hash或者朴素hash来实现分配.

其本质的核心是通过hash算法算出一个slot 把对应的key放到对应的节点上.

关于cluster的可用性还是用简单主从节点实现的,每一个数据节点都有一个slave节点备份一模一样的数据充当standby节点

下面我们说下如何部署上面的集群,我们假设有3个数据节点,3个备份节点

```conf
daemonize yes #后台启动

cluster-enabled yes #开启cluster

cluster-config-file node.conf #自动生成
cluster-node-timeout 15000 #节点通信时间
cluster-require-full-coverage no
appendonly yes #持久化方式
```

用redis-trib可以一键部署,可以下载ruby并安装redis-trib

配置集群的副本

```shell
redis-trib.rb create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005
```

就可以启动集群了





### Cluster数据分布

#### 顺序分布

有点像nginx的轮询,来一个数据按顺序放到节点上,但查询会比较难,且数据迁移火葬场,这里就只是一提了.

#### hash分布

朴素hash在数据节点扩容时候会遇到迁移数据的问题,所以一般会采用分片扩容,如下.

![](https://img2018.cnblogs.com/blog/1133627/201810/1133627-20181027173336747-1673966639.png)

扩容的节点取余3的等于1如果翻倍的话取余6应该有一部分等于1一部分等于4,所以只要迁移50%的数据,所以扩容的时候一般扩容相同的大小.

分布式的hash算法一般采用一致性hash算法.

memcached采用的就是一致性hash算法.

![](https://img2018.cnblogs.com/blog/1133627/201810/1133627-20181027173356124-1016731228.png)

每个node都被分配一个token值.该节点就保存对应范围的数据.对每一个key进行hash运算,被哈希后的结果在哪个token的范围内,则按顺时针去找最近的节点,这个key将会被保存在这个节点上.

![](https://img2018.cnblogs.com/blog/1133627/201810/1133627-20181027173404739-1007977005.png)

![](https://img2018.cnblogs.com/blog/1133627/201810/1133627-20181027173411531-183289257.png)

按照上面翻倍扩容的逻辑,我们可以知道其扩容规则.



虚拟槽分配

redis不采用上面的数据分配模型而是采用的虚拟曹分配(slot)

![](https://img2018.cnblogs.com/blog/1133627/201810/1133627-20181027173424090-1936846535.png)

```note
1.把16384槽按照节点数量进行平均分配,由节点进行管理
2.对每个key按照CRC16规则进行hash运算
3.把hash结果对16383进行取余
4.把余数发送给Redis节点
5.节点接收到数据,验证是否在自己管理的槽编号的范围
    如果在自己管理的槽编号范围内,则把数据保存到数据槽中,然后返回执行结果
    如果在自己管理的槽编号范围外,则会把数据发送给正确的节点,由正确的节点来把数据保存在对应的槽中
```

根据redis结构

![](https://upload-images.jianshu.io/upload_images/12185313-0f55e1cc574cae70.png)

我们知道每个节点都会知道其他节点的信息,也就是说知道对应槽位节点的信息,即可转发到相应的节点用来存储数据,然后动态的伸缩节点实现也比较容易.





### 分布式选举

分布式选举是分布式系统里面的分布式协议(例如Paxos)也是Sentinel和zookeeper在主要节点挂了之后的协调策略(重新选出master节点) 也就是因为此机制所以至少要有3个节点才能保证选举的成功或者失败

redis-slave的选举算法:

接下来会对 slave 进行排序:
-   按照 slave 优先级进行排序,slave priority 越低,优先级就越高。
-   如果 slave priority 相同,那么看 replica offset,哪个 slave 复制了越多的数据,offset 越靠后,优先级就越高。
-   如果上面两个条件都相同,那么选择一个 run id 比较小的那个 slave。

quorum和majority:(majority>quorum)

如果有quorunm个哨兵认为主节点挂了,才可以选举出一个哨兵然后majority个哨兵授权才能让这个哨兵称为主节点.



## redis 高级特性

### redis发布订阅模式

redis支持和消息队列一样的发布订阅模式,但是redis一般不用作专门的发布订阅.



### redis事务

redis支持事务,redis集群模式**不支持事务**,即把所有命令都序列化,然后一次执行,但redis的事务不支持回滚(对于错误的命令redis是选择跳过执行下一条命令,和mysql的事务截然不同),且事务不具有原子性,因为使用redis事务一般是用于执行某条命令.关于事务的常见命令如下

1. MULTI:使用该命令,标记一个事务块的开始,通常在执行之后会回复OK,(但不一定真的OK),这个时候用户可以输入多个操作来代替逐条操作,redis会将这些操作放入队列中.

2. EXEC:执行这个事务内的所有命令

3. DISCARD:放弃事务,即该事务内的所有命令都将取消

4. WATCH:监控一个或者多个key,如果这些key在提交事务(EXEC)之前被其他用户修改过,那么事务将执行失败,需要重新获取最新数据重头操作(类似于**乐观锁**)

5. UNWATCH:取消WATCH命令对多有key的监控,所有监控锁将会被取消.

从上面的命令我们也可以看出,可以借助WATCH实现CAS或者是事务回滚操作.一般而言,redis使用lua脚本进行操作,我们可以编写**lua脚本**,redis的事务支持或者是借助redis实现的一些原子类来进行实现.

先来看原生实现

```java
private Boolean setLock(String lockKey) {
  // 使用sessionCallBack处理
  SessionCallback<Boolean> sessionCallback = 
    new SessionCallback<Boolean>() {
    
    List<Object> exec = null;
    
    @Override
    @SuppressWarnings("unchecked")
    public Boolean execute(RedisOperations operations) throws DataAccessException {
      
      operations.multi();// 开启事务
      stringRedisTemplate
        .opsForValue()
        .setIfAbsent(lockKey,0); // 设置值
      stringRedisTemplate
        .expire(lockKey,Constants.REDIS_KEY_EXPIRE_SECOND_1_HOUR, TimeUnit.SECONDS);
      exec = operations.exec(); // 执行事务
      if(exec.size() > 0) {
        return (Boolean) exec.get(0);
      }
      return false;
    }
  };
  return stringRedisTemplate.execute(sessionCallback);
}
```

但上面的方式不是原子性的,是有可能出现问题的,因此我们不能直接使用上面的方式实现锁.

除此之外我们也可以实现非常简单的单次不可重入锁,下面即是一个乐观锁的实现,是一次性锁

```java
public static safeExec(String key){
  try{
    for(;;){
      Boolean lockFlag = redisTemplate.opsForValue()
        .setIfAbsent(key, "val", 10, TimeUnit.SECONDS); // 加锁
      if(lockFlag){ // 只有一个线程获取了锁,即设置成功了
        // 这块区域执行的代码就是线程安全的,但是注意如果这里面的代码执行超过10秒就会出错
        // HTTP请求用户服务进行用户相关的校验
        // 用户活动校验
        // 库存校验
        // 生成订单
        // 发布订单创建成功事件
      }
    }
  }finally {
    // 释放锁
    stringRedisTemplate.delete(key);
  }
}
```

但上面这样子是有可能出现线程安全问题的[参考](https://blog.csdn.net/bntX2jSQfEHy7/article/details/107724043?utm_medium=distribute.pc_relevant.none-task-blog-baidujs_title-1&spm=1001.2101.3001.4242),如果超过了10s那么就有可能会使状态变乱,要想实现相对安全的分布式锁,必须依赖key的value值.在释放锁的时候,通过value值的唯一性来保证不会勿删.我们使用的是lua脚本去实现,其多了一重`in == curr`的判断,但这显然也不是一种特别好的解决方式,因为要用到lua增加了其他开销成本,一般是会考虑使用redis的原子性命令直接实现一些简单的功能,比如increment实现计数器.

改进后的代码如下,利用lua脚本来控制释放锁的过程,必须让key和val都对应上才能够删除,然后传入的时候传入线程的堆栈信息或者是随机生成一个数.通关观察我们发现下面的代码执行性能低下,redis不太适合用作分布式锁的一个原因也在此.

```java
public Boolean lock(String key, String val, Integer time, TimeUnit unit) {
  return redisTemplate.opsForValue()
    .setIfAbsent(key, val, time, unit);
}

public Boolean unLock(String key, String val) {
  String luaScript = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
  RedisScript<Long> redisScript = RedisScript.of(luaScript,Long.class);
  Object res=redisTemplate.execute(redisScript, Collections.singletonList(key), val);
  return res != null && res.equals(1L);
}
```

这样就可以相对安全的实现一次性锁.如果是需要更可靠的分布式锁,需要用下面的工具包

redisson

```xml
<dependency>
  <groupId>org.redisson</groupId>
  <artifactId>redisson</artifactId>
  <version>3.11.1</version>
</dependency>
```

其本质是用了Redis执行lua脚本的方式去构建的各种锁.但redis的分布式锁会有各种问题(因为事务的原子性)



原子自增类

下面的方法实现了一个计数器令牌,当一秒内调用1000次的时候就会停止

```java
public Boolean tryAcquire(String usertoken) {
  // 有可能出现多个线程调用,使用ThreadLocal
  SimpleDateFormat df = ThreadSafeDateFormatter.dateFormatThreadLocal.get();
  String key = usertoken + " limit count " + df.format(new Date());
  long expired = 1000L + new Random().nextInt(1000);
  // 如果不存在就加入一个key
  try {
    redisTemplate.opsForValue().setIfAbsent(key, 0L, expired, TimeUnit.MILLISECONDS);
    // redis实现了一个分布式自增的类
    RedisAtomicInteger i = new RedisAtomicInteger(key, Objects.requireNonNull(redisTemplate.getConnectionFactory()));
    int val = i.getAndIncrement();

    if (val >= 1000) {
      // 超过1000的全部给false,此时数据库的值在增加,但接口全部不予以调用
      return false;
    } else {
      return true;
    }
  } catch (Exception e) {
    // log
    e.printStackTrace();
    return null;
  }
}
```

### 高级数据结构

- bitmap 特殊结构,可以用来实现布隆过滤器
- hyperLogLog 统计方法
- Geo Hash 地理信息的Hash
- Stream 即 pub/sub 其中大部分东西用消息队列代替

bitmap可以直接用RedisTemplate去操控

```java
redisTemplate.opsForValue().setBit(key, offset, bool);
redisTemplate.opsForValue().getBit(key, offset);
```

其主要使用场景有如下几种

- 实现布隆过滤器判断某一个id重复
- 日活统计,因为活跃之后也是不需要计数的只需要区分是不是
- 点赞服务,点赞只能有一个,某一个bit去实现点赞,因为只能有一次点赞
- 签到服务,同上可以归咎于需要大量key,但只需要boolean的状态



hyperLogLog是一重要的统计功能,其主要实现的事基数(去重)统计,其用极少的内存处理巨量的数据.统计存在误差(和布隆过滤器一样).

```java
redisTemplate.opsForHyperLogLog().add(key,val);
redisTemplate.opsForHyperLogLog().size(key); // 统计功能 注入灵魂
redisTemplate.opsForHyperLogLog().delete(key);
```

我们可以把其当成一个集合,其可以知道在集合内有什么元素,但不能取出集合的元素(满满的hash思想),我们看下其实现思路.

我们看下之前使用的bitmap,set同样可以去使用基数统计,不过两者都有问题,先说set,如果数据量很大,那么set的速度会很慢,bitmap则是另一种方法,如果我们使用bitmap就可以节省下非常多的内存,不过其有一些问题,例如要先进行编码,如果要进行合并的话需要进行或操作.但问题在于,如果bitmap存储的是对象,可能要经过非常复杂的编码,且不易于压缩.这个情况下我们应该使用HyperLogLog.



### 一些重要的应用功能的实现

-   令牌桶
-   限流计数器
-   分布式锁
-   全局唯一token

有些功能在前面已经实现了就不在赘述了

-   未完待续





## redis实现

### 服务器线程结构

Reactor 连接处理的线程模型是 redis 使用的线程模型

> The reactor design_pattern is an **event_handling** pattern for handling service requests delivered concurrently to a service handler by **one or more inputs**. The service handler then **demultiplexes** the incoming requests and **dispatches** them synchronously to the associated request handlers.

可以看到 reactor 模型是一种事件驱动的模型,其专门针对服务器的I/O场景设计,可以处理多个输出,利用I/O多路复用,处理异步请求等.Java中的NIO(Non-Blocking-i/o)便是采用了这种模型,Netty和tomcat8.0以上也是采用了这样的模型,在说这个模型之前,我们来聊下I/O多路复用

I/O 多路复用

![](https://pic3.zhimg.com/80/5d8e39d83e931da6ba3b6bc496302e5c_720w.jpg?source=1940ef5c)

I/O 多路复用有几种经典的实现

- select 单线程,远古时期算法,只支持1024个handler
- poll 单线程,改进了select,使用了轮询算法去检查 select 有没有被select
- epoll 多线程,2002年实现,只存在于linux平台,基于poll改进,不再使用轮询去访问 Selector,其采用的是通知的机制(回调函数)来进行实现,其可以很好的实现多线程的模式

[tomcat 服务器线程模型文档参考](https://github.com/tearsforyears/note/blob/master/Java/base/%E5%A4%9A%E7%BA%BF%E7%A8%8B%E4%B8%8E%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86.md)



思考

- 为什么 poll 不能实现多线程
- 一个服务器使用 I/O 多路复用的请求解耦方式,BIO服务器 tomcat 7.0 真的是单线程服务器吗?
- 为什么 epoll 比 poll 效率快很多倍

Reactor 模型分为几种

- 单 Reactor 单线程 select,poll Java的NIO采用的就是类似poll模型来实现的(不支持多线程)
- 单 Reactor 多线程 epoll
- 多 Recator 多线程 epoll

单线程 Reactor 指的是所有的I/O 在同一个线程内完成,该线程接受客户端的TCP请求,对传输数据进行编码和解码,而多线程的 Reactor 模式值得是有个专门的 Acceptor 用来处理 I/O 请求用来提高 acceptor 的并发量.且是一种无锁化的思想,同一个I/O线程可以处理多个 SocketChannel 的事件.

每个 Reactor 模型中有如下组件

- **Reactor**：把IO事件分配给对应的handler处理
- **Acceptor**：处理客户端连接事件
- **Handler**：处理非阻塞的任务

![](https://pic3.zhimg.com/80/v2-a3a7f2b064f424fbb11e77f019123e62_720w.jpg)

如上图,acceptor用来处理连接事件,读写等交给后续线程去处理(实际上也只有一个线程),一个线程去处理自然引起性能问题.当事件队列过多的时候就会出问题.那我们可以对无状态的几个操作进行线程池的优化

- reactor 所有请求打过来这,没有前方路由不能多线程,有前方路由多实例,这里只是作为一个中转的功能去设计
- accepor accept请求,这个会产生一个socket,本身不是阻塞的

![](https://pic1.zhimg.com/80/v2-d60a5c2c930e3ec611855d387d2429ec_720w.jpg)

单reactor多线程模型改进是把处理请求的部分利用线程池进行了多线程的处理.Reactor承担所有线程的监听和相应.这也体现了对于无关乎调度状态的操作可以交给后续的并发的线程池去处理.

![](https://pic2.zhimg.com/80/v2-ca0ee6f64ec8654ba143c30548874095_720w.jpg)

上面其实还可以拆分成主从 reactor,注意到只有连接是需要等待三次握手完成才能accept出socket,所以单线程去处理连接请求,多线程去处理其他请求,可以尽可能的减少阻塞的部分.

> mainReactor : 监听 ServerSocketChannel 、建立与 SocketChannel 的连接、将完成建立连接之后的 Socket 交给 subReactor
>
> subReactor : 监听SocketChannel的 I/O事件，完成编解码、相应的业务处理（默认为CPU个数）

可以看到主从 reactor 的拆分是吧 Accept 这件事单独抽出来去处理.即是所谓的I/O多路复用的思想.



#### redis 的线程模型

![](https://img-blog.csdnimg.cn/20190918215924363.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3hwX3hweHA=,size_16,color_FFFFFF,t_70)

![](https://img-blog.csdnimg.cn/20190615185708852.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM4NjAxNzc3,size_16,color_FFFFFF,t_70)

![](https://segmentfault.com/img/remote/1460000040376115)

显而易见的,redis6.0的多线程操作和redis6.0以下的单线程操作其实是一样的,其核心都使用了主线程进行执行,不过网络的读写交给了多线程组去执行,即并发度更高了



redis提供了原子性的保证,即执行的指令可以被合称为一个**[ae事件](http://www.web-lovers.com/redis-source-ae.html)**,可以由lua脚本保证

> ## Redis is single threaded. How can I exploit multiple CPU / cores?
>
> **It's not very frequent that CPU becomes your bottleneck with Redis, as usually Redis is either memory or network bound.** For instance, using pipelining Redis running on an average Linux system can deliver even 1 million requests per second, so if your application mainly uses O(N) or O(log(N)) commands, it is hardly going to use too much CPU.
>
> However, to maximize CPU usage you can start multiple instances of Redis in the same box and treat them as different servers. At some point a single box may not be enough anyway, so if you want to use multiple CPUs you can start thinking of some way to shard earlier.
>
> However with Redis 4.0 we started to make Redis more threaded. For now this is limited to deleting objects in the background, and to blocking commands implemented via Redis modules. For future releases, the plan is to make Redis more and more threaded.

6.0的性能比之前提高了一倍,使用多线程相当于把原来单线程的写回socket这部分操作从单线程变成了多线程

### redis数据结构

本章节主要讲redis实现的原理部分,涉及到数据结构,内存管理,线程模型,日志系统等.

![](https://img2018.cnblogs.com/blog/1289934/201906/1289934-20190621163930814-1395015700.png)

我们看到其无外乎就五中数据结构

-   string 充当基本缓存,可以充当计数器,可以序列化对象(比如session)
-   hash 缓存,和hashmap类似
-   list 双端链表,和Java中的linkedlist差不多,实现阻塞队列等,可以实现timeline
-   set 集合不可重复支持交并补操作,无序,可以实现点赞收藏,或者是同种标签等
-   **zset** 集合不可重复,通过分数排序(有序),可以实现排行榜

其类型存储如下

![img](https://img2020.cnblogs.com/blog/1993240/202009/1993240-20200922093317769-1818232862.png)

所以说hash实际的底层类型包括如下几种

-   raw (simple dynamic string) 小字符串,需要分配两个对象sds,redisobj
-   int 
-   embstr 只需要分配一个对象,区别于raw,只需要分配sds
-   
-   ziplist 可压缩的ArrayList
-   linkedlist 链表
-   quicklist 结合了linkedlist和ziplist外层linkedlist,里层ziplist
-   hashtable 即java中的hashmap
-   inset 用hash进行去重保存在同一contents里面,按hash进行二分搜索
-   skiplist zset特有,更好实现的红黑树

我们都知道redis是用C实现的,这里会设计部分C的源码,一个redisObject用下面的方式表示

```c
typedef struct redisObject {
    unsigned [type] 4; // string hash list set zset之一
    unsigned [encoding] 4; // 对应右边的编码
    unsigned [lru] REDIS_LRU_BITS; // 表示本对象的空转时长
    int refcount; // 用于gc
    void *ptr; // 指向具体的实现
} robj;
```

![](https://img2020.cnblogs.com/blog/1993240/202009/1993240-20200922095552955-1765467256.png)

| 编码常量                  | 编码所对应的底层数据结构    |
| ------------------------- | --------------------------- |
| REDIS_ENCODING_INT        | long 类型的整数             |
| REDIS_ENCODING_EMBSTR     | embstr 编码的简单动态字符串 |
| REDIS_ENCODING_RAW        | 简单动态字符串              |
| REDIS_ENCODING_HT         | 字典                        |
| REDIS_ENCODING_LINKEDLIST | 双端链表                    |
| REDIS_ENCODING_ZIPLIST    | 压缩列表                    |
| REDIS_ENCODING_INTSET     | 整数集合                    |
| REDIS_ENCODING_SKIPLIST   | 跳跃表和字典                |

#### string

string的编码方式可以是,在redis中是没有int类型的,这个int指的是Long在java中需要经过转化

-   int
-   raw (传统动态字符串,用于存储小于某一字节的字符串)
-   embstr (用于存储大于某一字节的字符串)

embstr只需要分配一次内存,raw需要分配两次(一次为[`sds`](https://github.com/antirez/redis/blob/unstable/src/sds.h)分配对象,另一次为objet分配对象),sds对象(simple dynamic string),我们只是看其数据结构的定义

```c
typedef char *sds;

/* Note: sdshdr5 is never used, we just access the flags byte directly.
 * However is here to document the layout of type 5 SDS strings. */
struct __attribute__ ((__packed__)) sdshdr5 {
    unsigned char flags; /* 3 lsb of type, and 5 msb of string length */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr8 {
    uint8_t len; /* used */
    uint8_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr16 {
    uint16_t len; /* used */
    uint16_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr32 {
    uint32_t len; /* used */
    uint32_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
struct __attribute__ ((__packed__)) sdshdr64 {
    uint64_t len; /* used */
    uint64_t alloc; /* excluding the header and null terminator */
    unsigned char flags; /* 3 lsb of type, 5 unused bits */
    char buf[];
};
```

上面我们可以看到redis对内存进行的优化,不同的字符串对应不同的结构体去存.看其源码,我们可以看到其没有使用c语言的原生字符串去存(因为原生字符串本质上是字符数组,结尾还有`\0`等一些缺点,且也容易出现一些字符串的拼接问题)

embstr只是只读的形式,语义为不可修改,我们对embstr的操作都要被转化成raw然后在转会embstr,raw编码在内存分配上会分配redisObject,sdshdr,而embstr会一次性分配redisObject,sdshdr(连续空间,因为不可变).所以就不可变的字符串来说,这种空间分配方式极具优点,也是redis快的原因之一.

![](https://segmentfault.com/img/remote/1460000018887259)

![](https://segmentfault.com/img/remote/1460000018887260)

上图就可以清洗的看到其存储结构的不同

#### list

list有两种编码,ziplist和linkedlist.元素少的时候使用ziplist,元素多的时候使用linkedlist,关于linkedlist的设计思路,绝大多数语言中(例如java和python)都有本地类库的实现,此处就不再赘述.我们重点介绍ziplist

-   linkedlist
-   ziplist
-   quicklist

zip的设计思路有点像ArrayList,其存储在连续的空间中,每次插入的复杂度是O(N),需要进行一次relloc,整个结构只需要malloc一次就能创建出来,其结构如下

<img src="https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201001100507850-847200896.png" alt="120%" style="zoom:200%;" />

-   zlbytes 整个链表所占的bytes
-   zltail 链表的尾指针距离链表头指针的offset
-   zlen 节点数量
-   entry_i 具体的元素
-   zlend 压缩链表的末端

和ArrayList一样不适合用来存需要经常修改的,比较大的元素,因为会涉及到复制移动,经常调度内存.

两种数据结构各有千秋,在比较新的版本里加入了quicklist,可以看做是linkedlist和ziplist的混合体.它将linkedlist按段切分,每一段使用ziplist来紧凑存储,多个ziplist之间使用双指针串接起来。

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201001103326988-2044742495.png)

默认每个ziplist是8k,如果超出这个字节数会生成一个新的ziplist,可以使用`list-max-ziplist-size`来决定这个大小.为了节约空间,quicklist还是用了LZF压缩算法,对部分ziplist进行压缩

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201001111702607-948543746.png)

可由参数`list-compress-depth`指定压缩深度,所谓的压缩深度比如默认的0是不压缩,上图的压缩深度是1.各种值的含义如下

-   0: 是个特殊值,表示都不压缩。这是Redis的默认值。
-   1: 表示quicklist两端各有1个节点不压缩,中间的节点压缩。
-   2: 表示quicklist两端各有2个节点不压缩,中间的节点压缩。
-   3: 表示quicklist两端各有3个节点不压缩,中间的节点压缩。

借助上面的结构我们可以实现简单的消息队列

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201001112341182-215857925.png)

#### hash

hashtable可以由ziplist或者hashtable来实现,当数量少的时候使用ziplist进行一次全表扫描更快获取结果,下面我们讲下hashtable,hashtable主要通过dict来实现

```c
typedef struct dict {
    dictType *type;
    void *privdata;
    dictht ht[2]; // 每个dict都有两个hashtable
  
    long rehashidx; /* rehashing not in progress if rehashidx == -1 */
    int iterators; /* number of iterators currently running */
} dict;
typedef struct dictht {  
    dictEntry **table;  
    unsigned long size;  
    unsigned long sizemask;  
    unsigned long used;  
} dictht;
```

每个dict都有两个hashtable,通常只有一个是有值的,这是因为在扩容的时候,分配了新的hashtable然后迁移,迁移结束后,旧的hashtable删除

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201002105644237-1980970838.png)

其数据结构几乎是和java的一致,是通过分桶来解决冲突的

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201002105929003-1083710349.png)

在进行RDB时是不会去扩容的,但是如果hash表的元素个数已经到达了第一维数组长度的5倍的时候,就会强制扩容,不管你是否在持久化.相对而言还有缩容,缩容的条件是元素个数低于数组长度的10%.

rehash的步骤

1.  为ht[1] 分配空间,让字典同时持有ht[0]和ht[1]两个哈希表
2.  (定时)维持一个索引计数器变量rehashidx,并将它的值设置为0,表示rehash开始；
3.  在rehash进行期间,每次对字典执行CRUD操作时,程序除了执行指定的操作以外,还会将ht[0]中的数据rehash到ht[1]表中,并且将rehashidx加一；
4.  当ht[0]中所有数据转移到ht[1]中时,将rehashidx设置成-1,表示rehash 结束;(采用渐进式rehash 的好处在于它采取分而治之的方式,避免了集中式rehash带来的庞大计算量.特别的在进行rehash是只能对ht[0]进行使得h[0]元素减少的操作,如查询和删除;而查询是在两个哈希表中查找的,而插入只能在ht[1]中进行,ht[1]也可以查询和删除)
5.  将ht[0]释放,然后将ht[1]设置成ht[0],最后为ht[1]分配一个空白哈希表.有安全迭代器可用,安全迭代器保证,在迭代起始时,字典中的所有结点, 都会被迭代到,即使在迭代过程中对字典有插入操作.

#### set

set可以是由两种编码类型构成

-   hashtable (这个的实现方式和HashSet的思路一致就不赘述了)
-   inset

我们主要来看inset

```c
typedef struct intset {
    uint32_t encoding;
    uint32_t length; // 数组长度
    int8_t contents[]; // 实际保存元素的数据结构,没有重复元素,且元素从小到大排列
} intset;
```

查找元素使用的是二分法,复杂度为log(n),而如果才有hash,其复杂度为O(1).当然因为数据类型等一些不同,其实际操作的复杂度会因为扩容类型转换等有不同.我们看到的是inset只是单纯对数(存储内容)本身进行了升序排列,而zset是使用了一个score来进行排列

#### zset

zset保留了set的特性之外,还增加了根据score排序的功能,其也有两种实现方式

-   ziplist
-   skiplist

关于skiplist可以看下面具体的介绍,关于ziplsit可以看上面对于list的介绍.这里因为对两者都进行了排序所以都需要说明下.

前面我们知道了ziplist的数据结构.其按照下面的形式保存zset的分数.

![](https://img2020.cnblogs.com/blog/1993240/202010/1993240-20201002160252776-1435470436.png)

第一个节点用于保存其member,第二个节点用于保存其分数.如上示意图.关于skiplist可以看下面具体的操作介绍,我们来看其具体的数据结构.

```c
typedef struct zskiplist {
    // 头节点，尾节点
    struct zskiplistNode *header, *tail;
    // 节点数量
    unsigned long length;
    // 目前表内节点的最大层数
    int level;
} zskiplist;

/* ZSETs use a specialized version of Skiplists */
typedef struct zskiplistNode {
    // member 对象
    robj *obj;
    // 分值
    double score;
    // 后退指针
    struct zskiplistNode *backward;
    // 层
    struct zskiplistLevel {
        // 前进指针
        struct zskiplistNode *forward;
        // 这个层跨越的节点数量
        unsigned int span;
    } level[];
} zskiplistNode;
```

实际上,skiplist和dict是一起被使用的,因为skip可以提供顺序(范围)的快速查找,而dict可以提供O(1)的查找效率,利用更多的指针保存sds的数据信息,两者都作为zset的索引.

##### zset的使用场景

上面的使用场景都比较简单,这里单独说明zset的使用场景.

-   实时排行榜,通过score很容易理解
-   延时队列,通过score表示时间戳
-   score作为时间戳的限流





### 跳表skip-list

跳表是一种典型的空间换时间的数据结构

**跳跃表的插入**
首先我们需要插入几个数据。链表开始时是空的。
![链表开始](https://img-blog.csdnimg.cn/2019060819523524.png)
**插入 level = 3,key = 1**
当我们插入 level = 3,key = 1 时,结果如下：
![ level = 3,key = 1](https://img-blog.csdnimg.cn/20190608202331965.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
**插入 level = 1,key = 2**
当继续插入 level = 1,key = 2 时,结果如下
![level = 1,key = 2](https://img-blog.csdnimg.cn/20190608202534527.png)
**插入 level = 2,key = 3**
当继续插入 level = 2,key = 3 时,结果如下
![ level = 2,key = 3](https://img-blog.csdnimg.cn/20190608202608186.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
**插入 level = 3,key = 5**
当继续插入 level = 3,key = 5 时,结果如下
![level = 3,key = 5](https://img-blog.csdnimg.cn/20190608202625967.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
**插入 level = 1,key = 66**
当继续插入 level = 1,key = 66 时,结果如下
![ level = 1,key = 66](https://img-blog.csdnimg.cn/20190608202641442.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
**插入 level = 2,key = 100**
当继续插入 level = 2,key = 100 时,结果如下
![level = 2,key = 100](https://img-blog.csdnimg.cn/20190608202652893.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
上述便是跳跃表插入原理,关键点就是层级–使用**抛硬币**的方式,感觉还真是挺随机的。每个层级最末端节点指向都是为 null,表示该层级到达末尾,可以往下一级跳。

跳跃表的查询

现在我们要找键为 **66** 的节点的值。那跳跃表是如何进行查询的呢？

跳跃表的查询是从顶层往下找,那么会先从第顶层开始找,方式就是循环比较,如过顶层节点的下一个节点为空说明到达末尾,会跳到第二层,继续遍历,直到找到对应节点。

如下图所示红色框内,我们带着键 66 和 1 比较,发现 66 大于 1。继续找顶层的下一个节点,发现 66 也是大于五的,继续遍历。由于下一节点为空,则会跳到 level 2。
![顶层遍历](https://img-blog.csdnimg.cn/20190608204026487.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
上层没有找到 66,这时跳到 level 2 进行遍历,但是这里有一个点需要注意,遍历链表不是又重新遍历。而是从 5 这个节点继续往下找下一个节点。如下,我们遍历了 level 3 后,记录下当前处在 5 这个节点,那接下来遍历是 5 往后走,发现 100 大于目标 66,所以还是继续下沉。
![第二层遍历](https://img-blog.csdnimg.cn/20190609155105393.png)
当到 level 1 时,发现 5 的下一个节点恰恰好是 66 ,就将结果直接返回。
![遍历第一层](https://img-blog.csdnimg.cn/20190609155503225.png)

**跳跃表删除**
跳跃表的删除和查找类似,都是一级一级找到相对应的节点,然后将 next 对象指向下下个节点,完全和链表类似。

现在我们来删除 66 这个节点,查找 66 节点和上述类似。
![找到 66 节点](https://img-blog.csdnimg.cn/20190610143318878.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
接下来是断掉 5 节点 next 的 66 节点,然后将它指向 100 节点。
![指向 100 节点](https://img-blog.csdnimg.cn/20190610143609229.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MTYyMjE4Mw==,size_16,color_FFFFFF,t_70)
如上就是跳跃表的删除操作了,和我们平时接触的链表是一致的。当然,跳跃表的修改,也是和删除查找类似,只不过是将值修改罢了,就不继续介绍了。

查找节点复杂度logn

使用跳表而不用红黑树的原因

1.  在做范围查找的时候,平衡树比skiplist操作要复杂.在平衡树上,我们找到指定范围的小值之后,还需要以中序遍历的顺序继续寻找其它不超过大值的节点.如果不对平衡树进行一定的改造,这里的中序遍历并不容易实现.而在skiplist上进行范围查找就非常简单,只需要在找到小值之后，对第1层链表进行若干步的遍历就可以实现.
2.  平衡树的插入和删除操作可能引发子树的调整,逻辑复杂,而skiplist的插入和删除只需要修改相邻节点的指针,操作简单又快速.
3.  从内存占用上来说,skiplist比平衡树更灵活一些,一般来说,平衡树每个节点包含2个指针(分别指向左右子树),而skiplist每个节点包含的指针数目平均为1/(1-p),具体取决于参数p的大小.如果像Redis里的实现一样,取p=1/4,那么平均每个节点包含1.33个指针,比平衡树更有优势.



### LRU算法的实现

**LRU(Least Recently Used)**,即最近最少使用.Redis采用的是近似LRU.和常规LRU不太一样.常规LRU采用的是大小固定的队列,达到固定size之后,入队一个就出队一个,以保持内存中常驻key的稳定.

Redis LRU采用的是随机采样法,随机选择5个然后淘汰掉以前没使用过的key.可以通过`maxmemory-samples`来修改采样数量.和随机梯度下降一样,如果淘汰的次数足够多,那么整个算法就会收敛趋于稳定.如果采样的数量足够大,那么随机LRU就趋近于LRU.

LRU让每个key存储了一个24bit的时间轴,用以记录最后一次被访问的时间,redis3.0对LRU算法进行了一些优化.

新算法会维护一个候选池(这个候选池维护的是**将要被淘汰的key**),池中是按随机访问时间进行排序的,第一次进入池子是随机进入的,然后每次选取key,每次选取key都选择小于本池子中最小的(更久没被使用的),当池子放满之后,淘汰掉就近被访问的.算法的效果图如下

![](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9zMS41MWN0by5jb20vaW1hZ2VzL2Jsb2cvMjAxOTEwLzIzLzhhY2VjNjU2YjFhN2Y0ZmJkOGRlM2JjYjdmNWM3Y2RiLnBuZw?x-oss-process=image/format,png)

-   浅灰色是被淘汰的数据
-   灰色是没有被淘汰掉的老数据
-   绿色是新加入的数据

所以我们看到误伤的数据还是比较少的.算法性能上也是redis3.0的新LRU会更好

#### LFU

**Least Frequently Used**是Redis4.0里面加入的一种新算法.根据key被访问的频率进行淘汰,上面LRU是根据key被访问的**时间**进行淘汰.lfu一共有两种策略,具体含义在上文中有讲述,和lru类似.

-   volatile-lfu
-   allkeys-lfu

针对lru和lfu可以发现,lfu更加适合热点数据,只有不经常被使用的数据会被淘汰掉,这样热点数据即使有段时间没被使用都会留在内存里面.