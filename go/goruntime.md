# runtime

[TOC]

## 语言层面

### goroutine

---

goroutine 类似线程,不同于线程,线程是操作系统调度的,但 goroutine 是由 go 进行调度的,go 会把对应执行的函数智能分配给 cpu.写法很简单,只要在调用函数之前加上`go`关键字就可以了.一个简单的 case

```go
package main

import (
	"fmt"
	"strconv"
	"time"
)

func pri(s string){
	fmt.Println(s)
}

func main() {
	for i := 0; i < 10 ; i++ {
		go pri(strconv.Itoa(i))
	}
	time.Sleep(time.Second * 1) // 这里需要 stop 不然主函数的 goroutine 结束了其子 routine 跟着结束
}
```

和线程相比

-   os 的线程一般拥有 2MB 的栈和TCB, goroutine 拥有 2kb 且不固定可以伸缩,其栈能到 1GB 可以并发 100000 左右
-   goroutine 是 go 自己运行时调度的,这个调度器使用一个称为m:n调度的技术(复用/调度m个goroutine到n个OS线程).goroutine的调度不需要切换内核语境,所以调用一个goroutine比调度一个线程成本低很多.**可以指定`GOMAXPROCS`来指定有多少个操作系统的线程**,go在1.5之后就默认使用全部的核心数,之前是单线程

### channel

对于并发的处理,绝大多数语言选择了共享内存加锁,无论何种锁,都是静态条件的体现,go语言的并发模型是CSP,提倡通信实现共享内存而不是用共享内存实现通信.channel 就是 goroutine 之间的通信机制.channel 类似队列.

```go
func main() {
	var ch chan int // channel 的默认类型是 nil
	ch = make(chan int)
	go func() { ch <- 1 }() // 不在另外的 goroutine 中调用
	value := <-ch
	fmt.Println(value)
}
```

我们编写的 channel 程序又叫协程,channel 会一直阻塞到其他线程(goroutine)去读为止,故如下程序会死锁

```go
var ch chan int
ch = make(chan int)
ch <-1
```

如下

```go
func main() {
	var ch chan int
	ch = make(chan int)
	for i := 0; i < 10; i++ {
		go func() { ch <- i }()
	}
	var s int = 0
	s = <-ch
	fmt.Println(s) // 输出的结果可能是 1到10的任何一个值
}

func main() {
	for t := 0; t < 100; t++ {
		var ch chan int
		ch = make(chan int)
		go func(i int) { ch <- i }(3)
		go func(i int) { ch <- i }(4)
		go func(i int) { ch <- i }(5)
		i := <-ch
		j := <-ch
		k := <-ch
		fmt.Println(i, j, k)
	}
}
```

上面的 channel 是无缓冲区的通道,即发送端需要等待接收端响应,但 channel 可以理解为小型的消息队列,那自然就可以有消息堆积的能力,我们指定消息缓冲区的大小,如果缓冲区堆积满了,发送方会一直等待到缓冲区有空间为止

```go
ch := make(chan int, 100)
```

用 range 可以遍历通道,但如果通道没有关闭,那么就会一直阻塞

```go
for data := range ch {
  fmt.Println(i)
}

// 或者是我们可以使用下列的语句去判断通道里面是否有值
dt,ok := <-ch
```

单向通道

```go
var ch chan int
ch = make(chan int)

go func(c <-chan int) {
  for {
    res, ok := <-c
    if !ok {
      break
    }
    fmt.Println(res)
  }
}(ch)

go func(c chan<- int) { // 单向通道 只能接受不能发送
  for i := 0; i < 100; i++ {
    c <- i
  }
}(ch)

time.Sleep(time.Second * 1)
```

