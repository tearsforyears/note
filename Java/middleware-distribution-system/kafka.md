# kafka

---

[TOC]

## kafka简介

<font color='#FFFF7F'>kafka 不保证消息全局有序,其只保证在某一个 partition 内有序,消费者消费 partiton 可能是随机的</font>

> Apache Kafka is an open-source distributed event streaming platform used by thousands of companies for high-performance data pipelines, streaming analytics, data integration, and mission-critical applications.

kafka 在设计之初就是以流数据处理系统为目标的,其作为一个消息队列绰绰有余,我们看下其他流平台

<img src="https://img2020.cnblogs.com/blog/1089984/202006/1089984-20200610080225004-690722209.png" alt="50" style="zoom:50%;" />

可以看到市面上的流平台很多,流平台本质上是为了解决**无限大小的数据集批处理**的问题.普通的批处理处理问题是有边界的,换言之就是有开始和结束.而流处理,如流媒体,则是要处理永不间断的数据流(data stream).这就是流平台和其他数据平台的不同.

简单想一下,一个for/并发程序能完成想要的功能吗?显然是可以的,但如果是为了处理更大的数据集就必定会引入分布式计算的手段.流平台不强调持久化,但是也拥有交付保证.有两种方法可以实现Streaming框架

*原生流处理*：
这意味着每条到达的记录都会在到达后立即处理，而无需等待其他记录。有一些连续运行的过程（根据框架，我们称之为操作员/任务/螺栓），这些过程将永远运行，每条记录都将通过这些过程进行处理。示例：Storm，Flink，Kafka Streams，Samza。

