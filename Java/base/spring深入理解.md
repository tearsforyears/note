# 深入Spring设计原理

---

## 基础

-   反射
-   基本的多线程
-   spring框架的基本理解
    -   IOC & AOP
    -   bean的创建方式 (构造器,实例工厂,静态工厂)
    -   bean的状态模式 单例,原型(多例),Session,Request(每个会话或者请求创建一个实例)

## spring加载过程

<font color="red">spring的启动是建立在servlet启动之上的</font> 

web初始化

>   Tomcat初始化jar包,一些相关组件,并去读web.xml里面的内容按顺序初始化context-param,listener,filter,servlet.在Listener初始化的时候就配置让web应用在ServletContext出来之前把WebApp注入ServletContext,ContextLoaderListener去监听web加载
>
>   简单来讲 该过程如下
>
>   1.读取web.xml listener和context-param
>
>   2.创建ServletContext(全局上下文)
>
>   3.创建listener(spring读取beans.xml),创建filter,创建servlet

**ContextLoader**在Listener初始化时才去读取spring的**beans.xml** 此时springbean

**ServletContext的初始化早于WebApplicationContext 后者放于前者中于加载入Tomcat时完成**

bean初始化

>1.读取配置文件 加载各类定义资源(如果是包扫描器应该在BeanFactory之前加载好)
>
>2.准备BeanFactory
>
>**注意:BeanFactory是创建bean的工厂类的顶级接口**
>
>3.Bean的实例化,注入属性,init-method

## spring的设计模式

---

-   单例模式
-   工厂模式(实例工厂静态工厂)
-   代理模式(jdk动态代理) AOP实现
-   观察者模式 监听者模式
-   装饰者模式(wrapper)
-   适配器模式(Adapter)

## aop实现底层原理

---

aop几乎是spring中最强大的部分了IOC和spring本身也提供了AOP基础的实现

-   cglib (继承代理)
-   jdk动态代理 (公共接口代理)
-   ASM框架修改字节码
-   springAOP(运行时增强 基于代理)和AspectJ(编译时增强 基于字节码)的异同
-   AOP和自定义注解 这个其实多数要基于IOC的实现

### cglib



### jdk动态代理



### ASM修改字节码



### AspectJ和springAOP的异同



### 自定义注解和使用

一般我们实现自己的注解有两种思路

-   借助AOP拦截特定方法检查有无我们的注解获取注解属性进行增强
-   借助IOC的三个类进行上下文级别的全局增强

我们这里说AOP拦截特定方法和自己检查注解

## ioc

### ioc创建过程

-   整个bean对象产生的整个过程 从spring容器开始(ApplicationContext初始化成功)

