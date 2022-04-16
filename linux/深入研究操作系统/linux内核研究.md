## linux内核,c/c++

---

虽然说本文档主要研究是linux,但c和c++代码的研究显然对linux内核有着至关重要的特性,下面我们一一讲述,这里主要是以linux内核为主,c/c++为辅助去研究操作系统的一些底层性质,对于c/c++代码有极强的阅读能力即可.

[TOC]

## c/c++

### 内存布局

c语言内存布局,其中主要分为以下几个部分

<img src="https://img-blog.csdn.net/20180928101110275?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ZzZnNmc2Rmc2RmZHI=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70" style="zoom:50%;" />

1. Text/Code Segment 文本/代码区, 存放机器码,这个区域通常只是只读区,可以利用只读特性防止堆栈溢出
2. Initialized Data Segments(GVAR) 初始化的数据区 存放了全局,静态,常量,外部变量(对应四个关键字),然后被拷贝到了初始化数据区
3. Uninitialized Data Segments (BBS) 未初始化的数据区 
4. Stack Segment 栈区,栈区存放了所有局部变量的地址,而他们真正的数据可能指向**初始化区或者堆区** 栈区是紧连着堆区的,堆和栈的增长方向相反,该函数的返回地址和调用者的环境信息被保存在栈中,应该还保存了局部变量值,栈的生长方向是高地址向低地址生长
5. Heap Segment 堆区 通过malloc, realloc和free来管理.堆区被所有线程.公用库.动态加载模块所共享.

GVAR和BSS合称数据段.

堆栈的一些具体实例如下

```c
int a = 0; //全局初始化区 
char *p1; //全局未初始化区 
main() 
{ 
    int b; //栈 
    char s[] = "abc"; //栈 
    char *p2; //栈 
    char *p3 = "123456"; //123456\0在常量区，p3在栈上。 
    static int c =0； //全局（静态）初始化区 
    p1 = (char *)malloc(10); //堆 
    p2 = (char *)malloc(20);  //堆 
}
```

![](https://img-blog.csdn.net/20180319184706943?watermark/2/text/Ly9ibG9nLmNzZG4ubmV0L01SQ0VITg==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

### 内存分配

-   静态内存分配 是在程序编译和链接时就确定好的内存 常量分配等
-   动态内存分配 是在程序加载,调入,执行的时候分配/回收的内存 malloc relloc

### 编译过程



