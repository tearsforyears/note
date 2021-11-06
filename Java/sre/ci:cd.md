## CI/CD

注册runner,首先找个物理机或者容器安装好gitlab-runner

```shell
sudo gitlab-runner register
gitlab-runner run
```

`.gitlab-ci.yml`该文件是gitlab-runner的配置,直接运行在宿主机上,用于执行gitlab-pipeline

```yml
compile:
  stage: build
  script:
  - mvn $COMMON_MAVEN_CLI_OPTS -Dmaven.test.skip=true compile
  only:
  - merge_requests
check_sytle:
  stage: test
  script:
  - mvn $COMMON_MAVEN_CLI_OPTS
    org.apache.maven.plugins:maven-checkstyle-plugin:3.1.0:checkstyle-aggregate
    org.apache.maven.plugins:maven-checkstyle-plugin:3.1.0:check
    -Dcheckstyle.config.location="/root/dywx-checkstyle.xml"
    -Dcheckstyle.suppressions.location="/root/dywx-checkstyle-suppression.xml"
  - mkdir style && cp -r ./target ./style
  artifacts:
    paths:
    - style/
  only:
  - merge_requests
  - master
  - staging
```

顶层标签定义了一个job,每个job至少包含script上面的pipeline会在对应动作的时候执行,我们看下具体的服务怎么部署

```yml
deploy_staging_audit: # job名称
  stage: deploy
  script:
  - 'mvn $COMMON_MAVEN_CLI_OPTS package -Dmaven.test.skip=true'
  - 'export ENV=staging'
  - 'export SERVICE=em-comment-audit' # 定义环境变量和服务名字
  - 'cd /root/common/docker-deployer/docker-deployer && python portal.py' # 执行脚本,这句话估计导入k8s集群
  environment:
    name: staging_audit
    url:  # 参考用可以不写,可以绑定域名后协商
  when: manual # 手动触发该 job
  only: # 哪个分支可以使用该 job
  - master
  - staging
```

`deploy.yml`是k8s的配置文件,k8s是个容器编排工具,配合docker的容器技术,组成了CI/CD生态,相对于虚拟机,容器更加轻量级.容器技术如果上云就会遇到容器漂移的问题(即原来在node1上创建的节点因为资源不够等原因,会在node2上重建),而k8s就是容器分布式部署的方案.k8s提供了微服务的解决方案

- 服务发现与调度
- 负载均衡
- 服务自愈
- 服务弹性扩容
- 横向扩容
- 存储卷挂载

k8s架构如下

![](https://pic2.zhimg.com/80/v2-499cc023903440be0fee5cf63b689c89_720w.jpg)

k8s是典型的MS架构,所有的命令都发往master节点,master节点主要维护者集群的管理状态,资源调度,以及保存集群的状态.`kubectl get nodes`查看节点状态.可以看到pod即是各个节点的工作负载docker的具体实例.如果pod挂了,那么对应的kubelet将尝试重启节点,这个kubelet类似于node agent的功能.每个pod将被分配ip,参考堡垒机的访问.pod的重启会让其ip地址变化,但因为有proxy存在所以其ip地址(dns名称)不会发生改变.