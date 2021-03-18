# web服务器的实现原理

---

[toc]

---

本文档主要想谈谈从基本的网络协议构建出最简单web服务器,中间我们会加强基本的web环境的建设,以及对servlet服务器的一些机制包括但不限于.此文档会逐渐完善.

-   I/O
-   操作系统连接的并发(POXIS协议)
-   socket结构解析与应用
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



#### TCP拥塞控制

一共有4种算法

-   慢开始(指数增长)
-   拥塞避免(线性增长)
-   快重传(不必等待计时器过期,直接重传)
-   快恢复

![](https://img-blog.csdnimg.cn/20190731155254165.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxNDMxNDA2,size_16,color_FFFFFF,t_70)

![](https://img-blog.csdnimg.cn/20190731165743903.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxNDMxNDA2,size_16,color_FFFFFF,t_70)



快重传和快恢复

![](https://img-blog.csdnimg.cn/20190731165605396.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxNDMxNDA2,size_16,color_FFFFFF,t_70)

![](https://img-blog.csdnimg.cn/20190731184314574.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxNDMxNDA2,size_16,color_FFFFFF,t_70)

![](https://img-blog.csdnimg.cn/20190731184640178.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxNDMxNDA2,size_16,color_FFFFFF,t_70)





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

这里主要说NIO和BIO,为了提高http的I/O性能.I/O的细粒度和高异步显得尤为必要.以及部分流式计算对高性能服务器而言此中I/O尤为重要.

### 传统I/O体系

byte是最小的处理单位,在TCP的通信中通常是以byte来传送数据

char是最常用的处理单位,可以被人类辨识,通常使用Unicode编码来处理

i/o的分类五花八门,为了提高性能和讲明处理原理大概可以分为下列类别,JDK1.8默认是UTF-8编码

![](https://img-blog.csdn.net/2018081912294996?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM0NjkzMTA0/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

流的响应过程

不带有阻塞的流(FileInputstream),打开一次,如果是带有阻塞的流(比如socketInputstream)等都是read之后在下次调用read时发现没有数据则进行阻塞等待写.而write流则可以在两次read之前进行传输,从TCP的角度看,全双工通信导致其读写不是同时阻塞的,上面这些就是流的工作原理.

read(buff)和read(buff,offset,len)的工作原理本质上都是读进buff,返回的则是实际读出的长度(如果流关闭了就返回-1)

如下一段小型服务器能说明IO流的基本用法,至于Reader则不过是对该方法的二次封装.

```java
static final ExecutorService pool = Executors.newCachedThreadPool();

public static void main(String[] args) throws IOException {
  ServerSocket ss = new ServerSocket(8000);
  System.out.println("服务器启动");
  while (true) {
    Socket server = ss.accept();
    System.out.println("一个请求来了");
    pool.submit(() -> {
      try (InputStream ins = server.getInputStream(); DataOutputStream os = new DataOutputStream(server.getOutputStream())) {
        byte[] buff = new byte[1024];
        int len;
        while ((len = ins.read(buff)) != -1) {
          System.out.println(new String(buff, 0, len));
          os.writeUTF("发送成功");
          os.flush();
        }
        //                    IOUtils.print(ins);

      } catch (IOException e) {
        System.out.println("客户端请求关闭");
        //                    e.printStackTrace();
      }finally {
        System.out.println("连接关闭");
      }
    });
  }
}
```

### nio

nio称之为非阻塞I/O,指通过各种技术打破传统I/O在读流的时候需要等待的耗时操作.下面所说的pipeline为管道,channel为通道.另外这个耗时操作除了传统的**阻塞等待**之外还有和流很不同的一点,即是我们如果从操作系统层面上看待,传统I/O是没有缓冲区的,而nio是面向块的(buffer),即其性能要高上很多,向操作系统请求的次数也会相对较小.

#### 管道 pipeline

管道这个技术是为了完成线程间的通信的(IPC),其需要操作系统内核提供一块缓冲区其实现方式有很多种,比如文件,消息队列,共享内存,信号量,socket等.管道是一种半双工的通信方式.

java对于管道的实现如下

![](http://wiki.jikexueyuan.com/project/java-nio/images/8.png)

中间其实有两个`Channel`.其本质是借助c++的`mkfifo()`

```java
static final ExecutorService pool = Executors.newFixedThreadPool(4);
    PipedInputStream pin = new PipedInputStream();
    PipedOutputStream pout = new PipedOutputStream();
    {
        try {
            pout.connect(pin); // 管道需要连接才行,可以倒过来连接都一样
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

@Test
public void test() throws InterruptedException {
  pool.submit(() -> {
    IOUtils.print(pin);
  });
  Thread.sleep(200);
  pool.submit(new Callable(){
    @Override
    String call() throws Exception{
      pout.write("管道你好\n".getBytes());
      pout.flush();
      Thread.sleep(1000);
      pout.write("管道你好".getBytes());
      pout.flush();
      pout.close();
      return null;
    }
  });
}
```

其是一种半双工的通信方式也就意味着在同一时间只有一个方向的数据被传输

#### FileLock

顾名思义对文件加锁,也是nio的一种工具,该锁是jvm级别的,如果不释放的话就得等jvm完全退出之后才能够释放.其和JUC一样分为共享锁和排他锁,分别制约文件的读写(参考ReentrantReadWriteLock)

```java
FileChannel fileChannel=new FileOutputStream("./1.txt").getChannel();
FileLock lock=fileChannel.lock(); // 默认是排它锁
//对此文件进行一些读写操作。
lock.release();
```

#### I/O多路复用(Reactor模型)

I/O多路复用是linux系统的一项技术,其被广泛使用在各种成熟的解决方案中,例如redis单线程却实现了相当高的性能.多路复用就是利用了select,poll,epoll同时监听多个流的能力.

![](https://img-blog.csdnimg.cn/2019031811242212.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21hc2hhb2thbmcxMzE0,size_16,color_FFFFFF,t_70)

可以看到I/O多路复用是基于这么一个过程,也就是说省去了绝大部分等待数据到达的时间,而不用一直等待,但数据拷贝还是需要CPU的.

I/O多路复用一般来说是select,poll,epoll三种实现

selector在监听着数据socket的请求一旦有I/O请求,就会调用select函数用户线程立即返回,数据到达时,检查socket是否可读然后发出read请求,读取数据.因为可以注册多个socket,所以效率比传统I/O高很多,而传统阻塞I/O直接从头到尾进行阻塞.该模型的好处是可以监视多个socket,一旦他们连接即可select等待数据到达而不必如阻塞I/O只能一次处理一个.当数据可读的时候才需要用户线程分配CPU的时间片.

![](https://images0.cnblogs.com/blog/405877/201411/142332187256396.png)

select和poll都实现了上面的模型,不同的是select实现的年代比较早,select不是线程安全的,且只能支持1024个连接,poll在其基础上进行了改进,不过poll依然不是线程安全的.线程安全的问题直到epoll才被解决.epoll改进了read请求这点,变成通知从而使得其效率提高.且epoll是线程安全的

>   poll和epoll的不同
>
>   poll基于轮序去访问selector这样一来就会导致某些线程是要空轮询去响应事件的就消耗资源复杂度是O(n)
>
>   epoll对其进行了改进poll使用的是pollfd结构.epoll有三个函数epoll_ctl,epoll_wait,epoll_create
>
>   其没有使用轮询,在epoll_ctl函数中注册新事件到epoll句柄,epoll拷贝进用户空间的数据只用一次.而poll需要拷贝多次.epoll为每个fd指定一个回调函数,当设备就绪唤醒waiter时就会调用回调函数.这样一来就避免了轮序.其利用回调函数的机制解决了poll的轮询问题,epoll只需要判断一下selecor为不为空就行,而poll和select需要时刻轮序事件的发生并去相应,epoll的事件响应由回调函数执行,其线程多半在睡眠中,多线程的特性就体现了出来

很显然我们看出来java的nio是基于poll去进行实现的.且java的nio不支持多线程





#### java.nio

虽然传统I/O可以借助多线程加线程池的方式来极大的增加成本,但是传统的I/O方式会在一些场景上遇到问题,比如有许多要求HTTP长连接的场景/游戏服务器同步信息等,但这些连接和传统的FileInputStream不同,因为这些连接不是每时每刻都在传送数据的.根据这个特点,nio提供了一种全新的操作方式用来避免上面的情况.

![](https://awps-assets.meituan.net/mit-x/blog-images-bundle-2016/77752ed5.jpg)

IO的基本分类如上,

传统的BIO属于一直阻塞到底的非同步I/O,如果buffer里面没有数据就会阻塞到有数据到来

NIO是buffer里面有数据,就从网卡把数据读到内存,并且返回给用户,否则返回0永远不会阻塞

AIO(异步I/O)等待和从网卡到内存里,从内存里等待都是非阻塞的.

**NIO最大的特点就是非阻塞模式下读写函数是可以直接返回的**



在NIO的设计中,调度的工作交由Selector来做,而传输的工作交由Channel来做,Selector负责监视这些Channel的状态.

![](https://developer.ibm.com/developer/default/articles/j-lo-javaio/images/image019.jpg)

其核心为一下几个点

-   Channel (File,Datagram,Socket,ServerSocket)
-   Buffer (Byte,Char,Double,Float,Int,Long,Short,MappedByteBuffer)
-   Selectors 

我们可以把Channel理解成传统I/O中的Stream.数据从Channel读到Buffer中,或者从Buffer写到Channel中

![](https://ifeve.com/wp-content/uploads/2013/06/overview-channels-buffers1.png)

Selector允许单线程处理多个Channel,如果打开了多个通道,Selector处理效率就会很高.其结构如下

![](https://ifeve.com/wp-content/uploads/2013/06/overview-selectors.png)

NIO因为其立即返回的特性,所以可以在返回时候知道数据到底读好没,这时就可以利用selector,在selector上做标记,然后**切换到**其他链接进行读写.我们要在合适的时机告诉选择器我们对何种事件感兴趣.主要事件就三个,**读就绪,写就绪,有新连接到来**.根据[美团技术团队](https://tech.meituan.com/2016/11/04/nio.html)

>对于写操作，就是写不出去的时候对写事件感兴趣；
>
>对于读操作，就是完成连接和系统没有办法承载新读入的数据的时；
>
>对于accept，一般是服务器刚启动的时候；
>
>而对于connect，一般是connect失败需要重连或者直接异步调用connect的时候

我们根据此就可以建立一个大概的线程模型用NIO来处理海量连接

BIO的多线程阻塞读写,变成了单线程轮询,除了事件轮询是阻塞的,I/O都需要CPU参与没必要开启多线程.我们需要以下几种线程

-   事件分发器 单线程选择就绪事件
-   I/O处理器 read write 主要处理I/O
-   业务线程 即处理完I/O之后 可能还要处理下业务逻辑,DB,PRC,其他阻塞

java的selector对于linux系统来说有致命限制:同一个channel的select不能被并发调用,多线程的环境下,必须保证一个socket只属于一个LocalThread,当然一个LocalThread可以管理多个socket.对于连接的处理和读写可以分离.海量的读写和注册就可以分发

![](https://awps-assets.meituan.net/mit-x/blog-images-bundle-2016/5c0ca404.png)

关于NIO的应用上,最著名的就是Netty框架,屏蔽了操作系统的一些差异,且对于NIO而言不适合适用多线程,要尽量避免多线程.

##### buffer

buffer实际上是块内存区域,可读可写,并且与NIO的通道进行交互.Buffer写法一般是以下

-   写入数据到Buffer
-   调用`flip()`方法,转换读写模式
-   从Buffer中读取数据
-   调用`clear()`方法或者`compact()`方法,清空缓冲区

clear清理整个缓冲区和compact清理读过的数据,如下

```java
File file = new File("...");
try (FileInputStream ins = new FileInputStream(file)) {
  FileChannel inc = ins.getChannel();
  int buffersize = 64;
  ByteBuffer buffer = ByteBuffer.allocate(buffersize); // 创建缓冲区
  // ByteBuffer buffer = ByteBuffer.allocateDirect(buffersize); 
  
  int len;
  byte[] bytes = new byte[buffersize];
  while ((len = inc.read(buffer)) != -1) {
    buffer.flip(); // 不能省略,改变读写指针位置,读写模式切换见下
    buffer.get(bytes, 0, len);
    System.out.print(new String(bytes, 0, len));
    buffer.clear();
  }
}
```

从上面我们可以看到buffer的分配可以是直接内存或者是堆内存(分别对应allocateDirect和allocate).在此处利用直接内存分配速度会超级加倍.其是使用了Unsafe类分配了内存.

Buffer中有三个重要的机制

-   capacity
-   position
-   limit

![](https://ifeve.com/wp-content/uploads/2013/06/buffers-modes.png)

如上内存区域,capacity是其总长度,position表示当前指针所处的位置.当读写时,position会移动到下一可读写的位置.读写切换时`buffer.flip()`,会重置指针的位置.limit表示能往Buffer里写多少数据,在切换时limit会变成写时position的值,就能确定哪部分区域是有效能读的了.

```java
ByteBuffer buffer = ByteBuffer.allocate(buffersize);
buf.put(127); // 也可以直接放入内存
buf.get() // 可以直接从内存读取
```

##### 多buffer读写

指的是分散和聚合,nio支持scatter/gather,

-   scattering read指的是在通道读数据的过程中读到多个buffer里
-   gathering write指的是channel在写操作时,把多个buffer写进同一channel里

如果数据可以分开处理,这样的特性可以大大提高效率.

```java
ByteBuffer header = ByteBuffer.allocate(128);
ByteBuffer body   = ByteBuffer.allocate(1024); 
ByteBuffer[] bufferArray = {header,body};
channel.read(bufferArray); // 如果是以buffer数组,则每个数组都会接受通道的数据
// 且是按照顺序写到每个buffer中的,相当于buffer都有一副本
```

写的情况是每个buffer按顺序写入

```java
int buffersize = 128;
ByteBuffer buffer1 = ByteBuffer.allocate(buffersize);
ByteBuffer buffer2 = ByteBuffer.allocate(buffersize);
buffer1.put("123".getBytes());
buffer2.put("4576".getBytes());
buffer1.flip();
buffer2.flip();
osc.write(new ByteBuffer[]{buffer1, buffer2});
```

##### 通道连接 transferTo

```java
RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel fromChannel = fromFile.getChannel();
RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel toChannel = toFile.getChannel();
fromChannel.transferTo(0, fromChannel.size(), toChannel);
```

此外要注意,在SocketChannel的实现中,SocketChannel只会传输此刻准备好的数据(可能不足count字节).因此,SocketChannel可能**不会将请求的所有数据(count个字节)全部传输**到FileChannel中.

##### Selector

selector选择器可以连接多个channel,这样就能在一个线程内管理多个Channel即多个网络连接.这一举措是为了减少开销,因为创建线程提高速度同样的也需要大量的系统资源.

```java
Selector selector = Selector.open();
SelectableChannel channel;
channel.configureBlocking(false); // FileChannel等是不可不阻塞的
SelectionKey key = channel.register(selector,SelectionKey.OP_READ);
// 注册事件,当相应下个阶段的时候就可以注册相应的事件
```

register注册的是监器,selector会监听channel的事件,并响应

-   Connect
-   Accept
-   Read
-   Write

通道触发这些事件称为通道读就绪,写就绪等.这些事件可以通过位或运算连接起来.

```java
ByteBuffer buffer = ByteBuffer.allocate(1024); // read buffer
Selector selector = Selector.open();
ServerSocketChannel ssc = ServerSocketChannel.open();
ssc.configureBlocking(false); // 设置为非阻塞方式
ssc.socket().bind(new InetSocketAddress(8080));
ssc.register(selector, SelectionKey.OP_ACCEPT);// 注册监听的事件

while (true) {
  selector.select(); // 选择在这里是阻塞的
  Set selectedKeys = selector.selectedKeys();
  // 取得所有selectkey,这里指的是响应OP_ACCEPT操作的(因为只注册了这么一个)
  Iterator it = selectedKeys.iterator();
  while (it.hasNext()) {
    SelectionKey key = (SelectionKey) it.next();
    if ((key.readyOps() & SelectionKey.OP_ACCEPT) == SelectionKey.OP_ACCEPT) { // 响应OP_ACCEPT
      // 可以用key.isAcceptable() 来做判断
     	
      ServerSocketChannel ssChannel = (ServerSocketChannel) key.channel();
      SocketChannel sc = ssChannel.accept();//接受到服务端的请求
      sc.configureBlocking(false);
      sc.register(selector, SelectionKey.OP_READ);
      
    } else if ((key.readyOps() & SelectionKey.OP_READ) == SelectionKey.OP_READ) {
      
      SocketChannel sc = (SocketChannel) key.channel();
      while (true) {
        buffer.clear();
        int n = sc.read(buffer); //读取数据
        if (n <= 0) {
          break;
        }
        buffer.flip();
      }
    }
    it.remove();
  }
}
```

我们来讲述其过程select方法是阻塞的,没有连接是则会一直卡着不动,实际上nio也并不是完全不用阻塞的,只有阻塞的时候才能调度,一般性而言我们会利用线程把二者分离,一个线程专门处理select的问题,另一个线程用来响应这些请求,从多线程和nio的角度合理调度资源.从上面而言,主线程内部,我们在后面会实现这个模型.

selector维护三种集合

-   **已注册的键的集合(Registered key set)**
-   **已选择的键的集合(Selected key set)**
-   **已取消的键的集合(Cancelled key set)**

SelectionKey相当于一个通道和selector建立的操作对象,通过这个对象可以操作通道和selector.该对象一般存在selector的内部,SelectionKey里面有如下属性

-   interest集合 监听事件集合
-   ready集合 就绪操作集合
-   Channel
-   Selector
-   附加的对象(可选)

```java
key.isAcceptable();
key.isConnectable(); 

// 利用SelectionKey访问.
Channel channel = key.channel();
Selector selector = key.selector();

// attach 和 LockSupport.park的参数差不多,可选,标识通道
key.attach(object);
Object obj = key.attachment();
```

**select方法**

如果某些事件已经准备就绪了,就可以被select返回对应的通道了.select也是个阻塞方法,当通道就绪的时候,select会返回.selectNow会立即返回不会阻塞,如果没有可返回的通道

-   select()
-   select(long timeout)
-   selectNow()

```java
Selector selector = Selector.open();
channel.configureBlocking(false);
SelectionKey key = channel.register(selector, SelectionKey.OP_READ);

while(true) {
  int readyChannels = selector.select(); // 返回就绪的通道数,阻塞方法
  if(readyChannels == 0){
    continue;
  }
  Set selectedKeys = selector.selectedKeys(); // 访问被选择的key的集合
  Iterator keyIterator = selectedKeys.iterator();
  while(keyIterator.hasNext()) {
    SelectionKey key = keyIterator.next();
    if(key.isAcceptable()) {
        // a connection was accepted by a ServerSocketChannel.
    } else if (key.isConnectable()) {
        // a connection was established with a remote server.
    } else if (key.isReadable()) {
        // a channel is ready for reading
    } else if (key.isWritable()) {
        // a channel is ready for writing
    }
    keyIterator.remove();
  }
}
```







##### Channel

其分为以下重要的实现类

-   FileChannel 从文件中读写
-   DatagramChannel UDP中读写
-   SocketChannel TCP读写数据
-   ServerSocketChannel 监听TCP,每个新来的连接都会创建一个SocketChannel

从上面我们也能看出channel的基本用法,所谓的通道可以理解为和Buffer相连的数据通路

我们这里着重讲SocketChannel,和ServerSocketChannel.

SokcetChannel阻塞模式的读写如下

```java
SocketChannel socketChannel = SocketChannel.open();
socketChannel.connect(new InetSocketAddress("www.baidu.com", 80));
ByteBuffer buf = ByteBuffer.allocate(48);
int bytesRead = socketChannel.read(buf);
// 其写如下
ByteBuffer buf = ByteBuffer.allocate(48);
buf.clear();
buf.put(newData.getBytes());
buf.flip();
while(buf.hasRemaining()) { // 重复写直到没有字节为止
    channel.write(buf);
}
```

非阻塞模式下,其性能加快特别多,可能在连接之前就返回了我们要做判断如下

```java
socketChannel.configureBlocking(false);
socketChannel.connect(new InetSocketAddress("http://www.baidu.com", 80));
while(!socketChannel.finishConnect()){
  // wait for connect
}
```

read和write方法也是异步的,所以我们要做一个循环等待去判断,read利用返回的字节数,write要循环写.



**ServerSocketChannel**

该类是建立nio服务器的基础类,其和ServerSocket一样,监听一个TCP连接,和传统Socket一致

```java
ServerSocketChannel serverSocketChannel = ServerSocketChannel.open();
serverSocketChannel.socket().bind(new InetSocketAddress(8000));
while(true){
    SocketChannel socketChannel = serverSocketChannel.accept();
}
```

我们利用上面的技术设计单线程的NIO服务器如下

```java
try {
  selector = Selector.open();
  ssc = ServerSocketChannel.open();
  ssc.socket().bind(new InetSocketAddress("127.0.0.1", port));
  ssc.configureBlocking(false);
  ssc.register(selector, SelectionKey.OP_ACCEPT); // listen accept
  writeBuffer.put("received\n".getBytes());
  while (true) {
    //                    System.out.println(Thread.currentThread().getName() + "阻塞等待选择");
    int readys = selector.select(); // main thread process and blocked the thread

    // process event
    Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();
    while (iterator.hasNext()) {
      SelectionKey selectionKey = iterator.next();
      iterator.remove();
      if (selectionKey.isAcceptable()) { // process accept event
        System.out.println(Thread.currentThread().getName() + "接受连接请求");
        SocketChannel channel = ssc.accept();
        channel.configureBlocking(false);
        channel.register(selector, SelectionKey.OP_READ);

        // accept link and wait to be select read
      } else if (selectionKey.isReadable()) {
        System.out.println(Thread.currentThread().getName() + "处理读事件");
        SocketChannel channel = (SocketChannel) selectionKey.channel();
        readBuffer.clear();
        channel.read(readBuffer);
        readBuffer.flip();
        String str = new String(readBuffer.array());
        System.out.println("received : " + str);
        selectionKey.interestOps(SelectionKey.OP_WRITE);
      } else if (selectionKey.isWritable()) {
        System.out.println(Thread.currentThread().getName() + "处理写事件");
        SocketChannel channel = (SocketChannel) selectionKey.channel();
        writeBuffer.rewind();
        channel.write(writeBuffer);
        selectionKey.interestOps(SelectionKey.OP_READ);
      }

    }
  }
} catch (IOException e) {
  e.printStackTrace();
}
```

另外关于NIO的http服务器实现只要改写成报文的内容就行,报文的处理过程相对更复杂,如果要使用该种服务器,用Netty框架而不是用基础的nio是更好的选择.



#### java.aio

-   未完待续

### 流式计算

在java中实现流式计算在JDK1.8之后,JDK1.8以后有了Stream和接口的默认方法,使得流式计算拥有了同一的api,在spark/mapreduce中,流式计算的思想也极其重要.在python中也对基本的map/reduce进行了实现,但流式计算的核心,在构建出一条流水线,使得迭代次数减少进而提高计算效率.其操作可分为下面几种(熟悉spark的知道其部分原理)

| 操作                              | 状态                       | api                                                          |
| --------------------------------- | -------------------------- | ------------------------------------------------------------ |
| 中间操作(Intermediate operations) | 无状态(Stateless)          | unordered() filter() map() mapToInt() mapToLong() mapToDouble() flatMap() flatMapToInt() flatMapToLong() flatMapToDouble() peek() |
|                                   | 有状态(Stateful)           | distinct() sorted() sorted() limit() skip()                  |
| 结束操作(Terminal operations)     | 非短路操作                 | forEach() forEachOrdered() toArray() reduce() collect() max() min() count() |
|                                   | 短路操作(short-circuiting) | anyMatch() allMatch() noneMatch() findFirst() findAny()      |

**中间操作知识一个标记,等结束操作的时候才会触发真正的计算**,就并行计算而言,无状态和有状态的区别在于,无状态不需要收调用链前面的影响,而有状态的操作必须等所有操作操作完以后才能知道结果.传统的实现方法如下

![](https://images2015.cnblogs.com/blog/939998/201703/939998-20170328220216904-281721275.png)

但这种做法有很大的弊端,其一就是来回回调函数使得中间用来处理的对象增加,第二个是不断产生中间结果的list极大的损耗空间(spark中可以缓存)

#### 记录操作

Stream接口的设计者把用户的操作在一次迭代中执行掉,从而省去了回调函数的时间.如下

![](https://images2015.cnblogs.com/blog/939998/201703/939998-20170328220309045-1952777908.png)

和spark一样(倒不如说spark和java一样),java的stream使用stage来描述每个阶段的变化上面的PipelineHelper的实例对象表示某种Stream.其实现类除了`ReferencePipeline`还有`IntPipeline`, `LongPipeline`,` DoublePipeline`,为Pipeline的主要计算所在的数据类型提供支持其中StatelessOp和StatefulOp分别用来标识Stage的类型,head是链表的头指针,维护Stage链条.

![](https://images2015.cnblogs.com/blog/939998/201703/939998-20170328220336326-882287689.png)

这就是Stream记录操作的方式.

#### Sink接口

sink接口用于协调Stage之间的关系其包含如下方法或接口

| 方法名                          | 作用                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| void begin(long size)           | 开始遍历元素之前调用该方法，通知Sink做好准备。               |
| void end()                      | 所有元素遍历完成之后调用，通知Sink没有更多的元素了。         |
| boolean cancellationRequested() | 是否可以结束操作，可以让短路操作尽早结束。                   |
| void accept(T t)                | 遍历元素时调用，接受一个待处理元素，并对元素进行处理。Stage把自己包含的操作和回调方法封装到该方法里，前一个Stage只需要调用当前Stage.accept(T t)方法就行了。 |

begin和end是有状态操作需要实现的,cancellationRequested()是短路操作需要实现的,每个Stage只要知道Sink的accept方法就可以往下进行调用了.

所以我们并行处理的时候accept调用就可以按照每个元素去并行处理了,普通的accept方法要包装成一个sink,那么对于sorted这种需要读取元素的方法其实现如下.

```java
// Stream.sort()方法用到的Sink实现
class RefSortingSink<T> extends AbstractRefSortingSink<T> {
  private ArrayList<T> list; // 存放用于排序的元素,中间结果
  RefSortingSink(Sink<? super T> downstream, Comparator<? super T> comparator) {
    super(downstream, comparator);
  }
  @Override
  public void begin(long size) {
    ...
      // 创建一个存放排序元素的列表
      list = (size >= 0) ? new ArrayList<T>((int) size) : new ArrayList<T>();
  }
  
  @Override
  public void end() {
    list.sort(comparator);
    // 只有元素全部接收之后才能开始排序,其他则是可以放在accept中
    downstream.begin(list.size()); // 调用下游的开始操作层层递归
    if (!cancellationWasRequested) {
      // 下游Sink不包含短路操作,那必然是无状态操作或者有状态操作
      list.forEach(downstream::accept);// 将处理结果传递给流水线下游的Sink
    	// list.forEach有自己的实现是for循环调用accept接口即一个个往下传
    }else {// [下游Sink包含短路操作]即下一步就要出结果了,赶紧调用计算
      for (T t : list) {
        // 每次都调用cancellationRequested()询问是否可以结束处理。
        if (downstream.cancellationRequested()) break;
        downstream.accept(t);// 调用下游的计算操作
      }
    }
    downstream.end(); // 调用下游的技术操作
    list = null;
  }
  @Override
  public void accept(T t) {
    list.add(t);// 使用当前Sink包装动作处理t，只是简单的将元素添加到中间列表当中
  }
}
```

因为其无法不借助中间结果,所以我们可以通过begin和end来制约操作执行的实现.我们知道sink的调用顺序时{begin,accept,cancellationRequested,end},我们把其计算部分的实现放到了end上,add用于读取数据而不在用于和map一样进行计算,这样一来,有状态的操作也完成了解耦合,到这一步为止sink封装的stage的操作被定义了出来,如果不涉及到结束操作,那么上述计算就不会发生.同时从上面我们也可以看到其能通过和下游的sink发生交互来查看下游的sink是否是短路操作.

#### 流水线的结果

我们表示了完整的计算链条,上面的计算链条中accept操作只是表示对单一元素的处理直到在有状态和终止操作的时候才会发生相应的计算.其遍历次数大大降低.而流水线的结果根据不同的调用方式以不同的形式保存,如下

| 返回类型 | 对应的结束操作                    |
| -------- | --------------------------------- |
| boolean  | anyMatch() allMatch() noneMatch() |
| Optional | findFirst() findAny()             |
| 归约结果 | reduce() collect()                |
| 数组     | toArray()                         |

 boolean和Optional只需要记录在sink中就可以了.规约结果放在用户指定的容器里



#### 并行流

多线程并行才是流最终的处理目的,串行流的性能有限我们需要多个线程去完成此任务.Stream接口中同样实现了并行的处理模式.stream().parallel()和parallelStream(),并行流默认通过`ForkJoinPool`来提高运行速度.需要注意的是并行的流虽然大幅度提高了性能,但其从某种意义上说来更难以debug,且会因为内部I/O时间过长等问题从而影响到整个线程池的性能.且并行流不是线程安全的,所以在使用的时候要注意I/O和线程安全问题.



## socket

---

socket是java和其他线程等,网络通信的基础,从TCP的传输层出发,作为沟通的单位,其中用的技术是I/O加监听.其监听端口的时候即端口回调了socker接口,通过socket的accept函数返回,才会进行下一步,这一步是阻塞I/O,然后中途进行反复读写相应数据.可以看到在阻塞I/O的模型下两者是相互阻塞的.

![](https://img-blog.csdnimg.cn/20190718154556909.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3Bhc2hhbmh1NjQwMg==,size_16,color_FFFFFF,t_70)

如上为socket客户端和服务端的构建

### socket

-   Socket 是 TCP 客户端 API,通常用于连接远程主机。
-   ServerSocket 是 TCP 服务器 API,通常接受源于客户端套接字的连接。
-   DatagramSocket 是 UDP 端点 API,用于发送和接收数据包
-   MulticastSocket 是 DatagramSocket 的子类,在处理多播组时使用。

socket一般分为两种用途,构造发信器,构造服务器

```java
public class SimpleServer {
  static final ExecutorService pool = Executors.newCachedThreadPool();

  public static void main(String[] args) throws IOException {
    ServerSocket ss = new ServerSocket(8000);
    System.out.println("服务器启动");
    while (true) {
      Socket server = ss.accept();
      System.out.println("一个请求来了");
      pool.submit(() -> {
        try (InputStream ins = server.getInputStream(); OutputStream os = server.getOutputStream()) {
          byte[] buff = new byte[1024];
          int len;
          String readStr;
          while ((len = ins.read(buff)) != -1 && !"bye".equals(readStr = new String(buff, 0, len).trim())) {
            System.out.println(readStr);
            os.write("发送成功".getBytes());
            os.flush();
          }
        } catch (IOException e) {
          System.out.println("客户端请求关闭");
          //                    e.printStackTrace();
        } finally {
          System.out.println("连接关闭");
        }
      });
    }
  }
}
```

发信器的部分一般`nc -vn`命令就可以实现那种带有长连接的tcp发信器,而http的发信只是一个简短的过程发完获取完数据就关闭,所以对于需要保持连接的TCP服务器就需要额外设置指令另其关闭.从这个角度看,TCP的服务器设计是要专门设计才可以进行开启关闭事件而非Http服务器的一次性请求,对于某些要保持长连接的系统(例如游戏服务器,通信客服服务器)应该使用TCP层面的服务器设计,而非使用http.但用tcp服务器可以设计出http服务器,只要把报文处理好就行.下面会展示这种思路设计出来的http服务器.

发信器的构造如下

```java
private void sendMsg(String message) {
Socket socket = null;
try {
  if (USE_HTTPS) { // 是否使用https
    socket = SSLSocketFactory.getDefault().createSocket(HOSTNAME, 443);

  } else {
    socket = new Socket();
    socket.connect(new InetSocketAddress(HOSTNAME, PORT));
  }
  socket.setSoTimeout(1000);
} catch (IOException e) {
  e.printStackTrace();
}
assert socket != null;


try (InputStream is = socket.getInputStream(); OutputStream os = socket.getOutputStream();) {
  os.write(message.getBytes()); // message为发送的信息由函数传入
  os.flush();
  int bufferSize = 1024;
  byte[] bytes = new byte[bufferSize];
  int len = bufferSize;
  while (true) {
    len = is.read(bytes);
    System.out.print(new String(bytes, 0, len, ENCODING));
  }
} catch (IOException e) {
  System.err.println("socket关闭");
}
}
```

对其,我们进行小小的改造,让其能发送最基本的http信息

```java
String message = "GET /" + param + " HTTP/1.1\r\n" +
  "Host: " + HOSTNAME + "\r\n" +
  "Connection: keep-alive\r\n" +
  "sec-ch-ua-mobile: ?0\r\n" +
  "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36\r\n" +
  "sec-ch-ua: \"Google Chrome\";v=\"87\", \" Not;A Brand\";v=\"99\", \"Chromium\";v=\"87\"\r\n" +
  "Accept: */*\r\n" +
  "Sec-Fetch-Site: none\r\n" +
  "Sec-Fetch-Mode: cors\r\n" +
  "Sec-Fetch-Dest: empty\r\n" +
  //  "Accept-Encoding: gzip, deflate, br\r\n" +
  "Accept-Encoding:\n" +
  "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,und;q=0.7,ja;q=0.6,la;q=0.5\r\n\r\n";
sendMsg(message);
```

其实从上面我们就可以看到,其本质就是发送http报文,并无特别的难度.如果要发送其他更加复杂的请求的话,要么自己构造更复杂的报文,要么使用http库



### http库

HttpURLConnection和HttpClient是两个Http请求库,前者为原生jdk,后者为apache项目

-   HttpURLConnection是基于socket建立专门用于发Http请求的库
-   HttpClient属于对上面的封装,对cookie等处理进行了大量优化

**HttpURLConnection在处理非get的问题的时候会变得很复杂**

总的来说这两玩意都是通过搭建TCP的socket然后拼接报文完成,在不同的场合能够适应不同的工作



### socket实现小型http服务器

在这里我们要开始走tomcat的老路,在早期tomcat是一个支持servlet的单实例多线程的服务器,这里我们将用传统I/O实现该服务器.前面我们已经造出了TCP服务器,那么我们其实根据TCP服务器接受请求报文然后编写响应报文即可造出http服务器,我们仿照servlet开始尝试进行制造,其包括以下功能

-   处理get和post请求
-   处理静态文件.html .js
-   处理重定向/forward

上面的处理有利于我们理解tomcat是如何被制造出来的.





### socket实现RPC

-   未完待续



## netty

-   未完待续