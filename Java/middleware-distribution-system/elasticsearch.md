

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

### API及使用

```shell
curl localhost:9200 # 查看说明信息
curl 'localhost:9200/_cat/indices?v' # 查看索引
curl 'localhost:9200/{index}/{type}/_search?pretty&q={content}' # 收缩index下type类型,含有content的内容
# &from=0&size=2 等价于 limit 0,2
# &sort=created_on:asc &sort=created_on:desc sort=_score 排序
# _source=organizer,description 指定哪些属性返回
screen -S mfmc mfmc -w 9090
curl --socks5 127.0.0.1:9090 '..../video/_search?pretty&q=T&from=0&size=1'
curl --socks5 127.0.0.1:9090 '..../video/UNBdGWIBI2NcsxokJ0lQ' # 根据id查询video
```

#### Java

本质上,其使用的也是Restful请求,我们利用Java的SDK可以构建请求,这里需要说明下其有三种客户端rest-high-level-client,rest-low-level-client,TransportClient.low-level和high-level是相对封装层次而言的.TransportClient分发查询数据比较慢,但启动较快.下面以High-level进行说明.需要说明的是其具有两种变成风格,一种是同步的,一种是异步的操作.我们讲解同步的操作方式,异步的方式可以通过添加监听器监控其回调操作.

```xml
<!-- 下用到的版本是基于 6.0.0 的 -->
<dependency>
  <groupId>org.elasticsearch</groupId>
  <artifactId>elasticsearch</artifactId>
</dependency>
<dependency>
  <groupId>org.elasticsearch.client</groupId>
  <artifactId>elasticsearch-rest-client</artifactId>
</dependency>
<dependency>
  <groupId>org.elasticsearch.client</groupId>
  <artifactId>elasticsearch-rest-high-level-client</artifactId>
</dependency>
```

```java
@Configuration
public class ElasticsearchConfig {

  @Bean(destroyMethod = "close")
  public RestHighLevelClient buildTransportClient(
      @Value("${elasticsearch.endpoints}") List<String> endpoints) {
    RestClientBuilder builder = RestClient.builder(
        endpoints.stream()
            .map(s -> {
              try {
                URI uri = new URI(s);
                return new HttpHost(uri.getHost(), uri.getPort(), uri.getScheme());
              } catch (Exception e) {
                throw new RuntimeException(e);
              }
            }).toArray(HttpHost[]::new)
    ).setRequestConfigCallback(requestConfigBuilder -> requestConfigBuilder
        .setConnectTimeout(500).setSocketTimeout(500));
    return new RestHighLevelClient(builder);
  }
}
```

新增更新和删除以及简单获取

```java
Map<String, Object> map = new HashMap<String, Object>();
UpdateRequest updateRequest = new UpdateRequest("{index}","{type}", "{id}").doc(map);
UpdateResponse updateResponse = client.update(updateRequest, RequestOptions.DEFAULT);
System.out.println(updateResponse.status());

DeleteRequest request = new DeleteRequest("{index}","{type}","{id}");
DeleteResponse delete = client.delete(request, RequestOptions.DEFAULT);

GetRequest posts = new GetRequest("{index}","{type}","{id}");
GetResponse response = client.get(posts, RequestOptions.DEFAULT);
System.out.println(response.getId());
System.out.println(response.getIndex());
System.out.println(response.getSourceAsString());
System.out.println(response.getSourceAsMap());
```

搜索

```java
@Autowired
RestHighLevelClient client;

QueryBuilder titleQueryBuilder =
        QueryBuilders.matchQuery(TITLE.getOrDefault(area, Video.TITLE), keyword)
            .analyzer(ANALYZERS.getOrDefault(area, "english")) // 指定分词器
            .fuzziness(Fuzziness.AUTO)
            .fuzzyTranspositions(true) // 模糊查询 需要分词器
            .prefixLength(2)
            .maxExpansions(5);

SearchRequest searchRequest = new SearchRequest() // 拼接的那串url参数
  .indices(Video.INDEX_NAME)
  .types(Video.TYPE_NAME)
  .source(new SearchSourceBuilder()
          .fetchSource("id", null)
          .from(offset) // 分页参数
          .size(limit)
          .query(titleQueryBuilder)
          .timeout(new TimeValue(10, TimeUnit.SECONDS))
    );

SearchResponse response = client.search(searchRequest);
```

其含义我们来看如下代码段

```java
SearchSourceBuilder sourceBuilder = new SearchSourceBuilder();
SearchRequest rq = new SearchRequest();
// 索引
rq.indices(index);
// 各种组合条件
rq.source(sourceBuilder);
// 请求
System.out.println(rq.source().toString());
SearchResponse rp = client.search(rq);
```

