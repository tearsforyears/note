

## jvm

---

[TOC]

Java virtual machine

之前已经写过类似的文档 但总结起来就是每次都有新的认识

写于2020年

---

### 内存结构

**heap 用于存放process级别数据** class内的变量等 new 出来的变量等 数组等

heap是对象的存放区域也是管理最麻烦的一个区域,具体内容会在gc更加详细描述,这一区域在jdk1.8前后发生了很大的变化谨慎起见下面的结构都是1.8以前的

**stack 存放thread/function级别数据** 局部变量操作数栈动态链接方法出口

-   vm stack虚拟机栈 线程私有,即对应thread级别的数据,一个线程的局部变量等

    每个方法在执行的时候会在虚拟机栈生成一个栈帧,栈帧的结构如下

    -   操作数栈
    -   局部变量表
    -   动态链接
    -   方法出口信息

-   native method 原生方法栈 顾名思义是原生调用所使用的栈

**方法区 process级数据** 常量池 static变量区 **类接口等加载**

-   加载的类的信息(类名,修饰符)
-   常量池
-   静态变量
-   方法表
-   类的静态字段
-   对Class类的引用
-   对ClassLoader的引用
-   异常表

**navtive 方法区 global级别数据** 被jvm环境使用 存放c++实现的方法 主要针对字节码操作

![](https://s2.ax1x.com/2019/05/26/VECQk4.png)

**pc程序计数器** 这个记载着每条指令的字节码地址,如果是原生方法则为空,pc实际上不在内存中而在于CPU中

如果学习完后面的gc和对象的数据结构后之后可以采用如下更详细的图

![](https://img2018.cnblogs.com/blog/645365/201905/645365-20190515062344241-2072850649.png)

如图是JVM的内在数据结构,可以看到方法区中存有类的元信息和static变量和method执行的字节码,而栈帧又持有到该类方法区的引用,实例分配在堆上形成了jvm的完整数据结构,上面Class Data可称之为klass(c++实现中的叫法)

---

### jdk1.7升级到1.8内存区域的变化

![](https://img-blog.csdnimg.cn/20190305150132242.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM3NTk4MDEx,size_16,color_FFFFFF,t_70)

最大的变化就是方法区(准确的说是永久代)已经变成了元数据区,而元数据区的数据已经不再是jvm而是直接写进了本地内存中,关于Class的Meta信息在虚拟机中,但是关于static变量,常量池的信息是直接由本地内存的元数据区管理的.

-   **jdk1.8后字符串常量从常量池中变成了堆中**



### 对象

---

从上面我们可以知道在**Hotspot**中对象是存在方法区的,下面我们介绍对象具体的数据结构,而在另一文档中,我们会介绍对象与锁相关的知识

对象的元数据是以字节码形式存储在**方法区**中,而对象本身需要开辟的内存则是在**堆内存**中,可以说方法区只包含了基本信息的这么一个数据结构,真正的对象还是保存在堆中

如下图,_klassOop指的是klass指针,klass存储在方法区中

![](https://img-blog.csdn.net/20170419212953720?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvenF6X3pxeg==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

对象的数据结构包括三个部分

-   对象头 Header
-   实例数据 Instance Data
-   对齐填充 Padding



#### 对象头 Header

对象头包括两部分(数组是三部分信息)

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302104003563-2094361065.png)

由此我们可以计算对象头大小 上图的32bit/64bit指的是在32位或64位的JVM下,而64位的JVM开启指针压缩之后markword还是8byte但是ClassMetadata Address已经从8byte压缩到4byte

##### Markword

markword存储的是对象运行时的信息,如哈希码(HashCode),GC 分代年龄,锁状态标志,线程持有的锁,偏向线程 ID,偏向时间戳,对象分代年龄

##### ClassMetadata Address

指向klass元数据信息的指针

##### 对象头的数据格式

在32bit的JVM下根据锁的状态(标记位的状态)markword中存储信息的含义会发生变化,如下

关于锁的状态会在另一文档详细说明

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302152004001-388228627.png)

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302152048845-1639352445.png)

在64bit的JVM下

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302152202938-44866486.png)



#### 实例数据 Instance Data

实例数据是对象的非final和static内部成员变量,而关于函数相关的信息都在metaspace或者方法区里面了



#### 填充 Padding

在java中无论是32位还是64位该种数据结构都是对齐8byte

```java
Class A {
    int i;
    byte b;
    String str;
}
```

估算上面对象的大小,如下即可知对齐

