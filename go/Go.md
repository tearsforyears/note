# Go

---

[TOC]

go语言,又叫 golang 是应对高并发场景下一种面向过程的语言.go 是一门静态强类型,编译型的语言.其语法和 c语言相近,但又有以下特性,内存安全,**GC**,结构形态,并发计算.同时 go 自身内嵌了 dict 数据结构.Go可以直接被编译为机器码,所以意味着其有极高的执行效率.**go天生支持并发,可以充分发挥多核优势**,其可以**内嵌c的代码,直接使用 I/O 多路复用的一些技术**.go的用途

-   服务端代码
    -   虚拟机处理
    -   日志处理
    -   文件系统
    -   分布式系统
    -   内存数据库
    -   网络编程
    -   虚拟化平台(docker / k8s yyds)

---

## hello world

```go
package main //  包名为 main 是函数的入口,每个工程都有这样的入口

import "fmt"

func init(){ // init 函数优先执行
	fmt.Print("init function invoke\n")
}

func main() { // 主函数执行
	fmt.Print("hello world")
}
```

### 特殊语法和约定

-   当标识符（包括常量、变量、类型、函数名、结构字段等等）以一个大写字母开头,那么他就可以被外部对象引用
-   当标识符（包括常量、变量、类型、函数名、结构字段等等）以一个小写字母开头,那么他就对外部不可见

### 编译执行程序

```shell
go run main.go
go build main.go # 生成二进制文件,可以使用 ./main 执行
```

### 分割符

-   python 以间隔为分割,其他大多数语言是以分号为分割, go 语言是以行为分割,加不加`;`

### 标识符

-   字母数字下划线,和常规的语言一致

### 后缀声明类型

```go
var age,count int;
var f float64;
var name = "go language" // 自动判定类型
```

### 数据类型

```go
var b bool = true; // bool
var str = "string test" // Unicode UTF-8 由字符连接起来的序列
// 数字类型 uint8 uint16 uint32 uint64 int8-int64 
// 浮点数和复数 float32 float64 complex64 complex128
// byte rune uint int uintptr
// nil 和 None null 一样
```

### 定义变量

```go
package main

import "fmt"
func main() {
    var a string = "string test"
    var b, c int = 1, 2 // 支持tuple定义
    fmt.Println(b, c)
}

var(
  d int
  e int
)
```

```go
// 下面的函数初始化时候的值为 nil
var a *int
var a []int
var a map[string] int
var a chan int // 通道
var a func(string) int
var a error // error 是接口
```

声明还可以写成下面的形式

```go
intVal := 1 // 基本相当于
var intVal int 
intVal = 1
```

可以下面这种写法

```go
var e, f = 123, "hello"
g, h := 123, "hello"
// 和python有相似的语法,交换两个变量的值
a , b = b , a
```

写法归不同,语义上有一点点不同

-   `:=` 用于声明局部变量,通常在函数内部
-   `var`可以用在函数声明之外

```go
var a int = 30
func main() {
	a := 20
	fmt.Println("hello world",a)
}
```

如上面例子,a使用的是局部变量的值也就是20

### 常量

```go
const a, b, c = 1, false, "str"
```

用 const 可以实现枚举

```go
const (
    Unknown = 0
    Female = 1
    Male = 2
)
```

常量可以使用内置函数进行赋值

```go
import "unsafe"
const (
    a = "abc"
    b = len(a)
    c = unsafe.Sizeof(a)
)
```

### 多个变量赋值与初始化

没有定义类型默认和最上面`地址一致

```go
var (
	ap int8 = 3
	bp int8 // 初始化 0
)

const (
	ad int8 = 3
	bd
	cd // 初始化都是三,根据上面的值而定
)

// iota 可以理解为 const语句块内的行索引,如下
const (
	a = iota // 0
	b = iota // 1
	c = iota // 2
)
const (
	d = iota // 0
	e // 1
	f // 2
)

const (
  a = iota   //0
  b          //1
  c          //2
  d = "ha"   //独立值，iota += 1
  e          //"ha"   iota += 1
  f = 100    //iota +=1
  g          //100  iota +=1
  h = iota   //7,恢复计数
  i          //8
)
```

那么试着理解下下面的值为多少

```go
const (
    i=1<<iota
    j=3<<iota
    k
    l
)
```





## 基本类型

也分**值类型**和**引用类型**,像基本数据类型就是值类型,**需要注意的是string也是基本类型,而Java中不是**,而一般默认go中是值传递

- 基本数据类型的赋值相当于内存中的值发生了拷贝,可以使用`&variable`来获取内存地址,和c一致

  

## 选择

### if-else

```go
if variable > 30 {
  fmt.Printf("%d gt: %d", variable, 30)
} else if variable > 40 {
  fmt.Printf("%d gt: %d", variable, 40)
} else {
  fmt.Printf("other value: %d", variable)
}
```

### switch-case

这个switch可以不拘束于类型,少了繁文缛节的break

```go
switch variable {
	case 20:
		print("bing")
	case 30:
		print("seen")
	case 40:
		print("teen")
	default:
		print("pink")
	}

// 或者是等效的 if else
switch {
  case variable > 30:
  fmt.Printf("%d gt: %d", variable, 30)
  case variable > 40:
  fmt.Printf("%d gt: %d", variable, 40)
  default:
  fmt.Printf("other value: %d", variable)
}
```

### fallthrough

因为没有了break我们如果想要执行下列的语句使用`fallthrough`关键字

```go
switch {
    case false:
            fmt.Println("1、case 条件语句为 false")
            fallthrough
    case true:
            fmt.Println("2、case 条件语句为 true")
            fallthrough
    case false:
            fmt.Println("3、case 条件语句为 false")
            fallthrough
    case true:
            fmt.Println("4、case 条件语句为 true")
    case false:
            fmt.Println("5、case 条件语句为 false")
            fallthrough
    default:
            fmt.Println("6、默认 case")
    }
```

###select关键字 

和上面不同的是 select 关键字会让线程阻塞直至达成某一条件位置,所以一般而言,这样的语句块得是个通信且没有 default 的字句.一般有如下约定

-   每个 case 得是一个通信
-   所有 channel 都会被求值
-   所有的发送表达式都会被求值
-   如果多个 case 可以执行,则随机公平选出一个可执行的
-   一般没有 default 语句

```go
select {
      case i1 = <-c1:
         fmt.Printf("received ", i1, " from c1\n")
      case c2 <- i2:
         fmt.Printf("sent ", i2, " to c2\n")
      case i3, ok := (<-c3):  // same as: i3, ok := <-c3
         if ok {
            fmt.Printf("received ", i3, " from c3\n")
         } else {
            fmt.Printf("c3 is closed\n")
         }
   }
```

上面一些语法在后面会涉及到,这里可以简单理解为 select 必须的条件是**阻塞的**,到看完 channel 回过头来看这个就ok



## 循环

go语言中没有while,for语句有以下几种形式

```go
var variable int8 = 0
for { // for(;;)
  print(variable++)
}

for true { // while true
  print(variable++)
}

var sum int8 = 0
for i := 0; i <= 10; i++ {
  	sum += i
}

// for each 遍历数据结构,range 关键字在后文
for key, value := range oldMap {
    newMap[key] = value
}

for index, value := range arr {
  fmt.println(index,value)
}
```

## 函数

go的函数函数返回值的类型也是后置声明,这点不得不说好烦,如无返回值可以不写,像main一样

```go
func add(a int, b int) int {
	return a + b
}

