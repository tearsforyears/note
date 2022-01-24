# kafka

---

[TOC]

## kafka简介

kafka 在设计之初就是以流数据处理系统为目标的,其作为一个消息队列绰绰有余,我们对比下其他流平台

![](https://img2020.cnblogs.com/blog/1089984/202006/1089984-20200610080225004-690722209.png)



和其他消息队列的对比

![](https://pic1.zhimg.com/80/v2-984876e8232372b9e16180c68927a378_720w.jpg?source=1940ef5c)





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
