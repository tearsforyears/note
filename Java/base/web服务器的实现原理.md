# web服务器的实现原理

---

[toc]

---

本文档主要想谈谈从基本的网络协议构建出最简单web服务器,中间我们会加强基本的web环境的建设,以及对servlet服务器的一些机制包括但不限于.此文档会逐渐完善.

-   I/O
-   操作系统连接的并发(POXIS协议)
-   socket结构解析与应用
-   web中机制(listener)
-   tomcat结构解析
-   多线程web服务器的构建
-   Netty

从此种角度对基本的web服务器服务器进行分析和实现.

## 网络协议及底层模型

### 物理层和链路层协议

#### 物理层协议

-   LLC 链路逻辑控制
-   MAC (media access control)

#### 链路层协议

-   ppp (点对点协议) 为TCP/IP提供实现基础
-   以太网
    -   CSMA/CD

帧编码和CRC差错控制是这一层的主要功能,(封装成帧,透明传输和差错控制).这一层以bit流作为传输的结构.

ppp的帧结构

标志字段(1B),地址字段(1B),控制字段(1B),协议(2B).信息部分FC(2B),标志字段(1B)

### 网络层协议

-   ip
-   icmp (internet control message proto) ip的一部分
-   APR 地址转换 ip->mac
-   RAPR 反向解析地址

APR和RAPR不用多说.是把ip地址和mac地址装换的协议.

ip协议利用了数据链路层的一些,把相应的数据帧变成以报文格式的,如下结构

![](https://img-blog.csdn.net/20180829161408481?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM3ODg0Mjcz/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

ip是要基于局域网协议的,所以其最大长度即是MTU.IP协议支持单点传送,广播和多点传送.TTL为数包在网络间的最大生存时间.

ICMP为ip协议的一部分,icmp按照ip路径反着来报告差错的报告.其主要功能差错控制和信息查询.其报文格式如下

![](https://images2018.cnblogs.com/blog/806469/201803/806469-20180306123940403-1730998630.png)

ping命令就是使用icmp报文来进行实现的如下其只需要通过发回随意的相同标识数据,就可以知道两个数据包来回的时间.这个在linux实现得进行封包和拆包,其实就是用c++的icmp类

![](https://images2018.cnblogs.com/blog/806469/201803/806469-20180306124106517-1608215708.png)

当然可以用来实现tracerouter

![](https://images2018.cnblogs.com/blog/806469/201803/806469-20180306124141264-1747233430.png)

其本质就是到达每个路由器TTL自减然后往回发送报文,通过发送若干TTL不等的数据包即可确定往返的数据内容,通过发送相同的数据包和不同的TTL即可确定途中经过的路由

用来检测**UDP端口是否开启**

当ICMP发送到服务器的不可达端口的时候,返回"端口不可达"报文.

![](https://images2018.cnblogs.com/blog/806469/201803/806469-20180306124203238-282815051.png)

端口扫描分为TCP端口扫描和UDP端口扫描

而ICMP实现的UDP的端口扫描,TCP的实现是通过尝试三次握手来判定是否建立TCP连接,如果可以进行三次握手则可以扫描端口.

我们利用java的icmp来实现一些功能,java的相关类都在`java.net.*`下,在`java.net`里面有个



### TCP/UDP

TCP是面向连接的稳定的连接过程,所以其建立连接的过程,要求很强的可靠性.所以在使用IP报文中,需要保证接收端的收发能力,以及发送端的收发能力,同时也要准确的保证双方可以稳定的通信,就需要服务器端建立相应的socket线程给进行处理.这就有了TCP的三次握手

-   [client] **SYN = 1**,seq = x 客户端请求服务器端的socket同步(client发送能力)
-   [server] **SYN = 1,ACK = 1**,seq = y,ack = x+1 服务器收到相应,请求客户端同步 (server的收发能力)
-   [client] **ACK = 1**,seq = x+1,ack = y+1 客户端发送确认请求,开始通信 (client接受能力)

大写的SYN,FIN,ACK是TCP专门的同步信号的建立,确认和释放

同步信号SYN = 1请求同步,回应时要使用SYN = 1 ACK = 1

x,y是服务器或者客户端发送的序列号,ack是确认报文已经到达,索取下一个序列号的报文的意思

![](https://img2018.cnblogs.com/blog/1615025/201905/1615025-20190518144433795-281529451.png)

tcp建立连接之后就可以稳定传输数据了,而建立连接之后就要释放连接,释放连接就要双方确认才行,否则会使得其中一方放不开连接,即四次挥手,其发起者可以client也可以是server

-   [sender] FIN = 1 , seq = x
-   [reciver] ACK = 1, seq=y ,ack = x + 1
-   [reciver] ... 常规报文传输最后的数据
-   [reciver] FIN = 1 , seq=z ,ack = x
-   [sender] ACK = 1, seq= x+1,ack = z +1

当回应FIN信号之后 ACK = 1发送之后,接收端就进入CLOSE-WAIT状态了,此时接收端只会发送报文传输数据,等待发送完 FIN = 1信号之后.发送端等待2MSL的时间,这个时间是两次报文的时间就是发送ACK = 1 的报文所需要的时间加上ICMP出错回传的时间,如果出错回传了能监测到,那么发送端就得重新发送数据,否则则是安静关闭.

![](https://img2018.cnblogs.com/blog/1615025/201905/1615025-20190518144523766-28426128.png)



### HTTP

HTTP相对不在多赘述,其本质上是建立了tcp连接之后,以tcp传输数据的形式把报文字段传送过去,拥有不同的报文头,有几类特殊的报文,例如上传报文等.相应的报文格式也在相应的网络或是资料上可以找到

#### http测试工具

本质上讲就是http请求库,或者爬虫结构工具很多,这里随便列举几种

-   postman / telent api Tester 
-   curl / nc
-   HttpClient(java) / requests (python)
-   scrapy view

curl的使用

```shell
curl -X POST --header "Content-Type:application/json"  --data '{}'  127.0.0.1:8000/user/getAllUserInfo
curl -I www.baidu.com # 获取头部信息
```

我们可以利用TCP和curl探明http请求的报文是如下

```http
GET / HTTP/1.1
Host: 127.0.0.1:8000
User-Agent: curl/7.68.0
Accept: */*
```

nc的使用

nc在安全界又称瑞士军刀,明文传输,tcp/udp协议层次的服务器请求命令

```java
nc -nvz [地址] [端口号] // n 不使用dns v列出执行过程 z不发生io仅扫描
nc -nv [地址] [端口号] // 和telnet一样可以发生交互
nc -l -p // 启用监听模式,相当于小型tcp服务器
```





## I/O

这里主要说NIO和BIO



## socket

---

socket是java和其他线程等,网络通信的基础,从TCP的传输层出发,



### socket类

-   Socket 是 TCP 客户端 API,通常用于连接远程主机。
-   ServerSocket 是 TCP 服务器 API,通常接受源于客户端套接字的连接。
-   DatagramSocket 是 UDP 端点 API,用于发送和接收数据包
-   MulticastSocket 是 DatagramSocket 的子类,在处理多播组时使用。





### 简易http服务器



### 对socket封装的http库

HttpURLConnection和HttpClient是两个Http请求库,前者为原生jdk,后者为apache项目

-   HttpURLConnection是基于socket建立专门用于发Http请求的库
-   HttpClient属于对上面的封装,对cookie等处理进行了大量优化

**HttpURLConnection在处理非get的问题的时候会变得很复杂**

总的来说这两玩意都是通过搭建TCP的socket然后拼接报文完成,在不同的场合能够适应不同的工作