func add(a, b) int {
	return a + b
}
```

### 支持闭包

```go
func genNext() func() int{
  i:=0 // 该变量会保存
  return func() int {
    i+=1
    return i
  }
}
```

和 js python 等不太一致的点,像python等会直接等到函数执行完,即会使用全

```go
func gen() func() int{
  for i:=0;i<10;i++; { // 该变量不会保存
    return func() int {
      return i
    }
  }
  return nil;
}
```

### 函数作为参数

可以用下面的形式

```go
func invoke(f func() int) int {
	return f()
}
```

### defer 关键字

defer代码块会在函数调用链表中增加一个函数调用。这个函数调用不是普通的函数调用，而是会在函数正常返回，也就是return之后添加一个函数调用。因此，defer通常用来释放函数内部变量

-   **defer在定义的时候就保存了调用的参数,虽然在代码结束后执行**
-   **逆序执行return 前定义好的defer**
-   **能够读取到最新的变量**

定义之前就返回了是不会执行了

```go
func swi(num int) {
	if num > 3 {
    return 
		defer fmt.Println(3) // 无输出
	}
}

func swi(num int) {
	if num > 3 {
		defer fmt.Println(3) // 输出 3
    return 
	}
}
```

逆序关闭,如下面的程序(栈)

```go
func swi(num int) {
	if num > 3 {
		defer fmt.Println(3)
	}
	if num > 5 {
		defer fmt.Println(5)
	}
	return
}
// 输出 5\n3
func main() {
	swi(10)
}
```

参数传递的变量在一瞬间已经停了,但读取变量读到的是函数执行罪行的

```go
func inc(i int) {
   defer func(){
      i++
      fmt.Println(i)
   }()
   i++
   return
}
```



## 数组

go的数组和指针具有c的特性,我们来考虑c的数组和指针

c的指针实现偏移是这样的

```c
int* p;
*(p+2)=3
```

首先计算偏移地址,我们假设这里p的基址是2000,所以`*(p+2)`先根据p取得p的地址算出`0x2000+2*sizeof(int)=0x2008`然后把3放入对应的偏移地址中,可表示为`*(*(0x1004)+2)=3`其中`0x1004`代表指针的地址.

而数组则省略了一部分操作

```c
int b[10];
b[2] = 3
```

b就表示内存的开始地址,<font color="red">不同于上面表示指针的地址</font>,所以取址少了一次,直接存储连续的数据,假设开始地址为`0x1000`,那么最后的结果为`0x1000+2×sizeof(int)=0x1008`往该地址填入数据3

go的数组类型同样延续了后置声明的方式,如下

```go
var balance [10]float32{}
var balance = [5]float32{1000.0, 2.0, 3.4, 7.0, 50.0}
balance := [5]float32{1000.0, 2.0, 3.4, 7.0, 50.0}
balance := [...]float32{1000.0, 2.0, 3.4, 7.0, 50.0}
//  将索引为 1 和 3 的元素初始化
balance := [5]float32{1:2.0,3:7.0}

// 动态扩容数组,让数组具有有序表特性
balance = append(balance,1)
```

可以看到其语法格式是把数组的元素优先声明了不同于Java的`int[10]`以及c语言的`int a[10]`,这个形式的定义更像一个类型而非指针.遍历如下两种形式,数组有界

```go
for idx, res := range arr {
		println(idx,res)
}
for i := 0; i < len(arr); i++ {
		println(i,arr[i])
}
```

### 二维数组

```go
a := [3][4]int{  
 {0, 1, 2, 3} ,   /*  第一行索引为 0 */
 {4, 5, 6, 7} ,   /*  第二行索引为 1 */
 {8, 9, 10, 11},   /* 第三行索引为 2 */
}
```

### 作为参数在函数中传递

数组设置大小是唯一的不同

```go
func getAverage(arr []int, size int) float32 {}
func getAverage(arr [5]int, size int) float32 {}
```

这两者均只能传递对应的变量,视为不同的类型.

## Map

map的实现是通过hash表实现的,所以我们可以理解其为一种dict的结构,其实也就是hashmap,一种json字典结构.map的默认初始化是nil,其是线程不安全的,线程安全应该使用 sync.Map

```go
//var dict map[string]string = map[string]string{"key":"value"}
dict := map[string]int{"key": 32}
dict["newkey"] = 16
for key, value := range dict {
  fmt.Println(key, value)
}
```

contains的判断逻辑有两种方式,默认值判断以及boolean判断

```go
v := dict["keys"] 
print(v) // 如前context中不包含上下文,则返回 int 的默认值 0
v := dict["key"] // 返回 32
v,exist:= dict["key"] // 32 true
if _,exist := dict["keys"]; exist {
  
}
```

删除 key,使用 delete 函数 其实这里是 delete if absent

```go
delete(dict,"aaaaa")
```

map 和 dict 可以认为不是传赋值,以为其修改可以直接作用到底层的地址上,无论是数组的切片还是 map 的首地址,这点比c更有java的特性,其引用可以让修改无需考虑特别多

关于数组和map的最大区别是,map里的修改可以看做是引用级别的修改,而数组则会把内部的值进行函数的参数的拷贝然后修改拷贝的副本,从这里可以看到map具有引用的特性,而数组具有值的特性



## 结构体

面向对象的本质出自这里,即数据结构组织方式的一种.封装继承多态中实现了封装的最重要形式.可以用来实现更加复杂的数据结构.结构体的本质即类型,或类,其实现的理念是封装.其数据组织形式同样使用了封装的形式.

```go
type Books struct {
   title string
   author string
   subject string
   book_id int
}
```

一旦定义了类型即可当成普通类型来使用,go和其他面向对象在类和结构体的使用形式上达成了一致.相比于Java的Pojo,结构体更加纯粹的表达了该种封装机制

```go
var book Books = Books{"Go 语言", "null", "Go", 6495407}
book.title = "Golang"
book.author = "null"
book.subject = "go"
book.book_id = 1
fmt.Println(book)
```

访问结构体的成员变量使用`.`操作符,我们对比下c

-   `(*struct).member` 等价于 `struct->member`
-   但是go只用`.`就可以使用完成上面的操作了,看来来是更加智能了

结构体的修改需要传递指针例如下面的函数就无法被修改其值,因为其是上层的拷贝

```go
	messages := []message{
    message{title:"title", subject: "subject", context:"context"},
    message{"title", "subject", "context"},
    message{"title", "subject", "context"},
    message{"title", "subject", "context"},
  }
changeMessageTitle(messages, "t")
for _, m := range messages {
  fmt.Println(m)
}

/* define */
type message struct {
	title   string
	subject string
	context string
}

func changeMessageTitle(msgs []message, title string) {
	for _, m := range msgs {
		m.title = title
	}
}
```

但我们可以通过指针去改值

```go
	messages := []*message{
		&message{title: "title", subject: "subject", context: "context"},
		&message{"title", "subject", "context"},
		&message{"title", "subject", "context"},
		&message{"title", "subject", "context"},
	}
	changeMessageTitle(messages, "t")
	for _, m := range messages {
		fmt.Println(m)
	}

/** define **/
type message struct {
	title   string
	subject string
	context string
}

