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

redis是队列循环加单线程模型

其利主要利用了IO复用(请求注册,注册操作)

### 有待补充

## redis缓存击穿和缓存雪崩

缓存击穿:一个key非常热点 并发操作 导致这个缓存瞬间穿破缓存直接请求数据库

解决方案 布隆过滤器 缓存空对象

缓存雪崩: 在缓存层出现了错误 导致直接访问存储层 存储层调用量暴增

解决方案: redis高可用集群 限流降级 数据预热

### 有待补充



## 和memcached的对比

-   线程模型是单线程
-   在数据类型上支持更多
-   比memcached可用性更高
-   Memcached采用LRU算法 而redis利用vm去管理虚拟内存

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

-   **master-slave(non-HA)**

    一个master多个slave slave读 master写

    master挂了之后没有选举机制 也就没有写的功能

    master修改之后会把命令同步到slave,维护backlog记录操作

    安全设置:客户端访问master要密码，客户端访问slave不需要密码，启动slave要密码

    备份master节点 不备份slave节点 

-   **Sentinel(哨兵模式)**

    sentinel是一个独立选举master的节点 当master挂了之后会从原来的集群中选择一个slave当成节点 (sentinel不要和master节点放在一起挂了之后就和master-slave一样人没了)

    master每隔10s发送一次heartbeat slave每隔1s发送一次heartbeat
    
    通过下面分布式选举可以确定新的master并更新到sentinel
    
-   **Cluster**

    哨兵模式解决了集群高可用的问题 但并没有解决集群扩容问题 其本质还是读写分离的服务器其可用性比Sentinel要高 因为所有节点都是一主一从(或者一主多从)的模式 不支持同时处理多个key 支持动态扩容 并发很高的时候处理多个key的创建可能会发生不可预测的问题

    其本质的核心是通过hash算法算出一个slot 把对应的key放到对应的节点上

Sentinel 保证了其高可用性为了选举 cluster提高了单机性能的扩充

### 分布式选举

分布式选举是分布式集群里面很重要的机制 也是Sentinel和zookeeper在主要节点挂了之后的协调策略(重新选出master节点) 也就是因为此机制所以至少要有3个节点才能保证选举的成功或者失败

slave的选举算法:

接下来会对 slave 进行排序：
-   按照 slave 优先级进行排序，slave priority 越低，优先级就越高。
-   如果 slave priority 相同，那么看 replica offset，哪个 slave 复制了越多的数据，offset 越靠后，优先级就越高。
-   如果上面两个条件都相同，那么选择一个 run id 比较小的那个 slave。

quorum和majority:(majority>quorum)

如果有quorunm个哨兵认为主节点挂了,才可以选举出一个哨兵然后majority个哨兵授权才能让这个哨兵称为主节点

### 分布式锁

### 有待后续



---

## 搭建集群

