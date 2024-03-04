# bigtable

---

[toc]

## Reference

[bigtable](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/bigtable-osdi06.pdf)

[bigtable精读](https://hardcore.feishu.cn/docs/doccnY21HwJO8LckMKEGMTzvm2g)

## Introduce

BigTable是一个稀疏的、分布式的、持久化存储的多维排序Map.Map 的索引是行,列,以及时间戳

```go
(row:string,column:string,time:int64)->string
```

我们考虑一个网站存储的数据库

![](https://img.snaptube.app/image/em-video/04fd764b175ccffd177c296c81460db6_618_203.png)

如上图,我们把域名的反写 com.cnn.www 作为行索引(使用字典序),把网页本身存储到 contents 列, anchor 包含引用这个页面的网页.然后每一份数据有其对应的时间戳.反写域名作为一种字典序的应用,我们可以利用字典序数字访问的相关性,把统一域名下的网页组织成连续的行.

### 行

在并发上 bigtable 的设计是以行为粒度的,**对于同一个行关键字的读和写都是原子的**. bigtable 的行是最大 64kb 的字符串,通过行关键字的字典顺序来组织数据.表中的每一个行都是可以动态分区的.每个分区叫 tablet 为负载均衡调整的最小单位.如果只是取比较少的几列数据,显而易见的能获得性能的提升.

### 列

>  Column keys are grouped into sets called column families, which form the basic unit of access control.

columns families 即若干列组成的集合,以 `family:qualifier`的方式命名.访问控制,磁盘和内存的使用层面都是在 column familiy 上进行的.

### Timestamp