func changeMessageTitle(msgs []*message, title string) {
	for _, m := range msgs {
		m.title = title
	}
}
```

所以从这里看出 go 的结构体和 c 有着相似的形式,go 的结构体代表着指针的特性,和数组一致,在修改值的时候需要借助指针,否则则会被视为拷贝,即引用特性对于结构体不适用

### 匿名结构体

```go
a:=struct {
  name string
  age int
}{
  name :"王二狗",
  age :30,
}
```



## 指针

---

和c/c++一样,go可以控制指针,且`*`和`&`的语义和c/c++相同,go里面的指针比之c/c++多了一些限制,比如数组和指针就被设计成完全不同的东西,指针偏移不在适用.这种不被语义识别的设计使得语义更加明确.

### 数组指针和指针数组

```go
var ptr [3]*int // 指针数组
var arr *[6]int // 数组指针
```

其含义和上面的语义命名一致,我们也看到了其编译的规则,数组和指针的命名规则,`[3]*int`为一数组,其类型为`*int`,`*[6]int`为一指针,其类型为`[6]int`.我们不妨对比下c的设计

```c
char(*pc)[9]; // 数组指针 其语义如下 [9] 数组 *pc 最后结合成指针,即为数组指针
char* pc[]; // 指针数组 `char*` 指针 的 数组 `[]`
// 下面展示下语义级理解,按照c和java的语义,上面可以理解为
char[9] (*pc);
char*[] pc;
// 那自然我们就可以看到类型了
```

对比下go会发现go的语义更加清晰.结合顺序和c有点不一致但都八九不离十.即结合顺序代表了指针或者数组类型的写法和形式.

两者的实际用途可以参考下面代码

```go
const n = 2
arr := [n]int{1, 2}
var arrptr [n]*int
for i := 0; i < n; i++ {
  arrptr[i] = &arr[i]
}
arr[0] = 3
arr[1] = 2
for i := 0; i < n; i++ {
  println(*arrptr[i])
}
```

```go
const n = 2
	arr := [n]int{1, 2}
	var arrptr *[n]int
	arrptr = &arr
	for i := 0; i < n; i++ {
		println((*arrptr)[i])
	}
```

如上可以得到数组的引用以及数组存储指针的方法

### 二级指针与值传递

即指向指针的指针

```go
var ptr **int;
```

先说下应用场景,在c语言的参数传递中,编译器总会制作副本,所以我们要实现一个交换函数如下

```c
void swap(int a,int b){
  int tmp = a;
  a = b;
  b = tmp;
}
```

我们会发现其根本不会交换,原因是a,b的副本发生了交换,我们看下地址的版本,为什么这个会涉及到地址的改动呢,因为编译器帮我们复制了值,但我们就是要改地址里面的内容,再看下面的场景

```c
void swap(int* a int* b){ // 因为复制的是个地址的值
  int tmp = *a;
  *a = *b;
  *b = tmp;
}
```

```c
int a= 10;
int b= 100;
int *q;
void func(int* p){
  p = &b;
}

void main(){
  q = &a;
  func(q);
}
```

我们看到上面是没有赋值的原因和上基本相同,因为传过去的指针的值,这个时候就需要二级指针了,这个现象的 key point 是指针传递时会传递副本,<font color="pink">即值传递,而不是引用传递</font>,变化的原因是因为传地址了且操作地址了,像上面这种需要给指针赋值的情况就需要二级指针即需要指针的地址

值传递这个现象在go中不止出现在函数的参数里还出现在赋值上

```go
arr1 := []int{1,2,3}
arr2 := arr1
arr2[0] = 0
fmt.Println(arr1, arr2) // [1,2,3] [0,2,3]
```



### 结构体指针

和c语言相比已经优化了一些,`->`和`.`符号统一变成了`.`所以可以使用下列方法访问成员变量以及修改,其效果等同于`(*book).title="GO GO GO"`,并无二致,所以从这点看go和c是有本质区别的,其在结构体设计理念更像python,java等语言

```go
func changeBook(book *Books) {
	book.title = "GO GO GO"
	book.author = "nil"
	book.subject = "go"
	book.book_id = 10
}
```

但是还是有如下的情况,所以对于类(结构体)和普通变量还是要分开来看的

```go
change(&a)
func change(a *int) {
	*a = 3
}
```



### 函数指针

函数指针在go中并没有,但有类似的效果如下

```go
var f func(int) int = nil
f = func(a int) int {
  return a+1
}
println(f(1))
```



## 切片 slice

切片为数组的抽象,和python中的切片数组很类似如下,切片数组具有动态的特性,长度可以是不固定的,但和python不一样的是,go不支持倒数`-1`这样的索引,如果我们平时不指定长度定义数组就是定义为切片

```go
arr:= [3]int{1,2,3}
s := arr[1:2]
fmt.Println(s,arr)  // [2] [1,2,3]
```

切片有两个关键属性 cap 和 len,可以用 `cap()`和`len()` 来确定,这两个属性代表两个意义,len代表切片的长度,cap代表切片底层数组元素的长度或者个数

```go
arr := []int{1, 2, 3}
s := arr[1:2]
fmt.Println(s, arr)
println(len(arr), cap(arr))
println(len(s), cap(s))
```

`[5]int`和`[25]int`这是两种不同的类型所以下列赋值会出错

```go
arr := [3]int{1, 2, 3} // 数组类型
arr = arr[1:2]
```

但以下的赋值却会正确

```go
arr := []int{1, 2, 3} // 切片类型
arr = arr[1:2]
```

切片的修改会穿透底层的数组,所以仅仅是作为一个数据的收集者,<font color="red">若干个切片共享底层数组</font>

```go
arr := [3]int{1, 2, 3}
s := arr[1:2]
s[0] = 3 // 或者是换成 arr[1] = 3 结果都是一致的
fmt.Println(s, arr)
fmt.Println(s, arr) // [3] [1,3,3]
```

我们之前使用过 `append`函数可以为切片添加元素,即切片的长度可以动态增加

```go
arr := [3]int{1, 2, 3}
res := append(arr[:],4) // res := append(arr,4) 会出错 因为不是切片
println(res)

veggies := []string{"potatoes","tomatoes","brinjal"}
fruits := []string{"oranges","apples"}
food := append(veggies, fruits...) // append 可以拼接多个切片
```

切片作为函数参数传递

```go
func subtactOne(numbers []int) {  
    for i := range numbers {
        numbers[i] -= 2
    }
}
func main() {
    nos := []int{8, 7, 6}
    fmt.Println("slice before function call", nos)
    subtactOne(nos)                               
    fmt.Println("slice after function call", nos)

}
```

实际上是会减少的,因为元素减少最终是落在了底层的数组,我们看下复制的内容仅仅是切片,所以可以认为切片含有Java,python语言等引用特性的动态数组.

切片还可以作为不被内存回收的凭证,只要切片存在内存中,底层共享的数组就不会被回收,如果想要底层数组被回收可以使用 copy 函数创建新的切片,如下

```go
countries := []string{"USA", "Singapore", "Germany", "India", "Australia"}
neededCountries := countries[:len(countries)-2]
countriesCpy := make([]string, len(neededCountries))
copy(countriesCpy, neededCountries)
```

创建新切片的时候

```go
arr := []int{1, 2, 3, 4, 5}
tmp := arr[2:4]
println(cap(tmp)) // 这个容量为3 因为拿到的事前一个长度的指针
println(len(tmp))
tmp = append(tmp,1)
tmp = append(tmp,1)
tmp = append(tmp,1)
fmt.Println(tmp) // [3,4,1,1,1]
fmt.Println(arr) // [1,2,3,4,1]
```





## range

range 关键字用于遍历,数组,切片,通道,集合.

```go
nums := []int{2, 3, 4}
sum := 0
for idx, num := range nums {
  sum += num
}
fmt.Println("sum:", sum)

