# Interduce to redis

---

[TOC]

[created at:2021年11月02日11:08:53] 此文档为 redis 的原理介绍,基本涉及到 redis 的实现细节



## 内存管理

---

- 持久化
- 非持久化

### 持久化

持久化分为两种

- AOF
- RDB

#### RDB [磁盘]

文件格式

```note
----------------------------# RDB文件是二进制的，所以并不存在回车换行来分隔一行一行.
52 45 44 49 53              # 以字符串 "REDIS" 开头
30 30 30 33                 # RDB 的版本号，大端存储，比如左边这个表示版本号为0003
----------------------------
FE 00                       # FE = FE表示数据库编号，Redis支持多个库，以数字编号，这里00表示第0个数据库
----------------------------# Key-Value 对存储开始了
FD $length-encoding         # FD 表示过期时间，过期时间是用 length encoding 编码存储的，后面会讲到
$value-type                 # 1 个字节用于表示value的类型，比如set,hash,list,zset等
$string-encoded-key         # Key 值，通过string encoding 编码，同样后面会讲到
$encoded-value              # Value值，根据不同的Value类型采用不同的编码方式
----------------------------
FC $length-encoding         # FC 表示毫秒级的过期时间，后面的具体时间用length encoding编码存储
$value-type                 # 同上，也是一个字节的value类型
$string-encoded-key         # 同样是以 string encoding 编码的 Key值
$encoded-value              # 同样是以对应的数据类型编码的 Value 值
----------------------------
$value-type                 # 下面是没有过期时间设置的 Key-Value对，为防止冲突，数据类型不会以 FD, FC, FE, FF 开头
$string-encoded-key
$encoded-value
----------------------------
FE $length-encoding         # 下一个库开始，库的编号用 length encoding 编码
----------------------------
...                         # 继续存储这个数据库的 Key-Value 对
FF                          ## FF：RDB文件结束的标志
```

可以从文件结构看出,其存储的就是 key-value 对的完整信息,这种持久化也称之为**内存快照**,落地磁盘以 `dump.rdb` 的方式存储

在redis.conf文件中可以指定rdb 持久化的相关参数

```conf
save 900 1  // 900 秒内 如果更新了1次(以上的操作)就会触发持久化
save 300 10
save 60 10000
```

该种持久化发生的时机

- save / bgsave (同步异步刷盘)
- flushall
- shutdown

一般这种持久化支持数据备份,同步等,类似于 mysql 中的 binlog(row)

#### AOF [内存磁盘]

aof 又叫 append only file, 即把执行的语句(日志)记录到文件中,通常用于数据恢复,类似于 mysql 中的事务日志 redo-log 和 es 中的 translog,主要作用是保证一致性或者是进行数据一致性恢复等

其拥有内存缓冲区 `aof_buf`

```conf
appendonly yes
appendfilename "appendonly.aof"
```

还有个操作叫rewrite,当触发下列限制的时候会让数据落盘(类似checkpoint),同样是带缓冲的结构

```conf
auto-aof-rewrite-percentage 100 // 比上次落盘后文件大小大100的文件会落盘
auto-aof-rewrite-min-size 64mb
```

### 非持久化

非持久化指的是数据库内存的清理和回收,redis 为一内存型数据库,内存的管理和回收尤为重要

- 过期的 key 会直接回收吗？
- 大规模的内存回收？

#### 内存分配

