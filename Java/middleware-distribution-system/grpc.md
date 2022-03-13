# Grpc

---

[TOC]

## rpc & http

grpc 即 google remote procedure call.在开始之前,我们先要看下其与http/tcp的区别.

> 一个完整的RPC[架构](https://so.csdn.net/so/search?q=架构&spm=1001.2101.3001.7020)里面包含了四个核心的组件,分别是Client ,Server,ClientOptions以及ServerOptions,这个Options就是RPC需要设计实现的东西。
>
> - 客户端（Client）：服务的调用方。
> - 服务端（Server）：真正的服务提供方。
> - 客户端存根（ClientOption / Client Stub）：socket管理，网络收发包的序列化。
> - 服务端存根（ServerOption / Server Stub）：socket管理，提醒server层rpc方法调用，以及网络收发包的序列化。

<img src="https://img-blog.csdnimg.cn/20210209104427782.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM2MzEwNzU4,size_16,color_FFFFFF,t_70#pic_center" alt="50" style="zoom:67%;" />

所以我们看到,rpc 和 http 显著不同的地方还需要考虑其序列化,以及调用和返回,最后还有 socket 之间的通信协议

<img src="https://lh3.googleusercontent.com/dJ0owNAZSWydRP90-wRzBnvBgLjjp2bQOb_Rtvq46PnKS882SRWEMtZ00887IVfOIkEommQZu1_vCaZHx3yNZerimxf4dxr8XeEscMNamAv_YblZP51tsXrYbFHgyxm8mOk0fIA6N5g" alt="50" style="zoom:70%;" />

## HTTP 2.0

[参考](http://xiaorui.cc/archives/7013),[参考](http://xiaorui.cc/archives/7054)

### RTT 

RTT (round trip time) 即生命周期内,或者是来回一次所需要的时间

![](http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0006-squashed.jpg)

Http 在无缓存的情况下会接收到很多这样的ACK应答,RRT的开销会很大,dns服务器也会消耗一个RTT,HTTP前期的TCP握手会消耗两个RTT,https要经历三次握手的RTT还要tls的2词rtt,ocsp校验还要几个RTT.

### Http 2.0

协议设计时需要考虑的问题有很多,像 thrift 基本上 load balancer 就不会支持.而 grpc 基本所有的 proxy 都支持,因为 proxy 支持 http2 比 thrift 协议要容易的多.

我们平时使用的协议是 http 1.1 其缺点非常明显,一个链接同一时间只能处理一个请求,请求**阻塞**则连接直接站住. 而 http1.1 pipeline 没有完全解决这个问题.http2.0 使用了多路复用技术如下,其并非 epoll 对 tcp 链接的复用,而是协议层的流并发复用,本质上链接还是那么多,但我发送的数据在传输层面解决成流的传输

![](http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0012-squashed.jpg)

即没有阻塞通路异步了接受响应的过程.http2.0 的最小单位是 frame 但是已经有了明确的 stream 概念,通过一个 id 来区分并发过来的请求.其是一个二进制协议

<img src="http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0022-squashed.jpg" alt="7" style="zoom:40%;" />





## protobuf

[参考](https://www.jianshu.com/p/73c9ed3a4877)

一种高效的压缩协议,来自 google.初学者可以类比于 json. 

![](https://upload-images.jianshu.io/upload_images/6009978-fa1925e9b2c985e3.png?imageMogr2/auto-orient/strip|imageView2/2/w/900/format/webp)

![](https://upload-images.jianshu.io/upload_images/6009978-334273bbb6191fd6.png?imageMogr2/auto-orient/strip|imageView2/2/w/680/format/webp)

message 由 一个个字段组成,其编写的时候先解析成上述结构,Length 是可选则断

### tag

![](https://upload-images.jianshu.io/upload_images/6009978-9ac80dc61783d5eb.png?imageMogr2/auto-orient/strip|imageView2/2/w/520/format/webp)

整个 tag 采用**Varints 编码**

- field_number 定义字段时的字段编号
- wire_type protobuf 编码类型

> 我们接收到了一串序列化的二进制数据，我们先读一个 Varints 编码块，进行 Varints 解码，读取最后 3 bit 得到 wire_type（由此可知是后面的 Value 采用的哪种编码），随后获取到 field_number （由此可知是哪一个字段）。依据 wire_type 来正确读取后面的 Value。接着继续读取下一个字段 field

### Varints 编码

其规则如下

- 在每个字节开头的 bit 设置了 **msb(most significant bit)**，标识是否需要继续读取下一个字节
- 存储数字对应的二进制补码
- 补码的低位排在前面

> arints 的本质实际上是每个字节都**牺牲**一个 bit 位（msb），来表示是否已经结束（是否还需要读取下一个字节），msb 实际上就起到了 Length 的作用，正因为有了 msb（Length），所以我们可以摆脱原来那种无论数字大小都必须分配四个字节的窘境。**通过 Varints 我们可以让小的数字用更少的字节表示**



### ZigZag 编码

>  有符号整数映射到无符号整数，然后再使用 Varints 编码。这样就解决了负数的问题

![](https://upload-images.jianshu.io/upload_images/6009978-e4df40b2cb502e6e.png?imageMogr2/auto-orient/strip|imageView2/2/w/720/format/webp)

### packed 编码

> 主要使让 ProtoBuf 为我们把 repeated primitive 的编码结果打包，从而进一步压缩空间，进一步提高效率、速度。这里打包的含义其实就是：原先的 repeated 字段的编码结构为 **Tag-Length-Value-Tag-Length-Value-Tag-Length-Value...**，因为这些 Tag 都是相同的（同一字段），因此可以将这些字段的 Value 打包，即将编码结构变为 **Tag-Length-Value-Value-Value...**

### TLV

Tag-Length-Value 上面的总称

![](http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0036-squashed.jpg)

上面这张图可以清晰看到 TLV 编码是如何实现的



## grpc

> gRPC是RPC的一种，它使用Protocol Buffer(简称Protobuf)作为序列化格式，Protocol Buffer是来自google的序列化框架，比Json更加轻便高效，同时基于 HTTP/2 标准设计，带来诸如双向流、流控、头部压缩、单 TCP 连接上的多复用请求等特性。这些特性使得其在移动设备上表现更好，更省电和节省空间占用。用protoc就能使用proto文件帮助我们生成上面的option层代码。
>
> 适用场景
>
> - 分布式场景 ：gRPC设计为低延迟和高吞吐量通信，非常适用于效率至关重要的轻型微服务。
> - 点对点实时通信： gRPC对双向流媒体提供出色的支持，可以实时推送消息而无需轮询。
> - 多语言混合开发 ：支持主流的开发语言，使gRPC成为多语言开发环境的理想选择。
> - 网络受限环境 ： 使用Protobuf（一种轻量级消息格式）序列化gRPC消息。gRPC消息始终小于等效的JSON消息。

### grpc 的调用方式

- 单项RPC (发送应答结束)
- 服务端流式RPC (客户端发送一个请求给服务端，可获取一个数据流用来读取一系列消息。客户端从返回的数据流里一直读取直到没有更多消息为止)
- 客户端流式RPC (即客户端用提供的一个数据流写入并发送一系列消息给服务端。一旦客户端完成消息写入，就等待服务端读取这些消息并返回应答)
- 双向流PRC (两边都可以分别通过一个读写数据流来发送一系列消息。这两个数据流操作是相互独立的，所以客户端和服务端能按其希望的任意顺序读写，例如：服务端可以在写应答前等待所有的客户端消息，或者它可以先读一个消息再写一个消息，或者是读写相结合的其他方式。每个数据流里消息的顺序会被保持)

我们直接看其中最重点的双向流 RPC

<img src="https://img-blog.csdnimg.cn/20210209104659217.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM2MzEwNzU4,size_16,color_FFFFFF,t_70#pic_center" style="zoom:50%;" />

这里和服务端客户端流式类似,不通点在于要双方应答才可结束通信.

### k8s pod using grpc

<img src="http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0057-squashed.jpg" style="zoom:40%;" />

<img src="http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0058-squashed.jpg" alt="4" style="zoom:40%;" />

其基于 tcp 如果发生丢包,会重传及时,避免用赛发生,窗口降为1,进行重传和慢启动

<img src="http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0059-squashed.jpg" alt="4" style="zoom:40%;" />

<img src="http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0062-squashed.jpg" alt="4" style="zoom:40%;" />



### 使用 grpc

#### unary

[参考](https://www.grpc.io/docs/languages/go/quickstart/)

安装先决环境

```shell
brew install protobuf
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
```

我们先定义数据结构 proto 文件编写

```protobuf
syntax = "proto3"; // 指定语法
option go_package = "./rpc"; // 当前目录
service Greeter { // 客户端服务名
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// 参照上面的类型写客户端请求和应答数据协议

// The request message containing the user's name.
message HelloRequest {
  string name = 1; 
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

```shell
protoc -I=. --go_out=plugins=grpc:. ./test.proto
```

生成可执行的 go 文件,此处需要 `protoc-gen-go`我们关注生成文件的如下结构体

```go
type GreeterClient interface {
	// Sends a greeting
	SayHello(ctx context.Context, in *HelloRequest, opts ...grpc.CallOption) (*HelloReply, error)
	// Sends another greeting
	SayHelloAgain(ctx context.Context, in *HelloRequest, opts ...grpc.CallOption) (*HelloReply, error)
}

type GreeterServer interface {
	// Sends a greeting
	SayHello(context.Context, *HelloRequest) (*HelloReply, error)
	// Sends another greeting
	SayHelloAgain(context.Context, *HelloRequest) (*HelloReply, error)
}
```

我们需要在自己的服务端实现这两个接口

```go
package main

import (
	"context"
	"fmt"
	pb "go-toy/rpc/proto/rpc"
	"google.golang.org/grpc"
	"log"
	"time"
)

func main() {
	//创建一个grpc连接
	conn, err := grpc.Dial("localhost:8002", grpc.WithInsecure())
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()

	//创建RPC客户端
	client := pb.NewGreeterClient(conn)
	//设置超时时间
	_, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	// 调用方法,客户端直接使用即可
	reply, err := client.SayHello(context.Background(), &pb.HelloRequest{Name: "我抄"})
	areply, err := client.SayHelloAgain(context.Background(), &pb.HelloRequest{Name: "我抄"})
	if err != nil {
		log.Fatalf("couldn not greet: %v", err)
	}
	log.Println(reply.Message)
	log.Println(areply.Message)
}
```

```go
package main

import (
	"context"
	"fmt"
	pb "go-toy/rpc/proto/rpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log"
	"net"
)

type Server struct {
}

//实现SayHello接口
func (s *Server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	log.Println(in.Name)
	return &pb.HelloReply{Message: "msg"}, nil // 应答
}

//实现SayHello接口
func (s *Server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	log.Println(in.Name)
	return &pb.HelloReply{Message: "msg"}, nil // 应答
}

func main() {
	//协议类型以及ip，port
	lis, err := net.Listen("tcp", ":8002")
	if err != nil {
		fmt.Println(err)
		return
	}

	//定义一个rpc的server
	server := grpc.NewServer()
	//注册服务，相当与注册SayHello接口
	pb.RegisterGreeterServer(server, &Server{})
	//进行映射绑定
	reflection.Register(server)

	//启动服务
	err = server.Serve(lis)
	if err != nil {
		fmt.Println(err)
		return
	}
}
```

#### streaming

- client streaming
- server streaming
- bidi streaming

我们不关心通信的数据结构而关心服务的定义,在单项通信中,我们有如下定义,其返回了直接HelloReply,我们在这里返回流式的结构

```protobuf
service Greeter { // 客户端服务名
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}
```

```protobuf
service Greet{
  rpc SayHello (HelloRequest) returns(stream HelloReply) {}
}
```

我们在此处返回 stream 的结构,然后调整实现,需要注意的是,服务端流指的是服务端向客户端发送若干消息,即服务端发送应答流.

```go
reply, err := client.SayHello(context.Background(), &pb.HelloRequest{Name: "wcccc"})
for {
		recv, err := reply.Recv()
		if err != nil {
			fmt.Println(err)
			break
		}
		fmt.Println(recv)
	}
```

服务端的改动会比较大

```go
func (s *Server) SayHello(request *pb.HelloRequest, server pb.Greeter_SayHelloServer) error {
	fmt.Println(request)
	var err error
	for i := 0; i < 2; i++ {
		err = server.Send(&pb.HelloReply{Message: strconv.Itoa(i) + " reply"})
		if err != nil {
			fmt.Println(err)
			return err
		}
	}
	return nil
}
```

同理我们可以编写客户端流的RPC

```protobuf
service Greets{
  rpc SayHello (stream HelloRequest) returns (HelloReply) {}
}
```

```go
func (*Server) SayHello(in pb.Greets_SayHelloServer) error {
	for {
		recv, err := in.Recv()
		//接收完数据之后发送响应
		if err == io.EOF {
			err := in.SendAndClose(&pb.HelloReply{Name: "ww", Message: "t"})
			if err != nil {
				return err
			}
			return nil
		} else if err != nil {
			return err
		}
		fmt.Println(recv)
	}
}
```

```go
for i:=0;i<10;i++ {
      err = greetClient.Send(&pb.HelloRequest{Name: "xx", Message: strconv(i)+"request"})
}
greetClient.CloseAndRecv()
```

同理可以实现双向流请求

### grpc 设计

![](http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0003-squashed.jpg)

grpc 由是三部分组成

- Http2 网络传输层
- protobuf 序列化协议
- sdk

![](http://xiaorui.cc/wp-content/uploads/2020/08/grpc-protobuf-http2_compressed_page-0042-squashed.jpg)





### Java Gprc

#### Netty

- 未完待续

#### source code

- 未完待续



## 原生 RPC 实现

除了 grpc 外我们也可以自己实现上面的过程,Java 可以利用Netty NIO TCP 协议栈进行开发.基于 TCP 实现的 RPC 性能很高可以根据TCP 灵活调整协议字段,网络开销更小.Http 实现协议栈则会比较重.基于 Http 2.0 协议实现的 grpc 和 tcp 大致相当.从 grpc 我们大概可以知道其物理实现有三部分

- 通信协议转可执行代码(预留接口实现)
- 序列化,反序列化协议
- 网络通信管理

未完待续