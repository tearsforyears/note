# Redis

---

nosql的一种 内存数据库 高效键值对的存储 优秀的持久化机制 构建分布式系统的组件

相比于大多数基于磁盘IO的数据库 redis显然速度要远高于mysql 适合存储需要高性能的数据

nosql满足下列分布式定理 并基于此定理构建系统

默认端口6379



## CAP定理

---

在计算机科学中, CAP定理（CAP theorem）, 又被称作 布鲁尔定理（Brewer's theorem）, 它指出对于一个分布式计算系统来说，不可能同时满足以下三点:

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
```

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



### 有待后续



## 使用场景

---

缓存Session 缓存小的数据(几百兆的就算了 内存压力大)

以下是类似**cache**的读机制 这个缓冲的主要是热点数据提高数据访问效率

![redis 的使用场景](https://upload-images.jianshu.io/upload_images/7896890-404e89059b6a96b5.png)

其次是处理高并发请求 也是缓冲请求数据本身 充当**缓冲队列**

也就是说对于临时高峰值业务(抢票 秒杀系统等) 我们直接存取redis集群 等待redis空闲时进行持久化



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

    这个SAVE是主进程执行的,并非子进程执行，所以服务器会阻塞一段时间

AOF重写

​	如果不加以控制,AOF文件的大小将会变得无法控制。所以对一些命令进行了重写,AOF的重写程序放到子进程中执行,如果在重写的时候有新的命令进来会遗漏,所以设置AOF缓冲区.我们可以用`BGREWRITEAOF`来进行AOF重写.这期间父进程主要完成的工作如下

1.将AOF重写缓冲区中的所有内容写入新的AOF文件中，这时新AOF文件锁保存的数据库状态和服务器当前状态一致

2.对新的AOF文件进行改名，原子性操作地覆盖现有的AOF文件，完成新旧AOF文件的替换。



## redis的线程模型

redis是队列循环加单线程模型,其利主要利用了IO复用(请求注册,注册操作).



## Redis的过期策略

redis里面如果有大量的key,我们看下其过期策略.其实际上使用了下面两种方式结合的删除策略.

### lazy删除

在访问某一key的时候才对其过期时间进行检查,如果过期了就删除.这种策略的弊病就是如果不进行检查的话,该key会一直留在内存中十分占有内存空间.

### 定期删除

redis会把所有设置了过期时间的key放到一个字典中,每隔10秒进行定期扫描.并且删除过期的key.其具体策略如下

1.  从过期字典中随机20个key
2.  删除这20个key中已过期的
3.  如果超过25%的key过期，则重复第一步

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
# Redis数据库索引（默认为0）
spring.redis.database=0  
# Redis服务器地址
spring.redis.host=localhost
# Redis服务器连接端口
spring.redis.port=6379  
# Redis服务器连接密码（默认为空）
spring.redis.password=
# 连接池最大连接数（使用负值表示没有限制） 默认 8
spring.redis.lettuce.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制） 默认 -1
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

# 配置监听的主服务器，这里sentinel monitor代表监控，mymaster代表服务器的名称，可以自定义，192.168.11.128代表监控的主服务器，6379代表端口，2代表只有两个或两个以上的哨兵认为主服务器不可用的时候，才会进行failover操作。
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
1.把16384槽按照节点数量进行平均分配，由节点进行管理
2.对每个key按照CRC16规则进行hash运算
3.把hash结果对16383进行取余
4.把余数发送给Redis节点
5.节点接收到数据，验证是否在自己管理的槽编号的范围
    如果在自己管理的槽编号范围内，则把数据保存到数据槽中，然后返回执行结果
    如果在自己管理的槽编号范围外，则会把数据发送给正确的节点，由正确的节点来把数据保存在对应的槽中
```

根据redis结构

![](https://upload-images.jianshu.io/upload_images/12185313-0f55e1cc574cae70.png)

我们知道每个节点都会知道其他节点的信息,也就是说知道对应槽位节点的信息,即可转发到相应的节点用来存储数据,然后动态的伸缩节点实现也比较容易.





### 分布式选举

分布式选举是分布式系统里面的分布式协议(例如Paxos)也是Sentinel和zookeeper在主要节点挂了之后的协调策略(重新选出master节点) 也就是因为此机制所以至少要有3个节点才能保证选举的成功或者失败

redis-slave的选举算法:

接下来会对 slave 进行排序:
-   按照 slave 优先级进行排序，slave priority 越低，优先级就越高。
-   如果 slave priority 相同，那么看 replica offset，哪个 slave 复制了越多的数据，offset 越靠后，优先级就越高。
-   如果上面两个条件都相同，那么选择一个 run id 比较小的那个 slave。

quorum和majority:(majority>quorum)

如果有quorunm个哨兵认为主节点挂了,才可以选举出一个哨兵然后majority个哨兵授权才能让这个哨兵称为主节点.



