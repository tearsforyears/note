# lua

---

[TOC]

我学 lua 的目的有两个,redis/nginx 的原子性脚本,饥荒mod.一种脚本语言

## basic

### snippet

```shell
brew install lua
```

```shell
lua
```

```lua
print("hello world") -- 一行注释
```

```lua
print(a) -- nil
a=10
print(a) -- 10
print("b".."a") -- 字符串连接符使用 ..
```

### 数据类型

- nil
- boolean false true
- number 可以表示浮点和普通数
- string "333"
- function 由 c 或者 lua 编写的函数
- userdata 存储在变量中的 c 的数据结构
- thread
- table 关联数组,和 hash 表类似,也可以当做 array 使用

看下面的代码段

```lua
-- 遍历数组
tab1 = {1,2,3}

for i=1,#tab1 do -- #tab1 代表长度,顺带一提 # 也可以用来计算字符串的长度
  print(tab1[i])
end
-- 遍历 dict
tab1 = {key1="val1",key2="val2"}
for k, v in pairs(tab1) do                                                        
  print(k .. " - " .. v)
end

-- 混合一下
tab1 = {"val0", key1 = "val1", key2 = "val2", "val3" ,"val4"}
for k, v in pairs(tab1) do                                                        
  print(k .. " - " .. v)
end
--[[
1 - val0 // 反人类的点来了,lua 的数组是从 1 开始的,可以指定为 0,后续更详细说明
2 - val3
3 - val4
key2 - val2
key1 - val1
]]--
```

Nil 的比较

```lua
> nil == nil
true
> nil == "nil"
false
> type(a) == "nil"
true
> type(a) == nil
false
> type(a)
nil
```

### 作用域

```lua
a = 5               -- 全局变量
local b = 5         -- 局部变量

function joke()
    c = 5           -- 全局变量
    local d = 6     -- 局部变量
end

joke()
print(c,d)          --> 5 nil

do
    local a = 6     -- 局部变量
    b = 6           -- 对局部变量重新赋值
    print(a,b);     --> 6 6
end

print(a,b)      --> 5 6

```



### function

```lua
function fib(n)
    if n == 0 or n == 1 then
        return 1
    else
        return fib(n - 2) +fib(n - 1)
    end
end
```



### if

```lua
if i > 1 then
  print(i)
elseif i~=0 and i<-1 then -- 这不等号太烦人类了,可以使用 not and or
  print(-i)
else
  print(0)
end
```



### for

从上面的例子中我们基本可以看到 for 如何使用的,其几种写法如下

```lua
for i=1,#tab1 do -- #tab1 代表长度
  print(tab1[i])
end

for i=1,10,2 do
  print(i) -- 1,3,5,7,9
end

for k, v in pairs(tab1) do                                                        
  print(k .. " - " .. v)
end
```



### while

```lua
while (true) do
  print(1)
end

repeat
  print(1)
until(false)
```



### 关联数组

```lua
-- 调用上和js类似
a = {a="1"}
a.a -- 当索引是关联数组的列的时候可以这么写
```

有了上面工具足够让我们写一个简单的脚本去操作 redis,遇到不会的操作在进行查询即可



## redis

redis 中的 lua 命令

- EVAL
- EVALSHA
- SCRIPT LOAD - SCRIPT EXISTS
- SCRIPT FLUSH
- SCRIPT KILL

### EVAL

- eval 执行 lua 脚本,传过去的参数可以通过 keys 接收,返回的是个字符串
- `EVAL script numkeys key [key …] arg [arg …]`

```shell
> EVAL "return KEYS[1]" 3 keys K A 
"keys" # 这个 3 表示后面根几个key
> EVAL "return KEYS[0]" 3 keys K A
(nil)
> EVAL "return KEYS[2]" 3 keys K A
"K"
> EVAL "return KEYS[3]..ARGV[1]" 3 keys K A bbb
"Abbb" # 后续的参数为 ARGV 中可以获取
> EVAL "return ARGV[1]..ARGV[2]" 0 keys K A bbb
"keysK"
```

- 返回多个值

```shell
> EVAL "return {'1','2','3',KEYS[1]+KEYS[2]}" 2 2 3 # 求了下和
1
2
3
5
```

### CALL

该函数或指令用于执行 redis 原生函数,配合上面参数传递的执行

```shell
eval "return redis.call('get', ARGV[1])" 0 aaa
```

下面我们就不赘述其包装直接以lua的形式呈现

```lua
for i=0,5 do
  redis.call('set','prefix:'..tostring(i),i);
  redis.call('expired','prefix:'..tostring(i),i*10);
end 
return 1
```

压缩下

```shell
eval "for i=0,5 do redis.call('set','prefix:'..tostring(i),i);redis.call('expired','prefix:'..tostring(i),i*10);end return 1" 0
```

至此基本操作 redis lua 脚本的方法结束

除了上面的形式,我们也可以用lua脚本文件去执行

```shell
redis-cli -h xxxxxxx --eval ./Redis_CompareAndSet.lua userName , zhangsan lisi 
```

lua 的使用大大提高了 redis 的使用上限,其最重要的功能便是原子性的使用,我们看在Java中如何执行该脚本

```java
DefaultRedisScript<String> script = new DefaultRedisScript<>();
script.setResultType(String.class);
script.setScriptText("return KEYS[1]");
script.getSha1();
List<String> keys = new ArrayList<>();
keys.add("key1");
keys.add("key2");
String res = redisTemplate.execute(script, keys, "10");
return res;
```