我们看下queryBuilder的参数

```java
// 参数，用于是否需要过滤
String[] includeFields = new String[]{"id"};

QueryBuilder queryBuilder = QueryBuilders
  .matchQuery("{docFieldName}","{keyword}")
  .matchQuery("{docFieldName}","{keyword}") // 查询一个或者多个字段匹配
  .sort(new FieldSortBuilder("id").order(SortOrder.ASC)) // 排序,需要注意默认序是按照score相关度的情况
  // .fetchSource(false)
  // 第1个参数是 需要显示的字段，第2个参数是需要过滤的字段
	.fetchSource(includeFields, null);
```

除了match之外,可以用如下方法进行匹配

- matchQuery 匹配单个字段
- multiMatchQuery 多个字段匹配某一个值
- wildcardQuery 模糊查询,`?`匹配单个字符`*`匹配多个字符
- BoolQueryBuilder 复合查询

```java
WildcardQueryBuilder queryBuilder1 = QueryBuilders.wildcardQuery("name", "*jack*");
// 搜索名字中含有jack的文档
WildcardQueryBuilder queryBuilder2 = QueryBuilders.wildcardQuery("interest", "*read*");
// 搜索interest中含有read的文档
BoolQueryBuilder boolQueryBuilder = QueryBuilders.boolQuery();
// name中含有jack或者interest含有read，相当于or
boolQueryBuilder.should(queryBuilder1);
boolQueryBuilder.should(queryBuilder2);
// 相当于and
boolQueryBuilder.must(queryBuilder1);
boolQueryBuilder.must(queryBuilder2);
```

#### 搜索与查询与过滤

ES提供了非常多的查询方式,此节阅读应在对ES的使用方式和原理有了基本了解之后.查询的方式叫DSL.

term译为轮,周期,在ES中是指**分词后的结果**.下面用json来表示请求的内容.[参考文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-your-data.html),请求如下url即可查询查询

##### 精确匹配

```shell
curl -X GET "host/{index}/_search?pretty" -H 'Content-Type: application/json' -d'{
  "query": {
    "match": {
      "user.id": "kimchy"
    }
  }
}'
```

```json
{ 
 "query": { 
     "term": { 
       "songName.keyword": { 
         "value": "7k - Ao Vivo", 
         "boost": 1.0 
       } 
     } 
   } 
}
```

精确匹配到value,可以匹配多个词

```json
{ 
 "query": { 
     "term": { 
       "songName.keyword": [{"value": "7k - Ao Vivo","boost": 1.0}, {"value": "7k","boost": 1.0}]
     } 
   } 
}
```

**这里需要注意**,如果精确查找是诸如 ugc-st 这样的词,则在分词器的指引下会分割成 ugc,st 两个词无法被精确查找,有两种解决方案,利用短语匹配或者增加索引

```json
PUT /my_store 
{
    "mappings" : {
        "products" : {
            "properties" : {
                "productID" : {
                    "type" : "string",
                    "index" : "not_analyzed" 
                }
            }
        }
    }
}
```



##### 模糊查询

```json
{ 
 "query": { 
   "fuzzy": { 
     "songName.keyword": { 
       "value": "Quem Mondou Chamer", # Mondou 错误，Chamer 错误  "fuzziness": "AUTO", 
       "max_expansions": 50, 
       "prefix_length": 0, 
       "transpositions": true 
       } 
     } 
   } 
}
```

##### 前缀查询

```json
{ 
 "query": { 
 "prefix": { 
 "songName": "7k" 
 } 
 } 
}
```

##### 通配符查询

```json
{ 
 "query": { 
 "wildcard": { 
 "songName": { 
 "value": "7?",  # 允许使用 ? * 进行查询
 "boost": 1.0 
 } 
 } 
 } 
}
```

这里说下在HighLevelClient中如何使用

```java
QueryBuilder uniCategoryQueryBuilder = new WildcardQueryBuilder("songName", "7?");
```

如果是要使用复合查询可以参考`new BoolQueryBuilder()`的should,must,filter方法

##### 范围查询

```json
{ 
 "query": { 
 "range": { 
 "age": { 
 "gte": 10, 
 "lte": 20, 
 "boost": 2.0 
 } 
 } 
 } 
}
```

##### 是否存在某字段

```json
{ 
 "query": { 
 "exists": { 
 "field": "songName" 
 } 
 } 
}
```

##### 复合查询

复合/布尔查询有四种过滤器

