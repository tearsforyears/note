#  runtime

[TOC]

## 前言

2022年03月14日 记录此文档的前言,有感而发,关于c/c++,go和java 三者,java和go都是一种折中,STW 机制是该类自动内存管理语言的特点,既有优点也有劣势,如果对性能有极致的追求请不要使用c/c++以外的语言.c/c++需要技术功底,但对于go而言其相比java是更好的折中,在一个月的使用体验后.作为基础设施,c++有无可替代的地位,无论是何种程序员请务必学好c/c++.

因为现团队对Java盲目的自信,以及对所谓技术的故步自封,必然会导致思维的离经叛道.我不反对使用java,其是门好语言,在平衡性能和开发效率上.技术从来都该用在适合他的地方,程序员的内功不是语言本身,jvm 只是一个有意思的实践.实现和理解都是关键,项目管理能力也是.

希望未来,能深入整个计算机体系,能够用好所有技术,不被眼前或者未来所束缚,明晰方向而前进,我目前看到了基础架构的开发者比业务更好的实践,但愿心明眼亮,祝每个人好运.

## 语言层面

前言 goroutine 在并发上面的使用比起 java 简单的锁更接近底层,也会碰触到C++以及操作系统层面的并发.这方面 java 确实无法比拟,这里也是 golang 并发的基本功.请务必精通此处的知识.

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



### context





## 虚拟机与内存分配

### C 的内存分配

我们看下c语言的内存分配一般是这种形式,栈往下长,堆往上涨

