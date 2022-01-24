

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

但是new出来的对象有可能在栈上分配内存以及TLAB

**stack 存放thread/function级别数据** 局部变量操作数栈动态链接方法出口

-   vm stack虚拟机栈 线程私有,即对应thread级别的数据,一个线程的局部变量等

    每个方法在执行的时候会在虚拟机栈生成一个栈帧,栈帧的结构如下

    -   操作数栈
    -   局部变量表
    -   动态链接
    -   方法出口信息

-   native method 原生方法栈 顾名思义是原生调用所使用的栈

**方法区 process级数据** 常量池 static变量区 **类接口等加载**

-   加载的类的信息(类名,修饰符) meta信息一直在非堆中
-   **常量池** (JDK1.6属于方法区,JDK1.7放入堆中)
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

-   **jdk1.8后字符串常量从常量池中变成了堆中,关于此中的验证可以查看intern方法**

其他常量池还是在永久代或者元空间中.

### JMM

JMM是指java-memory-model,相比于内存区域,JMM更关注并发上的问题,本章节虽然作为JVM的解析,但JMM的前置知识是对多线程有深入的理解,可以参考另一文档中对于多线程的理解再来阅读本章节可能会更加容易,当然可以直接阅读.

JMM出现的原因,屏蔽不同硬件的差异,因为不同硬件访问内存都有逻辑上的差异,JMM就是为了提供一套屏蔽操作系统和硬件差异的模型.JMM是源自于Java5的技术JSR-133.

Java并发采用的是**共享内存模型**.其是物理机或者虚拟机上解决并发问题的一种模型MESI协议就是基于物理的一种协议,而JVM则是虚拟机解决并发问题的一种规范.

JMM的内存分为工作内存和主内存