可以利用 select 语句设定超时

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    ch := make(chan int)
    quit := make(chan bool)

    go func() {
        for {
            select {
            case num := <-ch:
                fmt.Println("num = ", num)
            case <-time.After(3 * time.Second):
                fmt.Println("超时")
                quit <- true
            }
        }

    }()

    for i := 0; i < 5; i++ {
        ch <- i
        time.Sleep(time.Second)
    }

    <-quit
    fmt.Println("程序结束")
}
```



### sync 包

在 Java/c++ 中我们一般使用线程池或线程组创建线程.一般都有自己的工具包(例如juc)在 go 中可以使用 sync 包完成对 gorutine的控制,sync 的包都可以视作重量级锁,其需要操作系统切换到内核态

-   waitGroup 计数器,可以简介理解为可加减的 countdown latch
-   Mutex 信号量,单锁
-   RWMutex 读写锁
-   Once 资源只加载一次(函数只执行一次)
-   Map 类比于 concurrentHashMap
-   atomic 包 提供原子性操作,不需要切换到内核态

```go
var wg sync.WaitGroup

func hello(i int) {
    defer wg.Done()
    fmt.Println("Hello Goroutine!", i)
}

func main() {
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go hello(i)
    }
    wg.Wait()
}
```

一个简单的 waitgroup 计数器就做好了 done 是 -1, Add 是 +1

```go
var x int64
var wg sync.WaitGroup
var lock sync.Mutex

func add() {
    for i := 0; i < 5000; i++ {
        lock.Lock() // 加锁
        x = x + 1
        lock.Unlock() // 解锁
    }
    wg.Done()
}

func main() {
    wg.Add(2)
    go add()
    go add()
    wg.Wait()
    fmt.Println(x)
}
```

读写锁就和其使用场景一样,读多写少,读读共享锁,读写互斥,写写互斥.

```go
var (
    x      int64
    wg     sync.WaitGroup
    lock   sync.Mutex
    rwlock sync.RWMutex
)

func write() {
    rwlock.Lock() // 加写锁
    x = x + 1
    time.Sleep(10 * time.Millisecond) // 假设读操作耗时10毫秒
    rwlock.Unlock()                   // 解写锁
    wg.Done()
}

func read() {
    rwlock.RLock()               // 加读锁
    time.Sleep(time.Millisecond) // 假设读操作耗时1毫秒
    rwlock.RUnlock()             // 解读锁
    wg.Done()
}

func main() {
    start := time.Now()
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go write()
    }

    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go read()
    }

    wg.Wait()
    end := time.Now()
    fmt.Println(end.Sub(start))
}
```



## 虚拟机与内存

### C 的内存分配

我们看下c语言的内存分配一般是这种形式,栈往下长,堆往上涨

![](https://upload-images.jianshu.io/upload_images/6328562-4df0b8ade52e88fd.png)

>   Go是内置运行时的编程语言(runtime)，像这种内置运行时的编程语言通常会抛弃传统的内存分配方式，改为自己管理。这样可以完成类似预分配、内存池等操作，以避开系统调用带来的性能问题，防止每次分配内存都需要系统调用。

### go 的内存分配

Go的内存分配的核心思想可以分为以下几点：

-   每次从操作系统申请一大块儿的内存，由Go来对这块儿内存做分配，减少系统调用
-   内存分配算法采用Google的 **TCMalloc**算法。算法比较复杂，究其原理可自行查阅。其核心思想就是把内存切分的非常的细小，分为多级管理，以降低锁的粒度。
-   回收对象内存时，并没有将其真正释放掉，只是放回预先分配的大块内存中，以便复用。只有内存闲置过多的时候，才会尝试归还部分内存给操作系统，降低整体开销

go 会去申请一块虚拟内存,如下

![](https://pic4.zhimg.com/80/v2-d5f5de4d6d22e67887ab4861ba5e721f_1440w.jpg)![img](https://pic4.zhimg.com/80/v2-d5f5de4d6d22e67887ab4861ba5e721f_1440w.jpg)

其分为了3个区域

-   arena 就是其他语言的堆区,go 的动态分配都是这个区域,把内存分割成 8kb 大小的页,一些页组合起来叫 mspan
-   bitmap 用于标识 arena 区域中保存了哪些对象,4bit
-   spans 



### 栈区

go 调用方法的时候限制最大参数为 2000 byte







### TCMalloc





### gc

首先来看使用 gc 的工具

```shell
GODEBUG=gctrace=1  go run main.go # 开启追踪 gc
```

快速实现监控线程

```go
import (
    "net/http"
    _ "net/http/pprof"
)
go func() {
            log.Println(http.ListenAndServe("localhost:8081", nil))
}()
```





### TCP





