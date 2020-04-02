# BIO NIO

----

bio nio 指的是block io和non-blocking io

顾名思义bio就是在io的时候阻塞而non-blocking io则是在io时候不阻塞

其实java中一些api已经用到了该模型Socket,ServerSocket对应的SocketChannel,ServerSocketChannel 就是一个例子

关于传统模型和NIO 可以表述成下图

![NIO/BIO](https://upload-images.jianshu.io/upload_images/1357217-1c856423372e7d5a.png)

随意我们看到IO复用是其中的关键之一

NIO编程的思路是 一个线程把连接注册到selector中 一个线程把selector的连接取出来使用

其实回过头来看 事件轮询机制就是IO多路复用

---

## Channel

和操作系统的通道类似 读线程可以直接读取通道(Channel)中的数据线程去干别的事(不是开辟新线程)写线程也是如此,通道是双向的 流是单向的

## Buffer 

普通IO面向流模型 NIO面向Buffer oriented ,java NIO 提供了每一种基本类型的缓冲区

## 通道和缓冲区的的关系

系统控制通道的数据直接向缓冲区写(计算机组成原理中的DMA) 通道只能与buffer进行交互

## Selectors

选择器用于完成IO复用由一线程完成

其核心实现是epoll模型的I/O复用

## epoll 模型



## 两者特性

Steam面向字节,而NIO面向字节块

Stream是阻塞的NIO是非阻塞的

---

JDK自身携带的api很不好用 所以Netty 封装了这些操作

Netty是一个异步事件驱动的网络应用框架