for i, c := range "go" {
  fmt.Println(i, c)
}

// range也可以用在map的键值对上。
kvs := map[string]string{"a": "apple", "b": "banana"}
for k, v := range kvs {
  fmt.Printf("%s -> %s\n", k, v)
}
```

## socket



### http



## 排序

需要重写函数,我们可以用 wrapper 转成其他语言 sorted 的形式

```go
type DataWrapper struct {
	data []*Data
	by   func(p, q *Data) bool
}

func (this DataWrapper) Len() int { // 重写 Len() 方法
	return len(this.data)
}
func (this DataWrapper) Swap(i, j int) { // 重写 Swap() 方法
	this.data[i], this.[j] = this.data[j], this.data[i]
}
func (this DataWrapper) Less(i, j int) bool { // 重写 Less() 方法
	return this.by(this.data[i], this.data[j])
}

sort.Sort(DataWrapper{plugins, func(x, y *Data) bool {
			return strings.Compare(x.Name, y.Name) > 0
}})
```



## I/O

I/O 的部分分为几类,文件 I/O,管道,socket

[参考](https://www.jianshu.com/p/abc396787a32)

-   io 存放操作系统原语
-   io/ioutil 实用函数
-   bufio 实现带缓冲的 io

### 接口

-   Reader
-   Writer
-   ReadAt
-   WriteAt

```go
/*
Read 将 len(p) 个字节读取到 p 中。它返回读取的字节数 n（0 <= n <= len(p)） 以及任何遇到的错误。
即使 Read 返回的 n < len(p)，它也会在调用过程中占用 len(p) 个字节作为暂存空间。若可读取的数据不到 len(p) 个字节，
Read 会返回可用数据，而不是等待更多数据。
*/
type Reader interface {
    Read(p []byte) (n int, err error)
}
type Writer interface {
    Write(p []byte) (n int, err error)
}
/*
ReadAt 从基本输入源的偏移量 off 处开始，将 len(p) 个字节读取到 p 中。它返回读取的字节数 n（0 <= n <= len(p)）以及任何遇到的错误。
当 ReadAt 返回的 n < len(p) 时，它就会返回一个 非nil 的错误来解释 为什么没有返回更多的字节。在这一点上，ReadAt 比 Read 更严格。
即使 ReadAt 返回的 n < len(p)，它也会在调用过程中使用 p 的全部作为暂存空间。若可读取的数据不到 len(p) 字节，ReadAt 就会阻塞,直到所有数据都可用或一个错误发生。 在这一点上 ReadAt 不同于 Read。
*/
type ReaderAt interface {
    ReadAt(p []byte, off int64) (n int, err error)
}
type WriterAt interface {
    WriteAt(p []byte, off int64) (n int, err error)
}
```

实现

```go
var (
    Stdin  = NewFile(uintptr(syscall.Stdin), "/dev/stdin")
    Stdout = NewFile(uintptr(syscall.Stdout), "/dev/stdout")
    Stderr = NewFile(uintptr(syscall.Stderr), "/dev/stderr")
)
```



### io 多路复用

[参考](https://www.cnblogs.com/luozhiyun/p/14390824.html),[参考](https://zhuanlan.zhihu.com/p/394872000)







## 高级特性

### 类型转换

go 不支持隐式转换,其转换类型和 python 类型

```go
var num float64 = 3.0
int(num) // 或者 (int)(num)

type msg struct {
	Data  string
	Code int
}