- must 相当于 and
- filter 所有自子句都必须匹配,此处查询属于 filter context 不属于 query context 即实际效果是查询与 score 无关
- should 相当于 or
- must_not

下面用Java代码描述,即可理解为必须匹配上此类条件,且不使用score

```java
BoolQueryBuilder boolQueryBuilder = new BoolQueryBuilder()
.filter(new TermQueryBuilder(Video.CAN_SHOW, true))
.filter(new TermQueryBuilder(Video.UNI_STATUS, true))
.filter(QueryBuilders.rangeQuery(Video.LOW_QUALITY_RATING).gte(5));
```

##### Boosting Query

因为除了filter以外的查询都会使用到score,有些时候需要降权或者升权.

```json
{ 
 "query": { 
 "boosting": { 
 "positive": { # 想匹配的内容
 "term": { 
 "artistNames.keyword": "Luiz De Carvalho" 
 } 
 }, 
 "negative": {  # 不想匹配的内容
 "term": { 
 "albumName.keyword": "Pobre Peregrino, Vol. 3" 
 } 
 }, 
 "negative_boost": 0.5 # 降权,即含有下列内容的文档分数下降
 } 
 }
}
```

##### Dis Max Query

分离化查询,如果文档匹配到了A,B,C三个字句,只把最佳匹配结果返回,可以通过tie_breaker确定权重

```shell
curl -X GET "localhost:9200/test/_search?pretty" 
{ 
 "query": { 
 "dis_max": { 
 "queries": [ 
 { "match": { "title": "java beginner" }}, 
 { "match": { "content": "java beginner" }} 
 ], 
 "tie_breaker": 0.7 
 } 
 } 
}
```

三个文档如下

```shell
# ⽂档⼀ 
title: "i like java", # 0.4 
content: "i am beginner" # 0.4 
# ⽂档⼆ 
title: "i like python", # 0.0 
content: "i am beginner", # 0.4 
# ⽂档三 
title: "i like it", # 0.0 
content: "i am java beginner" # 0.7 
```

```note
tie_breaker = 1 的情况下 
⽂档⼀: 0.4 + (1 * 0.4) = 0.8 
⽂档⼆: 0.4 + (1 * 0.0) = 0.4 
⽂档三: 0.7 + (1 * 0.0) = 0.7 
tie_breaker = 0.5 的情况下 
⽂档⼀: 0.4 + (0.5 * 0.4) = 0.6 
⽂档⼆: 0.4 + (0.5 * 0.0) = 0.4 
⽂档三: 0.7 + (0.5 * 0.0) = 0.7
```

按照此为score返回数据

##### Function Score Query

自定义搜索文档所占的权重

```json
{
 "query": { 
 "function_score": { 
 "query": { "match_all": {} }, 
 "boost": "5", 
 "functions": [ 
   { 
   "filter": { "match": { "test": "bar" } }, 
   "random_score": {}, 
   "weight": 23 
   }, 
   { 
   "filter": { "match": { "test": "cat" } }, 
   "weight": 42 
   } 
 ], 
 "max_boost": 42, 
 "score_mode": "max", // 各个函数得到的分数如何处理,比如这里是上面函数的最大值作为文档分数
 "boost_mode": "multiply", 
 "min_score": 42 
 } 
 } 
}
```

除此之外我们还希望通过点赞数之类字段添加权重

```json
{ 
 "query": { 
 "function_score": { 
 "query": { 
 "match": { 
 "title": "⼀剪梅" 
 } 
 }, 
 "field_value_factor": {  // 此字段增加权重
 "field": "likes", 
 "modifier": "sqrt", 
 "factor": 0.1 
 }, 
 "boost_mode": "sum" 
 } 
 } 
} 
// score = score + sqrt(1 + 0.1 * likes) 
```

随机的排序结果,可也通过指定seed来实现

```json
{ 
 "query": {"function_score": { 
 "query": {"match": { 
 "title": "⼀剪梅" 
 }}, 
  
 "random_score": { 
 "seed": 1, 
 "field": "uuid" 
 }, 
 "boost_mode": "replace" 
 }} 
}
```

我们可以根据递减函数查找想要的数据,比如距离

```json
{ 
 "query": { 
 "function_score": { 
 "query": { 
 "match": { 
 "title": "公寓" 
 } 
 }, 
 "gauss": { // 此处函数可以指定 linear exp gauss
 "location": { 
 "origin": { "lat": 40, "lon": 116 }, 
 "offset": "3km", 
 "scale": "7km" 
 } 
 }, 
 "boost_mode": "sum" // function和原始分的处理方式
 } 
 }
}
```

