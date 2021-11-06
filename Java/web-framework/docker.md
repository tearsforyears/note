Docker

[TOC]

## 重建docker安装的软件

-   redis
-   rabbitmq
-   nginx
-   mysql
-   alpine(小型基础命令行)
-   centos

## 概述

---

**Docker 属于 Linux 容器的一种封装，提供简单易用的容器使用接口。**

docker上可以运行tomcat mysql 其启动十分迅速 是轻量级的虚拟机

docker的隔离性稍弱属于进程性的隔离而一般虚拟机是系统上的隔离

Docker在Dockerfile上编写了容器的构造过程易于集群分发和部署

docker本质上是个可供web容器运行的**容器(Container)** 是一个虚拟机

其核心配置文件为**Dockerfile**,核心环境是**镜像(Image)**

其和git类似 都有着**仓库(Repository)**可以push和pull**镜像(Image)**

也可以操作tar文件进行load和save**镜像(Image)**

而通过镜像去run的程序称为一个容器可以通过commit编程镜像

其全部采用Restful的方式去进行网络通信

## 架构

---

![架构](https://www.runoob.com/wp-content/uploads/2016/04/576507-docker1.png)

这是docker的软件架构 关于容器和镜像关系可以上图表示 我们看下相对于操作系统的架构

这是普通虚拟机的架构

![应用运行](https://upload-images.jianshu.io/upload_images/12979420-15eaabb27b008ce1)

INFRASTRUCTURE: 基础设施 即运行docker的服务器等 上一层就是操作系统

HYPERVISOR: 这是虚拟机管理系统工具.利用Hypervisor,可以在主操作系统之上运行多个不同的从操作系统.类型1的Hypervisor有支持MacOS的HyperKit,支持Windows的Hyper-V以及支持Linux的KVM.类型2的Hypervisor有VirtualBox和VMWare 我们平时运行的环境则是HyperKit这类型的.

而如果一个组件就需要一个GUEST OS将会有大量内存开销,所以docker在隔离的时候使用下面的架构

![隔离架构](https://upload-images.jianshu.io/upload_images/12979420-005836e6ff3e6b39)

容器内装的如果是组件的话 一般不是完整的操作系统(完整的也行) 正是这一点大大降低组件的成本

---

## network

docker的网络是建立在Linux网路技术之上的,docker在启动时创建自己的虚拟网桥docker0,所有的容器可以通过该网桥和外部网络发生交互。

### NameSpace

linux内核提供,可以保证各个namespace就是各个沙箱,互相隔离

`ip netns`可以完成对namespace的各种操作

**对于每个namespace来说有自己独立的网卡、路由表、ARP 表、iptables**

### veth

veth属于可在namespace下转移的网络设备

### veth pair

这个是为了让两个veth在不同的namespace下完成通信的端口

![](https://upload-images.jianshu.io/upload_images/13618762-2aa4565233659af8.png)

如下可以在不同的命名空间下完成两个veth的通信

### bridge

veth pair只能完成两个端口间的通信，而bridge则是要完成两个namespace的通信

这个技术类似于虚拟交换机位于网络第二层专门用于转发，其基于MAC地址进行转发

`brctl` 该命令可以操作网桥

---

docker的网络在大规模使用docker的时候十分重要因为我们一般使用的是端口映射而真实的项目需要独立的ip地址(局域网也行) 容器内部都是由独立的虚拟网卡存在的

docker在启动时会创建一个docker0的虚拟网桥(mac还多了层虚拟机),并给docker0分配IP地址称为`Container-IP`,容器间可以通过Container-IP所在的网桥进行通信，而外部设备是不能找到docker0这个虚拟网桥的，如果外界需要访问得开启端口映射`-p -P`来指定映射的端口

### 网络模式

### **host**

使用宿主机网络ip 端口等 如下我们可以看到主机网卡和虚拟机网卡平级

`本质上是和宿主机共享namespace` 

![](https://pic002.cnblogs.com/images/2012/355296/2012040618213770.png)

这样子当我们真正访问路由的时候虚拟机之间就可以互相通信了

***在mac中docker运行在一个linux虚拟机上并没有docker0网桥(准确的说是连接到了虚拟机的docker0网桥上而外界无法对这个机子进行交互(docker-machine自己建的机子除外))所有不能使用host模式 一个大坑***

---

### **bridge**

默认连接到的网络 桥接模式

桥接模式相当于使用一个虚拟网桥(交换机)去抽象虚拟设备的网卡到同一局域网下

![](https://pic002.cnblogs.com/images/2012/355296/2012040618211860.png)

所以容器之间不能够互相通信 我们主机也不能直接访问(直接访问走主机网卡上方路由)

none:关闭网络

nat:网络地址转换模式(docker没有不多赘述)

---

### Container(docker特有)

所有容器会共享一个指定容器的ip和端口范围,并不会有自己的虚拟网卡.

容器和另外一个容器共享Network namespace,kubernetes中的pod就是多个容器共享一个namespace.

![](https://upload-images.jianshu.io/upload_images/13618762-790a69a562a5b358.png)

这个作用就是共享容器的网段,即是说,k8s也是利用此特性去创建了一众容器

---

###  none(docker特有)

容器拥有独立的namespace，但并没有进行其他的设置

---

### docker网络内部转发

实际上在docker中转发更为复杂

桥接模式转发

![](https://upload-images.jianshu.io/upload_images/7298148-659bfb4ab12f7fdc.png)

中间这个docker0是damon线程的虚拟交换机地址

host模式相对简单因为其网卡接口在运行docker的主机上

## demo

配置镜像

```json
{
 "registry-mirrors":
  ["http://hub-mirror.c.163.com",
   "https://3laho3y3.mirror.aliyuncs.com",
   "https://reg-mirror.qiniu.com/"],
  "experimental": false,
  "debug": true
}
```

安装mysql映射到3307端口 

1.docker pull mysql # 可以指定版本 mysql:5.7 默认最新

2.docker images # 查看装好没

3.docker run -p 3307:3306 --name mysql -e MYSQL_ROOT_PASSWORD=123456 -d mysql # navicat能连上了 这里的配置参数-e 是代表传递环境变量的意思

4.docker ps

4.docker rm -f {id} # 退出docker

大大简化了配置的过程啊 牛逼

---

配置centos并使用shell命令行

1.docker pull centos

2.docker run -d -i centos # -i 是即使不进入命令行或者不调用也不会shutdown process

3.docker exec -it {id} bash # 进入命令行

## 常用指令

```shell
docker pull nginx # 类似git pull 
docker pull mysql 

docker images # 查看本地镜像
docker ps # 查看本地运行的容器

docker rm -f {id} # 删除容器
docker rmi {id} # 删除镜像

docker run -i -d -p 81:80 nginx # -d 是后台运行 -p 是指定内外端口映射
# 81 是外部端口 80 是内部端口
docker exec -it {id} bash # 进入容器的bash

# 构建相关命令
docker build -t {镜像名} . 
# .代表当前目录下的Dockerfile文件 使用dockerfile去创建镜像
docker save {镜像名}>1.tar # 保存成tar文件
docker commit {容器名} {镜像名}# 保存成镜像

docker logs {id} # 这个很有用 可以查看对应配置等一些文件的位置 巨好用
docker inspect {id} | grep "IPAddress" # 查看容器的ip 一般会使用端口映射

docker rm {id} # 停止镜像
```

docker有自己类似github的社区可以把镜像上传到此[docker](https://www.docker.com)

内置端口映射特别好用 能基本隔离普通组件和代码运行环境

## 集群创建相关工具

![相关命令](https://dl.iteye.com/upload/picture/pic/137199/7dae6c9a-a506-3bde-8ef6-893793134eb7.png)

### Dockerfile

从已知镜像中定制 我们用的核心指令是build 和 save

```dockerfile
FROM nginx # 基于nginx创建定制化镜像
RUN echo '这是一个本地构建的nginx镜像' > /usr/share/nginx/html/index.html
# 执行命令行
```

RUN指令得写成如下形式 要不会创建三层镜像使得系统臃肿

```dockerfile
FROM centos
RUN yum install wget
RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz"
RUN tar -xvf redis.tar.gz

# 以上执行会创建 3 层镜像。可简化为以下格式：&& 连接起来
FROM centos
RUN yum install wget \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
    && tar -xvf redis.tar.gz
```

创建镜像

```shell
docker build -t nginx:test . 
# 会把.下的文件打包发送给docker引擎 所以不要放多余的文件 假设当前目录有home.txt
# .称为上下文路径 
```

COPY指令 #add指令同样可以做到但是官方推荐用copy

```dockerfile
COPY hom* /mydir/ # 可以把上下文路径中的文件复制到容器指定文件夹
COPY hom?.txt /mydir/
```

MAINTANER 维护者信息 

```dockerfile
MAINTAINER tearsforyears <1027664894@qq.com>
```

ENV 设置环境变量

```dockerfile
ENV JAVA_HOME /usr/bin/java
```

CMD指令

和RUN唯一的不同就是RUN是在build的时候执行的CMD在docker run的时候执行

### Compose

用于定义多容器运行的组件

定义好docker-compose.yml执行docker-compose up # 后续用到时补充

### Docker Machine

在虚拟机上安装docker 也可以集中管理所有docker主机 比如给100台服务器安装docker

## 实例

1.部署RabbitMQ

```shell
docker pull rabbitmq:management
docker run -d --hostname my-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:management
```

然后访问127.0.0.1:15672 用户名和密码都是guest 就可以使用队列了

2.找到docker所有容器的ip

```shell
docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)
```

