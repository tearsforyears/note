### Java基础

---

本章节主要讲一些基础知识在Java语法上的应用,涉及到JVM以及部分虚拟机解释的知识.源自于各种面试题和实际经历,知识点比较散.



---

[TOC]

#### 三元表达式多类型返回

```java
System.out.println(3<4?new Object():9.0);
```

这句话是可以运行且符合语法逻辑的.

#### linkedlist迭代子删除

```java
LinkedList<String> ls;

for (Iterator<String> it = ls.iterator(); it.hasNext();) {
  String str = it.next();
  System.out.println(str);
  if ("bd".equals("str")) {
      it.remove(str);
    }
  }
	System.out.println(ls);
}
```

#### Override和Overload,Overload是否可以改变返回值类型

-   如果参数列表(函数签名)不一样,可以
-   如果函数签名一样,那么就会被视为同个方法,无法重载

#### Static Nested Class 和 Inner Class的不同

![](https://img-blog.csdn.net/20180405170322857?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NkamFkeWNzZG4=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

-   静态嵌套内部类 可以通过类名直接内部类调用
-   嵌套内部类 需要外部类先实例化才能调用内部类

`List`、`Set`、`Map`是否都继承自`Collection`接口？

-   map是独立的接口

#### 什么是内存泄漏,什么是内存溢出

-   泄漏是使用了不可被gc的东西太多
-   栈溢出是用栈空间太多无法入栈,或是出栈太多导致越过下界

内存泄漏的程序

```java
public class Simple {
    Object object;
    public void method1(){
        object = new Object();
        //...其他代码
    }
}
```

如上,这个object因为有了赋值,但因为结束了方法的栈,所以依然保存在类中不被回收.但根据方法的语义其应该被回收的所以我们应该使用下面的代码

```java
public class Simple {
    Object object;
    public void method1(){
        object = new Object();
        //...其他代码
        object = null;
    }
}
```

#### 抽象的（abstract）方法是否可同时是静态的（static）,是否可同时是原生方法（native），是否可同时被synchronized修饰.

答案是不能,因为抽象方法是为了给子类继承的(static不能被继承).既然没有描述细节(不可能是native方法),抽象类也不能被实例化(synchronized),

#### this/super指针用法

this/super指针是C.this/C.super的简写,调用的是本类/父类的方法指针,分别代表对其**类**的引用

this()/super()指针用来调用构造器

this.toString()/super.toString()用来调用其他函数

#### 虚拟机参数

```java
-Xmx 虚拟机堆空间最大
-Xms 虚拟机堆空间最小
-Xmn 年轻代大小
```

#### 虚拟机与域的调用问题

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

    public final static String c = "C";
}
```

这个输出是C,因为final常量在解析的阶段就已经生成结束了,所以不会去触发类的初始化但

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

    public static String c = "C";
}
```

这里会输出ABC,因为调用C需要触发A,B两个类的初始化

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

    public final static String c = new String("C");
}
```

这个输出还是ABC,因为c不是常量了需要引用c需要在堆上分配内存了.元数据区域没有保存相应的值,因此要触发初始化.

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

这里会输出TestA,因为类加载阶段是在初始化之前的.加载完后是验证准备解析.

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



#### finally的执行时机

```java
public class Demo{
  public static void main(String args[]){
    int num = 10;
    System.out.println(test(num));
  }
  public static int test(int b){
    try{
      b += 10;
      return ++b; // a return
    }catch(RuntimeException e){
    }
    catch(Exception e2){
    }
    finally{
      b += 10;
      return b; // b return
    }
  }
}
```

finally多数情况下一定会执行，执行的位置是状态转移try和catch代码块控制权转移之前.

控制权转移为return 和 throw两个关键字，它们把控制权转一给了方法的调用者。

**也就是说如上,return b发生在了return a之前.还需要注意++b不是属于a return语句里面的,指的是返回值里面的语句执行结束,还未返回之前.**

```note
try-finally-return/throw
```

在一些特殊的情况System.exit(0)系统异常关闭等,finally语句是不会执行的.



#### static 和 abstract的冲突

static和abstract的冲突,抽象的含义就是意味着等待被重写.static的含义是不能被重写,即在方法区创建永久代的特性之一.



#### Integer的几种比较

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

#### byte加减法

```java
byte运算时提升为int，+= -=会隐式类型转换
常量和可以注入byte
```

```java
byte a = 127;       
byte b = 126;       
b = a + b; // 错误
b += a // 正常通过
```

```java
// 说明:byte初始化必须为一个 常量值
byte b1=1,b2=2,b3,b6;
final byte b4=4,b5=6;
b6=b4+b5;// byte=常量+常量
b3=(b1+b2);//byte=int ,故非法

byte a1=1,a2=3,a3,a4;
final byte a5=5,a6=6,a7; //a5 ,a6 ,a7均是常量
a3=(a1+a2);//1  byte=int ,故非法
a4=(a5+a1);//2  byte=int+常量=int  ,故非法
a4=a5+a6;//3    byte=常量+常量
a7=a5+a6;//4    常量=常量+常量
```

#### 大数计算

-   BigDecimal
-   BigInteger

需要注意的是初始化的时候选择字符串会比较好.

#### 输入流程序

```java
Scanner s = new Scanner(System.in);
s.nextInt();
s.nextLine();
s.next();
```

#### 类型擦出

```java
List<String> l1 = new ArrayList<String>();
List<Integer> l2 = new ArrayList<Integer>();
System.out.println(l1.getClass() == l2.getClass()); // true
```

**泛型信息只存在于代码编译阶段，在进入 JVM 之前，与泛型相关的信息会被擦除掉，专业术语叫做类型擦除**

### 排序与稳定性

堆排序、快速排序、希尔排序、直接选择排序是不稳定的排序算法,基数排序、冒泡排序、直接插入排序、折半插入排序、归并排序是稳定的排序算法.

![](https://img-blog.csdnimg.cn/2019082617095923.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQzMTUyMDUy,size_16,color_FFFFFF,t_70)

**稳定性的定义**

   假定在待排序的记录序列中，存在多个具有相同的关键字的记录，若经过排序，这些记录的相对次序保持不变，即在原序列中，ri=rj，且ri在rj之前，而在排序后的序列中，ri仍在rj之前，则称这种排序算法是稳定的；否则称为不稳定的。

当次序毫无意义的时候,那么就无需考虑稳定性算法,当保留原次序有意义.