![img](https://img2020.cnblogs.com/blog/1089984/202006/1089984-20200610080319504-1718003550.png)

*微批处理*：
也称为快速批处理。这意味着每隔几秒钟就会将传入的记录分批处理，然后以单个小批处理的方式处理，延迟几秒钟。例如：Spark Streaming, Storm-Trident。

![img](https://img2020.cnblogs.com/blog/1089984/202006/1089984-20200610080325506-631418045.png)

> 两种方法都有其优点和缺点。
>
> 原生流传输感觉很自然，因为每条记录都会在到达记录后立即进行处理，从而使框架能够实现最小的延迟。但这也意味着在不影响吞吐量的情况下很难实现容错，因为对于每条记录，我们都需要在处理后跟踪和检查点。而且，状态管理很容易，因为有长时间运行的进程可以轻松维护所需的状态。
>
> 另一方面，微批处理则完全相反。容错是免费提供的，因为它本质上是一个批处理，吞吐量也很高，因为处理和检查点将在一组记录中一次性完成。但这会花费一定的等待时间，并且感觉不自然。高效的状态管理也将是维持的挑战。

Kafka 和其他流平台的对比

- Storm: 古老的流处理框架,原生流处理,缺少事件时间处理,聚合等
- Flink: Storm 的继任者,原生流处理,完善了 Storm 的一些功能
- Spark streaming: mini 批处理,不是真正的流,在流处理上不如 Flink
- Kafka streaming: 一个轻量级的库,需要和 kafka 配合使用,适合用于微服务的场景

Kafka和其他消息队列的对比

![](https://pic1.zhimg.com/80/v2-984876e8232372b9e16180c68927a378_720w.jpg?source=1940ef5c)

和所有消息队列一样,Kafka 是一种发布订阅模式.

<img src="https://images2018.cnblogs.com/blog/1228818/201805/1228818-20180507190443404-1266011458.png" alt="5" style="zoom:50%;" />

### kafka 中的基本概念

<img src="https://images2018.cnblogs.com/blog/1228818/201805/1228818-20180507190731172-1317551019.png" style="zoom:80%;" />

- broker 一个集群节点即是一个 broker
- partition 分区,逻辑意义上数据被分割成多少部分
  - partition 之间是无序的,partition 内是有序的,想要全局有序 partition 应该设为 1

- topic 话题
  - 如果一个 topic 有 N 个 partition,集群有 N 个 broker,每个 broker 都会存储 topic 的一个 partition
  - 如果某topic有N个partition，集群有(N+M)个broker，那么其中有N个broker存储该topic的一个partition，剩下的M个broker不存储该topic的partition数据
  - 如果某topic有N个partition，集群中broker数目少于N个，那么一个broker存储该topic的一个或多个partition。在实际生产环境中，尽量避免这种情况的发生，这种情况容易导致Kafka集群数据不均衡

- Producer 生产者
  - 生产者即数据的发布者，该角色将消息发布到Kafka的topic中。broker接收到生产者发送的消息后，broker将该消息**追加**到当前用于追加数据的segment文件中。生产者发送的消息，存储到一个partition中，生产者也可以指定数据存储的partition。

- Consumer 消费者
  - 每个Consumer属于一个特定的Consumer Group（可为每个Consumer指定group name，若不指定group name则属于默认的group）

- Leader
  - 每个partition有多个副本，其中有且仅有一个作为Leader，Leader是当前负责数据的读写的partition。

- Follower
  - Follower跟随Leader，所有写请求都通过Leader路由，数据变更会广播给所有Follower，Follower与Leader保持数据同步。如果Leader失效，则从Follower中选举出一个新的Leader。当Follower与Leader挂掉、卡住或者同步太慢，leader会把这个follower从“in sync replicas”（ISR）列表中删除，重新创建一个Follower。




## 基本操作

一些命令,首先kafka有操控远程的命令行需要去官网下载,不然可以通过Java SDK达到同样的效果.

```shell
sh kafka-topics.sh --list --zookeeper broker.kafka.dev.mobiu.space # 查看所有topic
sh kafka-topics.sh --create --zookeeper broker.kafka.dev.mobiu.space --replication-factor 1 --partitions 1 --topic test # 指定分区数和副本数创建topic
sh kafka-topics.sh --delete --zookeeper broker.kafka.dev.mobiu.space --topic test # 阐述topic
```

模拟测试的生产者

```shell
sh kafka-console-producer.sh --broker-list broker.kafka.dev.mobiu.space --topic test
```

测试模拟消费者

```shell
sh kafka-console-consumer.sh --zookeeper broker.kafka.dev.mobiu.space --topic test --from-beginning
```



## kafka 架构

我们看其逻辑分层,leader 是按照 topic 的 partition 为单位去选举的,partition 还拥有各自在不同节点的 replica .

![](https://images2018.cnblogs.com/blog/1228818/201805/1228818-20180507192145249-1414897650.png)

<img src="https://img2018.cnblogs.com/i-beta/1101486/202001/1101486-20200131203824562-1714355832.png" alt="4" style="zoom:67%;" />

**kafka 不保证消息全局有序,其只保证在某一个 partition 内有序**,消费者消费 partiton 可能是随机的.

从上面我们其实可以看到 zookeeper 是一协调服务,协调各个服务.kafka 的实际落盘数据一般有三个文件`.index .timeindex .log`,如果一个文件太大是会被分割的,partition 是物理意义上的概念,生产者生产的数据会不断加到这个 log 文件中,这是每个数据 offset 的来源,消费者记录自己消费了哪个 offset 下次会从当前位置往下消费.这个 offset 保存在 `.index` 文件和zookeeper中. 

<img src="https://img2018.cnblogs.com/i-beta/1101486/202001/1101486-20200131204141140-970059672.png" style="zoom:67%;" />

log 文件可能会很大,所以为了定位位置等,会分成多个 segment.如下,index左边为offset,右边为对应在文件中的位置.先通过二分法找 segment 的位置,然后通过offset确定具体在文件中的位置,分区出现的主要目的是为了提高性能.

![](https://img2018.cnblogs.com/i-beta/1101486/202001/1101486-20200131204046081-2047384973.png)

生产者发送消息可以在客户端指定哪个 partition 也可轮询消息到不同的 partiion 中去.

kafka 通过 ACK 来保证消息可靠到达 partition,如果没收到 ACK 则会重新发送数据

```note
所以kafka为用户提供了三种可靠性级别，用户可以根据可靠性和延迟进行权衡，这个设置在kafka的生成中设置：acks参数设置

A、acks为0
生产者不等ack，只管往topic丢数据就可以了，这个丢数据的概率非常高

B、ack为1
Leader落盘后就会返回ack，会有数据丢失的现象，如果leader在同步完成后出现故障，则会出现数据丢失

C、ack为-1（all）
Leader和follower（ISR）落盘才会返回ack，会有数据重复现象，如果在leader已经写完成，且follower同步完成，但是在返回ack的出现故障，则会出现数据重复现象；极限情况下，这个也会有数据丢失的情况，比如follower和leader通信都很慢，所以ISR中只有一个leader节点，这个时候，leader完成落盘，就会返回ack，如果此时leader故障后，就会导致丢失数据
```

Kafka 通过 HW (high water) 来保证消费数据的一致性,即消费者只能看到更新最少量的数据,后面的数据看不到了也消费不到

![](https://img2018.cnblogs.com/i-beta/1101486/202001/1101486-20200131204307789-990426704.png)

```note
A、Follower故障
Follower发生故障后会被临时提出LSR，待该follower恢复后，follower会读取本地的磁盘记录的上次的HW，并将该log文件高于HW的部分截取掉，从HW开始想leader进行同步，等该follower的LEO大于等于该Partition的hw，即follower追上leader后，就可以重新加入LSR

B、Leader故障
Leader发生故障后，会从ISR中选出一个新的leader，之后，为了保证多个副本之间的数据一致性，其余的follower会先将各自的log文件高于hw的部分截掉（新leader自己不会截掉），然后从新的leader同步数据

注意：这个是为了保证多个副本间的数据存储的一致性，并不能保证数据不丢失或者不重复
```

### Kafka 高效的原因

- 顺序写日志落盘
- 零复制技术(内核优化),即把需要拷贝到内核中的数据直接变成了流去处理

## Kafka Streaming



