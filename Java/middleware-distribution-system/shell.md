# shell

---

shell/bash是非常强大的linux命令交互语言 由C写成

操作shell相当于操作操作系统,shell的编程因为是联通c所以使用起来会比较类似命令语言

---

## 变量和for

1.  设置变量`b=3`

2.  使用变量 `echo $b` 使用变量的时候得加`$` 或者是用${b} 花括号用来识别边界

3.  循环和使用变量

    ```bash
    #!/bin/bash
    # 这是一个简单的for循环
    for skill in Ada Coffe Action Java
    do
        echo "I am good at ${skill} Script"
    done
    
    for filename in `ls /etc` # for filename in $(ls /etc);
    do
        echo "filename ${filename}"
    done
    ```

4.  更一般的循环

    ```shell
    for i in {1..100..2} # `seq 1 100 2`也可生成相同序列
    do
    	echo $i
    done
    
    # 双括号表达式在下面会有更详细说明
    for ((i=0;i<3;i++))
    do
    	echo $i
    done
    ```

    

## 字符串

1.  单引号的字符串全部原样输出 无法使用转义符
2.  双引号字符串输出 **可以存在变量 可以存在转义符**
3.  获取字符串长度 `${#str}` 可以获取字符串长度
4.  `${str:1:4}` 字符串切片
5.  字符串拼接 `$str1$str2`直接放一起就行
6.  ${var/pt1/pt2} 字符串第一个匹配pt1的替换pt2
7.  ${var//pt1/pt2} 字符串所有的匹配pt1的替换pt2

## 数组

1.  定义 array_name=(value0 value1 value2 value3)
2.  `${array_name[1]}` 下标从1开始
3.  全部元素 `${arr[@]}`或者`${arr[*]}` 
4.  获取数组长度 `${#arr[*]}`

## 脚本传参数

`$0` 表示第一个参数 `$1`表示第二个参数 (怎么又回来了?) 

## 简单计算

shell原生不支持计算不过可以通过命令实现，bash中增加了`(())`用于计算

-   `expr 2 + 2`  这之间的空格不能省略 按照命令的格式计算
-    `expr 2 \* 2` 这里需要注意转义符才能正确计算
-   `expr` 表达式不能用于多重的 \` ......\` 嵌套，反引号只能执行一次 
-   `(())`只是用来扩展for,while,if 其他语句一般无法作为返回值使用
-   如果要作为返回值 $((3+3))可以取得表达式的值
-   `(())`可以进行赋值等c语言的语法操作,而且其**支持嵌套**

```shell
i=3
((i++))
echo $i # 4 上面可以进行赋值
echo $(($i+$(($i + 1)))) # 7 支持嵌套
```

## if判断

if和for是编程中最重要的东西我们这里说明几种运算符的使用等

`-eq -ne -lt -gt -le -ge` 表示常用的几种运算符 只能用于比较整数

`== !=` 用于比较字符串 原生的bash 

```shell
# if 和 运算符
if [ $a == $b ] # if [ $a -eq $b ]
then
   echo `expr $a $b`
fi

if [ $a != $b ] # if [ $a -ne $b ]
then
   echo `expr $a $b`
fi

if [ $a -lt $b ] # -gt -ge -le
then
   echo `expr $a $b`
fi

# if else
if [ $a -eq $b ]
then
		echo "a=b"
elif [ $a \> $b ]
then
		echo "a>b"
else
		echo "else"
fi

# 类c语法
if ((i<3))
then echo $i
else echo $i+1
```

## 函数

函数是任何一个脚本语言的核心

```shell
# 定义函数的三种方式 return 只能返回0-255的值
function f1(){ return 1}
function f1{ return 1}
f1(){ return 1}

f1 one two # 调用函数传入参数
```

函数接受参数的方法

```shell
$0 # 脚本名字
$1 # 传入的第一个参数
$@ # 传入的所有参数(封装成数组) 其封装成 $1\n$2\n$3\n...这种形式
$* # 和上面基本相同 其封装成 $1 $2 $3...这种形式
$# # 参数个数
$? # 上一条命令的执行状态 大部分命令执行成功返回0失败返回1 或者是返回值
```

这个返回值并不好取得 一般是使用echo当成return语句 如果不是的话需要用$?来获取返回值

```shell
f1(){
	echo $1
}
f1 one # 输出one

f2(){
	return $1;
}
f2 233 # 无反应
echo $? # 输出233
f2 one # 无反应
echo $? # 无输出,因为其只能输出有上限的整数
```

所以看上面的结果 推荐使用echo去代替return 用于对程序完成更好的解耦合效果

### 例子

阶乘

```shell
#!/bin/bash
mut(){
	if [[ $# != 1 ]]
	then
		echo "-1"
	else
		res=1
		for ((i=1;i<=$1;i++)){
			((res*=$i)) # (())赋值
		}
		echo $res
	fi
}
mut $*
```

斐波那契数组

```shell
#!/bin/bash
fib(){
	if [[ $# != 1 ]]
	then
		echo "-1"
	else
		a=1
		b=1
		res="1 1 "
		for((i=0;i<$1-2;i++)){ # (()) 转for
			tmp=$b;
			b=$(($a+$b)) # $(())取计算的值
			a=$tmp
			res=$res"$b " # 字符串拼接
		}
		echo $res
	fi
}
fib $*
```

## case

```shell
#!/bin/bash
while :
do
    echo -n "输入 1 到 5 之间的数字:"
    read aNum
    case $aNum in
        1|2|3|4|5) echo "你输入的数字为 $aNum!"
        ;;
        -1) echo "oh上帝,你输入了-1"
        ;;
        *) echo "你输入的数字不是 1 到 5 之间的! 游戏结束"
            break
        ;;
    esac
done
```



## 包含文件

>   `. filename`   # 注意点号(.)和文件名中间有一空格
>   `source filename`
>
>   `. ./test1.sh` 引入相对路径的文件 等价于 `source ./test1.sh`

source命令或者.就可以引入文件,这种引入可以引入函数和变量

## shell中各种括号

-   `()` 1.命令组 2.等价于\` \`用于命令替换 3.初始化数组
-   `(())` 1.计算扩展 `$(())`可以拿到计算结果 2.扩展if,for,while 3.转换进制`$((16#0cff)`
-   `[]` 1.bash内部命令 等同于test命令 2.参与正则 3.参与array索引
-   `[[]]` 扩展`[]`更适用于命令判断 
    1.  `[[ hello == hell? ]]`支持正则
    2.  支持参数扩展和命令替换
    3.  `[[ $a != 1 && $a != 2 ]]` 等价于 `if [ $a -ne 1] && [ $a != 2 ]`和 `if [ $a -ne 1 -a $a != 2 ]` 显然可以避免很多逻辑判断的错误
-   `{}` 
    1.  整数或字母扩展 {1..10} {a..b} {1,2,3} {a,c}
    2.  特殊的替换结构 `${var:-str}` 等价于 ```python: var if var else str``` 空替换 检查是否有变量
    3.  `${var:+str}` 等价于  ```python: var if !var else str`` 非空替换
    4.  `${var:?str}` 和 `${var:-str}` 基本一致 不同的是不是替换而是报str错

## 匹配模式

>   \# 是去掉左边(在键盘上#在\$之左边)
>   % 是去掉右边(在键盘上%在\$之右边)
>   \#和%中的单一符号是最小匹配，两个相同符号是最大匹配。

例子```${var%pattern},${var%%pattern},${var#pattern},${var##pattern}```

1.  ```${var%pattern}``` 从var右边开始去掉最短的pattern
2.  ```${var%%pattern}``` 从var右边开始去掉最长的pattern
3.  ```${var#pattern}``` 从var左边开始去掉最短的pattern
4.  ```${var##pattern}``` 从var左边开始去掉最宠的pattern

## 强大的命令

shell的强大在于他能够通过操作系统的层次去完成很多函数完成的工作，一般是充当于启动或是结束程序的逻辑编写。因为程序启动时不一定能调度到需要的资源，这个时候就需要shell去作为操作系统调度的周转。

[详细的后续会补充]

awk

curl