![](https://images2018.cnblogs.com/blog/1102674/201808/1102674-20180815143324915-2024156794.png)

和堆栈划分不同,这里我们从硬件层次可以看到

-   工作内存Local Memory对应**寄存器**和**高速缓存**,缓存行的结构就位于工作内存,对应到内存结构就是栈内存
-   主内存Main Memory对应到**物理内存**,对应到内存结构解释堆内存

如果熟悉读写屏障可以看到,如果每次都要在主内存中进行读写,开销很大,但如果每次都在工作内存中读写就无法即是同步更新信息到其他工作内存(并发访问资源),JMM做的就是制定一套标准解决工作内存什么时候会同步给其他线程.

基于计算机组成原理我们知道,对一块double区域的读写,有可能(根据计算机位数)其读取甚至都不是原子性的,这从根本上导致了一些double的并发问题.

#### 内存交互操作

内存交互操作有8种,虚拟机实现必须保证每一个操作都是原子的,不可在分的(对于double和long类型的变量来说,load,store,read和write操作在某些平台上允许例外)

-   lock(锁定):作用于**主内存**的变量,把一个变量标识为**线程独占**状态
-   unlock(解锁):作用于主内存的变量,它把一个处于锁定状态的变量释放出来,释放后的变量才可以被其他线程锁定
-   read(读取):作用于主内存变量,它把一个变量的值从主内存传输到线程的工作内存中,以便随后的load动作使用
-   load(载入):作用于工作内存的变量,它把read操作从主存中变量放入工作内存中
-   use(使用):作用于工作内存中的变量,它把工作内存中的变量传输给执行引擎,每当虚拟机遇到一个需要使用到变量的值,就会使用到这个指令
-   assign(赋值):作用于工作内存中的变量,它把一个从执行引擎中接受到的值放入工作内存的变量副本中
-   store(存储):作用于主内存中的变量,它把一个从工作内存中一个变量的值传送到主内存中,以便后续的write使用
-   write(写入):作用于主内存中的变量,它把store操作从工作内存中得到的变量的值放入主内存的变量中

JMM对上面的指令进行了规定

-   read必须和load一起出现,write必须和store一起出现
-   线程工作内存发生改变后,必须告诉主存
-   不允许一个线程将没有assign的数据从工作内存同步回主内存
-   一个新的变量必须在主内存中诞生,不允许工作内存直接使用一个未被初始化的变量.就是对变量实施use,store操作之前,必须经过assign和load操作
-   **一个变量同一时间只有一个线程能对其进行lock**(原子性),多次lock后,必须执行相同次数的unlock才能解锁
-   如果对一个变量进行lock操作,会清空所有工作内存中此变量的值,在执行引擎使用这个变量前,必须重新load或assign操作初始化变量的值
-   如果一个变量没有被lock,就不能对其进行unlock操作.也不能unlock一个被其他线程锁住的变量
-   对一个变量进行**unlock操作之前,必须把此变量写回主内存**

上述规则和volatile读写屏障一样,总结起来变成了happen-before原则.关于更具体的MESI协议在另一文档中有叙述,这章的主要内容是了解虚拟机对应在物理机上的内存结构



### 对象

---

从上面我们可以知道在**Hotspot**中对象是存在方法区的,下面我们介绍对象具体的数据结构,而在另一文档中,我们会介绍对象与锁相关的知识

对象的元数据是以字节码形式存储在**方法区**中,而对象本身需要开辟的内存则是在**堆内存**中,可以说方法区只包含了基本信息的这么一个数据结构,真正的对象还是保存在堆中

如下图,_klassOop指的是klass指针,klass存储在方法区中

![](https://img-blog.csdn.net/20170419212953720?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvenF6X3pxeg==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

这里说明下klass这个数据结构

#### klass-OOP model

我们知道Hotspot是基于c++实现的,c++本身是门面向对象的语言,那java中的对象最简单的就是使用c++中的对象去一一对应,但是为了扩充一些功能,hotspot选择用klass这c++类来表示java中的类而oop用来表示java中的对象.klass和oop称为`OOP-Klass Model`即面向对象模型.其原因是Hotspot设计者不想让java中的每个对象都有`vtable`(虚函数表)

关于C++和java多态实现方法

>   在C++中通过虚函数表的方式实现多态,每个包含虚函数的类都具有一个**虚函数表(virtual table）**,在这个类对象的地址空间的最靠前的位置存有指向虚函数表的指针.在虚函数表中,按照声明顺序依次排列所有的虚函数.由于C++在运行时并不维护类型信息,所以在**编译时直接在子类的虚函数表中将被子类重写的方法替换掉**.
>
>   在Java中,在运行时会维持类型信息以及类的继承体系.每一个类会在**方法区中对应一个数据结构用于存放类的信息**,可以通过Class对象访问这个数据结构.其中,类型信息具有superclass属性指示了其超类,以及这个类对应的方法表(其中只包含这个类定义的方法,不包括从超类继承来的）.而每一个在堆上创建的对象,都具有一个指向方法区类型信息数据结构的指针,通过这个指针可以确定对象的类型.

c++的类在java中的职责如下

![](https://www.hollischuang.com/wp-content/uploads/2017/12/2579123-5b117a7c06e83d84.png)

所以从这里我们可以看到**java的对象其实例数据保存在堆上,其本质是oop对象,其引用保存在栈上,其元信息保存在方法区,本质上是klassOop对象.**

#### Klass 数据结构

oop(Object-Oriented Programming)和oop(ordinary object pointer)普通对象指针不是同一个东西,klass-oop体系中的oop指的是后者.oop作为普通对象的指针,直接受到GC管辖.除了markOopDesc外,所有的实例都有GC管理.markOopDesc是直接对象(例如int直接存储在指针里,不再去堆中进行查找)

- oop用于表示对象的实例信息,其指向堆内存中的首地址
- klass则是包含元数据和方法信息

![](https://img-blog.csdnimg.cn/20190630101729566.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3Npbm9sb3Zlcg==,size_16,color_FFFFFF,t_70)

上面的图描述了两模型三维度的映射.两模型指的是oop和klass,而klass从元数据和函数分发表(虚函数表/分发规则)两个维度去描述一个Java类.元信息是实现反射的关键数据结构,能在运行时动态的反射出类的信息.

oop的模型描述中,不同的结构(类,方法,成员变量,常量,数组)用不同的oop去描述,oop的顶层类是oopDesc其包含了两个成员变量`_mark`用来保存markword的地址,`_metadata`用于保存元数据的指针.元数据用于描述一个类的TYPE(比如class,enum,interface,@interface),修饰符,类名,字节码,成员变量,静态区域等.

从这个角度我们介绍下Hotspot的加载顺序`ClassA a = new ClassA()`

- 把ClassA加载到perm区（方法区），创建instanceKlass用于描述这个类,和instanceOop用于指向instanceKlass
- 在堆中给实例对象开辟内存空间,存放实例数据

![](https://img-blog.csdnimg.cn/20190630101040739.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3Npbm9sb3Zlcg==,size_16,color_FFFFFF,t_70)

除此之外,JVM内部还有一种类叫handle

![](https://img-blog.csdnimg.cn/20190630101849710.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3Npbm9sb3Zlcg==,size_16,color_FFFFFF,t_70)

handle主要是用于作为oop和klass的一个封装,其最终就能操纵二者的行为.如果在其内部调用C++对应的oop函数可以不需要handle来中转,直接通过拿到oop拿到指定的klass.这个handle模型其实是Java类行为的表达.

---

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



#### 数组对象

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
     19     5    (loss due to the next object alignment)
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

如此一来便能建立完整的对象存储体系

#### 多维数组

多维数组是以多个一维数组多个一维数组的形式存起来的,所以其表现形式和C++的数组完全不一样.其内部存放的是各个数组的指针地址,而c++是纯粹的内存区域,从这点来看java的数组比之c++更耗费堆内存.



#### 字符串对象

---

字符串对象基本是作为java中最特殊的一类对象存在了,其中一些常量字符串对象(字面量,永久代中)和字符串对象(堆中分配的内存)的行为体现不同

```java
String str1 = "123";
String str2 = "12" + "3"; // 在编译阶段处理为"123"载入常量池中
System.out.println(str1 == str2);
String str3 = "12" + new String("3"); // 常量池中12的常量字符串对象和堆中字符串进行处理
String str4 = new String("12") + new String("3");
String str5 = "12" + new String("3");
System.out.println(str1 == str3);
System.out.println(str4 == str3);
System.out.println(str3 == str5);
// 只要涉及到字符串对象的操作就是以分配新内存的形式
// 字符串常量的加减会在编译阶段执行
```

##### 字面量和字符串对象

`"123"`形如这样的字符串为字面量`new String("123")`返回的对象则是字符串对象

字符串常量由常量池去存储,new String("123")是申请了堆内存,并在堆内存中构建字符串对象,把常量池的引用当做参数传入获取其值,而其引用不同.

-   JDK1.6两者一在堆内存一在永久代的常量池,两者自然不可能一致
-   JDK1.7以后常量池是在堆内存,故两者的字面量有可能一致的(下方验证)

##### intern方法

如果常量池中没有该字符串对象,那么就把字符串对象加入常量池,且返回常量池的引用,[引用美团技术团队的教程](https://tech.meituan.com/2014/03/06/in-depth-understanding-string-intern.html)

```java
String s3 = new String("1") + new String("1");
s3.intern();
String s4 = "11";
System.out.println(s3 == s4);
```

在jdk1.6和jdk1.7中其答案并不一样

-   jdk1.6中由于常量池的关系 其常量池一在永久代的方法区中,一在堆内存中,地址自然不同
-   jdk1,7中s3和s4均在堆内存中,其地址相同



#### Integer对象

```java
Integer i01 = 59;
int i02 = 59;
Integer i03 = Integer.valueOf(59);
Integer i04 = new Integer(59);
```

首先我们先要理解装箱和拆箱,上面的代码等价于

```java
Integer i01 = new Integer(59);
int i02 = 59;
Integer i03 = Integer.valueOf(59);
Integer i04 = new Integer(59);
```

##### 数值比较

如果`i02`和其他对象发生比较的话返回的一定是true,因为在和数值类型比较的过程中,先进行拆箱返回数值,然后利用数值进行比较.

##### 对象比较

其他的所有比较都是对象之间的比较,关于Integer对象的比较比较的是地址,`new Integer()`使用的是内部数据结构引用采用常量池引用而对象引用在堆内存.所以`new Integer()==new Integer()`返回类型一定是false

##### Integer.valueOf

```java
public static Integer valueOf(int i) {
  if (i >= IntegerCache.low && i <= IntegerCache.high)
    return IntegerCache.cache[i + (-IntegerCache.low)];
  return new Integer(i);
}
```

`-128~127`的从缓存中取,也就是说调用该函数的所有合适的值都会被缓存.



### 类加载与初始化过程

---

总的来说类的编译执行包括以下阶段

-   编译
-   加载 (ClassLoader)
-   验证
-   准备 (static分配)
-   解析 (常量池分配)
-   初始化
    -   类初始化\<clinit\>
    -   实例初始化\<init\>

#### 编译过程 javac

-   加载前

    Complier完成对.java文件的编译变成.class文件

    这个编译过程会对一些运算进行替换比如1==1替换成true

    这一阶段就会加入常量池

    其实没仔细说明 这一阶段所有final变量也会加入常量池留下引用

    常量池有字面量 符号引用和 运行时常量池

    通过javah命令编译之后,用javap -v 命令查看编译后的文件

#### 加载过程 java

加载过程如下,我们主要研究的就是Loading,Linking,Initalization.

![](https://img-blog.csdnimg.cn/20200524221637660.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_0,text_aHR0cDovL3d3dy5mbHlkZWFuLmNvbQ==,size_35,color_8F8F8F,t_70)

和下文的`<clinit>`方法不同,该过程在`<clinit>`之前执行,总的来说加载过程就是把类的字节码加载到JVM生成常量池引用和在方法区堆内存分配相应的数据结构的过程,并不包括初始化



##### 加载 Loading (此过程由ClassLoader完成)

从class中加载字节流 在方法区生成入口type=Class的对象

把字节码解析成方法区中的klass数据结构(元信息)

另外值得一提的是,此过程的所有符号引用都来自**常量池**

ClassLoader有用java实现的,也有用c++(jvm)实现的



##### 链接 Linking

链接是为了让类或者接口可以被java虚拟机执行,而将类或者接口并入虚拟机运行时状态的过程.

这个阶段分为三个小阶段 验证 准备 解析

-   验证 Verification 验证字节码的准确性,final是否被覆盖,函数签名
-   准备 Preparing 在**方法区**为**static变量**注入默认值,***对final static变量直接注入值***
-   解析 Resolution 确定运行时**常量池**的引用

##### 装载 Initialization

这个阶段会去真正的执行代码,依据代码的不同进行不同的执行,这个时候static成员变量的值才会被去注入,这个阶段执行的代码在下面也称为`<clinit>`和`<init>`表示类的初始化和对象的初始化,执行初始化的时机有以下几种

-   执行需要引用类或者接口的java虚拟机指令(new,getstatic,putstatic,invokestatic)的时候
-   初次调用java.lang.invoke.Methodhandle实例的时候
-   调用类库中的某些反射方法的时候
-   对类的某个子类进行初始化的时候
-   被选定为java虚拟机启动时候的初始类的时候

所以我们看到基本去访问static域的成员变量或者代码的时候都会触发装载.




#### 双亲委派模型

如下图,从用户加载器开始,会向上委托其父类加载器加载,不会自己加载,如果加载不了在一步步向下让加载器加载,所谓的双亲委派指的是委派父类完成加载,而不是自己加载

这样设计的原因是防止类重新加载,如果发现该类加载器已经加载了该类那么久不会重复加载而引用jvm里面的Class对象

![图片](https://upload-images.jianshu.io/upload_images/1833901-97c7f6c8d8e0965f.png)

整个编译过程为static final注入,static 默认值注入,常量替换和引用生成等.

![](https://img-blog.csdn.net/20150702112329327?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvb3BlbnN1cmU=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

上图为不同的classloader用来加载不同路径的类,



#### ClassLoader

ClassLoader只负责加载Loding,除了顶级的Bootstrap用C++实现以外其他都用java实现,除了隐式或者显示的new以外 形如Class.forName和ClassInstace.staticMethod都不进行对象初始化只加载到jvm

加载机制主要是三种

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

ClassLoader的主要方法

-   **defineClass** 

    byte流解析成jvm能够识别的对象,即把.class转化为Class

-    **findClass** 

     通过类名去加载对象,通常我们定义自己的类加载器用该方法实现

-    **loadClass** 

     加载类到JVM,双亲委派机制在这

-    **resolveClass**

     调用这个使得被加到JVM的类被链接

```java
protected Class<?> loadClass(String name, boolean resolve)
  throws ClassNotFoundException{
  
  synchronized (getClassLoadingLock(name)) {
    // First, check if the class has already been loaded
    Class<?> c = findLoadedClass(name);
    if (c == null) {
      long t0 = System.nanoTime();
      try {
        if (parent != null) {
          c = parent.loadClass(name, false); // 利用父类加载
        } else {
          c = findBootstrapClassOrNull(name); // 没有父类直接扔到顶
        }
      } catch (ClassNotFoundException e) {
        // ClassNotFoundException thrown if class not found
        // from the non-null parent class loader
      }

      if (c == null) {
        // If still not found, then invoke findClass in order
        // to find the class.
        long t1 = System.nanoTime();
        c = findClass(name); // 父类加载失败就调用自己的findClasss

        // this is the defining class loader; record the stats
        sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
        sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
        sun.misc.PerfCounter.getFindClasses().increment();
      }
    }
    if (resolve) {
      resolveClass(c); // 解析
    }
    return c;
  }
}
```

父子加载器之间的关系不是继承,类加载器会使用组合(**Composition**)而不是使用继承来复用父类加载器的代码.

```java
public abstract class ClassLoader {
    // The parent class loader for delegation
    private final ClassLoader parent;
}
```

破坏双亲委派机制,就直接重写loadClass,不委派就是了.破坏双亲委派模型一般是要来实现一些特殊的功能,比如JDBC,JNDI加载SPI接口.或者是实现热拔插.Tomcat等web容器也破坏了双亲委派模型(多个web项目的全限定类名可能是一样的,又不能让顶层加载器去加载,就只能自己实现了).



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



#### 复杂初始化

上面我们知道了父子类之间的初始化关系,那么我们看如下代码

```java
public class Test {
    public static void main(String[] args) {
        System.out.print(B.c);
    }
}
class A {
    static {
        System.out.print("A");
    }
}
class B extends A{
    static {
        System.out.print("B");
    }
    public final static String c = "C"; // 不会初始化类,因为可以从常量池取
  	public static String c = "C"; // 如果上面的语句换成了下面,就会初始化AB
  	public final static String c = new String("C"); // 常量阶段获取不到这,所以还是会发生类的初始化
}
```

上面的输出只有C,因为访问常量池是不需要初始化的,而常量池的常量都是从解析阶段就确定了,所以不需要`<clinit>`方法.

```java
public class Test {
    public static void main(String[] args) {
        System.out.print(B.c);
    }
}
class A {
    static {
        System.out.print("A");
    }
}
class B extends A{
    static {
        System.out.print("B");
    }
}
```



---

### **学会了?来试试下面习题吧**

#### 虚拟机加载过程理解应用

```java
public class Test {
    public static void main(String[] args) throws Exception{
      ClassLoader classLoader=ClassLoader.getSystemClassLoader();
      Class clazz=classLoader.loadClass("A");
      System.out.print("Test");
      clazz.forName("A");
    }
}
class A{
    static {
        System.out.print("A");
    }
}
```

会输出`TestA`,因为loadClass只是类加载阶段,没有触发`<clinit>`方法

#### 访问域问题

```java
public static void main(String[] args) {
	   System.out.println(A.c);
}
class B {
    static {
        System.out.print("B");
    }
    public final static String c = new String("C");
}
class A extends B {
    static {
        System.out.print("A");
    }
}
```

这个输出是`BC`因为不需要初始化A类.



#### 单一类加载的线程安全问题

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

#### 垃圾分类和垃圾处理示意

![](https://img2018.cnblogs.com/blog/926003/201909/926003-20190902230035745-1201448392.png)

![](https://img2018.cnblogs.com/blog/926003/201909/926003-20190902230111437-1106854979.png)

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

没有明确变量引用时,**除非是发生了内存溢出**否则该类对象也是不会被回收的

##### 软引用:obj=null;

拥有弱引用的对象都活不过下一次GC之前,也就是说**无论内存溢出与否下一次都会被回收**.

除了上面这种常规的使用方式之外,还可以用SoftReference,WeakReference,PhantomReference三种方式去获取本身的引用.

一般我们会配合ReferenceQueue去使用,其作用就是回收的时候这个对象加入软引用的队列,如果还没发生GC可以重新获得,如果发生了GC获得null

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

finalize时会用到的一种引用,使用较少,在任何时候都可能被垃圾回收器回收,其存在只是gc后对象能够收到通知执行finalize方法的一个引用

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

##### GC ROOT

可作为GC Root的对象包括4种

- 虚拟机栈(本地变量表)中被引用的对象
- 方法区中静态属性的对象
- 方法区中常量引用的对象
- 本地方法栈中JNI引用的对象



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



#### mark-compact和copying区别

两者的区别主要是copying需要额外空间,其对于新生代这些存活时间非常短,且存活数量少的对象具有极高速度,基本是所有对象都移动到**另外的空间(To 区)**.

而mark-compact则是用在存活率较高的空间,他们不需要额外的空间,就在原来的空间内(老年代)进行内存回收



#### 关于Full GC

Minor GC是回收年轻代的,Major GC是回收老年代的,**Full GC**是针对年轻代也是针对老年代的,所以我们可以知道Major GC和Full GC实际上是两个完全不同的东西

-   Major GC: 清理老年代
-   Full GC: 清理整个堆内存,包括年轻代和老年代

但是更多情况下,许多**Minor GC会触发Major GC**,所以实际情况两者分离是不可能的.这就使得我们关注重点变成,GC是否能并发处理这些GC.

**Full GC**的触发条件比较多

-   System.gc()

-   永久代空间不足

-   老年代空间不足

-   GC时出现Promotion Faield(年轻代空间不足够放下那么大的对象)

-   统计得到的Minor GC晋升到老年代的平均大小大于老年代的剩余空间(JVM觉得老年代空间要不够用了)

![](https://img2018.cnblogs.com/blog/926003/201909/926003-20190902230125562-2085470088.png)  

#### 空间分配担保

在进行`Minor GC`时jvm会检查老年代的可用空间是否大于新生代的所有空间,如果是的话可以保证`Minor GC`是安全的,如果不安全的话参照`HandlePromotionFailire`进行进一步处理,

如果允许继续检查老年代最大可用可用的连续空间是否大于之前晋升的平均大小,如果是就尝试进行一次`Minor GC`(如果新生代出现了大对象可能会失败,失败就触发`Full GC`)否则就进行`Full GC`,这个所谓的大对象在虚拟机中的参数可以调

这是一种动态的概率保护手段



#### 新生代晋升老年代的情况

-   分代年龄>15

-   对象太大

-   Minor GC 后 一般的Survior区和Eden区没法放下的对象 (空间分配担保机制)

-   survior区相同年龄对象总大小大于survior区空间的一半

    (众数群体大于一半,大于该群体年龄的所有对象晋升)



#### 垃圾回收器

垃圾回收器可以看做是上面一些GC的具体实现,根据对不同的区域,GC回收器一般可以用下图表示

![](https://img2018.cnblogs.com/blog/1120165/201908/1120165-20190806231839133-894902320.png)

如果垃圾回收器存在连线,说明其可以搭配使用.我们这里说一些主要的应用场景

-   ParNew是被用于运行在Server环境下首选的新生代GC,其可以配合CMS一起工作
-   CMS因为是并行进行回收,不会暂停,所以经常被用在服务端用于提供服务
-   G1完全并行,专门面向服务端应用



##### 一些只需要了解的垃圾回收器

-   Serial 串行垃圾回收,年代久远
-   ParNew 多线程新生代回收器 (*-XX:ParallelGCThreads*控制)
-   Parallel Scavenge 多线程采用`copying`算法的新生代垃圾回收器注重吞吐量的垃圾回收器
-   Serial Old 串行回收老年代采用`mark-sweep`算法
-   Parallel Old 并行回收老年代采用`mark-sweep`算法



##### ParallelGC(Server默认回收器)

```shell
-XX:+UseParallelGC # jdk的默认参数
```

这个其实是上面垃圾回收的组合,新生代使用`Parallel Scaveng`老年代使用`Parallel Old(mark-sweep)`进行垃圾回收,另需说明此处的`Parallel Old`是采用了`Serial Old`去进行设计的所以在很多资料中也能看到`Serial Old`的说法.**回收所有区域的垃圾**

一般来讲配合CMS使用

```shell
-XX:+UseConcMarkSweepGC -XX:+UseParNewGC
```

![](https://img-blog.csdnimg.cn/20190222222515855.jpeg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2l2YV9icm90aGVy,size_16,color_FFFFFF,t_70)



#####  CMS(Concurrent Mark Sweep)

```shell
-XX:+UseConcMarkSweepGC # 启用该垃圾回收器
-XX:+UseCMSCompactAtFullCollection # 因为采用了mark-sweep所以在内存碎片满的时候直接进行合并清空
```

其主要采用并发的`mark-sweep`算法来进行垃圾回收,其垃圾回收过程可以和用户的java线程一起并发执行,而其他回收器是得停掉用户的线程才能进行垃圾回收的.**回收老年代的垃圾**

其特别吃cpu的核心数,且会极大的影响系统性能,其无法处理浮动垃圾(因为要和用户线程一起并发,所以临时产生的垃圾就无法去清楚了),可能会触发Full GC,且其会产生大量的内存碎片

我们来详细说明其过程,CMS是为了解决Stop-the-world停顿时间过长而设计的一款垃圾回收器.其工作过程如图

![](https://img2018.cnblogs.com/blog/1326194/201810/1326194-20181017221500926-2071899824.png)

-   初始标记阶段,标记GC ROOT会存在stop-the-world现象
-   并发标记阶段,对GC ROOT进行跟踪,标记所有可达对象,此过程中就是CMS主要的思想体现了,没有stop-the-world,但因为并发执行的其他线程可能对GC ROOT产生一些影响.这些需要在后面的阶段进行处理.

    并发预清理阶段,重新标记修正被线程修改的部分对象的可达性,这个时候也是会发生stop-the-world,我们主要看老年代是如何处理的,这里老年代使用了一个`CARD_TABLE`,其把老年代划分成512byte的块,如果发生了改变就变成了`dirty_card`,这个阶段CMS就会重新扫描这些块把其中某些对象标记为可达.
-   重新标记阶段,重新扫描,扫描目标的新生代对象+GC ROOT+dirty_card,这里会存在stop-the-world阶段
-   并发清除,对标记的对象进行垃圾回收

上面我们看到标记阶段的stop-the-world会存在`初始标记,并发清理,重新标记`而

-   并发标记
-   并发清除

这两个阶段是会并发执行的,可以看到在这两个阶段都会产生一些问题都需要解决,并发清除中产生的一些新垃圾无法清除(称为浮动垃圾)

CMS的一些缺点

-   无法百分百清除所有垃圾
-   对于CPU资源比较敏感
-   无法处理浮动垃圾,可能出现Concurrent Model Failure失败而导致另一次Full GC的产生
-   CMS不对永久代进行垃圾回收

CMS的两个触发条件

-   阈值检查机制:由于并发清除过程会产生浮动垃圾.所以老年代的使用率没有办法达到100%.只能到达某一个阈值以后(jdk1.8默认值92%,1.6之后是92%,1.5默认是68%）,或者通过CMSInitiatingOccupancyFraction和UseCMSInitiatingOccupancyOnly 两个参数来调节;过小会造成GC频繁；过大,导致并发模式失败.
-   动态检查机制:JVM会根据最近的回收历史,估算下一次老年代被耗尽的时间,快到这个时间了就启动一个并发周期. 可以用UseCMSInitiatingOccupancyOnly来将这个特性关闭.



##### G1(garbage first)

```shell
-XX:+UseG1GC # 启用该垃圾回收器
```

JDK1.7以后前沿的垃圾回收器,服务器上常使用此垃圾回收器,其弱化了**分代**的概念,强化了**分区**的概念,且优先考虑从垃圾多的区域(存活数量少)开始回收,其用到的算法为`mark-sweep`和`copying`的算法,**回收所有区域的垃圾**,g1会给内存分出大小相同的区域(region),这些区域可能是新生代可能是老年代,也可能是他们联系在一起的区域.称新生代为Y,老年代为O.G1会第一时间处理垃圾最多的块,且g1是可以预测停顿的.

g1通过并发标记阶段查找老年代存活对象,通过并行`copying`存活对象

g1将一组或多组区域中存活对象以增量并行的方式复制到不同区域进行压缩,从而减少堆碎片,目标是尽可能多回收堆空间 **垃圾优先**,且尽可能不超出暂停目标以达到低延迟的目的.

和CMS相比,G1的优势

-   空间压缩更好
-   避免内碎片
-   因为把所有区域都是用了,内存使用更灵活,CMS是根据垃圾分代来的
-   G1可以设置预期stop-world的时间(Pause Time),控制垃圾回收时间
-   回收同时内存合并,CMS会在标记之后整理内存

我们来看其具体做法

![](https://awps-assets.meituan.net/mit-x/blog-images-bundle-2016/8ca16868.png)

G1默认把堆内存分为1024个区域,每个regin大小都是固定的,可以通过`-XX:G1HeapRegionSize`调整大小,上图的H表示的是一些大对象.大对象再分配内存前,检查是否超过initiating heap occupancy percent(启动堆占用比例)和the marking threshold(标记阈值),如果超,会启动global concurrent marking,为的是提早回收,防止evacuation failures 和full GC

如果一个系统中存在大量的大对象,建议增大regin的值来减少垃圾回收的影响.因为其是并发标记的所以对于一个对象其有三种状态(三色标记算法)

-   白色,对象没有标记到,标记阶段结束后,会当做垃圾回收.
-   灰色,对象被标记了,但是它的field还没有标记或还没有标记完.
-   黑色,对象被标记了,且它的所有field也被标记完了.

在并发标记的情况下,有两个线程来进行垃圾回收Mutator(变换器/增变因子)和Garbage Collector.两个线程的职责也相对明确,Mutator是用来对并发中增加对象进行处理,而Garbage Collector则是进行垃圾回收

-   在并发标记阶段,如果该白对象是new出来的,并没有灰对象持有.Region中有两个top-at-mark-start(TAMS)指针,分别是prevTAMS和nextTAMS.在TAMS以上的对象是新分配的,这是一种隐式标记,通过这种的方式找到了再GC过程中新分配的对象,并认为是活对象
-   Mutator删除了所有从灰对象到该白对象的直接或者间接引用
    如果灰对象到白对象的直接引用或间接引用被替换或者删除了,那白对象就会被**漏标**.G1给出了利用write barrier将就引用记录下来,以防止被清除)对象引用被替换是就会发生write barrier).
-   因为上面的算法,白对象有可能是要被回收的,那就会产生浮动垃圾(Float Garbage)

停顿预测模型(Pause Prediction Model)

G1使用暂停预测模型来满足用户定义的暂停时间目标,并根据指定的暂停时间目标选择要收集的区域数量.
G1 是一个相应时间优先的GC算法,它与CMS最大的不同是:用户可以设定整个GC过程的期望停顿时间.参数`-XX:XX:MaxGCPauseMillis`指定一个G1收集过程目标期望停顿时间,默认值200ms.G1根据整个模型统计计算出的历史数据来预测本次收集需要Region数量,从而满足用户设定 的目标停顿时间.停顿预测模型是以衰减标准偏差为理论基础实现的.

**工作流程**

![](https://img2018.cnblogs.com/blog/1326194/201810/1326194-20181017225802481-709835773.png)

-   初始标记:标记GC ROOT,然后修改TAMS,这个阶段需要线程停顿,消耗时间很短.
-   并发标记:从GC ROOT中找存活对象(与用户线程并发执行)
-   重新标记:修正部分标记,其记录用的数据结构叫RSet
-   筛选回收:根据Region的回收成本进行排序,根据用户期望的GC时间来进行回收
-   Evacuation对象拷贝:该阶段全暂停,用来根据上面的筛选结果进行回收,把Region中存活的对象拷贝到另外的Region上

对于G1的调优

-   `-XX:MaxGCPauseMillis`设置GC时间,默认是200ms,如果设置太短,垃圾消费速度跟不上生产速度就会退成Full GC.
-   `Evacuation Failure`和CMS中的晋升失败类似,如果垃圾太多就有可能发生一个,会触发Full GC.





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
java -verbose:jni 即可查看本地方法
java -verbose:gc 即可查看gc
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

- S0C:第一个幸存区的大小
- S1C:第二个幸存区的大小
- S0U:第一个幸存区的使用大小
- S1U:第二个幸存区的使用大小
- EC:伊甸园区的大小
- EU:伊甸园区的使用大小
- OC:老年代大小
- OU:老年代使用大小
- MC:方法区大小
- MU:方法区使用大小
- CCSC:压缩类空间大小
- CCSU:压缩类空间使用大小
- YGC:年轻代垃圾回收次数
- YGCT:年轻代垃圾回收消耗时间
- FGC:Full GC垃圾回收次数
- FGCT:Full GC垃圾回收消耗时间
- GCT:垃圾回收消耗总时间

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

-   无论在32位虚拟机上还是在64位虚拟机上,对象引用的大小都是4Byte和int一样大小.

-   所以对于线程切换来讲64位虚拟机是不会被中断掉的,也就是说赋值(引用和基本类型)在32位虚拟机上double和long等超过32位的是有可能被中断掉的

    

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
		System.out.println("JIT编译器名称:"+compilation.getName());
		//判断jvm是否支持编译时间的监控
		if(compilation.isCompilationTimeMonitoringSupported()){
			System.out.println("总编译时间:"+compilation.getTotalCompilationTime()+"秒");
		}
	}
	
	private static void printClassLoadingInfo(){
		ClassLoadingMXBean classLoad= ManagementFactory.getClassLoadingMXBean();
		System.out.println("已加载类总数:"+classLoad.getTotalLoadedClassCount());
		System.out.println("已加载当前类:"+classLoad.getLoadedClassCount());
		System.out.println("已卸载类总数:"+classLoad.getUnloadedClassCount());
		
	}
	
	private static void printRuntimeInfo(){
		RuntimeMXBean runtime = ManagementFactory.getRuntimeMXBean();
		System.out.println("进程PID="+runtime.getName().split("@")[0]);
		System.out.println("jvm规范名称:"+runtime.getSpecName());
		System.out.println("jvm规范运营商:"+runtime.getSpecVendor());
		System.out.println("jvm规范版本:"+runtime.getSpecVersion());
		//返回虚拟机在毫秒内的开始时间.该方法返回了虚拟机启动时的近似时间
		System.out.println("jvm启动时间(毫秒）:"+runtime.getStartTime());
		//相当于System.getProperties
		System.out.println("获取System.properties:"+runtime.getSystemProperties());
		System.out.println("jvm正常运行时间(毫秒）:"+runtime.getUptime());
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
				System.out.println("vm内存管理器:名称="+manager.getName()+",管理的内存区="
			+Arrays.deepToString(manager.getMemoryPoolNames())+",ObjectName="+manager.getObjectName());
			}
		}
	}
	
	private static void printGarbageCollectorInfo(){
		List<GarbageCollectorMXBean> garbages = ManagementFactory.getGarbageCollectorMXBeans();
		for(GarbageCollectorMXBean garbage : garbages){
			System.out.println("垃圾收集器:名称="+garbage.getName()+",收集="+garbage.getCollectionCount()+",总花费时间="
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
				//只打印一些各个内存区都有的属性,一些区的特殊属性,可看文档或百度
				//最大值,初始值,如果没有定义的话,返回-1,所以真正使用时,要注意
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
		System.out.println("线程总数(被创建并执行过的线程总数）="+thread.getTotalStartedThreadCount());
		System.out.println("当初仍活动的守护线程(daemonThread）总数="+thread.getDaemonThreadCount());
		
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



### 定位Full GC(JVM调优)

定位Full GC问题要利用到jvm的控制指令以及了解JVM的知识.所有调优的基础都日志信息,没有相应的日志就无法确定故障点.

-   登录到出问题的机器
-   **jps -l** 查看进程
-   **jstat -gcutil -h 20 pid 1000 20000** 查看GC统计信息 [jstat使用方法](https://blog.csdn.net/zhaozheng7758/article/details/8623549)
-   **jmap -histo:live pid | head -10** 统计存活对象
-   根据情况分析代码

可以看到核心的命令就是jstat,jmap两个.





### JIT与其他优化

我们看到Java虚拟机执行的原理如下

![](https://img-blog.csdn.net/20160812104144969?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

我们看到字节码有两种执行方式,解释器和JIT在由这些生成器或者解释器直接给硬件发出指令.

java的编译在早期的时候是由`javac`完成的,内存分配的工作也基本上由传统的JVM完成.JIT指的是java即是编译技术,对传统的技术做了分析和改进.下文主要是对JIT相关技术的分析,JIT的目的是为了降低内存负载,减少堆内存的分配压力,JIT的技术主要由逃逸分析,锁消除,锁膨胀,方法内联,空值检查消除,类型检测消除,公共子表达式消除.所以实际上JIT的技术就是**C++**的技术.

![](https://images2018.cnblogs.com/blog/1165868/201808/1165868-20180828180924226-980200012.png)

由上面我们可以看出编译器和解释器影响语言的动态静态和强弱,热点代码通过JIT等编译器由解释变为编译,Java使用的是热点技术的方法

-   为什么HotSpot虚拟机要使用解释器与编译器并存的架构？

尽管并不是所有的Java虚拟机都采用解释器与编译器并存的架构,但许多主流的商用虚拟机(如HotSpot）,都同时包含解释器和编译器.解释器与编译器两者各有优势:当程序需要*迅速启动和执行*的时候,解释器可以首先发挥作用,省去编译的时间,立即执行.在程序运行后,随着时间的推移,编译器逐渐发挥作用,把越来越多的代码编译成本地代码之后,可以获取*更高的执行效率*.当程序运行环境中*内存资源限制较大*(如部分嵌入式系统中）,可以使用*解释器执行节约内存*,反之可以使用*编译执行来提升效率*.此外,如果编译后出现“罕见陷阱”,可以通过逆优化退回到解释执行.

![](https://img-blog.csdn.net/20160812102841736?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQv/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

从上面我们也注意到了编译器由两种客户端和服务器的,客户端注重编译速度,服务端注重编译质量根据不同的使用场景而有不同.对于编译和解释其实也是有不同使用场景的

-   解释适合只执行一次的代码(类的初始化,无循环代码)
-   编译后的代码也是需要存储空间,且编译大多代码后会导致代码膨胀

```note
对一般的Java方法而言,编译后代码的大小相对于字节码的大小,膨胀比达到10x是很正常的.同上面说的时间开销一样,这里的空间开销也是,只有对执行频繁的代码才值得编译,如果把所有代码都编译则会显著增加代码所占空间,导致“代码爆炸”
```

JVM判断热点代码的方式目前来说分为两种

-   基于采样的热点探测(周期性检查栈顶方法统计)
-   基于计数器的热点探测(代码块建立计数器统计) (Hotspot采用这种)



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

#### 栈上分配内存

栈上分配内存的思路就是即每个线程如果没有逃逸出方法本身的话,都向堆请求内存的话就太浪费.但其有前提就是需要逃逸分析作为此技术的实现基础,在栈中如果没有逃逸出方法体的话,就有可能在栈上分配内存,而不是用堆空间进行内存分配.



#### TLAB栈上内存分配

TLAB(Thread Local Allocation Buffer)即栈上分配内存,默认是开启状态,可以用`-XX:+UseTLAB`即每个线程都向堆请求内存的话就需要大量的调度开销,所以就向JVM申请一段连续的内存(在堆空间上)称为TLAB去给这些对象分配内存.

同时TLAB还解决了指针碰撞问题,即两个线程并发new的时候指针的修改顺序的安全性.这里简单说下指针分配的问题

![](https://upload-images.jianshu.io/upload_images/14131260-4f531fdccb83fa85.png)

堆内存的对象是连续分配的,也就是对象多大,指针就要移动到哪个位置,有点像段式分配.而new对象的时候,就可能指针发生了两次移动,如果不加并发控制就会出现线程安全问题,这就是指针碰撞.解决这种指针碰撞的方法不止一个,而TLAB就是解决的方案之一.

所以虚拟机在线程栈初始化的时候会分配一块内存(这块内存位于**Eden区**),这块内存的大小很小仅有Eden区的1%,专门用于分配局部变量的内存.

![](https://img-blog.csdnimg.cn/20190809191201695.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2p1XzM2MjIwNDgwMQ==,size_16,color_FFFFFF,t_70)

TLAB的缺点

-   TLAB也在堆内存中申请空间,大小固定,大对象容纳不下TLAB失效,内碎片
-   TLAB申请的内存区域也是需要GC的,如果线程特别多就会频繁GC



### 字节码

-   未完待续



### 堆外内存的使用

堆外内存的使用方法一共有以下几种

- C/C++ 操作操作系统给 JVM 分配的内存块
- Unsafe 换汤不换药
- NIO Byte Buffer 本质上是调用了 Unsafe 去分配内存

```java
//直接操作堆外内存
unsafe.allocateMemory(100);
unsafe.reallocateMemory(100, 200);
unsafe.freeMemory(100);

// NIO
ByteBuffer buffer = ByteBuffer.allocateDirect(10 * 1024 * 1024);
```

#### 堆外内存的回收

使用堆外内存就意味着需要回收这一块内存,回收由JVM完成,对于`DirectByteBuffer`对象,其只有在创建时伴生的`Cleaner`对象才知道堆外内存的地址.`Unsafe.invokeCleaner(buffer),即可清理对应的内存块.

#### OHC

[参考](https://github.com/snazy/ohc)

OFF-HEAP-CACHE,堆外缓存,缓存数据量比较大时可以使用此种方法

> When using a very huge number of objects in a very large heap, Virtual machines will suffer from increased GC pressure since it basically has to inspect each and every object whether it can be collected and has to access all memory pages. A cache shall keep a hot set of objects accessible for fast access (e.g. omit disk or network roundtrips). The only solution is to use native memory - and there you will end up with the choice either to use some native code (C/C++) via JNI or use direct memory access.

堆外内存的优点

- 减少了垃圾回收,堆外内存不受GC影响,由程序员自身分配内存 OHC-jemelloc
- 加快了内存复制的速度

使用堆外内存做缓存

```xml
<dependency>
    <groupId>org.caffinitas.ohc</groupId>
    <artifactId>ohc-core</artifactId>
    <version>0.7.0</version>
</dependency>
```

```java
OHCache<String, String> ohCache = OHCacheBuilder.<String, String>newBuilder()
                .keySerializer(new StringSerializer())
                .valueSerializer(new StringSerializer())
                .eviction(Eviction.LRU)
                .build();
```

