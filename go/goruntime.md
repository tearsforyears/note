#  runtime

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

spans 管理 arena 中的对象,管理对象的元数据叫 mspan,spans 存储 mspan 的指针.下面会详细描述该结构



#### arena

-   从内存分配的角度去看,其就是一个个被等大小的 **page**
-   从程序的角度其实一个个**对象**
-   其相当于一个堆区,管理着所有新出来的对象



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

mspan 实际上是操作系统分配的

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

一种内存分配器,和mcentral,mheap相同,每个工作线程都会绑定个mcache,每个线程本地缓存 mspan 资源,直接给gorutine 分配就不需要考虑过个 gorutine 的竞争问题.

>   `mcache`用`Span Classes`作为索引管理多个用于分配的`mspan`，它包含所有规格的`mspan`。它是`_NumSizeClasses`的2倍，也就是`67*2=134`，为什么有一个两倍的关系，前面我们提到过：为了加速之后内存回收的速度，数组里一半的`mspan`中分配的对象不包含指针，另一半则包含指针。
>
>   对于无指针对象的`mspan`在进行垃圾回收的时候无需进一步扫描它是否引用了其他活跃的对象。

![](https://pic4.zhimg.com/80/v2-e6e061c4f9e1212b2bf32728dcb2aa17_1440w.jpg)

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
	tiny       uintptr
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

>   为所有`mcache`提供切分好的`mspan`资源。
>
>   每个`central`保存一种特定大小的全局`mspan`列表，包括已分配出去的和未分配出去的。
>
>   每个 mcentral 对应一种 mspan. 而`mspan`的种类导致它分割的`object`大小不同.
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

从上面可以总结出以下结构

-   mheap
    -   mspan
        -   span list
        -   class size
    -   arena ptr
    -   central
-   mcache
    -   mspan

##### 内存分配过程

-   32KB 的对象，直接从mheap上分配；
-   <=16B 的对象使用mcache的tiny分配器分配；
-   (16B,32KB] 的对象，首先计算对象的规格大小，然后使用mcache中相应规格大小的mspan分配；
-   如果mcache没有相应规格大小的mspan，则向mcentral申请
-   如果mcentral没有相应规格大小的mspan，则向mheap申请
-   如果mheap中也没有合适大小的mspan，则向操作系统申请



### TCMalloc

>   [TCMalloc](https://link.zhihu.com/?target=http%3A//goog-perftools.sourceforge.net/doc/tcmalloc.html) 是 Google 开发的内存分配器，在不少项目中都有使用，例如在 Golang 中就使用了类似的算法进行内存分配。它具有现代化内存分配器的基本特征：对抗内存碎片、在多核处理器能够 scale。据称，它的内存分配速度是 glibc2.3 中实现的 malloc的数倍。



### 栈区

go 调用方法的时候限制最大参数为 2000 byte



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



## GMP 调度

```note
 G - goroutine.
 M - worker thread, or machine.
 P - processor, a resource that is required to execute Go code.
     M must have an associated P to execute Go code[...].
```

<img src="http://5b0988e595225.cdn.sohucs.com/images/20180622/6765e36cc4604fba897976638af03524.jpeg" alt="50" style="zoom:70%;" />

我们知道 goroutine 是 go 自己实现的协程(coroutine).我们先来回顾下线程和进程

-   进程是操作系统持有资源的最小单位拥有自己的栈代码空间,持有文件描述符的锁,地址空间等
-   线程是操作系统调度的最小单位,持有自己的栈PC等

协程和上面二者不同的点在于,协程是用户级别的调度单位,一个线程可以拥有多个协程,其优势在于,其调度是在用户态进行完成的,也就是说无需操作系统中断用以完成切换.用户态的线程的效率也更高,在 java 中没有原生的该实现,但在 go 中有协程相关的实现被称为 gorutine.







