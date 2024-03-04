# LevelDB

---

[TOC]

## 前置

### 磁盘顺序写和随机写

这是计算机组织磁盘所决定的,如果使用磁盘这种存储进行读写要考虑巡道的问题,如果我们使用内存进行随机读写就没有这种问题,因为内存是固定内存颗粒的结构,[参考](http://t.zoukankan.com/yilang-p-11103061.html)其寻址方式和磁盘相比少了磁头的移动和开始地址的搜寻,其顺序读和随机读的性能差距不大,但如果我们看回磁盘的寻址,我们会发现其顺序读和随机读性能差距巨大

![](https://img-blog.csdnimg.cn/20190521200127319.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTA0NTQwMzA=,size_16,color_FFFFFF,t_70)

根据商业特性,我们只考虑机械硬盘,所以可以利用上面的特性专门为顺序写设计一个数据结构用以承载高性能的场景,一个典型的应用就是 kafka 和 LSM 组织文件的形式,所以从根本来看,LevelDB,RocksDB 本质上都是使用了磁盘顺序写比随机写快很多的特性.



### WAL

WAL 即 write ahead log 也称预写日志, mysql 的 redo-log 和 binlog 即是一个 WAL 日志,其结构非常简单,只有 append,但是基本没有随机读,想要找到某个数据只能通过 offset 去实现.大多数数据库的实现都依赖预写日志保证写不丢失.如 Hbase,RocksDB(TiDB),MongoDB 都使用了该种结构



### Bigtable





### LSM







