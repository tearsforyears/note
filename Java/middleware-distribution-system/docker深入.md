# docker 高级

以下主要是docker在devops和springcloud集成下的各种使用技术，关于docker基础架构和简介请专向docker.md文件,docker技术其实除了和微服务之外还有devops紧密联系在一起,所以docker的原理和使用方法还有一部分linux和运维的元素在里面下面会一一说明

---

## docker engine常用指令

```shell
docker pull nginx # 类似git pull 
docker pull mysql 

docker images # 查看本地镜像
docker ps # 查看本地运行的容器

docker rm -f {id} # 删除容器
docker rmi {id} # 删除镜像

docker run -i -d -p 81:80 nginx # -d 是后台运行 -p 是指定内外端口映射 本地81端口容器端口
docker run -i -d -p 5000:5000 centos python app.py # 可以跟着执行的命令
# 81 是外部端口 80 是内部端口
docker exec -it {id} bash # 进入容器的bash bash表示执行的命令也可以写成/bin/bash

# 查看运行日志
docker logs -f {id}


# 构建相关命令
docker build -t {imageName}:{versionName} . # 后面的点是基于该目录下的Dockerfile进行构建

# .代表当前目录下的Dockerfile文件 使用dockerfile去创建镜像
docker save {镜像名}>1.tar # 保存成tar文件
docker commit {容器名} {镜像名}# 保存成镜像

docker logs {id} # 这个很有用 可以查看对应配置等一些文件的位置 巨好用
docker inspect {id} | grep "IPAddress" # 查看容器的ip 一般会使用端口映射

docker rm {id} # 停止镜像
```

### `docker build -t {imageName}:{versionName} {runDir}`

## linux知识补充

因为linux是docker构建的基础,所以了解linux本身的知识对了解docker有很大帮助,像前面的docker网络已经很好的说明了这一点

>   ### 关于进程fork和系统进程初始化。
>
>   fork应该挺好理解的在c中fork()表示多创建一个`进程(资源不共享)`从调用语句往下分叉执行,通过fork的返回值可以判断当前上下文是父进程还是子进程。子进程是会fork出孙子进程的,所以在循环中的进程数就以$2^n$的形式增长
>
>   系统进程初始化即 0号进程,1号进程,2号进程
>
>   0号进程为idle进程,不参与CPU调度,是linux系统的第一个进程,不由fork产生,一个核心有一个消息队列,所以每个核心产生一个idle进程. 另外idle进程不接受CPU调度,调度机轮空的时候就会指向该进程,该进程可以认为是系统空闲,该进程的pid=0. 0号进程在完成内核初始化之后通过kernel_thread去创建init进程
>
>   1号进程 init进程,完成系统的初始化,是系统所有进程的祖先进程.当其在内核空间初始化完之后,加载init程序,init进程变成守护进程监视其他进程.
>
>   2号进程 kthreadd进程,是由idle进程创建的,其始终运行在内核空间,其始终运行在内核空间负责内核的线程调度.
>
>   liunx的简单启动,BIOS加电自检载入MBR中的引导程序LILO/GRUB,加载linux内核引导进程初始化.
>
>   ### linux文件系统
>
>   linux要运行的话至少需要两个文件系统
>
>   bootfs (boot file system) 启动文件系统包含boot loader和kernel,整个文件系统会被加载到内核空间,此时这个文件系统会卸载掉(即用户看不到挂载)
>
>   rootfs (root file system) 包含了 /dev, /proc, /bin, /etc, /lib, /usr, /tmp和运行系统所需要的二进制代码和库文件
>
>   ### liunx启动过程
>
>   待后续
>
>   ### linux运维命令相关
>
>   `df -h`查看磁盘整体大小使用情况
>
>   `du -h` 查看当前目录下各个文件的大小
>
>   `du -sh`查看当前目录下所有文件总大小 
>
>   `top` 动态查看进程
>
>   `nc -zv`检查端口是否启动 部分linux需要安装netcat
>
>   ### awk
>
>   这个命令是一个非常强大的文档流处理工具,可以以文件进行分割和操作或echo进行操作其函数的本质有点类似要你编写一段脚本去传给一个map函数处理 以下代码逻辑等效
>
>   ```shell
>   awk '{print hell}' {fileName} 
>   ```
>
>   ```python
>   map(lambda line: print('hell'),fileContent)
>   ```
>
>   awk可以进行行分割和列分割支持和c同样的格式,其基本分割方式也非常简单
>
>   ```shell
>   (base) ➜  desktop awk '{print $1,$11}' ./2.txt
>   this
>   this
>   (base) ➜  desktop cat 2.txt
>   this is a test file for awk
>   this is line 2 of this file
>   (base) ➜  desktop awk '{print $1,$3}' ./2.txt
>   this a
>   this line
>   ```
>
>   其还有一些高级用法我们列举其中几个比较有用的
>
>   `-F '[ ,]'` 指定二级分隔符,先是空格然后是逗号,后面还可以通过内建变量达到同样的效果
>
>   ```shell
>   ps aux | awk -F '[ ]' '$1=="root" {print $2,$3,$4,$11}' 
>   # $1=="root" 加入判断恐怖如斯 且条件空格相间隔可组合
>   ```
>
>   2.txt
>
>   ```txt
>   this is a test file for awk
>   this,is,line,2,of,this,file
>   ```
>
>   ```shell
>   awk -F '[ ,]' '{print $1,$4}' 2.txt
>   ```
>
>   还有一些常见的awk脚本的内建变量
>
>   -   $n 分割的第几个字段
>   -   FNR/NR 行号 (从1开始)
>
>   我们来优化下`ps aux`的简单版本
>
>   ```shell
>   ps aux |grep $threadName | awk 'BEGIN{print "pid","cpu","memory","cmd";print "----------------------"} {print $2,$3,$4,$11}'
>   ```

