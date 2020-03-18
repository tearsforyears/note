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

```redis-cli
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

## 使用场景

---

缓存Session 缓存小的数据(几百兆的就算了 内存压力大)

以下是类似**cache**的读机制 这个缓冲的主要是热点数据提高数据访问效率

![redis 的使用场景](https://upload-images.jianshu.io/upload_images/7896890-404e89059b6a96b5.png)

其次是处理高并发请求 也是缓冲请求数据本身 充当**缓冲队列**

也就是说对于临时高峰值业务(抢票 秒杀系统等) 我们直接存取redis集群 等待redis空闲时进行持久化

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

-   master-slave(non-HA)

    一个master多个slave slave读 master写

    master挂了之后没有选举机制 也就没有写的功能

    master修改之后会把命令同步到slave,维护backlog记录操作

    安全设置:客户端访问master要密码，客户端访问slave不需要密码，启动slave要密码

    备份master节点 不备份slave节点 

-   Sentinel(哨兵模式)

    sentinel是一个独立选举master的节点 当master挂了之后会从原来的集群中选择一个slave当成节点 (sentinel不要和master节点放在一起挂了之后就和master-slave一样人没了)

    master每隔10s发送一次heartbeat slave每隔1s发送一次heartbeat
    
    通过下面分布式选举可以确定新的master并更新到sentinel
    
-   Cluster

    哨兵模式解决了集群高可用的问题 但并没有解决集群扩容问题 其本质还是读写分离的服务器

    其可用性比Sentinel要高 因为所有节点都是一主一从(或者一主多从)的模式 不支持同时处理多个key 支持动态扩容 并发很高的时候处理多个key的创建可能会发生不可预测的问题

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

---

## 搭建集群