或者是通过自定义脚本的方式去实现规则

```json
{ 
 "query": { 
 "function_score": { 
 "query": { 
 "match": { "message": "elasticsearch" } 
 }, 
 "script_score": { 
 "script": { 
 "source": "Math.log(2 + doc['my-int'].value)"
 } 
 } 
 } 
 } 
}
```

上面的score_mode和boost_mode最终的选择如下

- multiply 分数相乘 
- sum 分数相加 
- avg 求平均 
- first 取第⼀个函数的分数 
- max 取最⼤的函数分数 
- min 取最⼩的函数分数 

boost_mode

- multiply 相乘 
- replace 函数分替代原始查询分 
- sum 求和 
- avg 函数分和查询分的平均值 
- max 函数分与查询分取最⼤ 
- min 函数分与查询分，取最⼩ 

##### 全文检索

间隙搜索

```json
{ 
 "query": { 
 "intervals" : { 
 "my_text" : { 
 "all_of" : { 
 "ordered" : true,
 "intervals" : [ 
 { 
 "match" : { 
 "query" : "my favorite food", 
 "max_gaps" : 0,  // 指定间隙为0 搜索hotwater
 "ordered" : true // 必须相邻
 } 
 }, 
 { 
 "any_of" : { 
 "intervals" : [ 
 { "match" : { "query" : "hot" } },  { "match" : { "query" : "water" } }  ] 
 } 
 } 
 ] 
 } 
 } 
 } 
 } 
}
```

短语匹配

```json
{ 
 "query": { 
 "match_phrase": { 
 "songName": { 
 "query": "O Chamar", 
 "slop": 1 // 准确匹配短语
 } 
 } 
 } 
}
```

其他更详细的查询可以参考官方文档



### Elasticsearch基础

#### Near RealTime

显然这种分布式系统是弱一致性的(BASE),写入数据到可以搜索(建立索引)大概有1S的延迟.基于ES执行搜索和分析可以达到秒级.而且需要注意的一点是ES中的数据结构在发生变动,根据分页请求出来的结果很可能会存在不同的变动情况.



#### Document

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

每一个key称为field.然而实际上,我们要直接操作的东西不是Document而是Index,ES会索引**所有field**,每次查找索引的时候,就直接查找该索引.原则上不要求文档有相桶的结构,但相同结构能提高搜索效率.

```shell
curl --socks5 127.0.0.1:9090 '..../video/_search?pretty&q={keyword}&from=0&size=1' # 查看 keyword
```

document有如下元数据,分别表示了文档所在的索引,分类以id,分值

```json
"_index" : "video",
"_type" : "video",
"_id" : "74582144",
"_score" : 1.0
```



#### Type/Mapping

索引Index包含了许多相似的文档,比如商品索引,每个索引下又有多个Type.这个Type可以理解为给不同的文档分组,可以使用下面的命令查看index下的Type. ES6.0只允许一个文档包含一个Type,7以上的版本会移除Type

```shell
curl '.../video/_mapping?pretty'
```

mapping而言每个字段可以指定其类型可以用PUT请求达成目的其类型

- 基本类型text/keyword,Date,Integer/Floating,Boolean,IPv4 &IPv6
- 特殊类型 geo_point & geo_shape/percolator

在首次写入的时候会自动推断其类型,但可能会由于推断不准确导致部分功能例如范围查询不可用.



#### shard 分片

碎片/分片(shard)和副本(replica),前者是解决海量数据的存储问题,后者是增加该数据系统的可用性.其集群可能是如下的存储形式,索引是被存储在分片上的.

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



### deep paging问题

这是一类会出现的分页问题,考虑下有6000条数据,3个分片,我们要搜索 offset = 1000, limit = 10 的数据应该如何做,其实ES会把每个分片的1000~1010条数据取出来,然后进行排序返回结果,当这个数字很大的时候一次性要拉取的数据就会非常多,导致ES性能拖慢



### 默认搜索过程与_all字段

```shell
curl 'localhost:9200/{index}/{type}/_search?pretty&q={content}'
curl 'localhost:9200/{index}/_search?pretty&q={content}'
curl 'localhost:9200/_search?pretty&q={content}'
```

我们在实际的搜索中发现指定关键字的值与不指定关键字的值,ES都能搜索出来,其内部的具体原理是`_all`元数据,在建立索引的时候,es会把多个字段的值变成一个长的字符串(以空格分割),作为`_all field`字段的值进行索引,如果没有指定更小的范围就会对`_all`进行搜索.那么这个全局字符串锁用的技术就是索引分词.默认的分词器是英文的.ES的分词器称为[analyzer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis.html),可以通过mapping查看到各分词器的具体配置

