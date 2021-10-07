# JVM-guide

---

[TOC]

本文档旨在用最少的语言描述jvm的关键特性,设计思路等进行描述,根据[此文档](https://github.com/tearsforyears/note/blob/master/Java/base/jvm.md)进行简化和说明.[create at : 2021年10月02日13:31:05]

## 虚拟机

>   虚拟机（Virtual Machine）指通过[软件](https://baike.baidu.com/item/软件/12053)模拟的具有完整[硬件](https://baike.baidu.com/item/硬件)系统功能的、运行在一个完全[隔离](https://baike.baidu.com/item/隔离/33079)环境中的完整[计算机系统](https://baike.baidu.com/item/计算机系统/7210959)。

虚拟机的重要设计思想和特性

-   屏蔽底层差异
    -   跨平台
    -   **屏蔽内存管理 (clinit,cinit,GC)**
-   动态特性
    -   动态编译,加快编译速度
    -   动态执行(Spring-AOP 的设计也参考了此思想)
        -   动态加载类(热部署)
        -   动态解释字节码
-   虚拟机/解释器的功能实现方式
    -   自举 (自己实现自己)
    -   自展 (用其他语言实现本语言,c++实现python解释器)
    -   混合 (绝大多数语言的选择,Jvm 的实现利用了c++和 Java)

虚拟机的劣势

-   性能在某些情况下较差
-   浪费资源在状态管理上



## JVM

JVM 即一种虚拟机的规范实现,一般我们讨论JVM指的是开源的HotSpot,也有其他不同的实现,在此不做讨论.JVM最初设计理念只是为了跨平台,但随着动态特性的应用使得Java社区和解决方案逐渐壮大.JVM由C++实现了其核心的内存管理功能,以及根类的加载,利用Java实现了普通类的加载.

Java 代码在运行的时候实质上是用 JVM 解释字节码或调用 C++ 函数的过程.



## 数据结构

数据结构分为两类

-   硬件(对虚拟机可见,即堆栈元空间等)
-   软件(对程序员可见,即对象,变量等)



### 硬件数据结构

硬件数据结构指的是JVM的虚拟硬件而并非物理硬件.如下区域

![](https://img2018.cnblogs.com/blog/645365/201905/645365-20190515062344241-2072850649.png)

![](https://images2018.cnblogs.com/blog/1102674/201808/1102674-20180815143324915-2024156794.png)

#### stack & heap

堆和栈是基本所有语言最基本的内存划分

-   栈区即是方法或者线程临时使用的内存区域,在物理硬件上其由寄存器/高速缓存和主内存三者共同构成
-   堆区即为公共的数据存储区域,一般由主内存构成

如上面的工作内存和主内存之间的内存差异实质上就是**寄存器/高速缓存**和**主内存**之间的数据差异,在多线程的场景下,会使用内存屏蔽去强制同步两者之间的差异.在Java编码中的体现就是 volatile 关键字的使用.

堆和栈的设计上就是两种不同资源的使用.临时私有资源和公有资源的使用.这种使用方式也体现在我们编码中的**全局变量**和**局部变量**上.



#### metaspace / 方法区 / Non Heap

metaspace译为元空间,其存储了类的meta信息,一般来说,meta信息是类加载到虚拟机时即会在元空间生成,这部分区域包含方法列表的指针,静态变量,类名,Class,ClassLoader引用等信息.

**早期版本的常量池也放在此区域中,1.7后放入 heap 中了**



#### native method area

就是 c++ 的函数,由虚拟机自行管理,我们调用 JNI 方法时候使用的内存就称之为 native method area.



### 软件数据结构

#### 引用和数据

```java
class A{
  String str = "123"; // 引用
  int i = 123; // 数据
}
```

所谓的引用指的是指针的形式存储,而数据则是内存地址上存的就是原始的值.基本数据类型就是以值的形式进行存储,而其他类型则是以4Byte(32位)的指针进行存储.



#### 对象

对象一词由OOP的设计思想而来,本质上其就是一个带有函数指针,数据指针的**结构聚合体**,在c++中已经实现了该种数据结构.JVM只不过是把该种数据结构进行简化实现,对象一共包括3个部分

-   markword
-   instance data 对象的字段信息
-   padding 填充对其内存

需要注意的是对象的**方法引用是存在方法区**,通过this指针引用实例方法,或者类名进行引用静态方法.

markword具体代表的含义如下,其是一个控制字段,包括锁,gc等控制,一共32位

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302152048845-1639352445.png)

![](https://img-blog.csdn.net/20170419212953720?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvenF6X3pxeg==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

Java对象在c++中的结构如上所示

我们把在metaspace中的数据结构叫klass,上面\_klass即代表指向此种数据结构的指针,\_mark则代表指向对象的markword.实例数据直接就在下方,需要注意的是,数组对象则对了一个\_length,对数组中的长度进行限定.数组中的具体数据则根据offset依次排列,在java中无论是32位还是64位该种数据结构都是对齐8byte

```java
Class A {
    int i;
    byte b;
    String str;
}
```

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302151508860-655456010.png)

所以我们通过上面例子能够计算出对象的大小

数组对象是对象里面比较特殊的,最简单的`int[]`其实是c++实现的比较特殊的类,其实例化方式更是和其他类不相同,其存储方式和对象却是一样的,首先其在堆内存上可以被new,其内部在对象头之后(markword,class指针,数组长度)有一段连续的空间存储基本类型的值,但是如果不是基本类型,(比如`Object[]`的实例,则是会存储这些实例的指针)

```java
new boolean[]{false,true,false};
```

```shell
[Z object internals:
 OFFSET  SIZE      TYPE DESCRIPTION   VALUE
      0     4 (object header)  01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4 (object header) 00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4   (object header) 05 00 00 f8 (00000101 00000000 00000000 11111000) (-134217723)
     12     4  (object header) 03 00 00 00 (00000011 00000000 00000000 00000000) (3)
     16     3   boolean [Z.<elements>   N/A # 这里存储大小是3字节
     19     5    (loss due to the next object alignment) # 对其
Instance size: 24 bytes
Space losses: 0 bytes internal + 5 bytes external = 5 bytes total
```

```java
new Double[]{200.0d,200.0d,200.0d};
new double[]{200.0d,200.0d,200.0d};
```

```shell
[Ljava.lang.Double; object internals:
 OFFSET  SIZE   TYPE DESCRIPTION   VALUE
      0     4                    (object header)                           01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4                    (object header)                           00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4                    (object header)                           9d 09 01 f8 (10011101 00001001 00000001 11111000) (-134149731)
     12     4                    (object header)                           03 00 00 00 (00000011 00000000 00000000 00000000) (3)
     16    12   java.lang.Double Double;.<elements> N/A # 12字节 3个引用
     28     4                    (loss due to the next object alignment)
Instance size: 32 bytes
Space losses: 0 bytes internal + 4 bytes external = 4 bytes total

[D object internals:
 OFFSET  SIZE     TYPE DESCRIPTION  VALUE
      0     4 (object header) 01 00 00 00 (00000001 00000000 00000000 00000000) (1)
      4     4  (object header) 00 00 00 00 (00000000 00000000 00000000 00000000) (0)
      8     4 (object header) b9 00 00 f8 (10111001 00000000 00000000 11111000) (-134217543)
     12     4  (object header) 03 00 00 00 (00000011 00000000 00000000 00000000) (3)
     16    24   double [D.<elements> N/A # 24个字节 所以应该直接存了double的值
Instance size: 40 bytes
Space losses: 0 bytes internal + 0 bytes external = 0 bytes total

```



## 类运行的过程

类运行的过程分为两个阶段

-   编译成`.class`文件
-   执行`.class`文件

### 编译过程

编译过程进行了一些简单的替换简单的拼接,final变量等常量会声明在`.class`文件中,可以使用`javap -v`查看编译的文件

### 加载过程

加载过程主要分为

-   Loading (由ClassLoader实现,即可能由C++或者Java实现)
-   Linking
-   Installization

#### Loading

Loading 过程是.class文件由字节流加载进虚拟机的过程,此过程生成了 klass 的数据结构,生成了 Class 对象和引用,此过程的具体实现依赖ClassLoader的实现

##### ClassLoader

![图片](https://upload-images.jianshu.io/upload_images/1833901-97c7f6c8d8e0965f.png)

![](https://img-blog.csdn.net/20150702112329327?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvb3BlbnN1cmU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

ClassLoader 一般分为以下几种,其中 Bootstrap ClassLoader 由C++ 实现,其他全部由 Java 进行自举.上图说明了每个类加载器的功能.

类确定由哪个类加载器进行加载**主要是通过双亲委派模型**进行加载的,如上该类自己加载的时候不会自己加载而是向上递归,委派父类完成加载,这样设计的方式是防止类重复加载,当发现父类已经加载过的时候则停止加载而是使用已经加载过的引用.如果父类没有加载过则会按照调用栈至底层类加载.

这个加载过程是可以被**程序员自定义的**,我们通过修改以下的方法再指定类的加载器就可以改变双亲委派模型,且双亲委派模型的实现也是由我们自己指定的.

ClassLoader为一抽象类,在java.lang下,上面则是实现该抽象类不同方法的类

-   **defineClass**

    byte流解析成jvm能够识别的对象,即把.class转化为Class

-    **findClass** 

     通过类名去加载对象,通常我们定义自己的类加载器用该方法实现

-    **loadClass** 

     加载类到JVM,双亲委派机制在这,JDBC加载驱动的时候需要破坏此种机制

-    **resolveClass**

     调用这个使得被加到JVM的类被链接

类的加载过程是线程安全的

#### Linking

Linking主要的目的是生成在JVM中的metaspace数据结构分为三个阶段

-   准备 验证字节码格式的准确性,final是否正确覆盖,函数签名等
-   验证 在方法区为 static变量注入默认值或注入final的值
-   解析 确定运行时常量池的引用

#### installization

这个阶段,程序员开始可以触及,一般分为两种装载方式,根据不同的调用状态选择一种或者两种装载方式

-   `<clinit>` 类的初始化
-   `<init>` 实例对象的初始化

所谓的初始化,即**依次(从上往下)执行如下操作**

-   `<clinit>`执行static代码块或为static成员变量赋值
-   `<init>` 执行普通代码块或为普通成员变量赋值

**Jvm的一个设计理念的是,尽可能少的触发装载.**

举几个例子

```java
public static void main(String[] args) {
	   System.out.println(A.c);
}
class B {
  static {
    System.out.print("B");
  }
  public final static String c = new String("C");
  {
    System.out.print("D");
  }
}
class A extends B {
    static {
        System.out.print("A");
    }
}
```

<font color="red" style="opacity: 1;">会输出BC,其原理是,A类的metadata在Linking阶段就已经生成了符号引用,A.c本身调用的就是A中指向B的meta区域的指针,所以需要给B进行初始化,</font>

```java
public class StaticTest{
    public static void main(String[] args){
        staticFunction(); // start
    }

    static StaticTest st = new StaticTest();

    static{
        System.out.println("1");
    }

    {
        System.out.println("2");
    }

    StaticTest(){
        System.out.println("3");
        System.out.println("a="+a+",b="+b);
    }

    public static void staticFunction(){
        System.out.println("4");
    }

    int a=110;
    static int b =112;
}
```

<font color="red" style="opacity: 1;">2,3,a=110,b=0,1,4 在触发 clinit 的过程中优先触发了 init</font>



## GC

GC 即垃圾回收,其是JVM的核心功能,也是区别于c++的主要机制,GC的回收设计是按照不同的内存区域来进行的,其主要对堆内的对象进行内存管理,metaspace也收到管理,但垃圾回收会比较少,对于堆中一般按照引用分为下面四种引用

![](https://img2018.cnblogs.com/blog/926003/201909/926003-20190902230035745-1201448392.png)

按照引用我们可以确定垃圾回收的时机.如果不使用引用队列按照写法也会有默认的队列,垃圾回收的时机,上述的引用对象适用于整个堆区(包括下面的老年代新生代等),metadata区域一般认为强引用,这部分信息由操作系统的直接内存所管辖(操作系统内存不够也有可能会动这块内存),JVM也可对其进行回收,一般也会以Full GC的形式进行回收.



### 分代回收垃圾思想

![](https://img-blog.csdn.net/20180711231128855?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3F6cWFuemM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

垃圾回收一般按上面区域进行分代,分代的主要目的是让**不同的垃圾回收器**回收不同的区域,根据对象的用途和存活时间设计不同的垃圾回收算法进行回收.

-   有一批对象是更新特别快的,这批对象叫新生代,我们主要对其使用copying算法
-   相对而言的就是老年代,这批对象可能是新生代放不下的对象,也可能是在新生代存活了很久的对象,我们一般使用mark-sweep算法对其进行回收.
-   而metadata的信息我们一般是不会进行更换的(重写classload的操作除外),所以其使用mark-compat算法



### 垃圾回收算法

#### 标记

在传统的垃圾回收中,我们一般是先标记后清除,而标记算法使用的就是 GC Root 向下递归标记被引用的所有对象.所谓的 GC Root 其实最常见的就是我们在栈上使用的变量.除此之外还包括以下

- 栈(本地变量表)中被引用的对象
- 方法区中静态属性的对象
- 方法区中常量引用的对象
- 本地方法栈中JNI引用的对象

![](https://imgconvert.csdnimg.cn/aHR0cDovL3VwbG9hZC1pbWFnZXMuamlhbnNodS5pby91cGxvYWRfaW1hZ2VzLzIwMzIxNzctOTk4ZmVkNzdhNzYxMmUxYi5wbmc?x-oss-process=image/format,png)

#### 清理

从上面看标记了对象就是不能被回收(因为还在被引用)而其他的内存区域则可以进行回收.清理的算法一般有三种

-   Copying算法 需要额外空间,高效 **新生代eden**

    具体的做法是按照GC Roots往下进行扫描然后把能到达的对象移动到一块空闲的内存区域

    ![](https://imgconvert.csdnimg.cn/aHR0cDovL3VwbG9hZC1pbWFnZXMuamlhbnNodS5pby91cGxvYWRfaW1hZ2VzLzIwMzIxNzctMGY0MDk0NDEzOTZlOTFmZC5wbmc?x-oss-process=image/format,png)

    其特点就是高效,**新生代的Eden**采用的就是这种算法,其缺点就是需要一块额外的空间来供内存移动

    关于To区和From区是作为Eden区垃圾回收的额外空间,正常的使用情况是使用一块Eden区和一块From区,垃圾回收时,把存活的对象复制到To区.当Eden和From区域不够的时候发生GC,To区被使用,当使用满了的时候此时则会有对象直接进入老年代.默认情况下,对象在Suvivor区域躲过垃圾回收15次,则会直接进入老年代.

-   Mark-sweep算法 无需移动对象,时间需要较为久,直接回收产生内碎片

    这个算法和复制算法相比不需要额外的空间,其做法是沿着GC Roots向下遍历,标记每一个可以到达的节点,然后在进行一次全盘扫描,把那些未标记的去掉,其优点是不需要额外的空间,其缺点是耗时会比较久而且会产生内碎片

    ![](https://imgconvert.csdnimg.cn/aHR0cDovL3VwbG9hZC1pbWFnZXMuamlhbnNodS5pby91cGxvYWRfaW1hZ2VzLzIwMzIxNzctNmNjMmRkMjg0ZGUyODg4YS5wbmc?x-oss-process=image/format,png)

-   Mark-compact算法 需要移动对象,时间最长,不会产生碎片,**旧生代**

    标记压缩算法是标记清除算法的一个改进,在Mark-sweep清除完后,把所有对象朝着一个方向移动,从而保证了不会产生内碎片

    ![](https://imgconvert.csdnimg.cn/aHR0cDovL3VwbG9hZC1pbWFnZXMuamlhbnNodS5pby91cGxvYWRfaW1hZ2VzLzIwMzIxNzctOWRlNTM4Mzg2ZTdjODk0Ny5wbmc?x-oss-process=image/format,png)

各代使用的垃圾回收算法总结

| 内存区域 | 回收特点                             | 适合使用算法               |
| -------- | ------------------------------------ | -------------------------- |
| 新生代   | 需要频繁进行GC回收,回收大部分对象    | Copying                    |
| 老年代   | 回收少量对象                         | Mark-Sweep \| Mark-Compact |
| 永久代   | 在主程序的运行中基本不会进行垃圾回收 | Mark-Compact               |



#### Full GC 触发的原因

如同洪水猛兽,会对所有区域进行垃圾回收

-   System.gc()

-   永久代空间不足

-   老年代空间不足

-   GC时出现Promotion Faield(年轻代空间不足够放下那么大的对象)

-   统计得到的Minor GC晋升到老年代的平均大小大于老年代的剩余空间(JVM觉得老年代空间要不够用了)



### 垃圾回收器

```shell
-XX:+PrintGCDetails # 开日志观察
```

![](https://img2018.cnblogs.com/blog/1120165/201908/1120165-20190806231839133-894902320.png)

上图说明了一些垃圾回收器的使用场景.以及联合使用的场景我们对主要的垃圾回收器进行说明

#### 串行垃圾回收

因为性能和维护等问题已经不做使用了

#### Parallel Scavenge

一个更关心吞吐量的垃圾回收器,可以设置最大停顿时间,用于新生代收集,使用copying算法.



MSC 为一种经典的垃圾回收使用的方式即 ParNew,Serial Old,CMS 三种垃圾回收器组合使用

#### ParNew

新生代首选的垃圾会后,可以在Server环境下和CMS一起配合工作,其作用是回收新生代的垃圾

```shell
-XX:+UseParNewGC
```

其为串行回收新生代的多线程版本用户回收,其是多线程的,执行垃圾回收操作的时候需要暂停所有的用户线程

![](https://img-blog.csdnimg.cn/20190222222515855.jpeg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2l2YV9icm90aGVy,size_16,color_FFFFFF,t_70)

#### [CMS](https://mp.weixin.qq.com/s/vmnBlrM7pTtVuyQU-GTcPw)

CMS(Concurrent Mark Sweep)该垃圾回收器其是一种非常关注停顿时间的垃圾回收器,其分为4个阶段,如下,其主要的设计思想就是把 **GC Root Trace 这一耗时操作**变成和用户线程并发执行,做的一种折中操作,其会引发少量的 stop-the-world.

![](https://img-blog.csdnimg.cn/20190222222845773.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2l2YV9icm90aGVy,size_16,color_FFFFFF,t_70)

-   <font color='red'>初始标记</font>会寻找所有的 GC Root 这个时候需要 Stop-the-world
-   并发标记会进行 GC Root Tracing,即往下查找引用,会和用户线程并发执行,这个时候可能会有些新生代的对象进行到老年代则垃圾回收的对象会增加,使用了一个`CARD_TABLE`又称为卡表,其把老年代划分成512byte的块,如果发生了改变就变成了`dirty_card`,这个阶段CMS就会重新扫描这些块,`CARD_TABLE`保存的是向外指的指针,表示该区域的指针还引用了哪些对象,依次递归
-   <font color='red'>重新标记</font>会判断上次标记的对象是否存活,这一阶段需要Stop-the-world
-   清除对象,和用户线程并发执行

为何初始标记不可以并发而清理和并发标记可以并发?

-   标记是因为得从 GC Root 开始,而线程的栈又经常会因为程序员的操作而改动(多或者少)会引发线程安全问题
-   清理可以并发是因为,JVM不会捡垃圾,即放弃的引用基本没有方法重新获得,即不进行GC垃圾只会增加不会减少
-   并发标记同样是只会增加不会减少(新年代晋升),故同样不会引发线程安全问题

CMS 设计的弊端

-   垃圾清理不干净,很显然在清理垃圾的时候用户线程还会制造垃圾就会有浮动垃圾
-   内碎片过多导致大量 Full GC

CMS的两个触发条件

-   阈值检查机制:由于并发清除过程会产生浮动垃圾.所以老年代的使用率没有办法达到100%.只能到达某一个阈值以后(jdk1.8默认值92%,1.6之后是92%,1.5默认是68%）,或者通过CMSInitiatingOccupancyFraction和UseCMSInitiatingOccupancyOnly 两个参数来调节;过小会造成GC频繁；过大,导致并发模式失败.
-   动态检查机制:JVM会根据最近的回收历史,估算下一次老年代被耗尽的时间,快到这个时间了就启动一个并发周期. 可以用UseCMSInitiatingOccupancyOnly来将这个特性关闭.

通常我们会选择ParNew+CMS+Serial Old的收集器组合,Serial Old将作为CMS出错的后备收集器,相当于内随便过多时需要整理

```shell
 -XX:+UseConcMarkSweepGC # 这一个就开启了上面三
```



#### G1

一个更为先进的垃圾回收器,**基于copying算法**其使用在新生带和老年代.G1 之后的 ZGC 和 Shenandoah 都不以老年代为主而是转向整个Java堆区,收集器面向局部收集的设计思路和基于 Region 的内存布局结构.G1 可以指定垃圾回收的最大停顿时间

G1 的设计思想其实就是,既然CMS还是会产生内碎片,每次还是要扫描所有堆,那不如自己维护对象与对象之间的标记关系减少扫描次数

```shell
-XX:+UseG1GC
-XX:MaxPauseMillis # 默认停顿时间
```

![](https://awps-assets.meituan.net/mit-x/blog-images-bundle-2016/8ca16868.png)

G1默认把堆内存分为1024个区域,每个regin大小都是固定的,可以通过`-XX:G1HeapRegionSize`调整大小为2的N次幂,上图的H表示的是一些大对象.其他依然遵循分代理论.

超过每个region容量的一般则可认为是大对象,如上图会被存放在连续的 region 中.大对象和老年代一致.

**G1 不再以代作为回收依据而是以region作为回收依据**,其每次回收指回收价值更大的region,才保证在停顿时间结束前完成垃圾回收.如果确定价值最大即回收时间和获得空间大小的权衡结果

![](https://segmentfault.com/img/bVbDzTy)

-   <font color='red'>初始标记</font>会寻找所有的 GC Root 这个时候需要 Stop-the-world
-   并发标记会进行 GC Root Tracing,即往下查找引用,会和用户线程并发执行,然后修正标记,利用了和CMS一样的卡表原理来判断数据
-   <font color='red'>最终标记</font>会判断上次标记的对象是否存活,这一阶段需要Stop-the-world,和CMS不同的是,此阶段对象的变化情况会被标记在Remembered Set,
-   <font color='red'>筛选回收</font>更新Region的统计数据,对Region的成本进行排序

我们来说明下 G1 的数据结构

-   CSET(Collection Set) 一组可被回收的region集合,在GC中存活下来的对象会被移动到另一region
-   RSET(Remember Set) 该数据结构用于维护其他区域引用本区域的关系,因为维护了这样的关系所以不用每次都扫描整个堆
-   CARD_TABLE 和 CMS 中卡表一样.维护了本区域对象引用了其他哪些区域

![](https://www.freesion.com/images/810/4557a5c3df3b9c42b7717af121f96f12.png)

上图中有三个Region,每个Region被分成了多个Card,在不同Region中的Card会相互引用,Region1中的Card中的对象引用了Region2中的Card中的对象,蓝色实线表示的就是points-out的关系,而在Region2的RSet中,记录了Region1的Card,即红色虚线表示的关系,这就是points-into.有了上面的数据结构,每次GC都是增量更新,所需要的时间大大减短

G1收集器突出表现出来的一点是通过一个停顿预测模型根据用户配置的停顿时间来选择CSet的大小,从而达到用户期待的应用程序暂停时间



并发标记的所以对于一个对象其有三种状态(三色标记算法)

-   白色,对象没有标记到,标记阶段结束后,会当做垃圾回收.
-   灰色,对象被标记了,但是它的field还没有标记或还没有标记完.
-   黑色,对象被标记了,且它的所有field也被标记完了.