## Dockerfile

Dockerfile是docker中最复杂的部分，其可以指定如何从原本的镜像中创建出要使用的镜像，一般而言我们不会过多使用原生镜像，因为我们会使用Dockerfile来配置自己所使用的哪些服务

Dockerfile分为以下几部分

-   FROM 从父镜像中创建
-   MAINTAINER 维护者信息
-   RUN,ENV,ADD,WORKDIR 等基本的镜像操作指令
-   CMD,ENTRYPOINT.USER 等启动docker容器的指令

先来看一个例子，如下Dockerfile文件

```dockerfile
# FROM centos
# RUN yum install wget
# RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz"
# RUN tar -xvf redis.tar.gz
# 以上执行会创建 3 层镜像 一般改写成 &&
FROM centos
RUN yum install wget \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
    && tar -xvf redis.tar.gz
```

`docker build -t {imagename}:{vername} {contextPath}` 可以用这种方法构建镜像contextPath是执行的上下文路径。这个执行的上下文路径是指本机路径一般指定为`.`这个意思是比如要打包当前路径的文件，如下打包。

```dockerfile
FROM nginx
# 指定工作路径
WORKDIR /usr/share/nginx/html
# 将前前路径下的所有文件都COPY到工作路径下
COPY . .
# EXPOSE 命令用来指定对外开放的端口,实际用处不大，可不写
EXPOSE 80
```

`docker build -tag {imagename}:{vername} {contextPath}` 可以不指定`vername`默认为lastest

下面介绍一些常见指令

### FROM

---

基于镜像构建新的镜像 比如FROM nginx



### RUN

---

执行命令,一般只写一次,写多次会创建多层镜像(多层一词的理解放在后文),如果要执行多条指令可以像上面一样用`&&`作为连接.RUN运行在docker虚拟机的层面,也就是镜像层面而非容器层面,每运行一次会多产生一层镜像.



### CMD

---

CMD和RUN是同样的运行命令的指令,不同的是,CMD只是作用于镜像启动之后(ENTRYPOINT之后). 而CMD是镜像容器启动之后.多个CMD指令只运行最后一个. 我们介绍两种指令的格式

-   exec模式 使用exec模式 CMD `["echo","hello"]` 则是要以容器1号进程的方式运行在容器内,且可以获得环境变量`CMD [ "sh", "-c", "echo $HOME" ]`
-   shell模式 `CMD top`则是以 `/bin/sh -c top`的形式运行在容器的1号进程中

CMD指令的使用一般还有一种使用方法为ENTRYPOINT提供默认参数 例如在写完了ENTRYPOINT指令之后`CMD ["param1","param2"]` 可以提供默认的参数



### ENTRYPOINT

---

ENTRYPOINT和CMD基本一致.其也有上面的两种格式,其作用也基本一致,我们来说说ENTRYPOINT的不同点. 相比于CMD我们可以通过上下文给ENTRYPOINT增加指令或者通过CMD给加参数都是可以的,或者是使用docker来增加指令

```dockerfile
FROM centos
ENTRYPOINT ["echo","1"]
CMD ["2"]
```

`docker run --rm {imagename} 3` 就会输出`1 2 3` 这些东西可以动态操控执行container的命令.这里还有个 --rm 是自定清理用户的文件 清理`/data`和`/volume`

**如果没有ENTRYPOINT或CMD那么程序会出问题,绝大多数镜像会有默认的CMD或ENTRYPOINT所以不会出问题,但如果是自己的镜像得至少有一个**

这里的entrypoint在后续的docker-compose中可以明白该进入点可以用于对于依赖启动的控制



### WORKDIR

---

