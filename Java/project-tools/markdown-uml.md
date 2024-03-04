# simple uml in markdown

---

[TOC]

## uml 简介

---

Unified Modeling Language 是一种建模语言 对流程图 时序图等都有相应的规范

包括 用例图 流程图 序列图 状态图

而markdown对 uml提供了简单的支持 踢狗sequence和flow的支持

## sequence 图

---

sequence语言 用于画序列图 如下

时序图的书写 markdown有天然优势 

```sequence
title: javaee+vue技术架构简单示意图
participant mysql
participant SpringMVC
participant vue/axios 
participant ElmentUI
# 创建序列柱子

vue/axios->SpringMVC:[sync] url-request
SpringMVC->mysql:[sync] mybatis access database
mysql-->SpringMVC:[sync] return data object
SpringMVC->SpringMVC:reduce data
SpringMVC-->vue/axios:[sync]response
vue/axios->vue/axios:render element-ui object
# 画线

note left of mysql: INNODB ENGINE
note left of SpringMVC:c3p0/druid
note right of SpringMVC:fastjson
note over SpringMVC:spring-base
# 注释
```

## flow图

---

流程图的重要性不必多说 是逻辑判断的主要刻画方式

后续而言 只用于表达逻辑思维就好 程序流程图基本GG

cond条件块 和 para 并行块能有第二个参数 top bottom left right 指定方向

para 第一个参数写path1 path2 path3

```flow
st=>start: Start
e=>end
op1=>operation: 操作
sub1=>subroutine: 子路线
cond=>condition: Yes or No?
io=>inputoutput: 输出
para=>parallel: 并行操作块

st->op1->cond
cond(yes)->io->e
cond(no)->para
para(path1, right)->sub1(right)
para(path2, top)->op1
para(path3, bottom)->io
```

以上的图是github的官方例子 下面演示一个循环的简单例子

```flow
st=>start: 开始
end=>end: 结束
if1=>condition: if i < 10:
print=>inputoutput: print(i)
op1=>operation: i+=1
op3=>inputoutput: save(i)

st->if1
if1(yes)->print->op1->if1
if1(no)->op3->end
```

呵呵 渲染引擎bug挺多的 简单任务还可 重度任务GG 

