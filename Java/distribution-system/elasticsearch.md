# Elasticsearch

---

分布式搜索引擎.基于Lucene

[TOC]



## Lucene

Lucene是一个全文检索的工具包.由Apache基金会维护,是开源的信息检索库.其主要做的功能就是全文索引和搜索.

### 倒排索引

有以下文档

| DocId | Doc                                            |
| ----- | ---------------------------------------------- |
| 1     | 谷歌地图之父跳槽 Facebook                      |
| 2     | 谷歌地图之父加盟 Facebook                      |
| 3     | 谷歌地图创始人拉斯离开谷歌加盟 Facebook        |
| 4     | 谷歌地图之父跳槽 Facebook 与 Wave 项目取消有关 |
| 5     | 谷歌地图之父拉斯加盟社交网站 Facebook          |

对文档进行分词之后，得到以下**倒排索引**.可以看到其是由(文档id,文档内容)的kv结构转变为(关键词,文档id)的内容结构,维护全文的词频信息.

| WordId | Word     | DocIds    |
| ------ | -------- | --------- |
| 1      | 谷歌     | 1,2,3,4,5 |
| 2      | 地图     | 1,2,3,4,5 |
| 3      | 之父     | 1,2,4,5   |
| 4      | 跳槽     | 1,4       |
| 5      | Facebook | 1,2,3,4,5 |
| 6      | 加盟     | 2,3,5     |
| 7      | 创始人   | 3         |
| 8      | 拉斯     | 3,5       |
| 9      | 离开     | 3         |
| 10     | 与       | 4         |
| ..     | ..       | ..        |



## Elasticsearch

Elasticsearch基于上面的包来实现分布式的搜索引擎,提供了更丰富的查询语言,我们可以通过Http restful接口和java api去访问到Elasticsearch的接口.直接使用Lucene需要集成大量的接口.下面我们用ES简称`Elasticsearch`.在ES没有的时候,一般使用Solr作为搜索引擎去使用.ES具有如下特性

-   分布式文档存储引擎
-   分布式搜索引擎和分析引擎
-   支持PB级数据

### 对比Solr

-   ES仅支持JSON格式文档
-   Solr要利用Zookeeper,ES自己就具有分布式协调功能
-   Solr拥有高级功能,ES更加轻量级由若干第三方插件实现可视化等高级功能
-   ES擅长处理实时应用,在实时领域比Solr效率更高,Solr擅长处理传统应用.

### Elasticsearch基本概念

#### Near RealTime

显然这种分布式系统是弱一致性的(BASE),写入数据到可以搜索(建立索引)大概有1S的延迟.基于ES执行搜索和分析可以达到秒级.

#### Document & Field

通常这里说的document是通常是json数据结构.和MongoDB的文档是一致的.例如

```json
{
    "product_id": "1",
    "product_name": "iPhone X",
    "product_desc": "苹果手机",
    "category_id": "2",
    "category_name": "电子产品"
}
```

每一个key称为field.

#### Index & Type

索引Index包含了许多相似的文档,比如商品索引,每个索引下又有多个Type.

#### shard & replica

碎片/分片(shard)和副本(replica),前者是解决海量数据的存储问题,后者是增加该数据系统的可用性.其集群可能是如下的存储形式

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214054870-834299590.png)

写入过程如下,采用的是cluster模式.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214131462-836539718.png)

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214145546-584371096.png)

#### 数据格式总结

| Elasticsearch | mysql    |
| ------------- | -------- |
| index         | 数据库   |
| type          | 数据表   |
| docuemnt      | 一行数据 |



### 使用搜索引擎



### 插件



### 细节和原理

#### 集群模式

ES是典型的cluster模式和MS模式,即内部使用分片机制,集群发现,分片负载均衡请求路由.ES把一个完整的索引拆成多个分片(shard),把数据分布到不同的节点上.分片的数量不可动态伸缩,副本replica作为数据的高可用机制也被分配在不同的节点上.且replica可以被负载均衡,能提高数据系统的吞吐量.**shard的数量是不可以改的,但replica数量是可以更改的**,不同的shard不会被存放在本服务器上,为了容灾会放在其他服务器上.

我们讨论下负载均衡算法,当创建document的时候,使用如下的方式确定该放在哪个分片上,我们也可以看到数据分片被固定的原因.

```note
shard = hash(routing) % number_of_primary_shards
```

![](https://img2018.cnblogs.com/blog/1555009/201906/1555009-20190611001903480-872125010.png)

有些文档里面说到主分片和副分片,指的是(primary shard)和(replica shard),所谓的主分片是对索引进行的分片,而来一个document要决定在index的那个主分片里面,相对应的副分片(副本分片)应该要把数据同步到上面.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214131462-836539718.png)

我们知道ES节点是有协调功能的,而Cluster并不能做到这点,ES还有MS模式,和Cluster模式共存.**这里需要注意索然ES集群有master节点,但其读写模式用的是cluster,MS模式仅作为协调**.ES会利用分布式选举出master节点,当master节点挂掉的时候就会切换master.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214145546-584371096.png)



### 写入和读取

#### 写入

-   写入的时候客户端是向协调节点(coordinating node)写
-   协调节点根据hash算出应该放在哪个primary shard然后放上去
-   相应的replica shard进行同步,同步完了之后返回响应结果给客户端

这里要注意下,**协调节点可以是每个节点,根据客户端的选择的节点有不同的协调节点**.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214202363-408958988.png)

写数据到线程时候是先写入缓冲区的,然后写入的时候在同步日志文件.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214213519-987528358.png)



#### 读取

和写入一样,读取也是分协调节点的.协调节点会算出在哪个primary shard上.

-   客户端访问协调节点进行读
-   协调节点从所有带有replica shard,primary shard的节点上选择一个读取
-   读取完了结果返回给协调节点,协调节点把结果返回给客户端



#### 搜索过程

上面我们说的是分片,但读取的过程不全是搜索的过程,因为要搜索的数据很可能是分布在不同的分片上的.这个过程其实也不复杂,就是让所有节点都去搜索,然后协调结果最后合并结果返回给客户端即可.

-   客户端访问协调节点进行读
-   协调节点把搜索请求转发给所有含有index的shard节点.
-   query phase 所有节点把自己搜索的结果返回给协调节点(doc id),由协调节点进行数据的合并分页等.
-   fetch phase 协调节点根据这些doc id去相应的shard拉取doc的数据.



### 调高查询性能

我们看其读写过程.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214213519-987528358.png)

系统的瓶颈在filesystem cache.如果给filesystem cache更多的内存,那么ES就基本是走内存去存的,如果走磁盘的搜索基本是秒级.如果走内存基本是毫秒级的.可如下分配内存

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214229417-987447848.png)

#### 只存储索引

然后就是搜索字段才存入ES,这样就可以尽量节省数据,意思是ES只用来存储索引.所以其他字段一般存入Hbase或者是mysql里面.一般使用hbase+elasticsearch架构.用ES单纯用作索引就好.

#### 数据预热

这个不难理解,把可能会被索引到的数据提前用ES搜索一次,建立好索引,刷新在filesystem cache里面即可提高整体效率.对于常年热门的数据,做一个专门的子系统用来进行数据预热.

#### 冷热分离

把冷数据写进一个索引中,然后热数据写入另一个索引中.这样可以确保数据预热后,尽量留在`filesystem os cache`中.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214248335-1581895054.png)

然后尽量避免复杂查询.
