指定工作路径 (如上) 其可以配合`RUN COPY CMD ENTRYPOINT`指令使用,一般 COPY会用的比较多或是默认使用的docker build也会用到WORKDIR。



### ENV

---

指定环境变量 `ENV {key} {value}` 或者`ENV {key}={value} {key}={value}` 



### COPY

---

copy指令比较简单一般配合WORKDIR使用 `COPY {originPath} {containerPath}`  

如果指定了WORKDIR,COPY指令在使用的时候就要写相对于WORKDIR的相对路径



### MAINTAINE

---

写维护者信息,可以不写,写的话如下的格式`MAINTAINER {author} {email_address}`，现已弃用LABEL指令可以代替



### LABEL

---

该指令和ENV指令格式一致,用来给镜像加入元数据信息,然后可以利用`docker image inspect --format='' {imageName}`来查看注入镜像中的元数据信息.



### EXPOSE

---

暴露和启用端口号 比如EXPOSE 80



### 其他指令

---

这里还有几个指令没有说,有机会的话可能会补上,但一般Dockerfile中用不到以下指令

-   ADD (和COPY类似)
-   STOPSIGNAL
-   USER
-   ONBUILD
-   VOLUME (下面会细说)

## VOLUME指令

VOLUME指令是Dockerfile里面的东西,之所以单独拿出来是因为其重要程度,我们先了解下其基本用法,VOLUME就是卷,所以这里是指令是挂载卷的意思,在`docker run -v` 我们也可指定挂载的卷。卷相当于各个镜像的**公共文件夹**,存放一些关键性的代码或者数据到这上面,而不用在镜像中写死或者是动态移入容器中。此指令能够实现容器对宿主机卷的挂载,其好处如下

-   避免容器过大,冗余过多,或是创建文件的时候所耗费的时间
-   重要数据,配置文件的可用性,防泄漏和重用等
-   多个容器共同访问的公共数据区

### docker文件系统

