# Go

---

[TOC]

go语言,又叫 golang 是应对高并发场景下一种面向过程的语言.go 是一门静态强类型,编译型的语言.其语法和 c语言相近,但又有以下特性,内存安全,**GC**,结构形态,并发计算.同时 go 自身内嵌了 dict 数据结构.Go可以直接被编译为机器码,所以意味着其有极高的执行效率.**go天生支持并发,可以充分发挥多核优势**,其可以**内嵌c的代码**.go的用途

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







## 高级特性

### 类型转换

go 不支持隐式转换,其转换类型和 python 类型

```go
var num float64 = 3.0
int(num)

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