一般我们是需要禁用该`_all`可利用如下方法进行修改，include_in_all 改为 false 即可

```http
PUT /{index}/{type}/_mapping  
{  
    "order": {  
        "include_in_all": false,  
        "properties": {  
            "name": {  
                "type": "string",  
                "include_in_all": true 
            },  
            ...  
        }  
    }  
}
```





### 插件

分词器,可通过插件的形式实现分词,我们使用中文的分词器

```shell
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.5.1/elasticsearch-analysis-ik-5.5.1.zip
```

我们可以用如下方法指定分词器

```shell
curl -X PUT 'localhost:9200/accounts' -d '
{
  "mappings": { # 此属性配置分词器
    "person": {
      "properties": {
        "user": { # 字段名字
          "type": "text",
          "analyzer": "ik_max_word", # 文本分词器
          "search_analyzer": "ik_max_word" # 搜索分词器
        },
        "title": { # 字段名字
          "type": "text",
          "analyzer": "ik_max_word",
          "search_analyzer": "ik_max_word"
        },
        "desc": { # 字段名字
          "type": "text",
          "analyzer": "ik_max_word",
          "search_analyzer": "ik_max_word"
        }
      }
    }
  }
}'
```

如何查看是否某个字段使用了分词器,去检查他们的mapping信息即可

```shell
curl 'localhost:9002/video/_mapping?pretty'
```



### _score 字段

该字段是用于查询出的文档相似度的,文档相关性越高的越靠前,及时根据这个_score进行排序.

#### [相关度](https://www.elastic.co/guide/cn/elasticsearch/guide/2.x/scoring-theory.html)

- 布尔模型
- 评分函数
- 词频逆向文档频率
- 向量空间

布尔模型,在查找的时候仅支持 AND OR NOT 三种逻辑运算.

词频/逆向文档频率(TF/IDF),当匹配到一组文档后,需要根据相关度排序这些文档,不是所有的文档都包含所有词,所以相关度要取决于词在文档中的权重.TF/IDF由三个因素决定

- 检索的频率,搜的越多,其相关性就会越高
- 反向文档频率,检索的可能是一组词,每个检索词在索引中出现的频率,如果同一文档中出现了多个检索词,那么其反向文档频率更高
- 字段长度准则,字段越短,相关性越高,显然如果一个结果出现在标题中,另一个出现在内容中,显然标题相关性更高

单个词的查询可以联合TF/IDF,例如余弦距离和模糊查询.我们如果想知道这个字段是如何计算的,可以在url中使用explain参数,但效率不高,从explain中我们看到,我们还可以用_explain参数看到为何没被匹配上,**文档频率**是在每个分片中计算出来的,而不是在每个索引中.我们可以看到如下结果(参考官方文档)

```json
"_explanation": { 
   "description": "weight(tweet:honeymoon in 0)
                  [PerFieldSimilarity], result of:",
   "value":       0.076713204,
   "details": [
      {
         "description": "fieldWeight in 0, product of:", 
         "value":       0.076713204,
         "details": [
            {  
               "description": "tf(freq=1.0), with freq of:", # 检索词频率
               "value":       1,
               "details": [
                  {
                     "description": "termFreq=1.0",
                     "value":       1
                  }
               ]
            },
            { 
               "description": "idf(docFreq=1, maxDocs=1)", # 反向文档频率
               "value":       0.30685282
            },
            { 
               "description": "fieldNorm(doc=0)", # 字段长度准则
               "value":        0.25,
            }
         ]
      }
   ]
}
```

我们看下其计算方法,

词频计算
$$
tf(t \ in \ d) = \sqrt{frequency}
$$
逆向文档频率,numDocs为索引中文档的数量 ,docFreq为包含改词的文档数
$$
idf(t) = 1 + log(numDocs/(docFreq+1)) 
$$
字段归一值,numTerms为词在字段中出现的次数
$$
norm(d) = 1 / \sqrt{numTerms}
$$
因为查询可能不止一个词可能我们需要借助词嵌入技术,这里不使用词向量,而是用更低纬度的数,句子不是矩阵而是向量.这样做的好处就是可以直接使用余弦近似度来评价两个文档的距离.计算力强大.