> ## [Memory allocation](https://redis.io/topics/memory-optimization)
>
> To store user keys, Redis allocates at most as much memory as the `maxmemory` setting enables (however there are small extra allocations possible).
>
> The exact value can be set in the configuration file or set later via [CONFIG SET](https://redis.io/commands/config-set) (see [Using memory as an LRU cache for more info](https://redis.io/topics/lru-cache)). There are a few things that should be noted about how Redis manages memory:
>
> - Redis will **not always free up (return) memory to the OS** when keys are removed. This is not something special about Redis, but it is how most malloc() implementations work. For example if you fill an instance with 5GB worth of data, and then remove the equivalent of 2GB of data, the Resident Set Size (also known as the RSS, which is the number of memory pages consumed by the process) will probably still be around 5GB, even if Redis will claim that the user memory is around 3GB. This happens because the underlying allocator can't easily release the memory. For example often most of the removed keys were allocated in the same pages as the other keys that still exist.
> - The previous point means that you need to provision memory based on your **peak memory usage**. If your workload from time to time requires 10GB, even if most of the times 5GB could do, you need to provision for 10GB.
> - However allocators are smart and are able to **reuse free chunks** of memory, so after you freed 2GB of your 5GB data set, when you start adding more keys again, you'll see the RSS (Resident Set Size) stay steady and not grow more, as you add up to 2GB of additional keys. The allocator is basically trying to reuse the 2GB of memory previously (logically) freed.
> - Because of all this, the **fragmentation ratio is not reliable** when you had a memory usage that at peak is much larger than the currently used memory. The fragmentation is calculated as the physical memory actually used (the RSS value) divided by the amount of memory currently in use (as the sum of all the allocations performed by Redis). Because the RSS reflects the peak memory, when the (virtually) used memory is low since a lot of keys / values were freed, but the RSS is high, the ratio `RSS / mem_used` will be very high.
>
> If `maxmemory` is not set Redis will keep allocating memory as it sees fit and thus it can (gradually) eat up all your free memory. Therefore it is generally advisable to configure some limit. You may also want to set `maxmemory-policy` to `noeviction` (which is *not* the default value in some older versions of Redis).
>
> It makes Redis return an out of memory error for write commands if and when it reaches the limit - which in turn may result in errors in the application but will not render the whole machine dead because of memory starvation.

总而言之就是 redis 实现了自己的内存分配和回收机制(虚拟机)来对操作系统分配的内存进行管理

redis 并没有自己实现的内存池,分配内存的方法也借由操作系统实现,编译时指定内存分配器,默认是jemalloc.三种内存分配的库,除了libc是没有对线程进行优化以外,其他两个库都对线程竞争进行了优化,通过竞争多变量和ThreadLocal的形式减少竞争.

#### 内存分配器

下面三种分配器可以在一些组件上上使用 mysql redis nginx等.但需要重新编译 `make && make install`,redis支持下面三种内存分配器的使用

- jemalloc 默认分配器,在减少内碎片方便做的很好,内存块使用多隔断的固定分配方法,其可以在多线程环境下使用.尽可能的减少内碎片,该分配器由 facebook 推出,用于 FreeBSD 的内存管理,其分页大小如下

  ![](https://img-blog.csdnimg.cn/20200405111412897.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2IxMzAzMTEwMzM1,size_16,color_FFFFFF,t_70)

- libc 标准的 malloc 和 free

  - malloc 从操作系统的空闲内存地址的链表中获取到空闲内存块的首地址
  - new 类似于 malloc,两者都是内存分配地址,malloc 失败返回`NULL`,new 失败抛出异常,new 必定构造对象调用构造函数,new 的指针类型确定,malloc 的指针需要强制转换,默认返回`void*`,其次内存分配的区域,new可能会不同在自由存储区,而malloc和free在堆上分配内存.

- tcmalloc Thread-Caching Malloc 由 google 实现的分配内存库,应用在chrome,safari上,golang 的内存分配算法和此分配器类似,tcmalloc在内存空间的占用上更少,为每个线程都提供了缓存

上述内存分配器的对比

![](https://images0.cnblogs.com/blog/305638/201307/19092238-4bb8ae93278d4b8f8e8526fefde1d5d8.png)

> 查询频率不高的情景建议使用tcmallo，但查询结果较小并查询频率极高的情景下还是使用 jemalloc 

#### 内存回收

[redis-lru-cache](https://redis.io/topics/lru-cache)

##### 直接访问

直接访问key,如果发现key过期了会清除

##### 定期删除

redis会把所有设置了过期时间的key放到一个字典中,每隔10秒进行定期扫描.并且删除过期的key.其具体策略如下

1. 从过期字典中随机20个key
2. 删除这20个key中已过期的
3. 如果超过25%的key过期,则重复第一步

为了保证循环不会持续太长时间,循环的默认上限是25ms.

##### redis内存淘汰策略

当key超过了使用**最大的内存时(自己设置)**就会触发内存淘汰机制,首先可以如下设置,对于32位系统来说只能使用3GB内存

```
maxmemory 100mb
```

redis淘汰策略大致如下

- **noeviction**：当达到内存限制并且客户端尝试执行可能导致使用更多内存的命令时返回错误（大多数写命令，但[DEL](https://redis.io/commands/del)和一些例外）。
- **allkeys-lru**：通过首先尝试删除最近较少使用的 (LRU) 键来驱逐键，以便为添加的新数据腾出空间。
- **volatile-lru**：通过首先尝试删除最近使用的 (LRU) 键来驱逐键，但仅限于**设置**了**过期时间的**键，以便为添加的新数据腾出空间。
- **allkeys-random**：**随机**清除key以便为添加的新数据腾出空间。
- **volatile-random**：**随机清除**key以便为添加的新数据腾出空间，但仅驱逐具有**过期设置的**密钥。
- **volatile-ttl**：驱逐**设置**了**过期**时间的键，并尝试首先驱逐具有较短生存时间（TTL）的键，以便为添加的新数据腾出空间。

可以看到**volatile**针对于大部分设置了expire的key.如果没有设置expire那么这几这行为一致.

###### LRU算法

**LRU(Least Recently Used)**,即最近最少使用.Redis采用的是近似LRU.和常规LRU不太一样.常规LRU采用的是大小固定的队列,达到固定size之后,入队一个就出队一个,以保持内存中常驻key的稳定.

Redis LRU采用的是随机采样法,随机选择5个然后淘汰掉以前没使用过的key.可以通过`maxmemory-samples`来修改采样数量.和随机梯度下降一样,如果淘汰的次数足够多,那么整个算法就会收敛趋于稳定.如果采样的数量足够大,那么随机LRU就趋近于LRU.

LRU让每个key存储了一个24bit的时间轴,用以记录最后一次被访问的时间,redis3.0对LRU算法进行了一些优化.

新算法会维护一个候选池(这个候选池维护的是**将要被淘汰的key**),池中是按随机访问时间进行排序的,第一次进入池子是随机进入的,然后每次选取key,每次选取key都选择小于本池子中最小的(更久没被使用的),当池子放满之后,淘汰掉就近被访问的.算法的效果图如下

![](https://redis.io/images/redisdoc/lru_comparison.png)

- 浅灰色是被淘汰的数据
- 灰色是没有被淘汰掉的老数据
- 绿色是新加入的数据

所以我们看到误伤的数据还是比较少的.算法性能上也是redis3.0的新LRU会更好

**Least Frequently Used**是Redis4.0里面加入的一种新算法.根据key被访问的频率进行淘汰,上面LRU是根据key被访问的**时间**进行淘汰.lfu一共有两种策略,具体含义在上文中有讲述,和lru类似.

- volatile-lfu
- allkeys-lfu

针对lru和lfu可以发现,lfu更加适合热点数据,只有不经常被使用的数据会被淘汰掉,这样热点数据即使有段时间没被使用都会留在内存里面.



## 服务器线程模型

---

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

上面其实还可以拆分,注意到只有连接是需要等待三次握手完成才能accept出socket,所以单线程去处理连接请求,多线程去处理其他请求,可以尽可能的减少阻塞的部分.

### redis 的线程模型

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



## 数据结构

---

### redis数据结构

本章节主要讲redis实现的原理部分,涉及到数据结构,内存管理,线程模型,日志系统等.

[![img](https://camo.githubusercontent.com/cdbc35896f0346ec2c14830aac34bc38f7697e6fd54f9909f2a877d76bce1050/68747470733a2f2f696d67323031382e636e626c6f67732e636f6d2f626c6f672f313238393933342f3230313930362f313238393933342d32303139303632313136333933303831342d313339353031353730302e706e67)](https://camo.githubusercontent.com/cdbc35896f0346ec2c14830aac34bc38f7697e6fd54f9909f2a877d76bce1050/68747470733a2f2f696d67323031382e636e626c6f67732e636f6d2f626c6f672f313238393933342f3230313930362f313238393933342d32303139303632313136333933303831342d313339353031353730302e706e67)

我们看到其无外乎就五中数据结构

- string 充当基本缓存,可以充当计数器,可以序列化对象(比如session)
- hash 缓存,和hashmap类似
- list 双端链表,和Java中的linkedlist差不多,实现阻塞队列等,可以实现timeline
- set 集合不可重复支持交并补操作,无序,可以实现点赞收藏,或者是同种标签等
- **zset** 集合不可重复,通过分数排序(有序),可以实现排行榜

其类型存储如下

[![img](https://camo.githubusercontent.com/9c7aefec9c959ac12961e2c702ba29687312ef234555958ed08cd44f1f1e59be/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323030392f313939333234302d32303230303932323039333331373736392d313831383233323836322e706e67)](https://camo.githubusercontent.com/9c7aefec9c959ac12961e2c702ba29687312ef234555958ed08cd44f1f1e59be/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323030392f313939333234302d32303230303932323039333331373736392d313831383233323836322e706e67)

所以说hash实际的底层类型包括如下几种

- raw (simple dynamic string) 小字符串,需要分配两个对象sds,redisobj
- int
- embstr 只需要分配一个对象,区别于raw,只需要分配sds
- 
- ziplist 可压缩的ArrayList
- linkedlist 链表
- quicklist 结合了linkedlist和ziplist外层linkedlist,里层ziplist
- hashtable 即java中的hashmap
- inset 用hash进行去重保存在同一contents里面,按hash进行二分搜索
- skiplist zset特有,更好实现的红黑树

我们都知道redis是用C实现的,这里会设计部分C的源码,一个redisObject用下面的方式表示

```
typedef struct redisObject {
    unsigned [type] 4; // string hash list set zset之一
    unsigned [encoding] 4; // 对应右边的编码
    unsigned [lru] REDIS_LRU_BITS; // 表示本对象的空转时长
    int refcount; // 用于gc
    void *ptr; // 指向具体的实现
} robj;
```

[![img](https://camo.githubusercontent.com/1dbe8297561ee45f252799722ba322638d4f42b37a1cea6d1f00d1e7eba5ff4d/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323030392f313939333234302d32303230303932323039353535323935352d313736353436373235362e706e67)](https://camo.githubusercontent.com/1dbe8297561ee45f252799722ba322638d4f42b37a1cea6d1f00d1e7eba5ff4d/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323030392f313939333234302d32303230303932323039353535323935352d313736353436373235362e706e67)

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

- int
- raw (传统动态字符串,用于存储小于某一字节的字符串)
- embstr (用于存储大于某一字节的字符串)

embstr只需要分配一次内存,raw需要分配两次(一次为[`sds`](https://github.com/antirez/redis/blob/unstable/src/sds.h)分配对象,另一次为objet分配对象),sds对象(simple dynamic string),我们只是看其数据结构的定义

```
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

[![img](https://camo.githubusercontent.com/f7c0d12f00dc08bb931866e0356a53e9cd892a419b9997f690b8d241c7949c8c/68747470733a2f2f7365676d656e746661756c742e636f6d2f696d672f72656d6f74652f31343630303030303138383837323539)](https://camo.githubusercontent.com/f7c0d12f00dc08bb931866e0356a53e9cd892a419b9997f690b8d241c7949c8c/68747470733a2f2f7365676d656e746661756c742e636f6d2f696d672f72656d6f74652f31343630303030303138383837323539)

[![img](https://camo.githubusercontent.com/90d6854282b6f9049dcdf4eaec93267bed602fb7c77efaa648b46fc1894821b7/68747470733a2f2f7365676d656e746661756c742e636f6d2f696d672f72656d6f74652f31343630303030303138383837323630)](https://camo.githubusercontent.com/90d6854282b6f9049dcdf4eaec93267bed602fb7c77efaa648b46fc1894821b7/68747470733a2f2f7365676d656e746661756c742e636f6d2f696d672f72656d6f74652f31343630303030303138383837323630)

上图就可以清洗的看到其存储结构的不同

#### list

list有两种编码,ziplist和linkedlist.元素少的时候使用ziplist,元素多的时候使用linkedlist,关于linkedlist的设计思路,绝大多数语言中(例如java和python)都有本地类库的实现,此处就不再赘述.我们重点介绍ziplist

- linkedlist
- ziplist
- quicklist

zip的设计思路有点像ArrayList,其存储在连续的空间中,每次插入的复杂度是O(N),需要进行一次relloc,整个结构只需要malloc一次就能创建出来,其结构如下

[![120%](https://camo.githubusercontent.com/7b437f2d29515ce8ea52608c57cec921f32ab338848b7f7bc83cc0604e43fc13/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313130303530373835302d3834373230303839362e706e67)](https://camo.githubusercontent.com/7b437f2d29515ce8ea52608c57cec921f32ab338848b7f7bc83cc0604e43fc13/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313130303530373835302d3834373230303839362e706e67)

- zlbytes 整个链表所占的bytes
- zltail 链表的尾指针距离链表头指针的offset
- zlen 节点数量
- entry_i 具体的元素
- zlend 压缩链表的末端

和ArrayList一样不适合用来存需要经常修改的,比较大的元素,因为会涉及到复制移动,经常调度内存.

两种数据结构各有千秋,在比较新的版本里加入了quicklist,可以看做是linkedlist和ziplist的混合体.它将linkedlist按段切分,每一段使用ziplist来紧凑存储,多个ziplist之间使用双指针串接起来。

[![img](https://camo.githubusercontent.com/d646bf57093266db2ef0da3893f419c189e52c202c05ffe1eda5c2cbef8d82ec/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313130333332363938382d323034343734323439352e706e67)](https://camo.githubusercontent.com/d646bf57093266db2ef0da3893f419c189e52c202c05ffe1eda5c2cbef8d82ec/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313130333332363938382d323034343734323439352e706e67)

默认每个ziplist是8k,如果超出这个字节数会生成一个新的ziplist,可以使用`list-max-ziplist-size`来决定这个大小.为了节约空间,quicklist还是用了LZF压缩算法,对部分ziplist进行压缩

[![img](https://camo.githubusercontent.com/14a34ea2e8c75e94951849e5663b65fe820d479b9689d4ee49cf9bd3e491b4e4/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313131313730323630372d3934383534333734362e706e67)](https://camo.githubusercontent.com/14a34ea2e8c75e94951849e5663b65fe820d479b9689d4ee49cf9bd3e491b4e4/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313131313730323630372d3934383534333734362e706e67)

可由参数`list-compress-depth`指定压缩深度,所谓的压缩深度比如默认的0是不压缩,上图的压缩深度是1.各种值的含义如下

- 0: 是个特殊值,表示都不压缩。这是Redis的默认值。
- 1: 表示quicklist两端各有1个节点不压缩,中间的节点压缩。
- 2: 表示quicklist两端各有2个节点不压缩,中间的节点压缩。
- 3: 表示quicklist两端各有3个节点不压缩,中间的节点压缩。

借助上面的结构我们可以实现简单的消息队列

[![img](https://camo.githubusercontent.com/a4449f27d1d1fdd61181f9d2d4e63533106124c99154ca4455a3dce49417c049/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313131323334313138322d3231353835373932352e706e67)](https://camo.githubusercontent.com/a4449f27d1d1fdd61181f9d2d4e63533106124c99154ca4455a3dce49417c049/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030313131323334313138322d3231353835373932352e706e67)

#### hash

hashtable可以由ziplist或者hashtable来实现,当数量少的时候使用ziplist进行一次全表扫描更快获取结果,下面我们讲下hashtable,hashtable主要通过dict来实现

```
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

[![img](https://camo.githubusercontent.com/304fd14dcad7b499a7d4a2609eeb1b7168d7816b3ffc616b2f54faa28811f288/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323130353634343233372d313938303937303833382e706e67)](https://camo.githubusercontent.com/304fd14dcad7b499a7d4a2609eeb1b7168d7816b3ffc616b2f54faa28811f288/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323130353634343233372d313938303937303833382e706e67)

其数据结构几乎是和java的一致,是通过分桶来解决冲突的

[![img](https://camo.githubusercontent.com/b5e07826f678b7ce95c234152215afcd7743257f178e04770a56e8debde62c9b/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323130353932393030332d313038333731303334392e706e67)](https://camo.githubusercontent.com/b5e07826f678b7ce95c234152215afcd7743257f178e04770a56e8debde62c9b/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323130353932393030332d313038333731303334392e706e67)

在进行RDB时是不会去扩容的,但是如果hash表的元素个数已经到达了第一维数组长度的5倍的时候,就会强制扩容,不管你是否在持久化.相对而言还有缩容,缩容的条件是元素个数低于数组长度的10%.

rehash的步骤

1. 为ht[1] 分配空间,让字典同时持有ht[0]和ht[1]两个哈希表
2. (定时)维持一个索引计数器变量rehashidx,并将它的值设置为0,表示rehash开始；
3. 在rehash进行期间,每次对字典执行CRUD操作时,程序除了执行指定的操作以外,还会将ht[0]中的数据rehash到ht[1]表中,并且将rehashidx加一；
4. 当ht[0]中所有数据转移到ht[1]中时,将rehashidx设置成-1,表示rehash 结束;(采用渐进式rehash 的好处在于它采取分而治之的方式,避免了集中式rehash带来的庞大计算量.特别的在进行rehash是只能对ht[0]进行使得h[0]元素减少的操作,如查询和删除;而查询是在两个哈希表中查找的,而插入只能在ht[1]中进行,ht[1]也可以查询和删除)
5. 将ht[0]释放,然后将ht[1]设置成ht[0],最后为ht[1]分配一个空白哈希表.有安全迭代器可用,安全迭代器保证,在迭代起始时,字典中的所有结点, 都会被迭代到,即使在迭代过程中对字典有插入操作.

#### set

set可以是由两种编码类型构成

- hashtable (这个的实现方式和HashSet的思路一致就不赘述了)
- inset

我们主要来看inset

```
typedef struct intset {
    uint32_t encoding;
    uint32_t length; // 数组长度
    int8_t contents[]; // 实际保存元素的数据结构,没有重复元素,且元素从小到大排列
} intset;
```

查找元素使用的是二分法,复杂度为log(n),而如果才有hash,其复杂度为O(1).当然因为数据类型等一些不同,其实际操作的复杂度会因为扩容类型转换等有不同.我们看到的是inset只是单纯对数(存储内容)本身进行了升序排列,而zset是使用了一个score来进行排列

#### zset

zset保留了set的特性之外,还增加了根据score排序的功能,其也有两种实现方式

- ziplist
- skiplist

关于skiplist可以看下面具体的介绍,关于ziplsit可以看上面对于list的介绍.这里因为对两者都进行了排序所以都需要说明下.

前面我们知道了ziplist的数据结构.其按照下面的形式保存zset的分数.

[![img](https://camo.githubusercontent.com/a7a7413a6181c82396f1fa1d74665da5a5774af7a7a4683b5a01f404edf4e706/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323136303235323737362d313433353437303433362e706e67)](https://camo.githubusercontent.com/a7a7413a6181c82396f1fa1d74665da5a5774af7a7a4683b5a01f404edf4e706/68747470733a2f2f696d67323032302e636e626c6f67732e636f6d2f626c6f672f313939333234302f3230323031302f313939333234302d32303230313030323136303235323737362d313433353437303433362e706e67)

第一个节点用于保存其member,第二个节点用于保存其分数.如上示意图.关于skiplist可以看下面具体的操作介绍,我们来看其具体的数据结构.

```
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

- 实时排行榜,通过score很容易理解
- 延时队列,通过score表示时间戳
- score作为时间戳的限流

### 跳表skip-list

跳表是一种典型的空间换时间的数据结构

**跳跃表的插入** 首先我们需要插入几个数据。链表开始时是空的。 [![链表开始](https://camo.githubusercontent.com/5cb14ad79b1d0c72cc3897e4b8e1af0d7ee71dd3756ce95bbdcd599c79c02833/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f323031393036303831393532333532342e706e67)](https://camo.githubusercontent.com/5cb14ad79b1d0c72cc3897e4b8e1af0d7ee71dd3756ce95bbdcd599c79c02833/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f323031393036303831393532333532342e706e67) **插入 level = 3,key = 1** 当我们插入 level = 3,key = 1 时,结果如下： [![ level = 3,key = 1](https://camo.githubusercontent.com/fa00a7d65241ff53c98373ef1825ad6ea852ab74b976145799343e793bed9445/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323333313936352e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/fa00a7d65241ff53c98373ef1825ad6ea852ab74b976145799343e793bed9445/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323333313936352e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) **插入 level = 1,key = 2** 当继续插入 level = 1,key = 2 时,结果如下 [![level = 1,key = 2](https://camo.githubusercontent.com/92e48f982e2ba5b2c1d1f42cd0d13ccc1587bf6e9a9343ad32f7ad9ba33cf59e/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323533343532372e706e67)](https://camo.githubusercontent.com/92e48f982e2ba5b2c1d1f42cd0d13ccc1587bf6e9a9343ad32f7ad9ba33cf59e/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323533343532372e706e67) **插入 level = 2,key = 3** 当继续插入 level = 2,key = 3 时,结果如下 [![ level = 2,key = 3](https://camo.githubusercontent.com/1b7a4bbfc774e0e541358a87b6f3b327dd31ad38f0f1985ab7dc8919d9dc9a89/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323630383138362e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/1b7a4bbfc774e0e541358a87b6f3b327dd31ad38f0f1985ab7dc8919d9dc9a89/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323630383138362e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) **插入 level = 3,key = 5** 当继续插入 level = 3,key = 5 时,结果如下 [![level = 3,key = 5](https://camo.githubusercontent.com/3a6d38bd73b9b6c9e356b5a6d0ce2cbb3a1d16dcd6ece407f787ca69e1e1ef7a/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323632353936372e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/3a6d38bd73b9b6c9e356b5a6d0ce2cbb3a1d16dcd6ece407f787ca69e1e1ef7a/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323632353936372e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) **插入 level = 1,key = 66** 当继续插入 level = 1,key = 66 时,结果如下 [![ level = 1,key = 66](https://camo.githubusercontent.com/6d91ca8a2989e3e193954b521807a6eb3b52e61ca87d2b469923a72af8fac69f/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323634313434322e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/6d91ca8a2989e3e193954b521807a6eb3b52e61ca87d2b469923a72af8fac69f/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323634313434322e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) **插入 level = 2,key = 100** 当继续插入 level = 2,key = 100 时,结果如下 [![level = 2,key = 100](https://camo.githubusercontent.com/139fd2ff08b750e6c5c8a1b231e043f4c6a9246954313ed5f2f9d42a5ee3eaf4/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323635323839332e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/139fd2ff08b750e6c5c8a1b231e043f4c6a9246954313ed5f2f9d42a5ee3eaf4/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230323635323839332e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) 上述便是跳跃表插入原理,关键点就是层级–使用**抛硬币**的方式,感觉还真是挺随机的。每个层级最末端节点指向都是为 null,表示该层级到达末尾,可以往下一级跳。

跳跃表的查询

现在我们要找键为 **66** 的节点的值。那跳跃表是如何进行查询的呢？

跳跃表的查询是从顶层往下找,那么会先从第顶层开始找,方式就是循环比较,如过顶层节点的下一个节点为空说明到达末尾,会跳到第二层,继续遍历,直到找到对应节点。

如下图所示红色框内,我们带着键 66 和 1 比较,发现 66 大于 1。继续找顶层的下一个节点,发现 66 也是大于五的,继续遍历。由于下一节点为空,则会跳到 level 2。 [![顶层遍历](https://camo.githubusercontent.com/e983cb04da6ce6afed0bd38ce8bc5cdea71a25ea36d2d8d22d126f4c9253df77/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230343032363438372e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/e983cb04da6ce6afed0bd38ce8bc5cdea71a25ea36d2d8d22d126f4c9253df77/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630383230343032363438372e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) 上层没有找到 66,这时跳到 level 2 进行遍历,但是这里有一个点需要注意,遍历链表不是又重新遍历。而是从 5 这个节点继续往下找下一个节点。如下,我们遍历了 level 3 后,记录下当前处在 5 这个节点,那接下来遍历是 5 往后走,发现 100 大于目标 66,所以还是继续下沉。 [![第二层遍历](https://camo.githubusercontent.com/f4395e537629ee7193b9bd45ec2781414f326d57c7b5078cf2c0ed2ddb49dd59/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630393135353130353339332e706e67)](https://camo.githubusercontent.com/f4395e537629ee7193b9bd45ec2781414f326d57c7b5078cf2c0ed2ddb49dd59/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630393135353130353339332e706e67) 当到 level 1 时,发现 5 的下一个节点恰恰好是 66 ,就将结果直接返回。 [![遍历第一层](https://camo.githubusercontent.com/5a4bd551cbb3ca484b998c59678ea5758b2939d4c4835f753579ced6d860e6a7/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630393135353530333232352e706e67)](https://camo.githubusercontent.com/5a4bd551cbb3ca484b998c59678ea5758b2939d4c4835f753579ced6d860e6a7/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303630393135353530333232352e706e67)

**跳跃表删除** 跳跃表的删除和查找类似,都是一级一级找到相对应的节点,然后将 next 对象指向下下个节点,完全和链表类似。

现在我们来删除 66 这个节点,查找 66 节点和上述类似。 [![找到 66 节点](https://camo.githubusercontent.com/3e0dbbf9b0925ea32523c2107a9927ca92c57885a1d8675e2e64244941fa0b6e/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303631303134333331383837382e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/3e0dbbf9b0925ea32523c2107a9927ca92c57885a1d8675e2e64244941fa0b6e/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303631303134333331383837382e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) 接下来是断掉 5 节点 next 的 66 节点,然后将它指向 100 节点。 [![指向 100 节点](https://camo.githubusercontent.com/787cd2a4c87aa3bace71908db7f290fc0a4e2e067455929fa87ffd58a5f828fd/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303631303134333630393232392e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730)](https://camo.githubusercontent.com/787cd2a4c87aa3bace71908db7f290fc0a4e2e067455929fa87ffd58a5f828fd/68747470733a2f2f696d672d626c6f672e6373646e696d672e636e2f32303139303631303134333630393232392e706e673f782d6f73732d70726f636573733d696d6167652f77617465726d61726b2c747970655f5a6d46755a33706f5a57356e6147567064476b2c736861646f775f31302c746578745f6148523063484d364c7939696247396e4c6d4e7a5a473475626d56304c33646c61586870626c38304d5459794d6a45344d773d3d2c73697a655f31362c636f6c6f725f4646464646462c745f3730) 如上就是跳跃表的删除操作了,和我们平时接触的链表是一致的。当然,跳跃表的修改,也是和删除查找类似,只不过是将值修改罢了,就不继续介绍了。

查找节点复杂度logn

使用跳表而不用红黑树的原因

1. 在做范围查找的时候,平衡树比skiplist操作要复杂.在平衡树上,我们找到指定范围的小值之后,还需要以中序遍历的顺序继续寻找其它不超过大值的节点.如果不对平衡树进行一定的改造,这里的中序遍历并不容易实现.而在skiplist上进行范围查找就非常简单,只需要在找到小值之后，对第1层链表进行若干步的遍历就可以实现.
2. 平衡树的插入和删除操作可能引发子树的调整,逻辑复杂,而skiplist的插入和删除只需要修改相邻节点的指针,操作简单又快速.
3. 从内存占用上来说,skiplist比平衡树更灵活一些,一般来说,平衡树每个节点包含2个指针(分别指向左右子树),而skiplist每个节点包含的指针数目平均为1/(1-p),具体取决于参数p的大小.如果像Redis里的实现一样,取p=1/4,那么平均每个节点包含1.33个指针,比平衡树更有优势.





## 集群

---

