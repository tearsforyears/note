# kafka

---



[TOC]

### kafka简介

传统架构一般是如下.DB和cache是为了应对存取的需求,而ES是为了全文检索日志(ELK)和Hadoop是为了理解用户行为进行离线数据的处理,这样的系统相较而言错综复杂,未来有可能引入实时模块和外部发生交互.

![](https://pic2.zhimg.com/80/v2-54ce5889e9445f43cc8712443865fce2_720w.jpg?source=1940ef5c)

Kafka可以让合适的数据以合适的形式出现在合适的地方.Kafka的做法是提供消息队列,让生产者单往队列的末尾添加数据,让多个消费者从队列里面依次读取数据然后自行处理.

![](https://pic1.zhimg.com/80/v2-7ddccdcd1e287b0c95a643a040a0afec_720w.jpg?source=1940ef5c)

从这里能看到kafka本身有数据集成的作用以Pub/Sub形式的消息总线形式提供.其有如下特性

- sub/pub模式对海量数据的处理
- 以高容错的方式存储海量数据流
- 保证数据流的顺序

相比于其他消息队列,kafka作为一个流式处理平台.kafka是一个成熟的系统,高吞吐量的分布式提交的日志(Kafka Connect和Kafka Streams)

Redis PUB/SUB使用场景

1. 消息持久性需求不高
2. 吞吐量要求不高
3. 可以忍受数据丢失
4. 数据量不大

Kafka使用场景

1. 高可靠性
2. 高吞吐量
3. 持久性高
4. 多样化的消费处理模型

#### 消息队列使用场景

消息队列的特性是用来沟通不同系统之间的,所以其强调的也是BASE,即核心是最终一致性,而非强一致性,这让消息队列有了很好的分布式系统的特性,而作为分布式系统的kafka可以做到这一步.

消息队列的四个常见的使用场景

- 解耦 (生产者和消费者可以更换)
- 异步
- 广播(消息分发)
- 削峰

使用消息队列的系统需要设计满足以下特性

- 生产者不需要从消费者中获取反馈
- 可以容忍最终一致性,而不强调强一致性

![](https://pic4.zhimg.com/80/v2-2c1b76c33d54ae173e55b0830202cce9_720w.jpg?source=1940ef5c)

一般来讲系统的演化可能如上.为了提高上述系统的性能,我们就可以对上面的系统进行异步处理

![](https://pic1.zhimg.com/80/v2-f7bc2f81a4839f5988b5b1baf60c4c67_720w.jpg?source=1940ef5c)

同时还得解耦，如果用线程池执行上面逻辑的话,还需要写不少接口.我们讨论下可能会遇到的问题

- 数据一致性问题

比如上述系统,怎么确保每个系统都成功执行了呢?可以通过分布式事务来解决,进行关键数据的回滚.

- 消息队列的高可用

同类产品的一些对比,对于消息分发我们看到单纯的Rocket具有更强的吞吐量,RocketMQ和Kafka都具有非常高的可用性.

![](https://pic1.zhimg.com/80/v2-984876e8232372b9e16180c68927a378_720w.jpg?source=1940ef5c)



## 维护消息队列可能会遇到的问题

- 重复消费
- 消息丢失
- 顺序消费

我们在后续会去介绍 kafka 是如何解决这种问题的



---

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











## kafka 服务器结构