type data struct {
	Data  string
	Code int
}
// 接口的互相转换
fmt.Print(msg(data{Data: "2", Code: 300}))
```



### 单引号双引号反引号

- '',用于表示 byte 类型或 rune 类型,默认是 rune.byte 用强调数据是 raw data 不是数字,大小为uint8,rune用来表示 Unicode 的code point,大小为int32
- "",字符串或者字符数组
- \`\`,不转义,原样字符 raw literal string.相当于 python 中的 `"""`

### == 比较符

结构体比较 按照数据类型 按地址逐个比较各个成员变量

```go
s1 := struct {
  a string
  b int
}{"1", 1}
s2 := struct {
  b int
  a string
}{1, "1"}
println(s1 == s2) // 报错

s1 := struct {
  b int
  a string
}{1, "1"}
s2 := struct {
  b int
  a string
}{1, "1"}
println(s1 == s2) // true
```

数组也是一样

```go
arr := [5]int{1, 2, 3, 4, 5}
arr1 := [5]int{1, 2, 3, 4, 5}
println(arr == arr1) // true
```

切片,数组不能比较

```go
arr := []int{1, 2, 3, 4, 5}
arr1 := []int{1, 2, 3, 4, 5}
println(arr == arr1) // 报错
mp1:=map[string]string{}
mp2:=map[string]string{}
println(mp2 == mp1) // 报错
```

如果结构体含有不能比较的东西也不行

```go
s := struct {
  b string
  a []int
}{"",[]int{1}}
t := struct {
  b string
  a []int
}{"",[]int{1}}
println(s == t)
```

能比较的东西才可以作为map的 key

```go
mp:=map[[5]int]string{} // ok
mp:=map[[]int]string{}
```





### 结构体方法

此特性让 go 的书写有了接近面向对象的形式,以dto类为举例

```go
type Data struct {
	message string
}

func (this *Data) getMessage() string {
	return this.message
}

func (this *Data) setMessage(msg string) {
	this.message = msg
}

func main() {
	data := &Data{"test"}
	data.setMessage("test data")
	fmt.Println(data.getMessage())
}
```

可以看到其和java的区别仅在于显式指定this指针,需要在函数前面指定函数的使用对象(struct),同样我们可以写非指针形式的不过无法传递关键信息(值拷贝)

```go
func (this Data) getMessage() string {
	return this.message
}

func (this Data) setMessage(msg string) {
	this.message = msg
}

func main() {
	data := Data{"test"}
	data.setMessage("test data")
	fmt.Println(data.getMessage()) // test 而不是 test data
}
```

所以按照语法而言建议其使用在结构体指针上



### 接口

这其实是定义了类似类的特性 配合上面的方法特性可以使得调用语法更像面向对象,从各种语言上理解`接口是一组方法签名的集合`

定义接口很简单,结合结构体方法绑定,即可认为**默认实现**了同接口

```go
type DataDAO interface {
	getMessage() string
	setMessage()
	toString() string
}
```

除此之外我们可以使用显式交接,但显得多此一举

```go
var dt Data
var dao DataDAO
dao = dt
```

接口的用处和面向对象中的作用基本一致,我们不需要去关心实现类如何即可调用如下

```go
package main

import "fmt"

type DataDAO interface {
	getMessage() string
	setMessage(string)
	toString() string
}
type Data struct {
	message string
}

func (this *Data) getMessage() string {
	return this.message
}

func (this *Data) setMessage(msg string) {
	this.message = msg
}
func (this *Data) toString() string {
	return "['message':'" + this.message + "']"
}

type MessageData struct {
	message string
	info    string
}

func (this *MessageData) getMessage() string {
	return this.message
}

func (this *MessageData) setMessage(message string) {
	this.message = message
}

func (this *MessageData) setInfo(info string) {
	this.info = info
}
func (this *MessageData) getInfo() string {
	return this.info
}

func (this *MessageData) toString() string {
	return "['message':'" + this.message + "'," + "'info':'" + this.info + "']"
}

func jsonStr(dao DataDAO) string { // 需要注意这里不是指针类型
	val := dao.toString()
	fmt.Println(val)
	return val
}

func main() {
	data := Data{"test"}
	data.setMessage("test data")
	fmt.Println(data.getMessage())
	jsonStr(&data) 
  // 这里需要传入指针类型,因为只有指针类型绑定了对应的方法,这里的接口是个抽象的概念,从上面绑定的方法来看
  // 真正绑定了这些方法的是结构体指针而不是结构体,所以这个接口指的是实现了这些方法的指针而不是结构体本身
  // 同样如果方法本身被实现了可以不使用指针的形式进行调用
	dataMsg := MessageData{
		message: "ok",
		info:    "info",
	}
	jsonStr(&dataMsg)
}
```

这里需要注意接口的一个问题,接口可以实现更多的方法但是必须要有接口中定义的参数绑定才行.

空接口即不定义任何方法的接口,和Java的顶层类Object,可以存储适配所有类型的数据

接口嵌套即接口的继承,一个接口继承另一个接口的所有方法集合

```go
type DataAOP interface {
  DataDAO
  getType() string
} 
```



### 结构体 tag

结构体 tag,如下用反引号括起来的内容`gorm:"column"`

```go
type Developer struct {
	Id            int32
	Name          string
	Email         string
	Password      string
  PluginCount   int32 `gorm:"column:pluginCount" json:"pluginCount"`
	DownloadCount int32 `gorm:"column:downloadCount"`
	ReportCount   int32 `gorm:"column:reportCount"`
	Status        int16
}

func (Developer) TableName() string {
	return "developer"
}
```





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





 



### 反射

```go
import "reflect"
```

-   type: type 指的是系统原生数据类型，如 int、string、bool、float32 等类型,或者是结构体
-   kind: 类型如下

```go
type Kind uint
const (
    Invalid Kind = iota  // 非法类型
    Bool                 // 布尔型
    Int                  // 有符号整型
    Int8                 // 有符号8位整型
    Int16                // 有符号16位整型
    Int32                // 有符号32位整型
    Int64                // 有符号64位整型
    Uint                 // 无符号整型
    Uint8                // 无符号8位整型
    Uint16               // 无符号16位整型
    Uint32               // 无符号32位整型
    Uint64               // 无符号64位整型
    Uintptr              // 指针
    Float32              // 单精度浮点数
    Float64              // 双精度浮点数
    Complex64            // 64位复数类型
    Complex128           // 128位复数类型
    Array                // 数组
    Chan                 // 通道
    Func                 // 函数
    Interface            // 接口
    Map                  // 映射
    Ptr                  // 指针
    Slice                // 切片
    String               // 字符串
    Struct               // 结构体
    UnsafePointer        // 底层指针
)
```

```go
fmt.Println(reflect.TypeOf(struct {
  a string
}{a: "a"}))
// struct { a string }
```

#### 指针反射

```go
fmt.Println(reflect.TypeOf(&struct {
  a string
}{a: "a"}))
// *struct { a string }

// 获取指针指向的地址
fmt.Println(reflect.TypeOf(&struct {
  a string
}{a: "a"}).Elem())
```

#### 结构体反射

获取结构体的反射在go中就相当重要,我们看主要方法

-   获取字段
    -   FieldByName(name string)
    -   Field(index int)
    -   NumField()

来实现一个功能,BeanUtil.copy

```go
type msg struct {
	Msg  string
	Code int
}

type data struct {
	Data  string
	Code int
}

func copyProperties(from interface{}, to interface{}) {
	typeF := reflect.TypeOf(from).Elem()
	valueF := reflect.ValueOf(from).Elem()
	typeT := reflect.TypeOf(to).Elem()
	valueT := reflect.ValueOf(to).Elem()
	num := typeF.NumField()
	for i := 0; i < num; i++ {
		if field, contains := typeT.FieldByName(typeF.Field(i).Name); contains {
			valueT.FieldByName(field.Name).Set(valueF.FieldByName(field.Name))
		}
	}
}
func main() {
	m := msg{Msg: "3", Code: 500}
	n := data{Data: "2", Code: 300}
	copyProperties(&m, &n)
	fmt.Printf("%v", n)
}
```



### 接口与类型

[参考](https://www.jianshu.com/p/ce307b8e9772),[参考](https://blog.csdn.net/weixin_42297746/article/details/112126019)可以研究下go的类型系统如何实现,理解类型方法接口

在上面我们已经知道了 type 的定义属于类型,而接口则更贴近方法签名的集合,其实不然,在 go 里面,接口涵盖的部分更加广,可以认为所有结构体都实现了空接口.

从上面反射的例子中,我们知道,接口虽然只能显示调用方法签名,但却可以通过反射来追溯接口实现的类型,以及对应的值.那么何为接口?

![](https://img-blog.csdnimg.cn/img_convert/3f094edb3f8fb6d1117d379fcdf55a75.png)



### 交叉编译

使用如下命令可以编译不同操作系统的二进制文件,下面是mac编译linux和windows的命令

```go
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build test.go
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build test.go
```

除此之外

```go
CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build test.go
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build test.go

CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build test.go
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build test.go
```







### 错误处理

先来抛出一个错误

```go
panic("runtime exception") // 传入接口类型
```

其他的错误处理一般通过接口层层返回

```go
func throwError() error {
	if true {
		panic("烫烫烫烫烫")
	} else {
		return nil
	}
}

func testError() (string, error) {
	if err := throwError(); err != nil {
		return "error", err
	} else {
		return "not error occur", nil
	}
}
func main() {
	res, err := testError()
	fmt.Println(res, err)
}
```

### unsafe

普通指针 & uniptr & unsafe.Pointer

>   -   *类型:普通指针类型，用于传递对象地址，不能进行指针运算。
>   -   unsafe.Pointer:通用指针类型，用于转换不同类型的指针，不能进行指针运算，不能读取内存存储的值（必须转换到某一类型的普通指针）。
>   -   uintptr:用于指针运算，GC 不把 uintptr 当指针，uintptr 无法持有对象。uintptr 类型的目标会被回收。

简而言之就是 go 的**普通指针**不是 c++ 的指针可以那么随心所欲.而 **uintptr** 解放生产力,和 **unsafe.Pointer** 配合可以进行指针运算

看下 unsafe 包的内容

```go
type ArbitraryType int
type Pointer *ArbitraryType
func Sizeof(x ArbitraryType) uintptr // 占用大小 Sizeof(int32(0)) 其和 c 基本一致
func Offsetof(x ArbitraryType) uintptr // 相对结构体的偏移量 常见使用方式 a.x a为结构体
func Alignof(x ArbitraryType) uintptr // 内存对齐地址的倍数 同上
```

我们来看个例子,最常见的 Pointer 构造和转换,联系下一章一起看吧-v-.

```go
package main

import (
	"fmt"
	"unsafe"
)

/*
void setInt(int addr,int val){
	int* ptr = (int*)(addr);
	*ptr = val;
}
int getInt(int addr){
	int* ptr = (int*)(addr);
	return *ptr;
}
*/
import "C"

const n = 4

var s [n]int32 = [n]int32{1, 2, 3, 4}
var offset int = (int)(unsafe.Sizeof(int32(0))) // 偏移量
var head uintptr = uintptr(unsafe.Pointer(&s))  // 数组首地址

func init() {
	for i := 0; i < n; i++ {
		C.setInt(C.int(int(head)+offset*i), C.int(i))                       // 用 c 的方法 set
		*(*int32)(unsafe.Pointer(uintptr(int(head) + i*offset))) = int32(i) // 用 go 的方法 set
	}
}
func main() {
	fmt.Println(s)
	fmt.Println(head)
	for i := 0; i < n; i++ {
		var val int32
		val = int32(C.getInt(C.int(int(head) + i*offset)))             // c 的方法 get
		val = *(*int32)(unsafe.Pointer(uintptr(int(head) + i*offset))) // go 的方法 get
		fmt.Printf("%d,%d\n", i, val)
	}
}
```

由上可以看到数组的本质就是一段连续内存,同c的理解







### go 内嵌 c++/c

内嵌 c 的代码 可以使用上面的方式直接调用 c 的结构体

```go
package main

/*
#include <stdio.h>
#include <stdlib.h>
typedef struct {
    int id;
}ctx;

ctx* createCtx(int id) {
    ctx *obj = (ctx *)malloc(sizeof(ctx));
    obj->id = id;
    return obj;
}
*/
import "C"
import (
	"fmt"
	"reflect"
)

func main() {
	var ctx *C.ctx = C.createCtx(100)
	fmt.Println(reflect.TypeOf(ctx))
	fmt.Printf("id : %d\n", ctx.id)
}
```

内嵌 c++ 则需要 c++ 通过编译



### 数组和切片

这两者都是值复制,除非显示指定指针,否则可以人为所有数据结构是使用了值拷贝,其中 slice 和 map 使用了浅拷贝

- `[5]int` 为数组类型
- `[]int` 为切片类型

```go
func test() {
	ints := [5]int{14, 14, 15}
	testCopy(ints)
	fmt.Println(ints)
}

func testCopy(arr [5]int) {
	arr[1] = -1 // 不会发生改变
}
```

### 值拷贝

值拷贝在 golang 中和c++基本是一致的,除了指针以外所有拷贝都是值的复制,包括结构体和 array

```go
func test() {
	a:=A{B{"1"}}
	testCopy(a)
  fmt.Println(a) // {{1}}
}

func testCopy(a A) {
	a.B.message = "3"
}
```

但如果传地址就不一样了

```go
type A struct {
	b *B
}
type B struct {
	message string
}

func test() {
	a:=A{&B{"1"}}
	testCopy(a)
  fmt.Println(*a.b) // {{3}}
}

func testCopy(a A) {
	a.b.message = "3"
}
```

### make & new

两者都是用于分配内存的

- new 用于给**指针**变量分配内存
- make 用于初始化 slice map 和 channel

更简单的概括就是 make 会给内部的指针赋值进行更加复杂的初始化(slice).而 new 则是相当于 malloc



### 数据结构详解

[参考](https://tiancaiamao.gitbooks.io/go-internals/content/zh/02.3.html)

### slice

本章讲解 runtime 的数据结构源码,从 runtime 的结构不难看出整个 runtime 是由 c/asm 和 go 共同完成的

```go
type slice struct {
	array unsafe.Pointer
	len   int
	cap   int
}
```

扩容

在对slice进行append等操作时,可能会造成slice的自动扩容.其扩容时的大小增长规则是:

-   如果新的大小是当前大小2倍以上，则大小增长为新大小
-   否则循环以下操作：如果当前大小小于1024，按每次2倍增长，否则每次按当前大小1/4增长。直到增长的大小超过或等于新大小。



### map

结合 unsafe 的理解不难看出来这段地址的排布,其len和cap排在结构体后半部分,我们来研究下 map

```go
type hmap struct {
	// Note: the format of the hmap is also encoded in cmd/compile/internal/gc/reflect.go.
	// Make sure this stays in sync with the compiler's definition.
	count     int // # live cells == size of map.  Must be first (used by len() builtin)
	flags     uint8
	B         uint8  // log_2 of # of buckets (can hold up to loadFactor * 2^B items)
	noverflow uint16 // approximate number of overflow buckets; see incrnoverflow for details
	hash0     uint32 // hash seed

	buckets    unsafe.Pointer // array of 2^B Buckets. may be nil if count==0.
	oldbuckets unsafe.Pointer // previous bucket array of half the size, non-nil only when growing
	nevacuate  uintptr        // progress counter for evacuation (buckets less than this have been evacuated)
	extra *mapextra // optional fields
}

// mapextra holds fields that are not present on all maps.
type mapextra struct {
	// If both key and elem do not contain pointers and are inline, then we mark bucket
	// type as containing no pointers. This avoids scanning such maps.
	// However, bmap.overflow is a pointer. In order to keep overflow buckets
	// alive, we store pointers to all overflow buckets in hmap.extra.overflow and hmap.extra.oldoverflow.
	// overflow and oldoverflow are only used if key and elem do not contain pointers.
	// overflow contains overflow buckets for hmap.buckets.
	// oldoverflow contains overflow buckets for hmap.oldbuckets.
	// The indirection allows to store a pointer to the slice in hiter.
	overflow    *[]*bmap
	oldoverflow *[]*bmap

	// nextOverflow holds a pointer to a free overflow bucket.
	nextOverflow *bmap
}

// A bucket for a Go map.
type bmap struct {
	// tophash generally contains the top byte of the hash value
	// for each key in this bucket. If tophash[0] < minTopHash,
	// tophash[0] is a bucket evacuation state instead.
	tophash [bucketCnt]uint8 // bucketCnt 为 1<<3,tophash 翻译为 高位 hash
	// Followed by bucketCnt keys and then bucketCnt elems.
	// NOTE: packing all the keys together and then all the elems together makes the
	// code a bit more complicated than alternating key/elem/key/elem/... but it allows
	// us to eliminate padding which would be needed for, e.g., map[int64]int8.
	// Followed by an overflow pointer.
}
```

看到其数据结构,显然他的增长方式和 java 的 hashmap 一样,是2倍增长,且使用类似的 oldbuckets 进行赋值,且可以看出其桶位最大只有8,其桶位变大是通过 overflow 来实现的

![](https://img.snaptube.app/image/em-video/10635a99c7989cfee6c816619f60c379_488_227.png)

>   按key的类型采用相应的hash算法得到key的hash值。**将hash值的低位当作Hmap结构体中buckets数组的index**，找到key所在的bucket。将hash的高8位存储在了bucket的tophash中。
>
>   **注意，这里高8位不是用来当作key/value在bucket内部的offset的，而是作为一个主键，在查找时对tophash数组的每一项进行顺序匹配的**。

上面引用自参考,解读下就是 桶位的计算 = hash(key) % bucketSize ,而 tophash 仅仅只是用**高8位加速判断**并没有其他用处

看其查找算法

```go
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	if raceenabled && h != nil {
		callerpc := getcallerpc()
		pc := funcPC(mapaccess1)
		racereadpc(unsafe.Pointer(h), callerpc, pc)
		raceReadObjectPC(t.key, key, callerpc, pc)
	}
	if msanenabled && h != nil {
		msanread(key, t.key.size)
	}
	if h == nil || h.count == 0 {
		if t.hashMightPanic() {
			t.hasher(key, 0) // see issue 23734
		}
		return unsafe.Pointer(&zeroVal[0])
	}
	if h.flags&hashWriting != 0 {
		throw("concurrent map read and map write")
	}
	hash := t.hasher(key, uintptr(h.hash0))
	m := bucketMask(h.B)
	b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.bucketsize)))
	if c := h.oldbuckets; c != nil {
		if !h.sameSizeGrow() {
			// There used to be half as many buckets; mask down one more power of two.
			m >>= 1
		}
		oldb := (*bmap)(add(c, (hash&m)*uintptr(t.bucketsize))) // 取模方法真快
		if !evacuated(oldb) {
			b = oldb
		}
	}
	top := tophash(hash) // 算出 tophash 值
bucketloop:
	for ; b != nil; b = b.overflow(t) { // 查找所有的 buckets,包括 overflow
		for i := uintptr(0); i < bucketCnt; i++ {
			if b.tophash[i] != top { // 快速试错,如果不等就下一个
				if b.tophash[i] == emptyRest {
					break bucketloop // 如果等于还是个空值就下一个
				}
				continue
			}
      // 这里已经从 tophash 中找到了值,获取 key,其key锁存放的位置是连续的
			k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.keysize))
			if t.indirectkey() {
				k = *((*unsafe.Pointer)(k))
			}
			if t.key.equal(key, k) {
				e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize)) // element
				if t.indirectelem() {
					e = *((*unsafe.Pointer)(e))
				}
				return e
			}
		}
	}
	return unsafe.Pointer(&zeroVal[0])
}
```

```go
// data offset should be the size of the bmap struct, but needs to be
// aligned correctly. For amd64p32 this means 64-bit alignment
// even though pointers are 32 bit.
dataOffset = unsafe.Offsetof(struct {
  b bmap
  v int64
}{}.v)

type maptype struct {
	typ    _type
	key    *_type
	elem   *_type
	bucket *_type // internal type representing a hash bucket
	// function for hashing keys (ptr to key, seed) -> hash
	hasher     func(unsafe.Pointer, uintptr) uintptr
	keysize    uint8  // size of key slot
	elemsize   uint8  // size of elem slot
	bucketsize uint16 // size of bucket
	flags      uint32
}
```

从上面我们可以看到几行关键代码

-   key:`unsafe.Pointer(b),dataOffset+i*uintptr(t.keysize)`
-   value:`unsafe.Pointer(b),dataOffset+bucketCnt*uintptr(t.keysize)+i*uintptr(t.elemsize))`

可以看到 key 的排布和 value 的排布是完全分开的,(好家伙您完全不告诉我指针放的是啥是吧)

扩容使用了和 java 的 hashmap 类似的方法,扩容的size都是2的倍数,这样一来有两个好处

-   扩容时候可以采用 rehash 的方法更快确定位置,高低1bit就可确认是否在原来的位子上
-   mod 方法取模变成 and mask,效率增加

go 中的扩容是增量扩容,rehash之后的旧的 pair 会随着 insert 和 remove 逐步扩容到新的 hashmap 上.扩容触发的条件是根据以下参数,如同 java 的 hashmap 有扩容因子的说法,java 的负载因子是 0.75,go 根据测试结果选择了 6.5,从这个值可以看出是查找不存在的 key 的平均查找长度

```go
        LOAD    %overflow  bytes/entry     hitprobe    missprobe
        4.00         2.13        20.77         3.00         4.00
        4.50         4.05        17.30         3.25         4.50
        5.00         6.85        14.77         3.50         5.00
        5.50        10.55        12.94         3.75         5.50
        6.00        15.27        11.67         4.00         6.00
        6.50        20.90        10.79         4.25         6.50
        7.00        27.14        10.15         4.50         7.00
        7.50        34.03         9.73         4.75         7.50
        8.00        41.10         9.40         5.00         8.00

 %overflow   = percentage of buckets which have an overflow bucket // 多少key-value需要额外空间
 bytes/entry = overhead bytes used per key/value pair // 每个键值对需要的 bytes
 hitprobe    = # of entries to check when looking up a present key
 missprobe   = # of entries to check when looking up an absent key
```

```go
// Maximum average load of a bucket that triggers growth is 6.5.
// Represent as loadFactorNum/loadFactorDen, to allow integer math.
loadFactorNum = 13
loadFactorDen = 2


// overLoadFactor reports whether count items placed in 1<<B buckets is over loadFactor.
// 判断是否大于负载因子
func overLoadFactor(count int, B uint8) bool {
	return count > bucketCnt && uintptr(count) > loadFactorNum*(bucketShift(B)/loadFactorDen)
}

func hashGrow(t *maptype, h *hmap) {
	// If we've hit the load factor, get bigger.
	// Otherwise, there are too many overflow buckets,
	// so keep the same number of buckets and "grow" laterally.
	bigger := uint8(1)
	if !overLoadFactor(h.count+1, h.B) {
		bigger = 0
		h.flags |= sameSizeGrow
	}
	oldbuckets := h.buckets
	newbuckets, nextOverflow := makeBucketArray(t, h.B+bigger, nil)

	flags := h.flags &^ (iterator | oldIterator)
	if h.flags&iterator != 0 {
		flags |= oldIterator
	}
	// commit the grow (atomic wrt gc)
	h.B += bigger
	h.flags = flags
	h.oldbuckets = oldbuckets
	h.buckets = newbuckets
	h.nevacuate = 0
	h.noverflow = 0

	if h.extra != nil && h.extra.overflow != nil {
		// Promote current overflow buckets to the old generation.
		if h.extra.oldoverflow != nil {
			throw("oldoverflow is not nil")
		}
		h.extra.oldoverflow = h.extra.overflow
		h.extra.overflow = nil
	}
	if nextOverflow != nil {
		if h.extra == nil {
			h.extra = new(mapextra)
		}
		h.extra.nextOverflow = nextOverflow
	}

	// the actual copying of the hash table data is done incrementally
	// by growWork() and evacuate().
}
```





### painc 捕获

有一些非 error 的捕获比较困难,我们会写出如下代码,又臭又长

```go
func (this *Controller) Search(ctx *gin.Context) {
	type param struct {
		Name   string `form:"name"`
		Email  string `form:"email"`
		Status string `form:"status"`
		Limit  int    `form:"limit"`
		Offset int    `form:"offset"`
	}
	par := param{}
	err := ctx.BindQuery(&par)
	if err != nil {
		ctx.JSON(http.StatusOK, Resp.ErrorOf(err))
	}
	if par.Limit == 0 {
		par.Limit = 10
	}
	xxx,err := this.xxx.Search(par.Name, par.Email, par.Status, par.Limit, par.Offset)
	if err != nil {
		ctx.JSON(http.StatusOK, Resp.ErrorOf(err))
	} else {
		ctx.JSON(http.StatusOK, Resp.OkOf(xx))
	}
}
```

这个时候就可以用 defer 进行全局的异常处理,这个两个异常可能看不出特别明显的点,但如果非常多的异常,这种方式就显得尤为有效,但这种方式也有其弊端就是,对于显式声明的异常不可以进行处理,所以需要层层 panic 用于 catch 

```go
func (this *Controller) Search(ctx *gin.Context) {
  defer func(){
      if err:=recover();err!=nil{
          ctx.JSON(http.StatusOK, Resp.ErrorOf(err))
			}
  }()
  
	type param struct {
		Name   string `form:"name"`
		Email  string `form:"email"`
		Status string `form:"status"`
		Limit  int    `form:"limit"`
		Offset int    `form:"offset"`
	}
	par := param{}
	err := ctx.BindQuery(&par) // 这里抛出了异常不会执行上面的值
	if par.Limit == 0 {
		par.Limit = 10
	}
	xxx,err := this.xxx.Search(par.Name, par.Email, par.Status, par.Limit, par.Offset) // 这里也是
	ctx.JSON(http.StatusOK, Resp.OkOf(xx))
}
```



### go.mod 与依赖管理

如同 pom.xml 一样是 go 的依赖管理文件,在1.6时可以使用 vender 进行管理,任何一个 https 可到达的目录即可使用 go get 进行拉取到本地的 GOPATH `go env GOPATH` 中.

```go
import (
	"github.com/gin-gonic/gin"
	"net/http"
)
```

`go mod tidy` 用于完成 `maven clean install` 的功能.

- 在新建项目的时候 `go mod init [packageName]`
- `go get -u []` 
- `go mod tidy`

go 的包管理官方采用 go.mod 文件,结束了之前用 vender goroot gopath 的混乱局面.



### go文档查看

```shell
(base) ➜  ~ go doc unsafe
package unsafe // import "unsafe"

Package unsafe contains operations that step around the type safety of Go
programs.

Packages that import unsafe may be non-portable and are not protected by the
Go 1 compatibility guidelines.

func Alignof(x ArbitraryType) uintptr
func Offsetof(x ArbitraryType) uintptr
func Sizeof(x ArbitraryType) uintptr
type ArbitraryType int
type Pointer *ArbitraryType
```



## 工具包

### time

```go
import "time"

func main() {
	fmt.Println(time.Now())
	fmt.Println(time.Now().UTC())
	fmt.Println(time.Now().Unix())
  fmt.Println(time.Now().Year())
  
  fmt.Println(time.Now().Add(time.Hour * 24)) // Sub
  fmt.Println(ttime.Now().Before(time.Now())) // After
}
```

定时调度,本质上是个通道

```go
ticker := time.Tick(time.Second) //定义一个1秒间隔的定时器
for i := range ticker {
  fmt.Println(i) //每秒都会执行的任务
}
```

### regexp

```go
func main() {
	regex := regexp.MustCompile("[0-9]*")
	fmt.Printf("%s",regex.Find([]byte("123as23")))
	//fmt.Print(regex.FindAllString("12321",-1))
}
```

### strings

保存字符串处理的类库,用的比较多的方法

-   Join
-   Split
-   Replace

### http

```go
func GetBody(url string) string {
	res, _ := http.Get(url)
	r, _ := ioutil.ReadAll(res.Body)
	res.Body.Close()
	return string(r)
}
```



### gin

go 的 web 框架,

#### gin.H

`gin.H`本质是 `map[string]interface{}`.下面两句语句等价

```go
c.JSON(http.StatusOK, gin.H{ "status": "登录成功"})
```

```go
c.JSON(http.StatusOK, map[string]interface{}{ "status": "登录成功"})
```

#### demo

```go
func InitRouter() *gin.Engine {
	r := gin.New()
	r.GET("/", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, &map[string]string{"status": "200", "msg": "pong"})
	})

	r.GET("/", service.DevController.Get) // implement Get Method
	r.DELETE("/:id", service.DevController.DeleteById)
	return r
}


func main() {
	r := router.InitRouter()
	err := r.Run(":" + conf.Config.Port)
	if err != nil {
		panic(err)
		return
	}
}
```

#### 获取参数

`c *gin.Context`

- `/user/:name`路径参数 `c.Param("name")` 

- `c.Query("name")` 获取请求参数 `c.QueryDefault("name","jerry")`

- `c.PostForm()`

- 通用获取方法,`BindWith`

    - 获取 body 中的 json

    ```go
    dev := model.Developer{}
    err := ctx.BindWith(&dev, binding.JSON)
    ```

    - 获取 body 中的 form 表单

    ```go
    dev := model.Developer{}
    err := ctx.BindWith(&dev, binding.Form)
    ```

    可选项有如下,功能相当强大,

    ```go
    var (
    	JSON          = jsonBinding{}
    	XML           = xmlBinding{}
    	Form          = formBinding{}
    	Query         = queryBinding{}
    	FormPost      = formPostBinding{}
    	FormMultipart = formMultipartBinding{}
    	ProtoBuf      = protobufBinding{}
    	MsgPack       = msgpackBinding{}
    	YAML          = yamlBinding{}
    	Uri           = uriBinding{}
    	Header        = headerBinding{}
    )
    ```


#### middleware

中间件并不是指第三方的中间件,而是指 controller 和 router 层之间的中间处理函数,我们可以如下方式指定中间件函数,比如上面的函数直接让没有token,token解析失败的请求嗝屁

```go
func Auth() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		token := ctx.GetHeader("Authorization")
		if "" == token {
			ctx.JSON(http.StatusForbidden, gin.H{"msg": "please login"})
			ctx.Abort() // 强制终止后续 ctx 传递流程
			return // 结束函数
		}
		claims, err := util.ParseToken(token)
		if err != nil {
			ctx.JSON(http.StatusForbidden, gin.H{"msg": "token forbidden"})
			ctx.Abort()
			return
		} else {
			ctx.Set("claims", claims)
		}
	}
}
// router
developer.GET("/", middleware.Auth(), service.DevController.Get)
```

### gorm

gorm 可以说是天坑中的坑其代码简直恶心,下面只说明基本操作和脚本级操作,不涉及工程操作

配置连接

```go
package db

import (
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
	"st-plugin-developer/conf"
	"time"
)

var Mysql *gorm.DB // 拿到了 db 对象就可以使用数据库了

func init() {
	var err error
	mysqlUrl := conf.Config.Mysql
	Mysql, err = gorm.Open("mysql", mysqlUrl)
	if err != nil {
		panic(err)
	}
	if conf.Config.Env != "prod" {
		Mysql.LogMode(true)
	}
	Mysql.DB().SetConnMaxLifetime(time.Minute * 3)
	Mysql.DB().SetMaxIdleConns(5)
	Mysql.DB().SetMaxOpenConns(20)

	if err != nil {
		panic(err)
	}
}

func CloseMysql() {
	if Mysql != nil {
		Mysql.Close()
	}
}
```

最常用的几个函数

-   Raw
-   Scan
-   First

```go
db.Table("").Select("*").Where("?", str).Scan(&pluginsInfo).Limit(limit).Offset(offset).Error

// in 语句 pkgs 是一字符串数组
db.Raw("select * from xx where xx=?  "+
		" and (xx,xx) in "+
		" (select xx,max(xx) from xxx "+
		" where xx=? and xx in (?) group by xx)", developer.Name, developer.Name, pkgs,
	).Scan(&pluginsVersion)
```

开启事务

```go
tx := this.Db.Begin()
for _, lang := range pluginLangs {
  if err := tx.Table("...").Save(&lang).Error; err != nil {
    tx.Rollback()
    return err
  }
}
if err := tx.Table("").Where("", str, str).Error; err != nil {
  tx.Rollback()
  return err
}
if err := tx.Table("").Where(str,str).Update(map).Error; err != nil {
  tx.Rollback()
  return err
}
tx.Commit()
```