![创建过程2](https://images2017.cnblogs.com/blog/256554/201709/256554-20170919234704353-487869759.png)

![时序图](https://images2018.cnblogs.com/blog/717817/201805/717817-20180522141553606-1691095215.png)

#### spring容器流程总结

---

该流程是对下面的总结,请先阅读下面的流程

spring容器和bean容器还是有点区别的,在于工厂那部分其实严格意义不属于bean的生命周期

1.  BeanFactory的准备 postProcessBean切入点 为BeanFactory注入配置
2.  **[开始进行bean的生命周期]** bean构造函数执行之前有一切入点 postProcessBeforeInitisititation
3.  执行构造函数 ,在这之后有一切入点(或者说在注入之前) postProcessPropertyValues
4.  注入依赖
5.  init-method之前有一切入点 postProcessBeforeInitialization
6.  执行init-method**(注意此处不是构造方法)**
7.  init-method之后有一切入点 postProcessAfterInitialization
8.  等到bean被垃圾回收或者applicationContext结束执行DisposibleBean的destory方法
9.  执行destory-method**[bean的生命周期结束]**

---

bean的生命周期中涉及到了4类方法

1.  bean自身的方法: bean本身调用的方法和配置文件中的init-method和destory-method
2.  bean生命周期接口: BeanNameAware,BeanFactoryAware,InitializingBean和DiposableBean这些接口的方法
3.  容器级生命周期接口方法: InstantiationAwareBeanPostProcessor和BeanPostProcessor这两个接口实现,一般称它们的实现类为"后处理器"
4.  工厂后处理器接口方法: AspectJWeavingEnabler, ConfigurationClassPostProcessor, CustomAutowireConfigurer等等非常有用的工厂后处理器接口的方法.工厂后处理器也是容器级的.在应用上下文装配配置文件之后立即调用

详细解释下各种方法

-   全过程

    首先spring容器初始化,指的是ApplicationContext里面的各种类全部初始化,当全部的bean准确的初始化之后ApplicationContext(Spring容器的初始化算完成)

-   spring对于bean的处理

    -   对于普通的bean,spring让类实现了BeanNameAware、BeanFactoryAware、InitializingBean和DiposableBean这四个接口 用来增强普通bean,主要作用有设置**bean的名字,生产bean的工厂,bean的属性设置完之后应该进行的方法,一次性类的销毁**.这几个方法的母的主要是spring用于对bean进行生产和管理的

    -   然后除此之外 以下三个类是用于进行bean的AOP的,用于对定制需求的方法的增强

        我们如果要自己实现自己的注解或者其他框架想要对bean进行增强可以自己修改下面几个构造器,而像spring

        ***[后续更新]实际上AspectJ和springAOP也借助了下面的Processor去检查注解实现自己的切入方法 这里可以解决AOP的代码执行时机在何时了***

-   bean的springAOP增强类

    -   BeanPostProcessor ***用于在bean的(init-method)之前之后AOP增强方法***

    -   BeanFactoryPostProcessor ***用于bean的生成工厂***

    -   InstantiationAwareBeanPostProcessor (初始化感知使用前的执行器)

        ***用在bean执行构造器之后 构造器执行之前 属性注入之前(初始化感知) bean完全构造完之后 的AOP增强方法***

    这三个类 在所有实例构造之前被初始化到容器中(不一定必须有,默认是不做任何处理) 根据功能的不同完全可以自由选用Processor对自己的类进行增强

我们可以修改这几个类不用spring提供的类而使用自己的类去观察结果

```xml
<bean id="beanPostProcessor" class="MyBeanPostProcessor">
</bean>
<bean id="instantiationAwareBeanPostProcessor" class="MyInstantiationAwareBeanPostProcessor">
</bean>
<bean id="beanFactoryPostProcessor" class="MyBeanFactoryPostProcessor">
</bean>
```

#### BeanPostProcessor

该过程对应spring使用时候的相关注解

-   @PostConstruct 用于指定init-method

-   @PreDestory 用于指定destory-method

这个类围绕在bean的init-method周围,bean post是bean投入使用的意思

**注意此处init-method并非构造器 对照上面的图**

可以在bean使用前后添加方法 对bean进行改造代理什么的

```java
public class MyBeanPostProcessor implements BeanPostProcessor {

    public MyBeanPostProcessor() {
        super();
        System.out.println("这是BeanPostProcessor实现类构造器！！");
        // TODO Auto-generated constructor stub
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName)
            throws BeansException {
        System.out
        .println("BeanPostProcessor接口方法postProcessAfterInitialization对属性进行更改！");
        return bean;
    }

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName)
            throws BeansException {
        System.out
        .println("BeanPostProcessor接口方法postProcessBeforeInitialization对属性进行更改！");
        return bean;
    }
}
```

#### InstantiationAwareBeanPostProcessor

这个切入点有三个 构造函数执行之前 属性注入之前(构造器执行之后) init方式执行之后

```java
public class MyInstantiationAwareBeanPostProcessor extends
        InstantiationAwareBeanPostProcessorAdapter {

    public MyInstantiationAwareBeanPostProcessor() {
        super();
        System.out
                .println("这是InstantiationAwareBeanPostProcessorAdapter实现类构造器！！");
    }

    // 接口方法、构造Bean之前调用
    @Override
    public Object postProcessBeforeInstantiation(Class beanClass,
            String beanName) throws BeansException {
        System.out
                .println("InstantiationAwareBeanPostProcessor调用postProcessBeforeInstantiation方法");
        return null;
    }

    // 接口方法、bean的init-method方法执行之后
    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName)
            throws BeansException {
        System.out
                .println("InstantiationAwareBeanPostProcessor调用postProcessAfterInitialization方法");
        return bean;
    }

    // 接口方法、注入之前/构造器执行之后使用
    @Override
    public PropertyValues postProcessPropertyValues(PropertyValues pvs,
            PropertyDescriptor[] pds, Object bean, String beanName)
            throws BeansException {
        System.out
                .println("InstantiationAwareBeanPostProcessor调用postProcessPropertyValues方法");
        return pvs;
    }
}
```

#### BeanFactoryPostProcessor

该Processor的切入点只有一个 为bean工厂注入bean的信息 或者前置处理等

这个玩意其实是属于BeanFactory的

```java
public class MyBeanFactoryPostProcessor implements BeanFactoryPostProcessor {
    public MyBeanFactoryPostProcessor() {
        super();
        System.out.println("这是BeanFactoryPostProcessor实现类构造器！！");
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory arg0)
            throws BeansException {
        System.out
                .println("BeanFactoryPostProcessor调用postProcessBeanFactory方法");
        BeanDefinition bd = arg0.getBeanDefinition("person");
        bd.getPropertyValues().addPropertyValue("phone", "110");
    }

}
```

### ioc中循环依赖问题的解决

循环依赖类似死锁,指的是A类中有B类的成员变量,B类中有A类的成员变量 这样依赖就编程循环依赖了

spring对此的解决方式其实十分简单 因为**构造和注入是分开的**等待构造完全之后再从构造完后的对象中填充到相应的依赖中去

DefaultSingletonBeanRegistry 类中有声明缓存结构

```java
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256); // 一级缓存 已经被实例化好的对象
// 单例对象的cache就是这个

private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);  // 三级缓存 实例生产时候使用的工厂 单例工厂的cache

private final Map<String, Object> earlySingletonObjects = new HashMap<>(16); // 二级缓存 提前曝光的单例对象
// 用于循环监测
```

我们可以看到 基于工厂建造的单例类spring是可以解决循环依赖的 但是基于构造函数注入的类spring是无法解决循环依赖问题的

spring从一级缓存获取不到会去访问二级缓存进而访问三级缓存,如果获取到了则移除三级缓存放入二级缓存中

### ioc线程安全问题

spring并不会保证单例模式线程安全,这得需要自己的机制去给线程加锁,但spring推荐使用ThreadLocal来解决线程安全问题.

ThreadLocal使用的好处就是线程内部有一个副本,不用像多例模式一样存储大量对象的开销,只需要类似{thread_id,value}的形式去存储相应的副本变量,

### 包扫描器

这个东西其实本质上就是读取对应的java文件,加载文件(JDK和JVM)就可以实现

```java
String packageDirName = packageName.replace('.', '/');  
Enumeration<URL> dirs =
Thread.currentThread().getContextClassLoader().getResources(packageDirName); // 
```

我们这里利用spring的方法去实现也可以自己在代码中进行包扫描注解检查

```java
public static void main(String[] args) throws Expection{
  Set<BeanDefinition> candidates = new LinkedHashSet<>();

  ResourcePatternResolver resourcePatternResolver = new PathMatchingResourcePatternResolver();  
  //这里特别注意一下类路径必须这样写
  //获取指定包下的所有类
  Resource[] resources = resourcePatternResolver.getResources("/com/example/mbttest/mapper");  
// 这里可以用classpath*:com/...和classpath:com/...来访问编译后classes下的文件,*表示包含jar,可以更改.classpath文件来扩大搜索范围
  MetadataReaderFactory metadata = new SimpleMetadataReaderFactory();
  for(Resource resource:resources) {
    System.out.println(resource);
    MetadataReader metadataReader=metadata.getMetadataReader(resource);
    ScannedGenericBeanDefinition sbd = new ScannedGenericBeanDefinition(metadataReader);
    sbd.setResource(resource);
    sbd.setSource(resource);
    candidates.add(sbd);
  }
  for(BeanDefinition beanDefinition : candidates) {  
    String classname=beanDefinition.getBeanClassName();
    //扫描controller注解
    Controller c=Class.forName(classname).getAnnotation(Controller.class);
    //扫描Service注解
    Service s=Class.forName(classname).getAnnotation(Service.class);
    //扫描Component注解
    Component component=Class.forName(classname).getAnnotation(Component.class);
    // 自定义注解..
    
    if(c!=null ||s!=null ||component!=null){       
      System.out.println(classname);
    }
  } 
}
```



## 事务

---

-   脏读 select到其他程序update的数据但未commit的数据

    脏读就是读到的数据不对

-   幻读 select到其他程序insert的数据但未commit的数据

    幻读就是读到原本不存在

-   不可重复读 两次select到其他程序commit前后的数据

### 事务隔离机制

---

下面所谓的commited就是把操作更新到数据库

read-uncommited 最低的级别 等于不做任何操作

读写操作都不提交 所以会出现 三种以上结果

**read-commited(默认操作)** 读操作就要在提交之后进行

读select之前要其他程序先提交update 以保证提交的是最新的数据 

其能解决脏读 因为脏读和volatile关键字的原理比较像 其原理应该是把数据拷贝一份到本线程 修改本线程在和主内存同步 read-commit直接禁用了缓存 和jmm中释放锁会把所有线程的东西写回主内存一样

**其不可解决 幻读问题** 为什么?因为复制过来的副本肯定不包含新插入的行 那么在对应的sql操作的线程中怎么肯能含有相应的数据节点 总不可能把整张表都load进内存

repeatable_read 其可以解决脏读和不可重复度问题 利用快照实现 就读快照的内容不读原数据库 显而易见只读自己内存副本里面的东西就绝对不会脏读和重复读 但有**幻读**问题

serializable 把所有操作序列化 所有事物按顺序执行 开销最大

---

### 事务传播行为

**所谓的当前有事务指的是另一个事务调用了本事务**

```java
public void methodA(){
  methodB();
  // doSomething
}

@Transaction(Propagation=Propagation.REQUIRED)
public void methodB(){
  // doSomething
}

@Transaction(Propagation=Propagation.REQUIRED)
public void methodC(){
  // doSomething
}
```

methodA调用了调用了methodB,但是在methodA中并没有开启事务(由AOP的机制就可以知道).我们一般在springboot中的service层使用@Transaction.且在一原子性Service中描述集体调用的方法

```java
@Service
class TransactionService{
  @Autowired
  XXXService s;
  
  public void invoke(){
  	s.methodB(); // 在自己的事务中独立运行
    s.methodC(); // 如果出现问题就回滚,不出现就在两个独立事务中巡行
  }
  
  @Transaction(Propagation=Propagation.REQUIRED) // 这里开启事务
  public void invokeTransaction(){
  	// 如果调用了该方法,该方法失败了比如可以1/0,那么该方法要回滚
    // 且methodB和methodC也要发生回滚,如果methodB或methodC发生异常
    // 那么所有方法都要进行回滚
    
    s.methodB();
    try{
    	s.methodC();
    }catch(Exception e){
    	// catch exception  
    }
    // 即是手动抓住了异常,invokeTransaction还是要进行回滚
    // 如果想要自己抓住部分异常的话选择NESTED,不过使用场景少意义不大
  }
}
```

例如把上面方法改成如下,我们来研究下其传播行为

```java
@Transaction(Propagation=Propagation.REQUIRED)
public void methodB(){
  // doSomething
}

@Transaction(Propagation=Propagation.New)
public void methodC(){
  // doSomething
}

@Transaction(Propagation=Propagation.New)
public void methodD(){
  // doSomething
}
```

```java
@Service
class TransactionService{
  @Autowired
  XXXService s;
  
  @Transaction(Propagation=Propagation.REQUIRED) // 这里开启事务
  public void invokeTransaction(){
    s.methodB();
    s.methodC();
    int i = 0/1; // 制造异常
  }
  // 上面会执行methodC而methodB会被回滚
  
  @Transaction(Propagation=Propagation.REQUIRED) // 这里开启事务
  public void invokeTransaction(){
    s.methodB();
    s.methodC(); // 如果C出现了异常那么两者会回滚
    s.methodD(); // 然后D因为开启了新事务则不会回滚
  }
}
```

我们可以总结出以下规律,事务是按照@Transaction的最外部方法区决定事务在哪开启的,然后出现了异常,所有该事务执行过的方法都要进行回滚,但用了Propagation.NEW的事务不需要进行回滚,除非该子事务本身出异常.其和下面行为一致

-   REQUIRED(默认):本事物默认加入其它事务中去执行,如果没有其他事务则重新开启事务
-   NEW:要求一定要有事务来供本方法的代码去执行,回去开启新事务异常同样整体回滚
-   NEST:本事物默认加入其它事务中去执行,如果没有其他事务则重新开启事务(可以被抓住异常)
-   MANDATORY:如果当前有事务加入当前事务,没有就抛异常

---

-   SUPPORTS:支持事务有事务按照事务运行,但如果没有事务就按没有事务的运行
-   NOT_SUPPORTED:不支持事务,有事务就暂停事务
-   NEVER:不能在事务中运行,有事务就抛出异常

### spring对事务管理器的配置

需要在配置文件中加入控制管理器

```xml
<!--  Transaction begin  -->
<tx:annotation-driven transaction-manager="transactionManager" />
<bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
  <property name="dataSource" ref="tddlGroupDataSource" />
</bean>
<!-- transaction end -->
```

或者是利用注解

```java
@EnableTransactionManagement
@SpringBootApplication
// 加载启动类上
public class ProfiledemoApplication{
  public static void main(String[] args) {
    SpringApplication.run(ProfiledemoApplication.class, args);
  }
}

// 创建配置类
@Configuration
public class TransactionConfig implements TransactionManagementConfigurer{
  	@Resource(name="txManager2")
    private PlatformTransactionManager txManager2;

    // 创建事务管理器1
    @Bean(name = "txManager1")
    public PlatformTransactionManager txManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    // 创建事务管理器2
    @Bean(name = "txManager2")
    public PlatformTransactionManager txManager2(EntityManagerFactory factory) {
        return new JpaTransactionManager(factory);
    }

    // 实现接口 TransactionManagementConfigurer 方法，其返回值代表在拥有多个事务管理器的情况下默认使用的事务管理器
    @Override
    public PlatformTransactionManager annotationDrivenTransactionManager()
    {
        return txManager2;
    }
}
```