![](https://upload-images.jianshu.io/upload_images/47789-897cb16e0f90fd7b.png?imageMogr2/auto-orient/strip|imageView2/2/w/578/format/webp)

>   Go是内置运行时的编程语言(runtime)，像这种内置运行时的编程语言通常会抛弃传统的内存分配方式，改为自己管理。这样可以完成类似预分配、内存池等操作，以避开系统调用带来的性能问题，防止每次分配内存都需要系统调用。

### 内联 inline

c++ 特有的特性,因为在函数调用的时候会使用到栈,函数返回表等需要额外性能开销的东西,为了减少性能开销,直接把相应的代码替换上去,这称之为内联,这回增加程序的体积(相当于不使用函数),但会减少开销,需要程序员权衡使用

```c++
inline int Max (int a, int b)
{
    if(a >b)
        return a;
    return b;
}
```

> - 内联就是用函数已被编译好的二进制代码，替换对该函数的调用指令
> - 内联在保证函数特性的同时，避免了函数调用的开销
> - 内联通过牺牲代码空间，赢得了运行时间

内联也可以视为一种**编译**优化策略

- 若函数在类或结构体的内部直接定义，则该函数被自动优化为内联函数，谓之隐式内联
- 若在函数定义前面，加上inline关键字，可以显式告诉编译器，该函数被希望优化为内联函数，这叫显式内联



### 句柄

句柄（handle）是C++程序设计中经常提及的一个术语。它并不是一种具体的、固定不变的数据类型或实体，而是代表了程序设计中的一个广义的概念。句柄一般是指获取另一个对象的方法——一个广义的指针，它的具体形式可能是一个整数、一个对象或就是一个真实的指针，而它的目的就是建立起与被访问对象之间的唯一的联系



### go 的内存

各个区域直接的关系

![](http://5b0988e595225.cdn.sohucs.com/images/20190612/71be99fcaeb540faa2852df5890cae51.jpeg)

![](https://image-static.segmentfault.com/413/158/4131582486-51e036ccb53d5d1a)

- mspan 由操作系统管理的 spans 的元数据,指针存放在 spans 区域,该指针指向 arena 区域
- mcache->spans 线程独有 mcache 对 spans 进行管理
- spans(*mspan 所管理的对象整块内存)->span
  - mspan 是 span 的元数据结构,从这个区域存放 mspan的指针,真正的 mspan 存在 arena  ,以双端链表的形式组织起多个 span
  - spans 是指 mspan* 指针的区域里面,mspan 存放 span 的数据结构,span 包含多个 pages
  - arena-pages 若干 page 组成了一个 span
- bitmap
  - pages

Go的内存分配的核心思想可以分为以下几点：

-   每次从操作系统申请一大块儿的内存，由Go来对这块儿内存做分配，减少系统调用
-   内存分配算法采用Google的**TCMalloc**算法。算法比较复杂，究其原理可自行查阅。其核心思想就是把内存切分的非常的细小，分为多级管理，以降低锁的粒度。
-   回收对象内存时，并没有将其真正释放掉，只是放回预先分配的大块内存中，以便复用。只有内存闲置过多的时候，才会尝试归还部分内存给操作系统，降低整体开销

go 会去申请一块虚拟内存,如下

![](https://pic4.zhimg.com/80/v2-d5f5de4d6d22e67887ab4861ba5e721f_1440w.jpg)![img](https://pic4.zhimg.com/80/v2-d5f5de4d6d22e67887ab4861ba5e721f_1440w.jpg)

其分为了3个区域

-   arena 就是其他语言的堆区,go 的动态分配都是这个区域,把内存分割成 8kb 大小的页,一些页组合起来叫 mspan
-   bitmap 用于标识 arena 区域中保存了哪些对象,4bit 表示 
    -   包含指针
    -   GC 标记
-   spans 保存了指针,一个指针的大小是 8 byte

#### spans

<img src="http://5b0988e595225.cdn.sohucs.com/images/20190612/8b4facbea912482b958be23edf7d911a.png" alt="5" style="zoom:80%;float:center" />

spans 管理 arena 中的对象,管理对象的元数据叫 mspan,spans 存储 mspan 的指针.下面会详细描述该结构.



#### arena

-   从内存分配的角度去看,其就是一个个被等大小的 **page**
-   从程序的角度其实一个个**对象**
-   其相当于一个堆区,管理着所有新出来的对象
-   arena 不止一个



#### bitmap

bitmap 有好几种

-   stack
-   data
-   bss bitmap
-   heap bitmap

主要讨论 heap bitmap,其标识 arena 区域哪些地址保存了对象,包含是否为对象和 GC 信息,如下图从高地址指向低地址.所以我们也知道了 bitmap 是从低地址往高地址长的,而 arena 是高地址往低地址长,从上图看起来就是从某一个点开始向两边长.bitmap 的主要作用就是服务于GC.

![](https://pic1.zhimg.com/80/v2-88e126617a256999b7a99977be676784_1440w.jpg)

标识一个对象有两个 bit,所以一个字节能标识4个对象,这两个bit分别表示两个作用

-   gc 标记
-   地址中是否存在对象



#### span

go 在管理的时候有 67 种大小的块(span),这也是 TCMalloc 的思路,然后按需使用,根据使用量寻找合适的span

```go
// path: /usr/local/go/src/sizeclasses.go

const _NumSizeClasses = 67

var class_to_size = [_NumSizeClasses]uint16{0, 8, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 288, 320, 352, 384, 416, 448, 480, 512, 576, 640, 704, 768, 896, 1024, 1152, 1280, 1408, 1536,1792, 2048, 2304, 2688, 3072, 3200, 3456, 4096, 4864, 5376, 6144, 6528, 6784, 6912, 8192, 9472, 9728, 10240, 10880, 12288, 13568, 14336, 16384, 18432, 19072, 20480, 21760, 24576, 27264, 28672, 32768}
```

超过 32kb 的时候会被认定为是特别的对象进行对待.

span 中包含以下信息

-   class： class ID，每个span结构中都有一个class ID, 表示该span可处理的对象类型
-   bytes/obj：该class代表对象的字节数
-   bytes/span：每个span占用堆的字节数，也即页数*页大小
-   objects: 每个span可分配的对象个数，也即（bytes/spans）/（bytes/obj）
-   waste bytes: 每个span产生的内存碎片，也即（bytes/spans）%（bytes/obj）

<img src="http://5b0988e595225.cdn.sohucs.com/images/20190612/ab9c52f725a847409220b1472e58e352.jpeg" alt="50" style="zoom:67%;" />

看上面的图我们会发现同一类型的 span 可能会有很多个,看其注释可以知道这些span占多少空间

```go
// class  bytes/obj  bytes/span  objects  tail waste  max waste
//     1          8        8192     1024           0     87.50%
//     2         16        8192      512           0     43.75%
//     3         24        8192      341           8     29.24%
```

每个 obj 占 8 byte,每个 span 一共占 8kb 可以装 1k 对象

#### 内存管理组件

![](http://5b0988e595225.cdn.sohucs.com/images/20190612/a886c49319d744faa230ee2dcaaa424b.png)

从上图可以看到除了对象本身之外还有一些结构是管理对象本身的,我们下面给出相应的说明.

-   mspan 为内存管理的基础单元，直接存储数据的地方。
-   mcache 每个运行期的 goroutine 都会绑定的一个 mcache (具体来讲是绑定的GMP并发模型中的P，所以可以无锁分配 mspan，后续还会说到)， mcache 会分配 goroutine 运行中所需要的内存空间(即 mspan )。
-   mcentral 为所有 mcache 切分好后备的 mspan
-   mheap 代表 Go 程序持有的所有堆空间。还会管理闲置的 span，需要时向操作系统申请新内存。

##### mspan

>    mspan 是一个包含起始地址、`mspan`规格、页的数量等内容的双端链表,这个链表是比 span 打一层的结构如下
>
>    span: class相同，多个连续pages
>
>    mspan是span节点的实际struct，mspan组成双端队列

![](https://pic2.zhimg.com/80/v2-3bf9a26798351ae6ad557a195a1e204d_1440w.jpg)

<img src="https://pic2.zhimg.com/80/v2-57c743a87c884c51a949d614208905a9_1440w.jpg" style="zoom:70%;" />

mspan 实际上是操作系统分配的,看下面的定义,其是分配在栈上面的.

```go
//go:notinheap
type mspan struct {
	next *mspan     // next span in list, or nil if none
	prev *mspan     // previous span in list, or nil if none
	list *mSpanList // For debugging. TODO: Remove.

	startAddr uintptr // address of first byte of span aka s.base()
	npages    uintptr // number of pages in span

	manualFreeList gclinkptr // list of free objects in mSpanManual spans

	// freeindex is the slot index between 0 and nelems at which to begin scanning
	// for the next free object in this span.
	// Each allocation scans allocBits starting at freeindex until it encounters a 0
	// indicating a free object. freeindex is then adjusted so that subsequent scans begin
	// just past the newly discovered free object.
	//
	// If freeindex == nelem, this span has no free objects.
	//
	// allocBits is a bitmap of objects in this span.
	// If n >= freeindex and allocBits[n/8] & (1<<(n%8)) is 0
	// then object n is free;
	// otherwise, object n is allocated. Bits starting at nelem are
	// undefined and should never be referenced.
	//
	// Object n starts at address n*elemsize + (start << pageShift).
	freeindex uintptr
	// TODO: Look up nelems from sizeclass and remove this field if it
	// helps performance.
	nelems uintptr // number of object in the span.

	// Cache of the allocBits at freeindex. allocCache is shifted
	// such that the lowest bit corresponds to the bit freeindex.
	// allocCache holds the complement of allocBits, thus allowing
	// ctz (count trailing zero) to use it directly.
	// allocCache may contain bits beyond s.nelems; the caller must ignore
	// these.
	allocCache uint64

	// allocBits and gcmarkBits hold pointers to a span's mark and
	// allocation bits. The pointers are 8 byte aligned.
	// There are three arenas where this data is held.
	// free: Dirty arenas that are no longer accessed
	//       and can be reused.
	// next: Holds information to be used in the next GC cycle.
	// current: Information being used during this GC cycle.
	// previous: Information being used during the last GC cycle.
	// A new GC cycle starts with the call to finishsweep_m.
	// finishsweep_m moves the previous arena to the free arena,
	// the current arena to the previous arena, and
	// the next arena to the current arena.
	// The next arena is populated as the spans request
	// memory to hold gcmarkBits for the next GC cycle as well
	// as allocBits for newly allocated spans.
	//
	// The pointer arithmetic is done "by hand" instead of using
	// arrays to avoid bounds checks along critical performance
	// paths.
	// The sweep will free the old allocBits and set allocBits to the
	// gcmarkBits. The gcmarkBits are replaced with a fresh zeroed
	// out memory.
	allocBits  *gcBits
	gcmarkBits *gcBits

	// sweep generation:
	// if sweepgen == h->sweepgen - 2, the span needs sweeping
	// if sweepgen == h->sweepgen - 1, the span is currently being swept
	// if sweepgen == h->sweepgen, the span is swept and ready to use
	// if sweepgen == h->sweepgen + 1, the span was cached before sweep began and is still cached, and needs sweeping
	// if sweepgen == h->sweepgen + 3, the span was swept and then cached and is still cached
	// h->sweepgen is incremented by 2 after every GC

	sweepgen    uint32
	divMul      uint16        // for divide by elemsize - divMagic.mul
	baseMask    uint16        // if non-0, elemsize is a power of 2, & this will get object allocation base
	allocCount  uint16        // number of allocated objects
	spanclass   spanClass     // size class and noscan (uint8)
	state       mSpanStateBox // mSpanInUse etc; accessed atomically (get/set methods)
	needzero    uint8         // needs to be zeroed before allocation
	divShift    uint8         // for divide by elemsize - divMagic.shift
	divShift2   uint8         // for divide by elemsize - divMagic.shift2
	elemsize    uintptr       // computed from sizeclass or from npages
	limit       uintptr       // end of data in span
	speciallock mutex         // guards specials list
	specials    *special      // linked list of special records sorted by offset.
}
```



##### mcache

![](https://image-static.segmentfault.com/413/158/4131582486-51e036ccb53d5d1a)

上面这幅图说明了各个组件之间的作用和关联,mcache 适用于在单线程内分配内存的(无锁 mspan 分配), mcentral 是用于切分 mspan 的.但它是线程共享的,所以需要信号量去控制其锁的情况.

每个 goroutine 都会绑定个mcache,每个线程本地缓存 mspan 资源,直接给 gorutine 分配就不需要考虑过个 gorutine 的竞争问题.

![](http://5b0988e595225.cdn.sohucs.com/images/20190612/cbdf952b8cbc45d39e4e50bc280176e1.jpeg)

Mcache 的 span 分两组,一是可以包含指针对象的 span,另一类是不包含指针对象的 span.对于不包含指针的对象列表无需进一步扫描是否引用其他活跃的对象.

> 对于 <=32k的对象，将直接通过 mcache分配

<img src="https://pic4.zhimg.com/80/v2-e6e061c4f9e1212b2bf32728dcb2aa17_1440w.jpg" alt="50" style="zoom:50%;" />

在刚开始使用的时候mcache是没有资源的,使用过程中会动态的从mcentral中申请然后缓存下来,然后用于小对象的分配 

```go
type mcache struct {
	// The following members are accessed on every malloc,
	// so they are grouped here for better caching.
	nextSample uintptr // trigger heap sample after allocating this many bytes
	scanAlloc  uintptr // bytes of scannable heap allocated

	// Allocator cache for tiny objects w/o pointers.
	// See "Tiny allocator" comment in malloc.go.

	// tiny points to the beginning of the current tiny block, or
	// nil if there is no current tiny block.
	//
	// tiny is a heap pointer. Since mcache is in non-GC'd memory,
	// we handle it by clearing it in releaseAll during mark
	// termination.
	//
	// tinyAllocs is the number of tiny allocations performed
	// by the P that owns this mcache.
	tiny       uintptr // (size < 16 bytes，no pointers)
	tinyoffset uintptr
	tinyAllocs uintptr

	// The rest is not accessed on every malloc.

	alloc [numSpanClasses]*mspan // spans to allocate from, indexed by spanClass

	stackcache [_NumStackOrders]stackfreelist

	// flushGen indicates the sweepgen during which this mcache
	// was last flushed. If flushGen != mheap_.sweepgen, the spans
	// in this mcache are stale and need to the flushed so they
	// can be swept. This is done in acquirep.
	flushGen uint32
}
```





##### mcentral

每个`central`保存一种特定大小的全局`mspan`列表，包括已分配出去的和未分配出去的。

>   为所有`mcache`提供切分好的`mspan`资源。每个 mcentral 对应一种 mspan. 而`mspan`的种类导致它分割的`object`大小不同.
>
>   当工作线程的`mcache`中没有合适（也就是特定大小的）的`mspan`时就会从`mcentral`获取.
>
>   `mcentral`被所有的工作线程共同享有，存在多个Goroutine竞争的情况，因此会消耗锁资源.

```go
type mcentral struct {
	spanclass spanClass

	// partial and full contain two mspan sets: one of swept in-use
	// spans, and one of unswept in-use spans. These two trade
	// roles on each GC cycle. The unswept set is drained either by
	// allocation or by the background sweeper in every GC cycle,
	// so only two roles are necessary.
	//
	// sweepgen is increased by 2 on each GC cycle, so the swept
	// spans are in partial[sweepgen/2%2] and the unswept spans are in
	// partial[1-sweepgen/2%2]. Sweeping pops spans from the
	// unswept set and pushes spans that are still in-use on the
	// swept set. Likewise, allocating an in-use span pushes it
	// on the swept set.
	//
	// Some parts of the sweeper can sweep arbitrary spans, and hence
	// can't remove them from the unswept set, but will add the span
	// to the appropriate swept list. As a result, the parts of the
	// sweeper and mcentral that do consume from the unswept list may
	// encounter swept spans, and these should be ignored.
	partial [2]spanSet // list of spans with a free object
	full    [2]spanSet // list of spans with no free objects
}

type spanSet struct {
	// A spanSet is a two-level data structure consisting of a
	// growable spine that points to fixed-sized blocks. The spine
	// can be accessed without locks, but adding a block or
	// growing it requires taking the spine lock.
	//
	// Because each mspan covers at least 8K of heap and takes at
	// most 8 bytes in the spanSet, the growth of the spine is
	// quite limited.
	//
	// The spine and all blocks are allocated off-heap, which
	// allows this to be used in the memory manager and avoids the
	// need for write barriers on all of these. spanSetBlocks are
	// managed in a pool, though never freed back to the operating
	// system. We never release spine memory because there could be
	// concurrent lock-free access and we're likely to reuse it
	// anyway. (In principle, we could do this during STW.)

	spineLock mutex
	spine     unsafe.Pointer // *[N]*spanSetBlock, accessed atomically
	spineLen  uintptr        // Spine array length, accessed atomically
	spineCap  uintptr        // Spine array cap, accessed under lock

	// index is the head and tail of the spanSet in a single field.
	// The head and the tail both represent an index into the logical
	// concatenation of all blocks, with the head always behind or
	// equal to the tail (indicating an empty set). This field is
	// always accessed atomically.
	//
	// The head and the tail are only 32 bits wide, which means we
	// can only support up to 2^32 pushes before a reset. If every
	// span in the heap were stored in this set, and each span were
	// the minimum size (1 runtime page, 8 KiB), then roughly the
	// smallest heap which would be unrepresentable is 32 TiB in size.
	index headTailIndex
}
```

![](https://pic2.zhimg.com/80/v2-f35013240082c8a6c4423a86d3a69cc5_1440w.jpg)

对照上图就会发现他维护了两个 list 的接口,上图是旧版本的go锁的粒度比较大,而1.16的源码中,锁在两个 list 中



##### mheap

![](http://5b0988e595225.cdn.sohucs.com/images/20190612/3f2aeb29311343889223b18660e3efae.png)

>   `mheap`：代表Go程序持有的所有堆空间，Go程序使用一个`mheap`的全局对象`_mheap`来管理堆内存。

```go
type mheap struct {
	// lock must only be acquired on the system stack, otherwise a g
	// could self-deadlock if its stack grows with the lock held.
	lock      mutex
	pages     pageAlloc // page allocation data structure
	sweepgen  uint32    // sweep generation, see comment in mspan; written during STW
	sweepdone uint32    // all spans are swept
	sweepers  uint32    // number of active sweepone calls

	// allspans is a slice of all mspans ever created. Each mspan
	// appears exactly once.
	//
	// The memory for allspans is manually managed and can be
	// reallocated and move as the heap grows.
	//
	// In general, allspans is protected by mheap_.lock, which
	// prevents concurrent access as well as freeing the backing
	// store. Accesses during STW might not hold the lock, but
	// must ensure that allocation cannot happen around the
	// access (since that may free the backing store).
	allspans []*mspan // all spans out there

	_ uint32 // align uint64 fields on 32-bit for atomics

	// Proportional sweep
	//
	// These parameters represent a linear function from heap_live
	// to page sweep count. The proportional sweep system works to
	// stay in the black by keeping the current page sweep count
	// above this line at the current heap_live.
	//
	// The line has slope sweepPagesPerByte and passes through a
	// basis point at (sweepHeapLiveBasis, pagesSweptBasis). At
	// any given time, the system is at (memstats.heap_live,
	// pagesSwept) in this space.
	//
	// It's important that the line pass through a point we
	// control rather than simply starting at a (0,0) origin
	// because that lets us adjust sweep pacing at any time while
	// accounting for current progress. If we could only adjust
	// the slope, it would create a discontinuity in debt if any
	// progress has already been made.
	pagesInUse         uint64  // pages of spans in stats mSpanInUse; updated atomically
	pagesSwept         uint64  // pages swept this cycle; updated atomically
	pagesSweptBasis    uint64  // pagesSwept to use as the origin of the sweep ratio; updated atomically
	sweepHeapLiveBasis uint64  // value of heap_live to use as the origin of sweep ratio; written with lock, read without
	sweepPagesPerByte  float64 // proportional sweep ratio; written with lock, read without
	// TODO(austin): pagesInUse should be a uintptr, but the 386
	// compiler can't 8-byte align fields.

	// scavengeGoal is the amount of total retained heap memory (measured by
	// heapRetained) that the runtime will try to maintain by returning memory
	// to the OS.
	scavengeGoal uint64

	// Page reclaimer state

	// reclaimIndex is the page index in allArenas of next page to
	// reclaim. Specifically, it refers to page (i %
	// pagesPerArena) of arena allArenas[i / pagesPerArena].
	//
	// If this is >= 1<<63, the page reclaimer is done scanning
	// the page marks.
	//
	// This is accessed atomically.
	reclaimIndex uint64
	// reclaimCredit is spare credit for extra pages swept. Since
	// the page reclaimer works in large chunks, it may reclaim
	// more than requested. Any spare pages released go to this
	// credit pool.
	//
	// This is accessed atomically.
	reclaimCredit uintptr

	arenas [1 << arenaL1Bits]*[1 << arenaL2Bits]*heapArena

	// heapArenaAlloc is pre-reserved space for allocating heapArena
	// objects. This is only used on 32-bit, where we pre-reserve
	// this space to avoid interleaving it with the heap itself.
	heapArenaAlloc linearAlloc

	// arenaHints is a list of addresses at which to attempt to
	// add more heap arenas. This is initially populated with a
	// set of general hint addresses, and grown with the bounds of
	// actual heap arena ranges.
	arenaHints *arenaHint

	// arena is a pre-reserved space for allocating heap arenas
	// (the actual arenas). This is only used on 32-bit.
	arena linearAlloc

	// allArenas is the arenaIndex of every mapped arena. This can
	// be used to iterate through the address space.
	//
	// Access is protected by mheap_.lock. However, since this is
	// append-only and old backing arrays are never freed, it is
	// safe to acquire mheap_.lock, copy the slice header, and
	// then release mheap_.lock.
	allArenas []arenaIdx

	// sweepArenas is a snapshot of allArenas taken at the
	// beginning of the sweep cycle. This can be read safely by
	// simply blocking GC (by disabling preemption).
	sweepArenas []arenaIdx

	// markArenas is a snapshot of allArenas taken at the beginning
	// of the mark cycle. Because allArenas is append-only, neither
	// this slice nor its contents will change during the mark, so
	// it can be read safely.
	markArenas []arenaIdx

	// curArena is the arena that the heap is currently growing
	// into. This should always be physPageSize-aligned.
	curArena struct {
		base, end uintptr
	}

	_ uint32 // ensure 64-bit alignment of central

	// central free lists for small size classes.
	// the padding makes sure that the mcentrals are
	// spaced CacheLinePadSize bytes apart, so that each mcentral.lock
	// gets its own cache line.
	// central is indexed by spanClass.
	central [numSpanClasses]struct {
		mcentral mcentral
		pad      [cpu.CacheLinePadSize - unsafe.Sizeof(mcentral{})%cpu.CacheLinePadSize]byte
	}

	spanalloc             fixalloc // allocator for span*
	cachealloc            fixalloc // allocator for mcache*
	specialfinalizeralloc fixalloc // allocator for specialfinalizer*
	specialprofilealloc   fixalloc // allocator for specialprofile*
	speciallock           mutex    // lock for special record allocators.
	arenaHintAlloc        fixalloc // allocator for arenaHints

	unused *specialfinalizer // never set, just here to force the specialfinalizer type into DWARF
}
```

```go
	// arenas is the heap arena map. It points to the metadata for
	// the heap for every arena frame of the entire usable virtual
	// address space.
	//
	// Use arenaIndex to compute indexes into this array.
	//
	// For regions of the address space that are not backed by the
	// Go heap, the arena map contains nil.
	//
	// Modifications are protected by mheap_.lock. Reads can be
	// performed without locking; however, a given entry can
	// transition from nil to non-nil at any time when the lock
	// isn't held. (Entries never transitions back to nil.)
	//
	// In general, this is a two-level mapping consisting of an L1
	// map and possibly many L2 maps. This saves space when there
	// are a huge number of arena frames. However, on many
	// platforms (even 64-bit), arenaL1Bits is 0, making this
	// effectively a single-level map. In this case, arenas[0]
	// will never be nil.
	arenas [1 << arenaL1Bits]*[1 << arenaL2Bits]*heapArena

// A heapArena stores metadata for a heap arena. heapArenas are stored
// outside of the Go heap and accessed via the mheap_.arenas index.
// 
//go:notinheap
type heapArena struct {
  bitmap [heapArenaBitmapBytes]byte
  spans [pagesPerArena]*mspan
  pageInUse [pagesPerArena / 8]uint8
  pageMarks [pagesPerArena / 8]uint8
  pageSpecials [pagesPerArena / 8]uint8
  checkmarks *checkmarksMap
  zeroedBase uintptr
}
```





### TCMalloc

>   [TCMalloc](https://link.zhihu.com/?target=http%3A//goog-perftools.sourceforge.net/doc/tcmalloc.html) 是 Google 开发的内存分配器，在不少项目中都有使用，例如在 Golang 中就使用了类似的算法进行内存分配。它具有现代化内存分配器的基本特征：对抗内存碎片、在多核处理器能够 scale。据称，它的内存分配速度是 glibc2.3 中实现的 malloc的数倍。



### 栈区

go 调用方法的时候限制最大参数为 2000 byte (base on go 1.16/mac).



### 看待内存管理

在 java 或者 c++ 中 我们使用 new 关键字显示的完成内存分配.

![](https://pic3.zhimg.com/80/v2-8be036952d5364273e6ac14a7cd331ee_1440w.jpg)

我们先来介绍下内存分配器,一般有以下三种分配器

- 线性分配器
- 空闲链表分配器

在操作系统我们学过两种分配方式,连续分配和分区分配,可以简单认为对应下面说的分配器

线性分配器只有一个指针指向后续的空间,单独使用无法**重用**已被回收的内存,可以通过整理内存碎片提高内存利用率,需要和垃圾回收算法配合使用.

空闲链表分配器把空闲内存以链表形式组织起来,使用首次适应,循环首次适应,最佳适应,隔离适应(分割成多个链表，每个链表的内存块大小不一样，但是同链表上内存块大小一致，申请时先选择链表，在选择链表上的内存块)等算法进行分配.go 使用的是**类似隔离适应算法.**

- 多级缓存: 引入了线程缓存、中心缓存、页堆
- 线程缓存: 分配小对象内存，属于每个独立线程，不存在锁等，能够提高部分性能
- 中心缓存: 分配小对象内存，线程缓存不满足需求的时候（如多线程），会使用中心缓存
- 页堆: 分配超过32KB以上对象，分配大内存

#### 申请流程

- Go 在启动的时候会为每个处理器都分配一个线程缓存
- **线程缓存**(mcache)，mcache存会管理特定大小的对象，持有mspan（内存管理单元）
- mspan 没有空闲对象后从 mheap 持有的134个**中心缓存** mcentral 中获取新的内存单元
- **中心缓存**属于全局的堆结构体 mheap
- mheap 会从操作系统中申请内存

特别的对于不同大小的对象基本遵从上面的规则,对于小对象就有可能会在线程缓存的微分配器上分配,**小于16字节**会被分配到微分配器,主要是小字符串,逃逸的临时变量,对象不可是指针类型,当所有对象可回收时,该块内存才可回收.大对象(32kb)的对象会直接被分配到堆上去.



#### 基本单元 mspan

- 内存不足的时候，以页为单位向堆申请内存
- 用户程序或线程向 mspan 申请内存的时候，可以通过 allocCache 快速查看未分配的内存
- 无空闲内存的时候，调用 refill 更新内存管理单元
- Go中有67中**跨度类**，每种**跨度类**的对象大小、页数等都不一样

可以看到**单个 mspan** 在内存分配的过程中充当了**线性分配器**(而不只是对象的元数据),其构成的双端链表,又构成了**空闲链表分配器**,其是一种结合了两个分配器特点的一种分配方案.同时 ClassSize 不同的 mspan 构成了多级分配的链表群.



#### 线程缓存 mcache

线程持有该缓存结构,其包含 67 * 2 个 mspan,每次内存申请的时候是从这些 mspan 中获取,线程缓存不够了的时候问中心缓存要.这个角度看上去 mcache 只是一个临时分配的一个结构.好处很明显无锁.这里还有个*2是因为一半包含指针,一半不包含指针的,分配更快.如此看来，在此进行的分配更接近栈上分配.



#### 中心缓存 mcentral

即mcentral，不独属于某个线程，因此访问需要上锁（悲观锁 mutex）,需要gc，更接近堆的分配

- 每个中心缓存只管理某个跨度类
- 持有两个spanSet，分别管理空闲以及忙碌的mspan
- 线程缓存（mcache）也是通过中心缓存获取mspan的
- 扩容，从mheap中获取对应跨度类的新mspan

mcache 不够用了,从mcentral拿,然后追加到后面,如下

![](https://pic4.zhimg.com/80/v2-b2fccd8698e4cfac9c6711794885407b_1440w.jpg)

如果依然没就从操作系统中申请

![](https://pic3.zhimg.com/80/v2-e6967e7b6a5bb838aa47b048789c8042_1440w.jpg)



#### mheap

- 为全局变量
- 统一管理堆上分配的对象
- 包含一个 mcentral 数组
- 包含heapArena字段，进行二维矩阵内存的管理
  - heapArena中有指针指向对应管理的内存位置
  - 每个管理64M空间 所以其实 **arena 是分割的**

![](https://pic2.zhimg.com/80/v2-96956b2a183e956855d1551f76f77b71_1440w.jpg)

#### 结构体的内存分配

##### c/c++

在聊结构体的内存分配之前我们先来聊下c++的结构体,如下一段代码展示了结构体在c/c++中也可带着方法以及私有成员,我们主要想聊的go的结构体设计理念其实和这个极其相似(方法绑定结构体),之后我们会聊下内存分配

```c++
#include <iostream>
using namespace std;
struct Point{
	int i;
	int j;
	Point(int ii,int jj){//类似于类的构造函数
		i=ii;
		j=jj;
		str="Point(int,int)";
	}
	Point(){
		str="Point()";
	}
	Point(int ii){
		i=ii;
		str="Point(int)";
	}
 
	int getI(){//类似于类的成员函数
		return i;
	};
	string getStr(){
		return str;
	}
private://可以通过类似于类的访问控制符来修饰
	string str;
};
int main()
{
	
	Point p;//必须有相对应的构造函数，姑且称之为构造函数吧
	p.i=1;
	p.j=2;
	//p.str="stringOne";//不能直接符访问
	string s=p.getStr();
	cout<<s<<endl;
	int k=p.getI();
	cout<<k<<endl;
	Point pp(3,4);
	int kk=pp.getI();
	cout<<kk<<endl;
	
	Point ppp(5);
	int kkk=ppp.getI();
	cout<<kkk<<endl;
	ppp.i=15;
	kkk=ppp.getI();
	cout<<kkk<<endl;
}
```

结构体在内存分配中的规则有两条

- 当前总大小是下一个数据类型的整数倍（如果不满足则补齐，但是单字节最大补齐4/8位具体由当前所有单字节数据类型中最大的数据类型决定）
- 整个结构体内存大小要满足最大单字节数据类型的整数倍

```c++
struct TestStr1    //    24 = 8*3 ((sizeof(double))*3)
{
    int a1;        //    4
    char c1;       //    4
    int a2;        //    8
    double d1;     //    8
};
 
struct TestStr2        //    48 = 8*6 ((sizeof(double))*6)
{
    int a1;            //    4
    char c1;           //    4
    TestStr1 TStr;     //    24
    int a2;            //    8
    double d1;         //    8
};
```

这个就是字节对齐,可以加速寻址.不知道有没有注意到的,因为这个内存对齐方式刚好和 Heap 中对象反过来,所以也可以证明一件事,就是 stack 是向下涨的(内存高地址),而 heap 是向上涨的(内存低地址),两者在内存对齐和寻址上刚好反过来.

再说结构体的内存分配之前,我们需要了解堆上分配和栈上分配,在 Java 中,我们知道了一个特性,new 出来的对象分配在堆上,但JIT告诉我们在逃逸分析下 TLAB 可能会让对象直接在栈上(堆中的一小块独立空间)进行分配.所以下面的说法是不带逃逸分析的分配方式,以c++为例.

```c++
typedef struct    //    24 = 8*3 ((sizeof(double))*3)
{
    int a1;        //    4
    char c1;       //    4
    int a2;        //    8
    double d1;     //    8
} ss;
// 定义结构体的数据,但并不进行内存分配
static typedef struct    //    24 = 8*3 ((sizeof(double))*3)
{
    int a1;        //    4
    char c1;       //    4
    int a2;        //    8
    double d1;     //    8
} sss; // 静态数据区分配内存
ss s; // 栈上分配内存
ss* ssptr = new ss(); // 堆上进行内存分配
```

我们顺便拓展下c的分配,malloc分配在堆,其他分配在栈

##### go

从上面我们看到,结构体的定义和内存分配这一行为本身并无任何关系,结构体的声明然后如何分配是程序员的决定的,而go则是由虚拟机决定的.而且我们可以看到一些特殊性质的东西,比如指针数组,其可以分配在栈上而指针数组的内容可以分配在堆上.

> How do I know whether a variable is allocated on the heap or the stack?
>
> From a correctness standpoint, you don't need to know. Each variable in Go exists as long as there are references to it. The storage location chosen by the implementation is irrelevant to the semantics of the language.
>
> The storage location does have an effect on writing efficient programs. When possible, the Go compilers will allocate variables that are local to a function in that function's stack frame. However, if the compiler cannot prove that the variable is not referenced after the function returns, then the compiler must allocate the variable on the garbage-collected heap to avoid dangling pointer errors. Also, if a local variable is very large, it might make more sense to store it on the heap rather than the stack.
>
> In the current compilers, if a variable has its address taken, that variable is a candidate for allocation on the heap. However, a basic escape analysis recognizes some cases when such variables will not live past the return from the function and can reside on the stack.

上面这一大段文字总结下

- 语言的定义和存储的位置无关
- 逃逸分析决定最后是在堆上分配还是在栈上分配,如果编译器无法证明返回后并未引用该变量,则在堆上进行分配
- 大变量存储于堆上

#### 基本类型和引用类型

我们介绍下常见的类型分配的做法

- 基本类型 int,float,bool,string,struct和数组
- 引用类型 slice,map,chan和值类型对应的指针

基本类型,直接在栈上进行分配(虽然根据逃逸分析可能会是堆分配),如果没有进行逃逸的话在函数调用完后释放.

引用类型,通常在堆上进行分配,通过GC回收,指针类型基本需要回收.



#### 关键字或函数

- `var :=`
- `new`
- `make`

我们先看下值的定义

```go
package main

import "fmt"

var a int // 默认初始化为 0

func main() {
	var b int
	c := 1
	var str int32 = 3
	d, c := 2, 5
	if true {
		b, c := 2, 5
		fmt.Println("b addr=", &b, "-", "c addr=", &c)
		e, d := 7, 8
		fmt.Println(b, "-", c, "-", e, "-", d)
		fmt.Println("d addr=", &d)
	}
	fmt.Println(a, "-", b, "-", c, "-", d)
	fmt.Println("str addr=", &str)
	fmt.Println("a addr=", &a, "\nb addr=", &b, "\nc addr=", &c, "\nd addr=", &d)
}
```

```note
str addr= 0x140000ae010
a addr= 0x1046431e8 
b addr= 0x140000ae000 
c addr= 0x140000ae008 
d addr= 0x140000ae018
```

我们修改下 str 的类型为 string

```note
str addr= 0x14000010240
a addr= 0x100d9f1e8 
b addr= 0x1400001e088 
c addr= 0x1400001e090 
d addr= 0x1400001e098
```

修改类型为 rune

```note
str addr= 0x1400001e098
a addr= 0x10023f1e8 
b addr= 0x1400001e088 
c addr= 0x1400001e090 
d addr= 0x1400001e0a0
```

我们发现如果大小相同的话是同一个 mspan 进行分配,而不同类型可能会被分配到不同的 mspan

- `make()` 的作用是初始化内置的数据结构，也就是我们在前面提到的`slice,map,chan`
- `new()` 的作用是根据传入的类型分配一片内存空间并返回指向这片内存空间的指针

```go
var p *int // 引用类型
*p = 10
fmt.Println(*p) //panic: runtime error: invalid memory address or nil pointer dereference
```

```go
var p *int = new(int)
*p = 10
fmt.Println(*p)
```

**new 的作用是初始化内存空间并且返回指针**,所以指针类型可以简单理解为引用类型,换言之下面代码等价

```go
var t *T
t =&T{}

// 等价初始化空的内存块
t:= new(T)
```

多级指针需要初始化对应的两块区域

```go
func main() {
	var p **int = new(*int)
	*p = new(int)
	fmt.Println(p)
	fmt.Println(*p)
	fmt.Println(**p)
}
```

在不需要引用的场合 new 其实是不常用的

```go
t := T{} 
```

上面是更常见的写法.直接不使用引用且不逃逸的栈上分配.



make 则不同,make 返回的事类型本身,或者说 slice map chan 本身就是引用类型,所以是不能取到地址的,但其是能有指针运算的,这里的实现应该和引用一致

```go
func main() {
	mp := make(map[string]string)
	ptr := &mp
	fmt.Println(mp)
	fmt.Println((*ptr)["1"] == "")
}
```

主要下面代码报错

```go
make(int) // 报错
```

而

```go
make(chan int)
```

能够很好的运行





## GC

- go tool pprof
- go tool trace / view trace

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





## GMP 调度

```note
 G - goroutine.
 M - worker thread, or machine.
 P - processor, a resource that is required to execute Go code.
     M must have an associated P to execute Go code[...].
```

<img src="http://5b0988e595225.cdn.sohucs.com/images/20180622/6765e36cc4604fba897976638af03524.jpeg" alt="50" style="zoom:70%;" />

> M代表内核线程，所有的G都要放在M上才能运行。
>
> P代表控制器，调度G到M上，其维护了一个队列，存储了所有需要它来调度的G。
>
> G代表一个go routine单元。

Goroutine 分配在逻辑处理器上,每个 goroutine 对应一个系统进程

![](https://pic2.zhimg.com/80/v2-fca58c2a3225d4fe70121788f47d5705_1440w.png)

我们知道 goroutine 是 go 自己实现的协程(coroutine).我们先来回顾下线程和进程

-   进程是操作系统持有资源的最小单位拥有自己的栈代码空间,持有文件描述符的锁,地址空间等
-   线程是操作系统调度的最小单位,持有自己的栈PC等

协程和上面二者不同的点在于,协程是用户级别的调度单位,一个线程可以拥有多个协程,其优势在于,其调度是在用户态进行完成的,也就是说无需操作系统中断用以完成切换.用户态的线程的效率也更高,在 java 中没有原生的该实现,但在 go 中有协程相关的实现被称为 gorutine.

### 调度模型

![](https://pic4.zhimg.com/80/v2-53ef5e5977e0f710f0798f34804d9d9b_1440w.jpg)

<p style="text-align:center">总览</p>

![](https://pic2.zhimg.com/80/v2-54e74087725901c0a1d0c99a429a34a9_1440w.jpg)

<p style="text-align:center">空闲本地P队列</p>

![](https://pic1.zhimg.com/80/v2-4ff422ff03ddbe8d40bd7a52d3cb6058_1440w.jpg)

<p style="text-align:center">P队列 OS Thread goroutine之间的关系</p>

![](https://pic2.zhimg.com/80/v2-e652ce9f17f709bb7d028fc483091a79_1440w.jpg)

<p style="text-align:center">无事可做的 os 线程会被回收然后扔进空闲队列里面</p>

- go 编译器根据处理器数量创建不同的 p 句柄在空闲的队列中
- gorutine 创建对应的系统进程 M
- 无事可做的 os 线程会被回收然后扔进空闲队列里面

#### 阻塞

**如果一个 gorutine 发生阻塞的话,那么处理器P会带着队列所有的 gorutine 去寻找新的 M 当M恢复过来时,一般情况下,会从别的M上拿过来一个 P ,并把原先跑在其上的 G 放到 P 的队列中,从而运行 G**

通常来讲,我们 OS Thread 的数量会远高于核心数P. 而有些时候我们会执行一些I/O操作导致阻塞.

```go
func main() {
	f, _ := os.Create("./trace.dat")
	defer f.Close()
	_ = trace.Start(f)
	defer trace.Stop()
	buff := make([]byte, 0, 2)
	fd, _ := os.Open("data")
    	// 执行系统调用 os.Open() 读取文件时，使用空闲队列 P 和 M 里的 P0 和 M0 组合来执行
  	// 然后阻塞等待
	wg.Add(1)
	go ff()
	defer fd.Read(buff) // 恢复的时候尝试使用原来的处理机,如果获取不到则放到空闲队列里面去
	defer fd.Close()
	wg.Wait()
	// println(string(buff)) // 42
}

func ff() {
	fmt.Println("hello")
	wg.Done()
}
```

![](https://img.snaptube.app/image/em-video/7d470b0b0608820b841a86a07bcbe3eb_2950_654.png)

G1 是大的主线程,可以看到其在执行 os.Open 的时候用的是同步阻塞的操作 G4 执行 start 去监控,G 5 执行我们自己定义的 goroutine,然后 waitGroup 阻塞执行完 G1 我们看到在 G1 到 G5 的时候有一段消失的时间片,这段时间就是 goroutine 在阻塞



我们讲个更常见的场景 http 的网络 I/O.

```go
func main() {
     _, _ = http.Get(`https://www.baidu.com`)
}
```

![](https://pic1.zhimg.com/80/v2-28a8277b8822071e164b5eecac924a94_1440w.png)

> `http.Get()` 的这个当前的 Goroutine 阻塞，转而使用轮询线程 `G7` 即 `G9 net/http.(*persistConn).readLoop` 来等到网络资源全部到达，Go 语言调度器才返回执行主线程 `G1` 即 `runtime.main` 和系统调用 `G9` 即 `G9 net/http.(*persistConn).readLoop`

所以我们看到了 http.Get 其实内部开启了 goroutine,读的 routine 在循环等待读,写的也是直到请求结束才返回给主的 goroutine

> *The GOMAXPROCS variable limits the number of operating system threads that can execute user-level Go code simultaneously. There is **no limit to the number of threads that can be blocked in system calls** on behalf of Go code; those do not count against the GOMAXPROCS limit. This package’s GOMAXPROCS function queries and changes the limit.*
>
> Go 为了优化性能会阻塞部分系统调用的线程,进而优化整体性能

简单的话来说就是有个全局队列(runable),然后每一个 goroutine 会创建在本地队列(local queue), goroutine 会创建对应的系统线程,然后系统线程负责调度,当系统线程发生I/O阻塞的时候 goroutine 会挂起,然后本地队列的下个 goroutine 会在创建系统进程,完了以后资源准备就绪了, 苏醒的 goroutine 尝试获取相同的处理机,获取不到就丢进全局队列

#### 长时间执行

长时间执行并非I/O的阻塞,不一定需要挂起线程.如果超过一定的时间(10ms),就在这个G任务的栈信息里面加一个标记.如果遇到普通函数（非内联函数）的调用会加个标记并且中断调 G 的执行.添加到末尾,如果遇到内联函数,则会一直执行内联函数知道内联函数结束,如果此时内联函数执行时间非常长的话,不会中断会一直执行下去.

中断时,寄存器里面的堆栈信息保存到函数里面,当再次轮到自己执行的时候使用这些寄存器信息进行执行即可.

#### 任务倾斜

如果某个 P 执行完了任务会去全局队列拿,如果拿不到就会去其他P的等待队列中拿一半用来解决任务分配倾斜的问题