![](https://img-blog.csdnimg.cn/20181026140013192.png)

可以看到物理层的存储和Hadoop等采用的是一样的分割文件的方式,容器中也有虚拟的文件系统,其主要管理方式一个是数据卷Volume，另一个就是Storage Driver。根据不同的文件系统LVM(Linux Virtual Machine)会分配不同的文件系统。

所有的docker容器都共享bootfs,每个容器都独享rootfs,所有基础镜像都共享这种rootfs，上图中Aufs是一种文件系统常用于Ubuntu.device mapper类似常用于centos.Aufs支持跨设备存储,而device mapper不支持.

Docker中使用的是联合文件系统(ufs)简单来说就是把所有文件系统都加载,叠加在一起形成最后我们看到的文件系统.

而Data Volume能直接越过docker的文件系统访问宿主机的存储系统自然速度快。

### docker run -v挂载目录

我们先介绍docker run命令的-v参数该参数的作用就是把宿主机文件系统的文件挂载到docker容器上. `docker run --rm -it -v {hostDirPath}:/data {imageId}` 此命令可以把宿主机的目录挂载到容器的`/data`目录上,上面都是绝对路径,如果写相对路径的话,容器会报错,宿主机的相对路径则是相对**`/var/lib/docker/volumes/`**的路径与当前执行的路径无关.

-   我们可以使用**` docker inspect {containerId}`**命令去查看容器的挂载情况

这些隐性的目录挂载**`/var/lib/docker/volumes/`**的子文件夹中,这些个文件夹一般用于短暂存放数据,一般我们要自己指定挂载的卷会比较好.如果不指定的话docker为我们自动创建一个挂载目录,挂载的目录在宿主机**`/var/lib/docker/volumes/`**的子文件夹下,且此种文件不会随着容器的销毁而销毁.当然也可挂载单个文件,比如nginx.conf

`docker volume ls` 可以查看本地所有数据卷,

我们以redis.conf启动redis为例子先写好配置文件

 ```conf
# bind 127.0.0.1

protected-mode yes # 限制bending访问
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

daemonize no # 不在这里开启守护线程

loglevel notice
logfile ""

databases 16
always-show-logo yes

#   save <seconds> <changes>
save 900 1 # 900秒内改变1次就存
save 300 10 # 300秒内改变10次就存
save 60 10000 # 60秒内改变10000次就存
# 省略
 ```

执行docker命令`docker run -p 6379:6379 --name myredis -v /usr/local/docker/redis.conf:/etc/redis/redis.conf -v /usr/local/docker/data:/data -d redis redis-server /etc/redis/redis.conf`

上面的命令挂载`/data`和`redis.conf`文件到容器中并执行`redis-server /etc/redis/redis.conf`完成使用配置文件启动redis的过程.

### docker run --volumes-from

`docker run --volumes-from {containerId} {iamgeId}` 

--volumes-form是继承相应容器的数据卷,这个操作直接指向宿主机的文件,多代继承下不会因为继承链的断裂而失去挂载文件指向

### volume指令

从上面的铺垫再看volumn指令,其实是在容器初始化的时候把宿主机的目录装载在了容器的文件系统上。当container中有需要持久化的数据的时候我们应该在Dockerfile使用volume指令。

volume卷的本质只是声明了容器内一个需要持久化的目录,这样一来及时,即使运行时没有-v来指定数据卷,docker也会在**`/var/lib/docker/volumes`** 里面帮我们创建一个文件



## 镜像分层

镜像分层是个有意思的东西,其是提高docker image创建速度,减少体积的关键。Dockerfile的每条指令都会为镜像添加一个层。我们在每到下一层之前要清理不必要的文件,我们需要利用shell和docker的技巧去减小文件,以便从上一层获取只需要获取的文件。

docker不是按照层去存储镜像的,相同的镜像在本地只会存储一份

<img src="https://img-blog.csdn.net/20180524122124153" alt="width:100px height:100px" style="zoom:50%;" />

上面为一个简单的ubuntu的镜像,可以通过`docker history {imageName}`去查看镜像的创建,`--no-trunc`来看更详细的信息,或者可以直接查看docker的结构`docker save {imageName}>{imageName}.tar`可以查看镜像的各个层级。

层级之间是有依赖关系的,子镜像依赖父镜像创建,必须启动了更底层的镜像才能往上面启动镜像.需要注意的是这些镜像基于Dockerfile进行创建,但不是每条指令都会留下一层镜像,只有一些读写的镜像会留下layer且这些layer经过aufs之后能够轻易整合成最后我们看到的容器层。

这里提醒一点就是没有读写的指令layer一层为0不会显示出来,可以认为这层layer是空,不过有些说法是每一条指令会创建一个新的layer是来自于此。每次只需要存储基础的镜像即可。

指令如ADD,COPY,RUN等其因为修改了容器的文件系统,所以需要额外的layer,每一层的大小即为增加的文件大小,另外镜像大小不是容器大小,容器还包括一些虚拟文件。



## docker网络

docker的基础网关结构在之前的docker中已经有详细的叙述了，我们这里将基于mac的软件架构，docker的虚拟网桥来进行容器互联和相关网络技术介绍

```shell
docker network ls # 查看docker的所有网络情况

# 创建网络指定桥接模式
docker network create -d bridge test-net
# 查看创建的网络的信息
docker network inspect {networkName}

# 在创建容器时可以使用 --net {networkName}来指定网络
docker run -itd -p 80:80 --net {networdName} {imagesname}
# 把容器连接到网络
docker network connect {networkName} {containerId}
# 容器断网
docker network disconnect {networkName} {containerId}
```

这里需要指出修改域名可以通过修改`/etc/hostname`文件来修改局域网内能ping到的主机名，而`/etc/host`文件则担任一部分dns的工作去直接寻找ip地址。docker容器内能直接ping主机是因为在docker0网桥下即同一局域网。



## docker与集群

docker所构建集群中有三个很重要的东西docker-machine,swarm,docker-compose.这三个东西共同完成了集群基础环境的构建,而容器编排(Container Orchestration)机制等确保了集群的底层能够高效运行.

-   docker-machine 让用户在其他平台快速安装docker
-   swarm 让容器在集群的生产环境中高效运行,其为一集群管理工具
-   docker-compose 把容器配置成服务,定义那些容器组运行那些服务,支持动态扩展是微服务的核心.**其本质上就是把所有功能容器或服务容器关联了起来来完成一个服务**

下所用的配置格式大多都是yaml，这种格式类似层级结构的现代配置文件格式

![](http://static.oschina.net/uploads/img/201502/27102024_HaUY.png)

### docker-machine

docker-machine可以快速的让100台服务器安装上docker,并对其进行集群化管理.docker-machine可以管理本机子上的docker也可管理云服务的供应商,阿里云,腾讯云等.docker-machine可以对这些节点的docker进行管理,对docker创建的虚拟机进行管理.可以升级docker,或是配置docker客户端和本机的通信.

![](https://docs.docker.com/machine/img/machine.png)

上面便是docker-machine的架构,常规的docker架构是由`DOCKER CLIENT`通过`REST API`去访问本地的docker守护进程,像上面的图我们可以看到docker machine和docker engine的区别,docker machine是通过rest api去控制远程的docker daemon来创建和管理远程的虚拟机.docker-machine把这些环境同一叫做provider

docker-machine提供了很多各个云服务的驱动,但因为国内环境,docker-machine提供了一个Generic选项,通过ssh对docker进行安装,这个可以用于一些docker无法直接支持的ECS,docker会自动安装.下面我们以一个例子来说明docker-machine的安装流程

1.  首先申请一台ECS,调通好免密登录,本机装好docker engine和docker-machine(mac只需要安装好docker即可)
2.  `docker-machine create --driver generic --generic-ip-address=203.0.113.81 --generic-ssh-key ~/.ssh/id_rsa vm ` 在mac上执行此命令 最后的vm为主机的名字,docker会把主机的hostname改成vm 默认端口是2376可以参照docker文档改

我们下面来介绍下常见的操作

-   `docker-machine ls` 查看所有docker
-   `docker-machine create {hostname}` 创建docker主机
-   `docker-machine stop {hostname}` 停止主机
-   `docker-machine start {hostname}` 启动主机
-   `docker-machine ssh {hostname}` ssh远程连接主机
-   `docker-machine env {hostname}` 查看主机环境变量

docker-machine只是提供了一套远程管理docker主机的工具, 其本质上并无直接操控集群那般,但是对于远程注解安装docker是极为友好的



### ***docker-compose***

docker-compose是通过yaml的配置文件执行类似`docker run`或者`docker build`的效果,其目的是在于我们如果要启动多个容器使用shell脚本会显得过于臃肿,docker compose不是为了取代Dockerfile而是为了让容器运行起来的配置文件.

**docker-compose就是把所有服务(包括服务所在的容器)连起来的一个工具.**其主要是docker-compose.yml的写法以及后续swarm的使用,其启动命令和终止命令.

-   `docker-compose up ` 启动
-   `docker-compose down` 终止

docker-compose处理执行了若干启动命令之外,还帮我们进行了组网,运行`docker-compose up`之后我们使用`docker netword ls`可以看到前后之间多出来了一个桥接的网络,作为该组容器的启动网络加入其中.

docker-compose把所管理的容器分为三层

-   工程(project)
-   服务(service)
-   容器(container)

docker-compose.yml就是一个project,其中包含了多个服务,服务中有可能包含多个容器

#### 编写基本docker-compose.yml

这里我们简单说明下yaml这种格式,在springboot中也有使用到的配置格式

```yaml
### 标量就不在赘述的
### 基本操作
list: # 数组
 - item1
 - item2
list: [ item1, item2 ] # 行内写法

list1: [ [ item1, item2 ] ] # 多维数组
list1: 
 - 
  - item1
  - item2
# dict
json: { key:value, key1:value1 } # 行内
json: # 展开
 key: value
 key1: value1
# 用-来表示null
null_value: -
# 强制类型转换
num: !!str 123 # 强制转换为字符串即非数字

### 锚点
localhost: &host 127.0.0.1 # 取别名
urls: 
 host1: *host # 这个相当于把host的内容并入到urls里面
 host2: 192.168.0.1
# <<按照集合并入
url: &url 
 url: 127.0.0.1
 name: localhost
socket:
	<<: *url # 把url,name并入socket的dict中
	port: 6379
```

docker-compose的使用流程

-   定义好 `Dockerfile`用于构建镜像`docker build`
-   定义好`docker-compose.yml`用于images启动成容器
-   执行`docker-compose up`开启容器群
-   执行`docker-compose down`关闭容器群	

`docker-compose.yml`配置实例

```yaml
# yaml 配置实例
version: '3' # 从docker-compose的那个版本定制的
services: # 配置了web和redis两个服务
  web:
    build: .
    ports: # 配置web服务的端口映射
     - "5000:5000"
  redis: # redis 采用了下面image的镜像
    image: "redis:alpine"
```

`docker-compose up -d` 在同级下**按顺序运行**运行即可让docker启动一群容器即完成本机的容器编排的初级配置

```yaml
version: "3.7"
services:
  webapp:
    build: 
    # 这个build比较特殊 是代替docker build -t {} . 此命令
    # 也是指定 docker build中各种参数和镜像的一种写法
      context: ./dir # 运行Dockerfile的目录
      dockerfile: Dockerfile-alternate
      args:
        buildno: 1
      labels:
        - "com.example.description=Accounting webapp"
        - "com.example.department=Finance"
        - "com.example.label-with-empty-value"
      target: prod # 多层镜像指定构建在哪一层(后续会说明这个层)
```

除此之外在全局上还有一些可以配置的属性,我们通过如下官方示例文件说明

```yml
version: "3.8"
services:
  redis: # redis数据库
    image: redis:alpine
    ports:
      - "6379"
    networks:
      - frontend
    deploy: # 部署的一些信息 在swarm中被应用到 所以放到后续
      replicas: 2 # 两个副本
      update_config:
        parallelism: 2 # 并行数
        delay: 10s
      restart_policy:
        condition: on-failure

  db: # 持久化数据库
    image: postgres:9.4
    volumes: # 挂载
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    deploy:
      placement:
        max_replicas_per_node: 1
        constraints:
          - "node.role==manager"

  vote: # 一个投票的web服务:python
    image: dockersamples/examplevotingapp_vote:before
    ports: # 端口映射
      - "5000:80"
    networks:
      - frontend
    depends_on:
      - redis
    deploy:
      replicas: 2
      update_config:
        parallelism: 2
      restart_policy:
        condition: on-failure

  result: # 一个查看结果的服务:js-express
    image: dockersamples/examplevotingapp_result:before
    ports:
      - "5001:80"
    networks:
      - backend
    depends_on:
      - db
    deploy:
      replicas: 1
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure

  worker: # 读取redis的结果,并把结果写入数据库
    image: dockersamples/examplevotingapp_worker
    networks:
      - frontend
      - backend
    deploy:
      mode: replicated
      replicas: 1
      labels: [APP=VOTING]
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
        window: 120s
      placement:
        constraints:
          - "node.role==manager"

  visualizer: # 一个swarm的可视化程序用于监控上面三个服务的运行
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    stop_grace_period: 1m30s
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints:
          - "node.role==manager"

networks: # 定义了docker-compose里面的网络
  frontend:
  backend:

volumes: # 定义了docker-compose里面的volume
  db-data:
```



#### docker-compose服务的启动顺序

```yaml
version: "3.7"
services:
  web:
    build: .
    depends_on: # web服务会在db和redis服务启动后才去启动
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```

`docker-compose up web`和`docker-compose up` 可以单独启动web或是按照顺序启动web但是他们启动之前都要先启动depends_on里面的依赖,但是web不会等待redis完全启动后再启动.为了同步这些服务的启动顺序我们不会使用depends_on，我们可以通过三种方式控制脚本启动顺序.

-   微服务的配置中心 (足够次数的重连机制保证各种服务连接到配置中心)

-   docker-compose的service的entrypoint指定启动脚本和等待启动脚本控制

    即启动service的时候如果没有启动依赖服务则启动依赖

-   docker-compose的service的entrypoint指定启动脚本和监测服务启动脚本

    启动service之前等待响应的端口开启服务

等待启动的脚本

```sh
#!/bin/sh

TIMEOUT=15
QUIET=0

echoerr() {
  if [ "$QUIET" -ne 1 ]; then printf "%s\n" "$*" 1>&2; fi
}

usage() {
  exitcode="$1"
  cat << USAGE >&2
Usage:
  $cmdname host:port [-t timeout] [-- command args]
  -q | --quiet                        Do not output any status messages
  -t TIMEOUT | --timeout=timeout      Timeout in seconds, zero for no timeout
  -- COMMAND ARGS                     Execute command with args after the test finishes
USAGE
  exit "$exitcode"
}

wait_for() {
  for i in `seq $TIMEOUT` ; do
    nc -z "$HOST" "$PORT" > /dev/null 2>&1

    result=$?
    if [ $result -eq 0 ] ; then
      if [ $# -gt 0 ] ; then
        exec "$@"
      fi
      exit 0
    fi
    sleep 1
  done
  echo "Operation timed out" >&2
  exit 1
}

while [ $# -gt 0 ]
do
  case "$1" in
    *:* )
    HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
    PORT=$(printf "%s\n" "$1"| cut -d : -f 2)
    shift 1
    ;;
    -q | --quiet)
    QUIET=1
    shift 1
    ;;
    -t)
    TIMEOUT="$2"
    if [ "$TIMEOUT" = "" ]; then break; fi
    shift 2
    ;;
    --timeout=*)
    TIMEOUT="${1#*=}"
    shift 1
    ;;
    --)
    shift
    break
    ;;
    --help)
    usage 0
    ;;
    *)
    echoerr "Unknown argument: $1"
    usage 1
    ;;
  esac
done

if [ "$HOST" = "" -o "$PORT" = "" ]; then
  echoerr "Error: you need to provide a host and port to test."
  usage 2
fi

wait_for "$@"
```

`./wait-for.sh www.baidu.com:80 -- echo "baidu is up"` 利用这种脚本可以等待某服务的启动

监测服务启动脚本

```sh
#!/bin/bash
#set -x
#******************************************************************************
# @file    : entrypoint.sh
# @author  : simon
# @date    : 2018-08-28 15:18:43
#
# @brief   : entry point for manage service start order
# history  : init
#******************************************************************************

: ${SLEEP_SECOND:=2}

wait_for() {
    echo Waiting for $1 to listen on $2...
    while ! nc -z $1 $2; do echo waiting...; sleep $SLEEP_SECOND; done
}

declare DEPENDS
declare CMD

while getopts "d:c:" arg
do
    case $arg in
        d)
            DEPENDS=$OPTARG
            ;;
        c)
            CMD=$OPTARG
            ;;
        ?)
            echo "unkonw argument"
            exit 1
            ;;
    esac
done

for var in ${DEPENDS//,/}
do
    host=${var%:*}
    port=${var#*:}
    wait_for $host $port
done

eval $CMD
#避免执行完命令之后退出容器
tail -f /dev/null
```

关于deploy属性,在swarm中会有说明



### ***docker swarm***

swarm是一集群管理工具,其和k8s,mesos一样是一种容器编排工具,docker-compose中的deploy属性等便是使用swarm进行容器编排的标志和方法.swarm是docker的**原生工具**,占用资源没有那么多,也是其他一些工具中学习成本最低的.

![](http://favorites.ren/assets/images/2018/docker/swarmcluster.png)

上面可以看出来swarm整合了多个docker主机,使得容器可以跨主机组网.docker-swarm具有相当高的性能,在小集群和打击群上面均具有优良的表现,其能在1000个节点上运行50000个容器.对于企业级应用而言**可扩展性**一个架构的关键.

swarm内置的调度器(scheduler)支持多种过滤器，节点标签，亲和性和多种部署策略，binpack，spread，random等.

和所有集群服务一样,swarm由swarm-manager也提供高可用性,其通过创建多个master节点和制订主master节点宕机时的备选策略,如果一个master节点宕机,那么slave节点将会代替master节点直到master节点恢复.宕机时,swarm会把容器调度到正常的节点上去.

docker-swarm提供了一套可靠的机制,能够提供高可用的集群部署方案。**有状态的服务应该尽可能避免部署到docker集群里面**,swarm不像hadoop集群那样具有高可用的hdfs,其对于跨节点的数据卷存储能力就比较弱,所以数据库和缓存一般是放置于外面的,可以把计算的web任务放到swarm集群中.而像**nginx**这样部署在前端的服务,则在一些情况下是难以获取用户真正的ip的,**这些服务不能部署到swarm集群中**.

***尽量减少数据卷的使用,更好的扩展性可以参考微服务的注册中心的思路,所有数据卷交给hdfs等分布式存储服务去处理会较为好***

---

#### 调度层次

swarm节点和常规的集群一样,由manager(master)和worker(slave)节点构成,master节点主要是执行docker swarm命令来管理集群的,manager节点可以有很多个,但是leader节点只有一个.工作节点一般执行退出swarm集群的命令docker swarm leave.该集群的选举协议是raft (zookeeper用的是zab),如下manager只有管理者的作用,不可充当worker.

![](http://favorites.ren/assets/images/2018/docker/swarm_manager_worker.png)

service被下放到各个worker节点上运行,管理节点也可以默认是工作节点,上图有一集群三个节点swarm和常规的集群一样以这样一种方式管理集群.

任务(Task,Job)相比只是细粒度的问题在hadoop中task的粒度比job更小,而在swarm中我们只用到Task和服务(service),task是swarm中的最小调度单位,而容器任务服务的关系如下图所示.

![](http://favorites.ren/assets/images/2018/docker/swarm_services.png)

service有两种模式,在搭建好集群之后可以通过`docker service create -mode`去指定

-   replicas  指定在各节点上运行指定的`任务Task`的个数
-   global  每个工作节点运行一个`任务Task`每个节点最多也只能运行一个

replicas的含义可以理解是自动分配,比如有5个副本那么在调度器的作用下各个节点会负载一共`replicas`个镜像,在后续的`docker service create --replicas`中可使用



#### 创建实例

我们以一个初始化集群的例子开始,`docker swarm init --advertise-addr {manageIp}`用于初始化管理节点,然后我们可以看到如下提示,下面提示可以帮助我们安装docker

```shell
[root@vm2 ~]# docker swarm init
Swarm initialized: current node (jo80bsf4ytk4ms7sav1g9u4m1) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-2b453kj9yifhxtkm8qxi7jx5u55k0yb8wlfa93xac24hrnuhph-4ofpbbwn9eep5ogyvqgbi3bdn 172.17.165.35:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

我们可以看到,利用`docker swarm join --token {token} 172.17.165.35:2377`来加入一个worker节点,或者通过`docker swarm join-token manager`加入一个管理节点,需要注意的是管理机需要有公网ip否则无法连接,或者一般而言三个节点都在同一局域网下,通过局域网互联也可.在管理节点可以使用`docker node ls`查看集群的节点信息.加入worker之前还需要把worker内部的docker镜像给配置好在启动swarm集群.

等添加好worker节点之后我们可以使用`docker node ls`来查看集群的各个节点,下面我们来创建service

```shell
docker service create --replicas {num} --name {serviceName} {imageName} {bashCommand}
```

`--replicas 3` 表明每个节点上运行3个实例,具体生产我们写一份`docker-compose.yml`然后利用`docker stack`命令部署就可

上面一次指定了副本数,服务的名字,镜像的名字和执行的bash

一些常用的命令如下

-   `docker service ps {serviceId/Name}`查看服务的开展情况
-   `docker service ls`可以查看当前集群运行的服务
-   `docker service inspect --pretty {serviceName}`查看服务的详细情况
-   `docker node ls` 查看节点运行情况
-   `docker service rm {serviceId}` 删除服务
-   `docker swarm init` 初始化集群
-   `docker swarm leave --force` 退出集群 

下面是动态扩展服务和更新服务的命令,此类命令更偏向运维

-   `docker service scale {serviceName/Id}={num} ` 动态改变服务的副本数
-   `docker service update --replicas {num}  ` 动态更新服务

上面两者的不同在于一个更新服务用于升级,另一个则是用于有延迟的服务扩展

#### docker stack

`docker stack`是`docker`使用`docker-compose.yml `来部署启动swarm集群的一种命令方式.我们通过编写`docker-compose.yml`来启动swarm集群.





## 容器编排(Container Orchestration)

容器编排是构建伸缩性服务的重要技术,所谓的伸缩性服务不单包括负载均衡的容器,还包括了自动化部署,管理和扩展.docker正式凭借着容器编排在软件交付维护上起到了非常重要的作用,其在超大型容器服务的编写中扮演着重要的角色.容器的扩展,部署,管理都可以通过此项技术解决

在当今软件的动态环境中,容器编排可以解决如下任务

-   调配和部署(provisioning)容器
-   冗余(redundancy)和可用性(aviliable)
-   扩展或者删除容器在主机结构中可以负载均衡
-   主机死亡或故障,docker服务迁移
-   容器之间的资源分配
-   额外的暴露容器运行暴露服务(内网自治)
-   容器之间的服务发现和负载均衡
-   容器和主机的健康监控
-   运行与它程序有关的应用程序配置

k8s和单独的swarm可以完成容器编排,其会从docker-compose.yml中获取到从何收集容器的镜像,如何在容器之间建立网络,如何挂载卷,如何存储日志等,容器通常在副本组(k8s pods)中,当新的容器部署到集群的时候,容器编排工具会根据预定的约束(例如CPU,内存的使用阈值)寻找最合适的主机来创建容器,一旦容器在主机上运行,编排工具会根据预定的文件来管理容器的生命周期,而大多数容器编排工具,**大多数容器编排工具都考虑了docker来作为编排的容器**,使得docker成为了微服务容器时代的一个通用性的容器,我们可以把服务封装到docker里面,按照容器编排来考虑服务间的通信流程等。



### Kubernetes简介

Kubernetes又称k8s,由google开发,事实上建立起了容器编排的标准,其提供了PaaS(platform as a service)即`平台即服务`,PaaS创建了硬件抽象常见的即是我们所见的各种云服务各种ECS。k8s这么做的好处是换平台部署的时候不用考虑硬件架构的不同(ECS的不同)或是不同系统间的差异,只用专注于业务逻辑的开发即可。和swarm相比其系统会完善很多但是同样的**其学习曲线会及其陡峭**

k8s的主要构件如下

-   cluster 集群一般是由至少一个主节点和一堆工作节点构成,和大数据理解的集群一致
-   kubernetes master 主节点管理从节点的调度和部署,主节点上运行的全套服务称之为控制面板(control panle),主节点通过kubernetes api和从节点进行通信,调度器根据预定的约束把节点分配给pods(下面会解释含义,这里可以理解为一个或多个容器)
-   Kubelet 每个节点都运行一个Kubelet的代理进程,负责管理节点的状态,根据控制面板的指令启动,停止和维护应用程序容器,kubelet从master节点接受所有信息.
-   Pods kubernetes 基本调度单元,其由至少一个的一组容器(这组容器应该尽可能的完成资源共享和调度),尽可能的在同一主机下的容器,**每个pod在集群中都有其唯一的ip地址**,这样使得应用程序减少冲突,可以通过yaml文件或者json去描述这些pod的状态(这些文件称为PodSpec.),并且由master节点通过api server传递到各个从节点上.
-   Deployments,Replicas,Replicas Set(部署,副本和副本集) 其为yaml定义了每个副本的pod和容器的实例对象的个数(称为副本replicas).对于每个pod我们可以定义副本的数量来确定集群中运行的副本集.(如果节点挂了,调度器会调度副本集的另一节点保证)
    -   deployments 是部署的对象
    -   replicas 副本:容器的实例
    -   replicas set 副本集:多个容器的实例的集合