最终score由[下列公式](https://www.elastic.co/guide/cn/elasticsearch/guide/2.x/practical-scoring-function.html)决定

```note
score(q,d)  =  
            queryNorm(q)  
          * coord(q,d)    
          * ∑ (           
                tf(t in d)   
              * idf(t)²      
              * t.getBoost() 
              * norm(t,d)    
            ) (t in q)
```





## Advance

### 集群模式

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

注意这里两个操作 fsync 和 flush

- fsync 5分钟内不使用的内存页(不活跃)就会被刷新到磁盘
- flush 是同步刷新磁盘

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



### 优化

[参考](https://blog.csdn.net/q364367207/category_8677712.html)

#### ES 使用到的资源

ES 主要使用heap和file system cache.堆中存储的东西是FST(Finite State Transducer)倒排索引的二级索引,一颗前缀树(1T 磁盘数据产生1G左右FST),如下图我们使用到其实现原理.

![img](https://lh6.googleusercontent.com/qgy55oYDCTjcrjO8_xBbXjGOVk9TN5tTTAuff-3vLEAEFK_doQvE2nPI9X5vyVkXRbXs_Kjr-P8Cqap3wjEVne_yD8HiWLaWwEQhehdilpw2L_BR-obzfv3se-os1hCeVrE6D_OS)

把索引内容加入文件系统缓存

```json
{
  "settings": {
  	"Index.store.preload":["nvd","dvd","tim","doc","dim"]
     }
}
```

- 存储索引倒排文件 .tim .tip .doc （tim 存储索引元数据,tip 存储倒排索引 doc存储doc的词频）
- 用于聚合排序 .dvd .dvm (按列存储的格式,用于聚合和排序)
- 全文检索 .pos .pay .nvd .nvm (pos是主要全文索引,保存term在doc中的位置,pay是应用payload查询的一些数据,后面两者字段加权文件)

[参考](https://elasticsearch.cn/article/6178)

**从这里也能看出全文索引是通过文件的形式去进行存储索引的**

force-merge 一部分不会更新的索引,等待ES自动merge是一个非常消耗内存的操作.

使用索引预排序.

```json
{
    "settings" : {
        "index" : {
            "sort.field" : "date", 
            "sort.order" : "desc" 
        }
    },
    "mappings": {
        "properties": {
            "date": {
                "type": "date"
            }
        }
    }
}
```

索引排序提高 AND 链接查询的效率,效果和 mysql 的组合索引类似.

可以指定分片优先级,`_primary`指定相关操作只在主节点上进行查询.

避免使用 script ,即painless,expression尽量不要使用

合理分配索引分片与副本

```note
腾讯基础架构部数据库团队推荐方案：
1. 数据量较少的index（100G 以下），一般3 - 5 个shard，副本设置为 1
2. 对于数据较大（100G 以上），一般把单个 shard 的数据控制在 20 - 50G
```

[参考文档](https://cloud.tencent.com/developer/article/1365893)





#### 提高查询性能

我们看其读写过程.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214213519-987528358.png)

系统的瓶颈在filesystem cache.如果给filesystem cache更多的内存,那么ES就基本是走内存去存的,如果走磁盘的搜索基本是秒级.如果走内存基本是毫秒级的.可如下分配内存

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214229417-987447848.png)

##### 只存储索引

然后就是搜索字段才存入ES,这样就可以尽量节省数据,意思是ES只用来存储索引.所以其他字段一般存入Hbase或者是mysql里面.一般使用hbase+elasticsearch架构.用ES单纯用作索引就好.



#### mappings 和 templates

mappings 和 templates 即上面工具的使用,mappings 可以理解为索引定义和schema定义meta定义等,比如可以通过 mappings 定义是否使用分词器等,而template则是映射模板

```http
GET /mapping_test/_mapping
```

```json
{
  "mapping_test" : {
    "mappings" : {
      "properties" : {
        "info" : {
          "properties" : {
            "address" : { // 字段属性
              "type" : "text", // 字段类型
              "fields" : {
                "keyword" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "card" : {
              "type" : "text",
              "fields" : {
                "keyword" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "is_vip" : {
          "type" : "boolean"
        },
        "uid" : {
          "type" : "long"
        },
        "user_name" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
      }
    }
  }
}
```

我们可以修改其中的信息

```http
PUT mapping_test3
{
  "mappings": {
    "properties": {
      "user_name":{
        "index": false, // 取消 index
        "type": "text"
      },
      "info":{
        "index_options": "positions",
        "type": "text"
      }
    }
  }
}
```

```json
{
  "mappings": {
      "_doc": {
          "dynamic": "strict",			
        	// schema 策略严格控制策略，遇到陌生字段当错误处理
        	// 可选值 true 遇到陌生字段开启动态映射
        	// 可选值 false 忽略遇到陌生字段
          "properties": {
              "name": { "type": "text" },
              "address": {
                  "type": "object",
                  "dynamic": "true"		// 开启动态映射策略
              }
          }
      }
  }
}
```

```http
PUT .../_mapping/_doc # 路由请求可以按路由或者json
{
"date_detection": false
} // 开启关闭日期检测
```

```json
"mapping": {
  "type": "text",        // 把所有的string类型, 映射成text类型
  "analyzer": "english", // 使用english分词器
  "fields": {
    "raw": {
      "type": "keyword",
      "ignore_above": 256
    }
  }
}
```

不使用分词器的字段

```shell
curl -XPUT '..../index/_mapping/type' -d '                                                            
{
    "type" : {
        "properties" : {
					"message" : {
            "type":"string",
            "index":"not_analyzed" # 同样可以在 mapping 中指定
            # "analyzer": "english" 或者是指定存在的分词器
					}
				}
		}
}'
```

而[模板](https://www.cnblogs.com/shoufeng/p/10641560.html)则是把创建好的settings和mapping保存下来,在搜索时刻重用,可以把模板理解为一组索引的使用

- Settings 指定 index 的配置信息,分片数,副本数,translog同步,refresh策略等,类似于环境变量
- mappings 用于指定 index 的内部构建信息

mapping 中的重要字段

- `_all` 6.0之后被替换成 copy_to 字段实现相同的功能了
- `_source` 如果不开启 `"_source": {"enabled": false}`则会只返回文档的id需要再次索引才能获取
- `properties` 最终要的配置也是我们上面研究的配置

创建模板

```json
PUT _template/shop_template
{
    "index_patterns": ["shop*", "bar*"],       // 可以通过"shop*"和"bar*"来适配索引,所有这个开头的索引都会走这个模板
    "order": 0,                // 模板的权重, 多个模板的时候优先匹配用, 值越大, 权重越高
    "settings": {
        "number_of_shards": 1  // 分片数量, 可以定义其他配置项
    },
    "aliases": {
        "alias_1": {}          // 索引对应的别名
    },
    "mappings": {
        // ES 6.0开始只支持一种type, 名称为“_doc”
        "_doc": {
            "_source": {            // 是否保存字段的原始值
                "enabled": false
            },
            "properties": {        // 字段的映射
                "@timestamp": {    // 具体的字段映射
                    "type": "date",           
                    "format": "yyyy-MM-dd HH:mm:ss"
                },
                "@version": {
                    "doc_values": true,
                    "index": "false",   // 设置为false, 不索引
                    "type": "text"      // text类型
                },
                "logLevel": {
                    "type": "long"
                }
            }
        }
    }
}
```





##### 数据预热

这个不难理解,把可能会被索引到的数据提前用ES搜索一次,建立好索引,刷新在filesystem cache里面即可提高整体效率.对于常年热门的数据,做一个专门的子系统用来进行数据预热.

##### 冷热分离

把冷数据写进一个索引中,然后热数据写入另一个索引中.这样可以确保数据预热后,尽量留在`filesystem os cache`中.

![](https://img2018.cnblogs.com/blog/1070942/201906/1070942-20190628214248335-1581895054.png)

然后尽量避免复杂查询.比如禁止查询过长字符,禁止深度分页

ES的冷热分离主要依赖分片规则

```properties
#设置节点属性rack_id及属性值rack_one
node.rack_id: rack_one  
#设置rack_id属性作为分片分布规则
cluster.routing.allocation.awareness.attributes: rack_id 
# 可以设置多个属性
cluster.routing.allocation.awareness.attributes: rack_id,zone
```

分片可以设置多个分片属性,当设置了分片属性时,如果节点没有设置其中任何一个属性,分片就不会出现在节点中

##### 分片规则

###### 强制分片规则

```properties
cluster.routing.allocation.awareness.force.zone.values: zone1,zone2  
# zone 为不同节点的规则分配
cluster.routing.allocation.awareness.attributes: zone
```

1个节点`node.zone`属性被设置为zone1,shard=5,replica=1.索引建立完成之后没有分片,只有当`node.zone`设置为zone2的时候,副本才会被分配到这个节点上

>  上面配置的意思就是设置属性zone作为分布规则，并且属性zone的值为zone1/zone2,由于副本与主分片不分配在一类节点中，则副本分片到zone2节点中。

###### 分片过滤规则

即是打上tag,使用 include 和 exclude 来控制分片分布

```properties
node.tag: hot
node.tag: cold
node.tag: value3
```

```shell
curl -XPUT localhost:9200/test/_settings -d '{ 
  "index.routing.allocation.include.tag": "hot"
  "index.routing.allocation.exclude.tag" : "value3"
}'
```

实现冷热分离

```properties
node.tag: hot
node.tag: cold
node.max_local_storage_nodes: 2   
#允许每个机器启动两个es进程(可选)
```

按照时间规律建立索引,比如

/index_2021-11-03,/index_2021-11-04,/index_2021-11-05

注意下 这样建立的索引就需要通过

- `/_search`
- `/index1,index2/_search`
- `/_all/_search` 

三种方式去完成

```http
PUT /_template/logstash
{
        "order": 0,
        "template": "logstash*", // 6.0 之后用 index pattern
        "settings": {
            "index.routing.allocation.include.tag": "hot", // 这行规则是主要的,新建的索引会分配到 node.tag = hot 下
            "index.refresh_interval": "30s",
            "index.number_of_replicas": "1",
            "index.number_of_shards": "1",
            "index.translog.flush_threshold_ops": "30000"
        }
}
```

或者是使用上面方式定义模板,会以 logstash 开头的所有模板进行匹配,然后使用定时任务吧历史索引保存到 cold 节点

这里有两种操作方式

1.手动标记,等 es 自动迁移数据到新节点下

```http
PUT /index_2021-11-03/_settings
{
   "index.routing.allocation.include.tag" : "cold"
}
```

2. 利用 [elasticsearch的命令行管理工具curator](https://github.com/elastic/curator) 编写定时脚本实现



### 日志与内存

首先我们要区分一下几个东西

- [磁盘]同步回复日志 translog
- [内存] 缓冲区 buffer
- [堆内存] FST 相当于前缀索引
- [操作系统内存 os cache] segment file 倒排索引 `.sl`文件存储元数据
- [磁盘] 大量数据,会活化到到内存

双写 translog 的原因是,translog 专门用于记录 checkpoint 的增量日志,比较简单不用建立数据结构(倒排索引和FST),所以直接落地磁盘

![img](https://lh6.googleusercontent.com/qgy55oYDCTjcrjO8_xBbXjGOVk9TN5tTTAuff-3vLEAEFK_doQvE2nPI9X5vyVkXRbXs_Kjr-P8Cqap3wjEVne_yD8HiWLaWwEQhehdilpw2L_BR-obzfv3se-os1hCeVrE6D_OS)

![](https://img-blog.csdnimg.cn/20190604221441892.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTIxMzMwNDg=,size_16,color_FFFFFF,t_70)

其中commit point是会维护一个`.del`文件,当文件过多时es会自动进行segment merge.这个删除的过程不是物理删除.

Luncene 把每次生成的倒排索引成为一个segment,然后使用另一个commit文件,记录所以内的所有segment,而生成segment的数据来源则是内存中的buffer.更新过程如下,总结起来就是 **新的数据写到新的索引文件里**

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1101.png)

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1102.png)

ES 首先把缓存刷到文件系统的缓存中最后再把数据落地到磁盘,ES的刷新频率是1s一次,所以可以做到准实时,这一步是可以通过`_refresh`接口刷新到文件系统的缓存.

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1105.png)

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1103.png)

从上面我们看出来ES其实是利用磁盘进行搜索的.

translog提供磁盘同步控制,在写入内存的buffer中还同时写入到translog里.等commit文件进行更新的时候translog才会被清空,同样可以使用`_flush`接口才控制这一操作,每30分钟或translog文件大小大于512M时ES会主动进行一次flush.也可以指定收到多少条消息之后数据之后flush一次.translog文件每5秒回强制落地磁盘,除此之外在每次写操作会强制触发写入磁盘,会牺牲性能.

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1106.png)

ES会对segment进行合并,因为每次请求不能都扫描所有文件,但是以文件的形式去进行搜索,这就涉及到了合并文件的问题.和并索引的时候是用额外空间合并的不会影响到搜索.和并完成后,大的索引文件落地磁盘,小文件删除如下

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1110.png)

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_1111.png)

### 分片计算

ES选择用了很简单的计算方式,shard计算方式如下,可以很简单计算其在那个分片上,所以ES在建立集群的时候分片数的数值是固定的是不允许更改的.
$$
shard = hash(\_id) \  \% \ number\_of\_primary\_shards
$$
数据写入流程如下

![](https://www.elastic.co/guide/en/elasticsearch/guide/current/images/elas_0402.png)

P代表分片,R代表副本,通过master计算出在哪个节点分配然后进行转发.两个副本中有一个成功了就可以返回给客户端了.服务器如果负载过高,我们也可以利用ES的move指令从需要的节点上移走部分分片.









