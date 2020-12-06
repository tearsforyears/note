# 分布式数据系统

kalfka是一个缓冲队列用于实现消息系统

Nosql中Mongodb和redis就实现了类似的功能

其他的数据系统 例如MapReduce/Spark更擅长计算而不是存储

所以从这个角度上来看 分布式存储要求比较高的数据查询修改结构的能力

说起分布式就不得不提到Hadoop和Spark以及搜索引擎elasticsearch

-   HDFS,MapReduce和Spark算子

    HDFS是整个Hadoop/Spark里面最终要的存储体系

    只不过Hadoop的中间结果需要落地磁盘Spark可以临时存放到内存

    所以需要计算查询的数据可以用sprak常驻内存 其他落地磁盘

-   Zookeeper,Yarn协调调度

    

-   redis

    持久化

    RDB(redis database) 数据库快照存储到disk上

    AOF(append only file) 日志记录指令,根据指令复现数据库

    如果不采用持久化策略 其功能的memcache基本一致

    #### redis的集群模式

    -   主从模式 没有HA

        master数据库进行读写 slave数据库进行读因为读请求远大于写请求(只要是存储系统应用都有的)如果节点挂了之后不影响slave的读 但写会暂时中断

    -   sentinel模式 sentinel是哨兵

        具备HA 建立在M-S模式之上 其主要思想就是由sentinel监测这样一个M-S模式

        类似选举的方式产生新的Master节点

    -   Cluster模式

        一主一从 或者多主一从 从节点不提供服务只作为备用

        所以这个模式下 我们需要6个节点才能建立起redis集群

-   redis和memcache

    redis是一个强大的分布式内存为主数据库

    支持持久化以及list set hash string 等多种类型的数据系统

    zset支持排序 有一定的数据能力

    但redis更多是用于对内存性数据的存储 功能强大

    其持久化只是用于内存不够的情况下的抗风险能力

    适合频繁访问

    而memcache则更倾向于第三方分布式缓存只有存储能力 对于其计算能力是没有的 当然其存储效率比redis要高 

    其他一些方面

    ```
    从内存管理方面来说，redis也有自己的内存机制，redis采用申请内存的方式，会把带过期时间的数据存放到一起，redis理论上能够存储比物理内存更多的数据，当数据超量时，会引发swap，把冷数据刷到磁盘上。而memcache把所有的数据存储在物理内存里。memcache使用预分配池管理，会提前把内存分为多个slab，slab又分成多个不等大小的chunk，chunk从最小的开始，根据增长因子增长内存大小。redis更适合做数据存储，memcache更适合做缓存，memcache在存储速度方面也会比redis这种申请内存的方式来的快。
    ```

    