![](https://images2015.cnblogs.com/blog/731716/201703/731716-20170302151508860-655456010.png)



### 类加载与初始化过程

---

#### 编译过程 javac

-   加载前

    Complier完成对.java文件的编译变成.class文件

    这个编译过程会对一些运算进行替换比如1==1替换成true

    这一阶段就会加入常量池

    其实没仔细说明 这一阶段所有final变量也会加入常量池留下引用

    常量池有字面量 符号引用和 运行时常量池

    通过javah命令编译之后，用javap -v 命令查看编译后的文件

#### 加载过程 java

和下文的`<clinit>`方法不同,该过程在`<clinit>`之前执行,总的来说加载过程就是把类的字节码加载到JVM生成常量池引用和在方法区堆内存分配相应的数据结构的过程,并不包括初始化

-   加载 Loading (此过程由ClassLoader完成)

    从class中加载字节流 在方法区生成入口type=Class的对象

    把字节码解析成方法区中的klass数据结构(元信息)

-   连接 Linking

    验证 准备 解析

    这个过程主要加载类的static变量完成默认值注入(只针对变量) 生成引用 

    ***对final static变量直接注入值***

    -   验证 Verification 验证字节码的准确性,final是否被覆盖,函数签名
    -   准备 Preparing 在**方法区**为static变量分配内存(注入默认值)
    -   解析 Resolution 确定运行时常量池的引用

-   装载 Initialization

    这个阶段会去真正的执行代码,依据代码的不同进行不同的执行,这个时候static成员变量的值才会被去注入

    

-   ClassLoader

    ClassLoader只负责加载Loding,除了顶级的Bootstrap用C++实现以外其他都用java实现

    除了隐式或者显示的new以外 形如Class.forName

    和ClassInstace.staticMethod都不进行对象初始化只加载到jvm

    机制主要是三种

    -   全盘负责 该类依赖的所有类都由该类的classloader加载

    -   缓存机制 先去缓存区域找 找不到了在去.class文件中加载

    -   双亲委派模型(主要) 

        用户加载器->应用加载器/系统加载器/上下文加载器->扩展加载器->根加载器

        按照此方式往上加载类
        
        好处是父类加载了就没必要自己加载一次
        
        平时默认是使用系统加载器的 也可以自己制自己的加载器
        
        ```java
        Class.forName(); 
        // 用当前类加载器
        Classloader.getSystemClassLoader().loadClass();
        // 用系统加载器
        Thread.currentThread().getContextClassLoader().loadClass();
        // 用上下文加载器
        ```
        
    

ClassLoader的代码结构

-   **defineClass** 
  
    byte流解析成jvm能够识别的对象
    
-    **findClass** 
  
    通过类名去加载对象,通常我们定义自己的类加载器用该方法实现
    
-    **loadClass** 
  
    加载类到JVM
    
-    **resolveClass**
  
    动调用这个使得被加到JVM的类被链接
    

#### 双亲委派模型

如下图,从用户加载器开始,会向上委托其父类加载器加载,不会自己加载,如果加载不了在一步步向下让加载器加载,所谓的双亲委派指的是委派父类完成加载,而不是自己加载

这样设计的原因是防止类重新加载,如果发现该类加载器已经加载了该类那么久不会重复加载而引用jvm里面的Class对象

![图片](https://upload-images.jianshu.io/upload_images/1833901-97c7f6c8d8e0965f.png)

整个编译过程为static final注入,static 默认值注入,常量替换和引用生成等.

![](https://img-blog.csdn.net/20150702112329327?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvb3BlbnN1cmU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

上图为不同的classloader用来加载不同路径的类



#### ***类和对象初始化***

clinit方法和init方法 是指类的初始化和对象的初始化

在编译.class文件的时候注入到字节码里面

-   clinit是类的初始化

    Static变量的赋值初始化 执行static代码块

    该方法只执行一次 若类中无static代码块 和 static变量 则没有该方法

-   init是实例的初始化

    实例初始化 类的构造方法和普通代码块的执行

---

##### 初始化顺序和方法执行特点

##### **1.类的初始化** clinit方法的特性

先执行父类在执行子类,先执行staic方法在执行普通方法,先初始化成员变量在初始化方法,

多个线程执行的时候blocked,只有唯一clinit方法在执行

***而静态代码块和静态成员变量按顺序从类的上往下依次执行***

***数组定义不会触发初始化！！ 本质上是加载数组类***

类的初始化条件 本质上是new,getstatic,putstatic,invokestatic指令执行的时候

1.  new 不包括 new ClassName[10]
2.  反射调用的时候
3.  父类初始化
4.  虚拟机加载的时候
5.  方法invoke 内部有隐式的new

##### **2.对象的初始化** init方法特性

执行变量初始化 方法指针生成等 和clinit类似

##### **3.初始化顺序**

  ```note
1.初始化父类代码块 初始化父类final static 初始化父类static 
//同一时间按序执行
2.初始化子类代码块 初始化子类final static 初始化子类static
3.初始化父类普通成员变量 初始化父类final 初始化父类普通代码块
4.初始化子类普通成员变量 初始化子类final 初始化父类普通代码块
  ```

总的来说初始化对象/类的过程,一是从父类开始逐一加载,二是clinit方法和init方法,clinit方法主要初始化的是static变量和代码块,而init方法则是初始化普通成员变量和普通代码块,其中clinit方法只执行一次

##### **clinit可以看做static的初始化方法,init可以看成普通的初始方法,构造函数属于普通的方法**



---

### **学会了?来试试下面习题吧**

```java
public class StaticTest{
    public static void main(String[] args){
        staticFunction();
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

这题十分考验对clinit和init的理解,我们这里讲述idea的debugger用于说明情况

### 使用idea的debugger

在启动debugger或者run菜单的选项中可以看到以下按钮

-   breakpoint 断点,执行指针停留的地方
-   Step over 按行执行(一般点击这个)
-   Force Step Into 到方法内部最底层的源码
-   Drop Frame 回退断点

#### 查看变量

-   本行执行语句的最右边会有
-   光标悬停在变量的引用上(常用)
-   底下variable区域会有
-   watches可以设置表达式查看变量的值

#### Evaluate Expression 调用方法/设置值/查看值

Evaluate Expression 或者像一个计算器的图标,点开即可在执行时刻任意注入值也可以调用方法,当然既然可以调用方法那么自然可以调用`System.out.println`来查看变量的值,是个非常有用的工具

#### 设置条件断点

在断点处单击右键即可用java代码设置条件,只有达到了条件才会断点停下

#### 调试上述问题

把初始化的地方全部打上断点,一步步点击`step over`发现程序在执行`<clinit>:8`之后跳去了`<init>:15`,此处能够说明的问题是,在`<clinit>`方法执行中,因为出现了new关键字,类虽然已经加载完成却在进行类初始化的中途去执行实例初始化了.

我们从上面的debug可以看到,`<clinit>`和`<init>`是两种独立初始化,其发生的顺序先后没有必然关系,而类加载只是分配好内存空间,并未进行相应的值的注入,所以应该把加载,初始化完全分开来看.



---

### GC

gc指的是garage collection,即垃圾回收.

我们基于如下图可以知道GC也是得分jdk1.7和jdk1.8的,下面我们将以1.7的为主,1.8特有的元空间最后在补充

![](https://img-blog.csdnimg.cn/20190305150132242.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM3NTk4MDEx,size_16,color_FFFFFF,t_70)



#### 内存结构基于GC的理解

-   方法区(常量池,static变量区,类的信息)

    在hotspot中这块区域对应**永久代(Permanent Generation)**,这一部分区域中,通常这部分数据不会被GC,但如果是常量池的回收和类的卸载还是会被GC掉的

-   heap

    重点的GC区域所有new出来的内存都在此分配

除此之外的所有区域是不会被回收的,gc的周期,包括jvm内存结构的周期和线程的周期一致



#### 引用

引用分为4种:强引用,弱引用,软引用,虚引用

##### 强引用:Object obj=new Object();

 我们平时自己new出来的有带变量接受称强引用

如果这些对象是OutOfMemoryError 也就是说jvm不可能回收这类对象

##### 弱引用:new Object();

没有明确变量引用时jvm会考虑回收

##### 软引用:obj=null;

只有在内存不足的时候JVM才会回收该对象一般我们会配合ReferenceQueue去使用

```java
import java.lang.ref.SoftReference; 
public class SoftRef {  
    public static void main(String[] args){  
        System.out.println("start");            
        Obj obj = new Obj();            
        SoftReference<Obj> sr = new SoftReference<Obj>(obj);  
        obj = null;  
        System.out.println(sr.get());  
        System.out.println("end");     
    }       
}
class Obj{  
    int[] obj ;  
    public Obj(){  
        obj = new int[1000];  
    }  
}
```

##### 虚引用:finalize

finalize时会用到的一种引用,使用较少,在任何时候都可能被垃圾回收器回收

```java
import java.lang.ref.PhantomReference;
import java.lang.ref.ReferenceQueue;
public class PhantomRef {
    public static void main(String[] args) {
        ReferenceQueue<String> queue = new ReferenceQueue<String>();
        PhantomReference<String> pr = new PhantomReference<String>(new String("hello"), queue);
        System.out.println(pr.get());
    }
}
```

| 引用类型 | 被回收时间    | 用途           | 生存时间      |
| -------- | ------------- | -------------- | ------------- |
| 强引用   | 从来不会      | 对象的一般状态 | JVM停止运行时 |
| 软引用   | 内存不足时    | 对象缓存       | 内存不足时    |
| 弱引用   | jvm垃圾回收时 | 对象缓存       | gc运行后      |
| 虚引用   | 未知          | 未知           | 未知          |

在实际使用的过程中弱引用与虚引用几乎没用到

所以我们使用完对象一般把变量置为null



#### heap的内存分区域(分代)

-   `gc所回收的对象都是不再被引用的对象,且主要是弱引用,软引用和虚引用` 

JDK1.7到1.8发生的改变主要是涉及到**方法区(永久代)**的改变,堆内存的使用方式和前代一致

![](https://img-blog.csdn.net/20180711231128855?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3F6cWFuemM=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

##### 永久代 Permanent Generation

在前面我们已经提到过**持久代/永久代(Permanent Generation)** 是指方法区,更具体的讲是Hotspot虚拟机才有的称为,在其他的一些jvm中可能没有这样的称呼,永久代的内存也是会被清理的,比如常量池的回收,或者类的卸载就会是的gc能够清理该部分的内存

##### 新生代 Young Generation

新生代适合生命周期较短,快速创建和快速销毁的对象.如图,新生代被分为Eden区(Eden是伊甸园的意思)和Suvivor区,Suvivor区分为**From区和To区**.FromSpace和ToSpace的大小一致.所有新建的对象都是从新生代分配内存,Eden区不足的时候会把对象转移到Survior区.新生代进行内存回收的时候会触发**Minor GC**又叫**Young GC**

关于From区和To区的作用是为了垃圾回收算法,下文的copying算法会详细解释.当新生代内存使用满了的时候此时则会有对象直接进入老年代.默认情况下,对象在Suvivor区域躲过垃圾回收15次,则会直接进入老年代.

##### 旧生代 Old Generation

旧生代用于存放新生代**多次回收依然存活的对象**,在旧生代满的时候需要对旧生代进行回收,称为**Major GC**或者**Full GC**,一般即使大型的服务的Full GC的频率也大于一天一次,过于频繁的GC会让系统性能下降.

新生代进入老年代时,内存如果不够可能会发生一次Full GC,如果新生代需要分配比较大的对象,找不到那么大的区域,那么该对象会提前触发一次Full GC而直接进入老年代

-   **`对象一般是被分配到新生代,极少数对象被分配到老年代`**

##### 元空间 Metaspace(jdk1.8 gc的变化)

![](https://img-blog.csdnimg.cn/20190305150132242.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM3NTk4MDEx,size_16,color_FFFFFF,t_70)

如图,我们可以看到元空间(元数据区)是相当于永久代的存在,这个改动的主要原因是因为永久代基本不会发生GC所以直接导致OOM问题的出现.所以JDK1.8之后对之前的内存结构进行了修改,其还会存放编译好的类的数据结构,常量池等,其最大的特点就是不参加GC,同时**字面量(字符串常量)被移到堆中接受GC管理**,其内存管理模式由操作系统的内存管理,在此不多赘述.



#### gc主要的算法

##### 回收判定算法

-   计数引用算法

    每一个对象被引用则计数器加一否则减一,此算法有个弊端就是类似死锁,两个对象互相持有对方的引用这样子gc就不可能清理掉

-   根搜索算法

    根搜索算法就是从一个GC Root的根出发,如果能到达则说明被引用,否则则可以视为清理,如下

![](https://imgconvert.csdnimg.cn/aHR0cDovL3VwbG9hZC1pbWFnZXMuamlhbnNodS5pby91cGxvYWRfaW1hZ2VzLzIwMzIxNzctOTk4ZmVkNzdhNzYxMmUxYi5wbmc?x-oss-process=image/format,png)

下面的所有回收算法都要依赖根搜索算法,顺带一提GC Root指的是从栈上引用的变量开始往下递归找

##### 回收算法

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

上面三种算法各有利弊,所以jvm的开发者设计了老年代,永久代,新生代三个区域,结合三种垃圾回收算法,综合进行了分区域的回收

各代使用的垃圾回收算法总结

| 内存区域 | 回收特点                             | 适合使用算法 |
| -------- | ------------------------------------ | ------------ |
| 新生代   | 需要频繁进行GC回收,回收大部分对象    | Copying      |
| 老年代   | 回收少量对象                         | Mark-Compact |
| 永久代   | 在主程序的运行中基本不会进行垃圾回收 | 无           |



#### 关于Full GC

Minor GC是回收年轻代的,Major GC是回收老年代的,**Full GC**是针对年轻代也是针对老年代的,所以我们可以知道Major GC和Full GC实际上是两个完全不同的东西



#### 触发gc的情况

-   Minor GC 年轻代满的时候

**Full GC**的触发条件比较多

-   System.gc()

-   永久代空间不足

-   老年代空间不足

-   GC时出现Promotion Faield(年轻代空间不足够放下那么大的对象)

-   统计得到的Minor GC晋升到老年代的平均大小大于老年代的剩余空间(JVM觉得老年代空间要不够用了)

    

#### 空间分配担保

在进行`Minor GC`时jvm会检查老年代的可用空间是否大于新生代的所有空间,如果是的话可以保证`Minor GC`是安全的,如果不安全的话参照`HandlePromotionFailire`进行进一步处理,

如果允许继续检查老年代最大可用可用的连续空间是否大于之前晋升的平均大小,如果是就尝试进行一次`Minor GC`(如果新生代出现了大对象可能会失败,失败就触发`Full GC`)否则就进行`Full GC`

这是一种动态的概率保护手段



#### 新生代晋升老年代的情况

-   分代年龄>15

-   对象太大

-   Minor GC 后 一般的Survior区和Eden区没法放下的对象 (空间分配担保机制)

-   survior区相同年龄对象总大小大于survior区空间的一半

    (众数群体大于一半,大于该群体年龄的所有对象晋升)



#### 垃圾回收器

##### 一些只需要了解的垃圾回收器

-   Serial 串行垃圾回收,年代久远
-   ParNew 多线程新生代回收器 (*-XX:ParallelGCThreads*控制)
-   Parallel Scavenge 多线程采用`copying`算法的新生代垃圾回收器注重吞吐量的垃圾回收器
-   Serial Old 串行回收老年代采用`mark-sweep`算法
-   Parallel Old 并行回收老年代采用`mark-sweep`算法



##### ParallelGC

```shell
-XX:+UseParallelGC # jdk的默认参数
```

这个其实是上面垃圾回收的组合,新生代使用`Parallel Scaveng`老年代使用`Parallel Old(mark-sweep)`进行垃圾回收,另需说明此处的`Parallel Old`是采用了`Serial Old`去进行设计的所以在很多资料中也能看到`Serial Old`的说法.**回收所有区域的垃圾**



#####  CMS(Concurrent Mark Sweep)

```shell
-XX:+UseConcMarkSweepGC # 启用该垃圾回收器
-XX:+UseCMSCompactAtFullCollection # 因为采用了mark-sweep所以在内存碎片满的时候直接进行合并清空
```

其主要采用并发的`mark-sweep`算法来进行垃圾回收,其垃圾回收过程可以和用户的java线程一起并发执行,而其他回收器是得停掉用户的线程才能进行垃圾回收的.**回收老年代的垃圾**

其特别吃cpu的核心数,且会极大的影响系统性能,其无法处理浮动垃圾(因为要和用户线程一起并发,所以临时产生的垃圾就无法去清楚了),可能会触发Full GC,且其会产生大量的内存碎片



##### G1(garbage first)

```shell
-XX:+UseG1GC # 启用该垃圾回收器
```

JDK1.7以后前沿的垃圾回收器,服务器上常使用此垃圾回收器,其弱化了**分代**的概念,强化了**分区**的概念,且优先考虑从垃圾多的区域(存活数量少)开始回收,其用到的算法为`mark-sweep`和`copying`的算法,**回收所有区域的垃圾**

g1会给内存分出大小相同的区域(region)

g1通过并发(并行)标记阶段查找老年代存活对象,通过并行`copying`存活对象

g1将一组或多组区域中存活对象以增量并行的方式复制到不同区域进行压缩,从而减少堆碎片,目标是尽可能多回收堆空间 **垃圾优先**,且尽可能不超出暂停目标以达到低延迟的目的.



---

### jvm控制指令

这里我们主要介绍一些控制jvm相关的指令

#### 原生指令

`java`和`javac`命令,`javac`负责把.java文件编译为.class文件,`java`则是运行字节码文件,这两者是最常见的指令 `java`既然是运行字节码文件的指令,自然可以指定jvm的性质

```shell
-XX:+PrintCommandLineFlags # 加入该参数可以打印命令行参数
-XX:+PrintGCDetails # 打印GC详情
```

#### 编译控制

```shell
java -verbose:class 即可查看加载了哪些类
java -Xmx 堆内存的最大大小
java -Xms 堆内存的最小大小
java -Xmn 新生代大小 (max new)
java -Xss 每个线程可使用的内存大小即栈的大小 (stack size)
```

![](https://img-blog.csdnimg.cn/20190418153058588.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3poYW5nZmVuZ2Fpd3V5YW4=,size_16,color_FFFFFF,t_70)

通过上面的命令我们能够控制新生代,老生代和持久代的大小等. 另外一提就是老年代的内存我们是控制新生代的内存大小和堆的大小来确定老年代的内存的.



#### 工具和指令

##### jps

jps是用来查看jvm里面线程的所有状态的

```shell
jps -m # 查看传给main的参数
jps -l # 查看类的完整路径
jps -v # 查看jvm上运行程序的jvm参数  
```

##### jinfo

用于查看jvm参数或者系统参数

```shell
jinfo -flags <pid> # 查看jvm的运行参数
jinfo -sysprops <pid> # 查看system的参数
jinfo <pid> # 查看所有参数
```

##### jstat

用于查看统计信息,是十分重要的一条命令,这个命令主要的作用就是看gc

```shell
jstat -class <pid> # 查看类的统计
# jstat -class <pid> <per/ms> <counts> 查看counts次统计每ms查看一次
jstat -complier <pid> # 查看编译统计
jstat -gc <pid> # 查看gc统计 这条命令比较重要
jstat -gccapacity <pid> # 堆内存统计

jstat -gcnew <pid> # 新生代回收统计
jstat -gcnewcapacity <pid> # 新生代容量统计
jstat -gcold <pid> # 老年代回收统计
jstat -gcoldcapacity <pid> # 老年代容量统计
jstat -gcperm <pid> # 永久代回收统计
jstat -gcpermcapacity <pid> # 永久代容量统计
# 因为元空间的回收不归GC管所以没有元空间的回收统计
jstat -gcmetacapacity <pid> # 元空间容量统计
```

jstat -gc 各个字段的意思

![](https://img2018.cnblogs.com/blog/978388/201906/978388-20190626150321415-587548863.png)

- S0C：第一个幸存区的大小
- S1C：第二个幸存区的大小
- S0U：第一个幸存区的使用大小
- S1U：第二个幸存区的使用大小
- EC：伊甸园区的大小
- EU：伊甸园区的使用大小
- OC：老年代大小
- OU：老年代使用大小
- MC：方法区大小
- MU：方法区使用大小
- CCSC:压缩类空间大小
- CCSU:压缩类空间使用大小
- YGC：年轻代垃圾回收次数
- YGCT：年轻代垃圾回收消耗时间
- FGC：Full GC垃圾回收次数
- FGCT：Full GC垃圾回收消耗时间
- GCT：垃圾回收消耗总时间

##### jmap

这里的指令是专门用来看内存的,甚至还可以dump出来内存的数据

```shell
jmap -heap <pid> # 查看堆内存使用量
jmap -histo:live <pid> # 查看对象个数和字节数的图表,如果不加live就是代表所有的而不是或者的对象的个数
jmap -dump:live,format=b,file=myjmapfile.bin <pid> # dump出内存了 myjmapfile.txt就是dump出的文件
```

##### jhat

jhat比较简单,用来配合jmap使用

```shell
jhat myjmapfile.bin # 可以开启一小型服务器,在7000端口访问能看到内存的统计信息
```

##### jstack

jstack和jstat不同,jstack是用来监视线程状态的一个命令,jstat是统计

```shell
jstack <pid>
```

其结果大致如下我们来分析下下面各成分间的含义


```shell
Full thread dump OpenJDK 64-Bit Server VM (25.262-b10 mixed mode):

"Attach Listener" #8 daemon prio=9 os_prio=0 tid=0x00007f0c60001000 nid=0x453c waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Service Thread" #7 daemon prio=9 os_prio=0 tid=0x00007f0c88119800 nid=0x96e runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C1 CompilerThread1" #6 daemon prio=9 os_prio=0 tid=0x00007f0c88116800 nid=0x96d waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"C2 CompilerThread0" #5 daemon prio=9 os_prio=0 tid=0x00007f0c88109800 nid=0x96c waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Signal Dispatcher" #4 daemon prio=9 os_prio=0 tid=0x00007f0c88107800 nid=0x96b runnable [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"Finalizer" #3 daemon prio=8 os_prio=0 tid=0x00007f0c880da000 nid=0x96a in Object.wait() [0x00007f0c78225000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	- waiting on <0x00000000ecd58038> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:144)
	- locked <0x00000000ecd58038> (a java.lang.ref.ReferenceQueue$Lock)
	at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:165)
	at java.lang.ref.Finalizer$FinalizerThread.run(Finalizer.java:216)

"Reference Handler" #2 daemon prio=10 os_prio=0 tid=0x00007f0c880d5800 nid=0x969 in Object.wait() [0x00007f0c78326000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	- waiting on <0x00000000ecd565c8> (a java.lang.ref.Reference$Lock)
	at java.lang.Object.wait(Object.java:502)
	at java.lang.ref.Reference.tryHandlePending(Reference.java:191)
	- locked <0x00000000ecd565c8> (a java.lang.ref.Reference$Lock)
	at java.lang.ref.Reference$ReferenceHandler.run(Reference.java:153)

"main" #1 prio=5 os_prio=0 tid=0x00007f0c8804b800 nid=0x967 waiting on condition [0x00007f0c8f540000]
   java.lang.Thread.State: TIMED_WAITING (sleeping)
	at java.lang.Thread.sleep(Native Method)
	at Test.main(Test.java:7)

"VM Thread" os_prio=0 tid=0x00007f0c880cb800 nid=0x968 runnable

"VM Periodic Task Thread" os_prio=0 tid=0x00007f0c8811c000 nid=0x96f waiting on condition

JNI global references: 5
```

-   nid (native thread id) 指的是该java线程在linux系下的id
-   prio 指的是线程的优先级
-   tid 线程id 

`locked <0x00000000ecd58038>` 获得该对象的锁

`waiting to lock <0x000000076bf62208>` 等待地址为0x000000076bf62208对象上的锁

`waiting for monitor entry [0x000000001e21f000]` 通过synchronized关键字进入了监视器的临界区,并处于"Entry Set"队列,等待monitor // 理解此处需要理解synchronized关键字的实现

其他的语句大同小异,等理解多线程的实现之后可以看懂jstack日志

##### javap反汇编

该指令可以分析java代码的字节码,我们反汇编一个helloworld

```shell
javap -v demo.class
```

```shell
  MD5 checksum 6db440ce535b8d85fc3ad654205fcb68
  Compiled from "Main.java"
public class com.demo.Main
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #6.#20         // java/lang/Object."<init>":()V
   #2 = Fieldref           #21.#22        // java/lang/System.out:Ljava/io/PrintStream;
   #3 = String             #23            // hello world
   #4 = Methodref          #24.#25        // java/io/PrintStream.println:(Ljava/lang/String;)V
   #5 = Class              #26            // com/demo/Main
   #6 = Class              #27            // java/lang/Object
   #7 = Utf8               <init>
   #8 = Utf8               ()V
   #9 = Utf8               Code
  #10 = Utf8               LineNumberTable
  #11 = Utf8               LocalVariableTable
  #12 = Utf8               this
  #13 = Utf8               Lcom/demo/Main;
  #14 = Utf8               main
  #15 = Utf8               ([Ljava/lang/String;)V
  #16 = Utf8               args
  #17 = Utf8               [Ljava/lang/String;
  #18 = Utf8               SourceFile
  #19 = Utf8               Main.java
  #20 = NameAndType        #7:#8          // "<init>":()V
  #21 = Class              #28            // java/lang/System
  #22 = NameAndType        #29:#30        // out:Ljava/io/PrintStream;
  #23 = Utf8               hello world
  #24 = Class              #31            // java/io/PrintStream
  #25 = NameAndType        #32:#33        // println:(Ljava/lang/String;)V
  #26 = Utf8               com/demo/Main
  #27 = Utf8               java/lang/Object
  #28 = Utf8               java/lang/System
  #29 = Utf8               out
  #30 = Utf8               Ljava/io/PrintStream;
  #31 = Utf8               java/io/PrintStream
  #32 = Utf8               println
  #33 = Utf8               (Ljava/lang/String;)V
{
  public com.demo.Main();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 13: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcom/demo/Main;

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=1, args_size=1
         0: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
         3: ldc           #3                  // String hello world
         5: invokevirtual #4                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
         8: return
      LineNumberTable:
        line 16: 0
        line 17: 8
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       9     0  args   [Ljava/lang/String;
}

```

通过反汇编我们也能知道jvm干了什么,各字节码的具体解读如下问



##### JOL包分析对象

```xml
<!-- JOL对象分析工具 -->
<dependency>
  <groupId>org.openjdk.jol</groupId>
  <artifactId>jol-core</artifactId>
  <version>0.14</version>
</dependency>
```

常用的方法

```java
ClassLayout.parseInstance(obj).toPrintable(); // 打印对象内部的结构和占用大小
```

我们用其打印一个hashmap如下

| OFFSET | SIZE | TYPE                 | DESCRIPTION        | VALUE       |
| ------ | ---- | -------------------- | ------------------ | ----------- |
| 0      | 4    |                      | (object header)    | 01 00 00 00 |
| 4      | 4    |                      | (object header)    | 00 00 00 00 |
| 8      | 4    |                      | (object header)    | a8 37 00 f8 |
| 12     | 4    | java.util.Set        | AbstractMap.keySet | null        |
| 16     | 4    | java.util.Collection | AbstractMap.values | null        |
| 20     | 4    | int                  | HashMap.size       | 2           |

......还有hashmap的其他成员变量

##### jconsole/VisualVM

jconsole是一可视化工具,可以连接本地jvm的进程或者连接远程jvm的进程,命令行直接输入jconsole即可

VisualVM也是一个可视化工具需要手动下载



#### javaapi/shell修改jvm内存相关信息

java 主要通过java.lang.management相关的类实现功能

```java
import java.lang.management.ClassLoadingMXBean;
import java.lang.management.CompilationMXBean;
import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryManagerMXBean;
import java.lang.management.MemoryPoolMXBean;
import java.lang.management.MemoryUsage;
import java.lang.management.OperatingSystemMXBean;
import java.lang.management.RuntimeMXBean;
import java.lang.management.ThreadInfo;
import java.lang.management.ThreadMXBean;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;
 
public class JvmInfo {
 
	static final long MB = 1024 * 1024;
	
	public static void main(String[] args) {
		
				
		//打印系统信息
		System.out.println("===========打印系统信息==========");
		printOperatingSystemInfo();
		//打印编译信息
		System.out.println("===========打印编译信息==========");
		printCompilationInfo();
		//打印类加载信息
		System.out.println("===========打印类加载信息==========");
		printClassLoadingInfo();
		//打印运行时信息
		System.out.println("===========打印运行时信息==========");
		printRuntimeInfo();
		//打印内存管理器信息
		System.out.println("===========打印内存管理器信息==========");
		printMemoryManagerInfo();
		//打印垃圾回收信息
		System.out.println("===========打印垃圾回收信息==========");
		printGarbageCollectorInfo();
		//打印vm内存
		System.out.println("===========打印vm内存信息==========");
		printMemoryInfo();
		//打印vm各内存区信息
		System.out.println("===========打印vm各内存区信息==========");
		printMemoryPoolInfo();
		//打印线程信息
		System.out.println("===========打印线程==========");
		printThreadInfo();
		
	}
	
	
	private static void printOperatingSystemInfo(){
		OperatingSystemMXBean system = ManagementFactory.getOperatingSystemMXBean();
		//相当于System.getProperty("os.name").
		System.out.println("系统名称:"+system.getName());
		//相当于System.getProperty("os.version").
		System.out.println("系统版本:"+system.getVersion());
		//相当于System.getProperty("os.arch").
		System.out.println("操作系统的架构:"+system.getArch());
		//相当于 Runtime.availableProcessors()
		System.out.println("可用的内核数:"+system.getAvailableProcessors());
		
		if(isSunOsMBean(system)){
			long totalPhysicalMemory = getLongFromOperatingSystem(system,"getTotalPhysicalMemorySize");
			long freePhysicalMemory = getLongFromOperatingSystem(system, "getFreePhysicalMemorySize");
			long usedPhysicalMemorySize =totalPhysicalMemory - freePhysicalMemory;
			
			System.out.println("总物理内存(M):"+totalPhysicalMemory/MB);
			System.out.println("已用物理内存(M):"+usedPhysicalMemorySize/MB);
			System.out.println("剩余物理内存(M):"+freePhysicalMemory/MB);
			
			long  totalSwapSpaceSize = getLongFromOperatingSystem(system, "getTotalSwapSpaceSize");
			long freeSwapSpaceSize = getLongFromOperatingSystem(system, "getFreeSwapSpaceSize");
			long usedSwapSpaceSize = totalSwapSpaceSize - freeSwapSpaceSize;
			
			System.out.println("总交换空间(M):"+totalSwapSpaceSize/MB);
			System.out.println("已用交换空间(M):"+usedSwapSpaceSize/MB);
			System.out.println("剩余交换空间(M):"+freeSwapSpaceSize/MB);
		}
	}
	
	private static long getLongFromOperatingSystem(OperatingSystemMXBean operatingSystem, String methodName) {
		try {
			final Method method = operatingSystem.getClass().getMethod(methodName,
					(Class<?>[]) null);
			method.setAccessible(true);
			return (Long) method.invoke(operatingSystem, (Object[]) null);
		} catch (final InvocationTargetException e) {
			if (e.getCause() instanceof Error) {
				throw (Error) e.getCause();
			} else if (e.getCause() instanceof RuntimeException) {
				throw (RuntimeException) e.getCause();
			}
			throw new IllegalStateException(e.getCause());
		} catch (final NoSuchMethodException e) {
			throw new IllegalArgumentException(e);
		} catch (final IllegalAccessException e) {
			throw new IllegalStateException(e);
		}
	}
 
	private static void printCompilationInfo(){
		CompilationMXBean compilation = ManagementFactory.getCompilationMXBean();
		System.out.println("JIT编译器名称："+compilation.getName());
		//判断jvm是否支持编译时间的监控
		if(compilation.isCompilationTimeMonitoringSupported()){
			System.out.println("总编译时间："+compilation.getTotalCompilationTime()+"秒");
		}
	}
	
	private static void printClassLoadingInfo(){
		ClassLoadingMXBean classLoad= ManagementFactory.getClassLoadingMXBean();
		System.out.println("已加载类总数："+classLoad.getTotalLoadedClassCount());
		System.out.println("已加载当前类："+classLoad.getLoadedClassCount());
		System.out.println("已卸载类总数："+classLoad.getUnloadedClassCount());
		
	}
	
	private static void printRuntimeInfo(){
		RuntimeMXBean runtime = ManagementFactory.getRuntimeMXBean();
		System.out.println("进程PID="+runtime.getName().split("@")[0]);
		System.out.println("jvm规范名称:"+runtime.getSpecName());
		System.out.println("jvm规范运营商:"+runtime.getSpecVendor());
		System.out.println("jvm规范版本:"+runtime.getSpecVersion());
		//返回虚拟机在毫秒内的开始时间。该方法返回了虚拟机启动时的近似时间
		System.out.println("jvm启动时间（毫秒）:"+runtime.getStartTime());
		//相当于System.getProperties
		System.out.println("获取System.properties:"+runtime.getSystemProperties());
		System.out.println("jvm正常运行时间（毫秒）:"+runtime.getUptime());
		//相当于System.getProperty("java.vm.name").
		System.out.println("jvm名称:"+runtime.getVmName());
		//相当于System.getProperty("java.vm.vendor").
		System.out.println("jvm运营商:"+runtime.getVmVendor());
		//相当于System.getProperty("java.vm.version").
		System.out.println("jvm实现版本:"+runtime.getVmVersion());
		List<String> args = runtime.getInputArguments();
		if(args != null && !args.isEmpty()){
			System.out.println("vm参数:");
			for(String arg : args){
				System.out.println(arg);
			}
		}
		System.out.println("类路径:"+runtime.getClassPath());
		System.out.println("引导类路径:"+runtime.getBootClassPath());
		System.out.println("库路径:"+runtime.getLibraryPath());
	}
	
	private static void printMemoryManagerInfo(){
		List<MemoryManagerMXBean> managers = ManagementFactory.getMemoryManagerMXBeans();
		if(managers != null && !managers.isEmpty()){
			for(MemoryManagerMXBean manager : managers){
				System.out.println("vm内存管理器：名称="+manager.getName()+",管理的内存区="
			+Arrays.deepToString(manager.getMemoryPoolNames())+",ObjectName="+manager.getObjectName());
			}
		}
	}
	
	private static void printGarbageCollectorInfo(){
		List<GarbageCollectorMXBean> garbages = ManagementFactory.getGarbageCollectorMXBeans();
		for(GarbageCollectorMXBean garbage : garbages){
			System.out.println("垃圾收集器：名称="+garbage.getName()+",收集="+garbage.getCollectionCount()+",总花费时间="
		+garbage.getCollectionTime()+",内存区名称="+Arrays.deepToString(garbage.getMemoryPoolNames()));
		}
	}
	
	private static void printMemoryInfo(){
		MemoryMXBean memory = ManagementFactory.getMemoryMXBean();
		MemoryUsage headMemory = memory.getHeapMemoryUsage();
		System.out.println("head堆:");
		System.out.println("\t初始(M):"+headMemory.getInit()/MB);
		System.out.println("\t最大(上限)(M):"+headMemory.getMax()/MB);
		System.out.println("\t当前(已使用)(M):"+headMemory.getUsed()/MB);
		System.out.println("\t提交的内存(已申请)(M):"+headMemory.getCommitted()/MB);
		System.out.println("\t使用率:"+headMemory.getUsed()*100/headMemory.getCommitted()+"%");
		
		System.out.println("non-head非堆:");
		MemoryUsage nonheadMemory = memory.getNonHeapMemoryUsage();
		System.out.println("\t初始(M):"+nonheadMemory.getInit()/MB);
		System.out.println("\t最大(上限)(M):"+nonheadMemory.getMax()/MB);
		System.out.println("\t当前(已使用)(M):"+nonheadMemory.getUsed()/MB);
		System.out.println("\t提交的内存(已申请)(M):"+nonheadMemory.getCommitted()/MB);
		System.out.println("\t使用率:"+nonheadMemory.getUsed()*100/nonheadMemory.getCommitted()+"%");
	}
	
	private static void printMemoryPoolInfo(){
		List<MemoryPoolMXBean> pools = ManagementFactory.getMemoryPoolMXBeans();
		if(pools != null && !pools.isEmpty()){
			for(MemoryPoolMXBean pool : pools){
				//只打印一些各个内存区都有的属性，一些区的特殊属性，可看文档或百度
				//最大值，初始值，如果没有定义的话，返回-1，所以真正使用时，要注意
				System.out.println("vm内存区:\n\t名称="+pool.getName()+"\n\t所属内存管理者="+Arrays.deepToString(pool.getMemoryManagerNames())
						+"\n\t ObjectName="+pool.getObjectName()+"\n\t初始大小(M)="+pool.getUsage().getInit()/MB
						+"\n\t最大(上限)(M)="+pool.getUsage().getMax()/MB
						+"\n\t已用大小(M)="+pool.getUsage().getUsed()/MB
						+"\n\t已提交(已申请)(M)="+pool.getUsage().getCommitted()/MB
						+"\n\t使用率="+(pool.getUsage().getUsed()*100/pool.getUsage().getCommitted())+"%");
			
			}
		}
	}
	
	private static void printThreadInfo(){
		ThreadMXBean thread = ManagementFactory.getThreadMXBean();
		System.out.println("ObjectName="+thread.getObjectName());
		System.out.println("仍活动的线程总数="+thread.getThreadCount());
		System.out.println("峰值="+thread.getPeakThreadCount());
		System.out.println("线程总数（被创建并执行过的线程总数）="+thread.getTotalStartedThreadCount());
		System.out.println("当初仍活动的守护线程（daemonThread）总数="+thread.getDaemonThreadCount());
		
		//检查是否有死锁的线程存在
		long[] deadlockedIds =  thread.findDeadlockedThreads();
		if(deadlockedIds != null && deadlockedIds.length > 0){
			ThreadInfo[] deadlockInfos = thread.getThreadInfo(deadlockedIds);
			System.out.println("死锁线程信息:");
			System.out.println("\t\t线程名称\t\t状态\t\t");
			for(ThreadInfo deadlockInfo : deadlockInfos){
				System.out.println("\t\t"+deadlockInfo.getThreadName()+"\t\t"+deadlockInfo.getThreadState()
						+"\t\t"+deadlockInfo.getBlockedTime()+"\t\t"+deadlockInfo.getWaitedTime()
						+"\t\t"+deadlockInfo.getStackTrace().toString());
			}
		}
		long[] threadIds = thread.getAllThreadIds();
		if(threadIds != null && threadIds.length > 0){
			ThreadInfo[] threadInfos = thread.getThreadInfo(threadIds);
			System.out.println("所有线程信息:");
			System.out.println("\t\t线程名称\t\t\t\t\t状态\t\t\t\t\t线程id");
			for(ThreadInfo threadInfo : threadInfos){
				System.out.println("\t\t"+threadInfo.getThreadName()+"\t\t\t\t\t"+threadInfo.getThreadState()
						+"\t\t\t\t\t"+threadInfo.getThreadId());
			}
		}
		
	}
	
	private static boolean isSunOsMBean(OperatingSystemMXBean operatingSystem) {
		final String className = operatingSystem.getClass().getName();
		return "com.sun.management.OperatingSystem".equals(className)
				|| "com.sun.management.UnixOperatingSystem".equals(className);
	}
}
```



### java编译优化JIT

java的编译在早期的时候是由`javac`完成的,内存分配的工作也基本上由传统的JVM完成.

JIT指的是java即是编译技术,对传统的技术做了分析和改进.下文主要是对JIT相关技术的分析,JIT的目的是为了降低内存负载,减少堆内存的分配压力,JIT的技术主要由逃逸分析,锁消除,锁膨胀,方法内联,空值检查消除,类型检测消除,公共子表达式消除



#### 逃逸分析 Escape Analysis

逃逸分析(Escape Analysis)是目前Java虚拟机中比较前沿的优化技术.这是一种可以有效减少Java 程序中同步负载和内存堆分配压力的跨函数全局数据流分析算法.通过逃逸分析,Hotspot编译器能够分析出一个新的对象的引用的使用范围从而决定是否要将这个对象分配到堆上.

逃逸分析的基本行为就是分析对象动态作用域:当一个对象在方法中被定义后,它可能被外部方法所引用,例如作为调用参数传递到其他地方中,称为方法逃逸.

如下方法内部栈创建了sb的引用,但sb有可能被方法外部的栈所引用,这叫方法逃逸,跨越线程访问的(即可被堆内存所访问叫线程逃逸),而如果返回String,那么sb则不会逃逸到方法外

```java
public static StringBuffer craeteStringBuffer(String s1, String s2) {
    StringBuffer sb = new StringBuffer();
    sb.append(s1);
    sb.append(s2);
    return sb; // sb.toString();
}
```

使用逃逸分析,JIT可以对代码做出如下优化

-   同步省略,如果一个对象只能被一个线程访问到,那么这个对象的操作可以不同步.
-   将堆分配转化为栈分配,如果一个对象的指针不会逃逸,那么可以不分配到堆而是栈.
-   分离对象和标量替换

`-XX:+DoEscapeAnalysis`和`-XX:-DoEscapeAnalysis`可以打开和关闭逃逸分析,JDK1.7以上默认打开逃逸分析.





### 字节码

-   未完待续