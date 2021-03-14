# 深入Spring设计原理

---

这是第三次大规模重新理解spring,这次除了高级应用方式web,我们开始探究其源码.探究其实现思想

[TOC]

## 基础

-   反射
-   基本的多线程
-   spring框架的基本理解
    -   IOC & AOP
    -   bean的创建方式 (构造器,实例工厂,静态工厂)
    -   bean的状态模式 单例,原型(多例),Session,Request(每个会话或者请求创建一个实例)

## springweb加载过程

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



## ioc

### IOC & DI

ioc容器是整个spring-core的核心,ioc容器负责实例化对象,并且管理装配bean.以下两个包管理这部分源码.

-   org.springframework.beans
-   org.springframework.context

简单的理解来说,springbean就是一个map,我们通过name或者id作为key就能获取到对应的对象.



### BeanFactory 对象工厂接口

IOC的核心是**BeanFactory**,对象工厂,他是一个**工厂**.BeanFactory是IOC容器的抽象.其能提供IOC容器的基本功能,单个bean的获取,对bean的作用域判断,获取bean的类型.根据名字BeanFactory是对象工厂,即生产对象的工厂,在spring有很多类都实现了这个接口,两个主要的实现如下

-   **DefaultListableBeanFactory类**

-   **ApplicationContext接口**

    

#### DefaultListableBeanFactory类(IOC容器)

是BeanFactory的一种原始实现,也是默认实现.通常也作为自定义IOC容器的父类.其功能实现大致如下

-   通过resource加载spring的xml配置信息,通过XmlBeanDefinitionReader解析xml
-   然后通过DefaultListableBeanFactory进行加载.

我们可以按照如下方式使用

```java
@Test
public void test() {
    // 懒加载
    Resource res = new ClassPathResource("spring-config.xml");
    DefaultListableBeanFactory factory = 
      new DefaultListableBeanFactory();
    XmlBeanDefinitionReader xmlReader = 
      new XmlBeanDefinitionReader(defaultListableBeanFactory);
    xmlReader.loadBeanDefinitions(res);
    
  	// 将这两行getBean代码注释掉再运行，IoC容器将不会真正的创建对象
  	// 这种方式我们称为lazy-init,只有真正需要对象的时候才去创建
    HelloSpring helloSpring = factory.getBean("helloSpring", HelloSpring.class);
    HelloSpring helloSpring2 = factory.getBean("helloSpring", HelloSpring.class);
    System.out.println(helloSpring);
    System.out.println(helloSpring2);
}
```

我们看下其接口定义,可以看到都是我们对bean常用的一些方法.

```java
public interface BeanFactory {

	String FACTORY_BEAN_PREFIX = "&"; // 获取对象而非对象工厂的前缀符号

	Object getBean(String name) throws BeansException;
	<T> T getBean(String name, Class<T> requiredType) throws BeansException;
	<T> T getBean(Class<T> requiredType) throws BeansException;
	Object getBean(String name, Object... args) throws BeansException;
	<T> T getBean(Class<T> requiredType, Object... args) throws BeansException;
	boolean containsBean(String name);
  
	boolean isSingleton(String name) throws NoSuchBeanDefinitionException;
	boolean isPrototype(String name) throws NoSuchBeanDefinitionException;
	boolean isTypeMatch(String name, ResolvableType typeToMatch) throws NoSuchBeanDefinitionException;
	boolean isTypeMatch(String name, Class<?> typeToMatch) throws NoSuchBeanDefinitionException;
	Class<?> getType(String name) throws NoSuchBeanDefinitionException;
  
	String[] getAliases(String name);
}
```

```java
public interface ListableBeanFactory extends BeanFactory {

	/**
	 * @param beanName the name of the bean to look for
	 * @return if this bean factory contains a bean definition with the given name
	 */
	boolean containsBeanDefinition(String beanName);

	/**
	 * @return the number of beans defined in the factory
	 */
	int getBeanDefinitionCount();

	String[] getBeanDefinitionNames();
	String[] getBeanNamesForType(ResolvableType type);
	String[] getBeanNamesForType(Class<?> type);
	String[] getBeanNamesForType(Class<?> type, boolean includeNonSingletons, boolean allowEagerInit);
	<T> Map<String, T> getBeansOfType(Class<T> type) throws BeansException;
	<T> Map<String, T> getBeansOfType(Class<T> type, boolean includeNonSingletons, boolean allowEagerInit)
			throws BeansException;

	// 获得持有该注解(或子注解)的对象名字
	String[] getBeanNamesForAnnotation(Class<? extends Annotation> annotationType);
	Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType) throws BeansException;

	/**
	 * @return the annotation of the given type if found, or {@code null}
	 */
	<A extends Annotation> A findAnnotationOnBean(String beanName, Class<A> annotationType)
			throws NoSuchBeanDefinitionException;

}
```



#### ApplicationContext 接口

org.springframework.context.ApplicationContext是BeanFactory的子接口.该接口添加的功能定义如下,根据他继承的其他接口,添加了

-   Spring AOP集成
-   消息资源处理（用于国际化）
-   事件发布
-   应用层特定的上下文WebApplicationContext等新功能

```java
public interface ApplicationContext extends EnvironmentCapable, ListableBeanFactory, HierarchicalBeanFactory,
		MessageSource, ApplicationEventPublisher, ResourcePatternResolver {

	String getId();
	String getApplicationName();

	/**
	 * Return a friendly name for this context.
	 * @return a display name for this context (never {@code null})
	 */
	String getDisplayName();

	/**
	 * Return the timestamp when this context was first loaded.
	 * @return the timestamp (ms) when this context was first loaded
	 */
	long getStartupDate();
      
	ApplicationContext getParent();
	
	AutowireCapableBeanFactory getAutowireCapableBeanFactory() throws IllegalStateException;

}
```

可以看到了其包含了BeanFactory接口功能的更高级的抽象.上下文对象是用来管理spring中所有的bean.看下其实现,主要如下

-   ClassPathXmlApplicationContext 从classpath去解析类
-   FileSystemXMLApplicationContext 从文件系统去解析类
-   XmlWebApplicationContext 从web.xml中解析类

**ApplicationContext是直接加载调用一次构造方法加载所有的普通bean,而lazy-init的对象都是默认单例的**.

我们定义的bean以及他们的依赖关系信息称为元数据(configuration meta).配置元数据可以以xml,java注释,java代码来表示.一般配置元数据有几种常见的方式

-   传统xml
-   基于Spring注解:@Autowired,@PostConstruct,@PreDestroy
-   基于Java注解:@Configuration,@Bean,@Import,@DependsOn

我们配置的元数据信息变成了**BeanDefinition**.这样就不用每次都去配置信息中在解析一次.BeanDefinition包含以下信息

-   bean的实现类全限定类名
-   bean的实现类型的全限定类型
-   bean在容器的作用范围,生命周期的回调函数
-   bean的依赖项

启动IOC容器的时候,IOC容器会借助**BeanDefinition**开始进行依赖注入过程.引入多个ApplicationContext的时候,我们可以直接在代码层面利用多个配置文件的引入方法,或者是在xml文件中用import标签

```xml
<import resource="spring-config2.xml"/>
```



### 循环依赖问题

spring中避不开的一个问题就是循环依赖,当A依赖B创建,B依赖A创建的时候就会出现这种现象而产生BeanCurrentlyCreationException.

解决方案是,我们依赖注入(DI)的时间发生在创建对象之后,等对象完全创建好了在根据setter或者setter进行依赖注入.在很多情况下我们使用构造器注入是更加安全的注入方式.



### FactoryBean 工厂对象

首先,他只是辅助实现,和IOC的过程没有任何关系.

和上面顶级接口长得很像,特别容易搞混,但本质上,FactoryBean是个对象的接口.而不是工厂的接口.他对工厂对象进行抽象,规定了一个正常的工厂应该有什么样的方法.定义如下

```java
public interface FactoryBean<T> {  
    T getObject() throws Exception;  
    Class<?> getObjectType();  
    boolean isSingleton();  
}
```

其可以用以下方式,来实现这个接口

```java
public class FactoryBeanPojo implements FactoryBean{
	private String type;
 
	@Override
	public Object getObject() throws Exception {
		if("student".equals(type)){
			return new Student();			
		}else{
			return new School();
		}	
	}
  
	@Override
	public Class getObjectType() {
		return School.class;
	}
 
	@Override
	public boolean isSingleton() {
		return true;
	}
 
	public String getType() {
		return type;
	}
 
	public void setType(String type) {
		this.type = type;
	}
}
```

两者毫无可比性,只是长得像而已,但是非常易混淆在此声明.



### ioc创建过程(bean生命周期)

整个bean对象产生的整个过程 从spring容器开始(ApplicationContext初始化成功)

![创建过程2](https://images2017.cnblogs.com/blog/256554/201709/256554-20170919234704353-487869759.png)

上面的图虽然相对复杂,但都是利用回调函数的机制,在以下几个时间发生的前后都预留了回调函数供给监测或者增强bean.所以其生命周期分为以下几个过程

-   根据BeanDefinition去加载类进入虚拟机`<clinit>`,static初始化等
-   执行Bean的构造器.(解决循环依赖)
-   给Bean注入属性.
-   服务其他类 (getBean) 此过程属于我们使用spring写的代码
-   销毁

而上面的过程前后,都有预留回调函数,可以通过实现某些类,经过配置进行bean的增强.

![时序图](https://images2018.cnblogs.com/blog/717817/201805/717817-20180522141553606-1691095215.png)

我们可以通过下面一些方法为一个对象的生命周期设置回调函数(listener模式)

```java
@Test
public void lifecycleCallback() {
    // 开启ioc容器
    ClassPathXmlApplicationContext ac = new ClassPathXmlApplicationContext("DI.xml");
    
  	// 主动获取bean才会回调,第二个参数指定的是回调的类,回调的类由我们自己实现方法监测
  	// 对象的生命周期,但这个生命周期和ioc容器的生命周期一致
    ac.getBean("lifecycleCallbackPro", LifecycleCallbackPro.class);
    ac.getBean("lifecycleCallbackPro", LifecycleCallbackPro.class);
    
  	// close关闭容器，一定是close才会触发
    ac.close();
    // gc不一定发生，对象不一定被彻底销毁
    System.gc();
}

@Component // 或者是在某一方法上利用@Bean注册,得加入SpringContext才行.
public class LifecycleCallbackPro {
  public LifecycleCallbackPro() {}

  @PostConstruct // 利用注解指定回收周期
  public void afterPropertiesSet() {
    System.out.println("prototype LifecycleCallbackPro初始化回调");
  }

  @PreDestroy
  public void destroy() {
    System.out.println("prototype LifecycleCallbackPro销毁回调");
  }

  @Override
  protected void finalize() {
    System.out.println("prototype LifecycleCallbackPro销毁");
  }
}
```







### spring容器流程总结

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

### BeanPostProcessor

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

### InstantiationAwareBeanPostProcessor

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

循环依赖类似死锁,指的是A类中有B类的成员变量,B类中有A类的成员变量 这样依赖就编程循环依赖了.需要声明的一点是,如果是依赖注入的循环依赖,spring是有解决档案的,但**构造器**的循环依赖是无法解决的.

```java
public class A {  
    private B b ;  
    public void setB(B b) {  
        this.b = b;  
    }  
    public A() {  
    }  
    public A(B b) {  
        this.b = b;  
    }  
}
public class B {  
    private C c ;  
    public void setC(C c) {  
        this.c = c;  
    }  
    public B() {  
    }  
    public B(C studentC) {  
        this.c = c;  
    }  
}
public class C {
    private A a; 
    public void setA(A a) {  
        this.a = a;  
    }  
    public C() {  
    }
    public C(A a) {  
        this.a = a;  
    }  
} 
```

```xml
<bean id="a" class="com.example.A">  
    <constructor-arg index="0" ref="b"></constructor-arg>  
</bean>  
<bean id="b" class="com.example.B">  
    <constructor-arg index="0" ref="c"></constructor-arg>  
</bean>  
<bean id="c" class="com.example.C">  
    <constructor-arg index="0" ref="a"></constructor-arg>  
</bean>
```

这样一来,就会出现构造器依赖,即会发生错误.

spring对此其他循环依赖的解决方式其实十分简单 因为**构造和注入是分开的**等待构造完全之后再从构造完后的对象中填充到相应的依赖中去.我们看下bean的调用过程设置对象属性

![](https://img-blog.csdn.net/20180331212327518?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM2MzgxODU1/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

spring先调用构造器实例化对象,把实例化对象放到一个Map中(这个Map是线程安全的).像这样的缓存spring有三级.

DefaultSingletonBeanRegistry 类中有声明缓存结构

```java
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256); // 一级缓存 已经被实例化好的对象
// 单例对象的cache就是这个

private final Map<String, Object> earlySingletonObjects = new HashMap<>(16); // 二级缓存 提前曝光的单例对象
// 用于循环监测

private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);  // 三级缓存 实例生产时候使用的工厂 单例工厂的cache
```

我们可以看到 基于工厂建造的单例类spring是可以解决循环依赖的 但是基于构造器注入的类spring是无法解决循环依赖问题的.

spring从一级缓存获取不到会去访问二级缓存进而访问三级缓存,如果获取到了则移除三级缓存放入二级缓存中.

这三级缓存对应对象创建的不同阶段

-   singletonObjects 
-   earlySingletonObjects 如果其他线程在三级缓存获取到了对象,对象就会被移入二级缓存
-   singletonFactories 三级缓存,可能是正在被工厂创建的类.我们先要去获取

这里就是遇到循环依赖问题时候会进行的处理逻辑

![](https://pic1.zhimg.com/80/v2-abe8d96f198a33fcfd51bb2108b00004_1440w.jpg)

处理完之后在进行值的注入.



### ioc线程安全问题

spring并不会保证单例自己模式线程安全,**但是会保证自己添加对象缓存依赖的时候是线程安全的.(利用了java原生的synchronized机制)**,这得需要自己的机制去给线程加锁,但spring推荐使用ThreadLocal来解决线程安全问题.

ThreadLocal使用的好处就是线程内部有一个副本,不用像多例模式一样存储大量对象的开销,只需要类似{thread_id,value}的形式去存储相应的副本变量.



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



## 事务

---

事务是一种控制读写的并发机制,事务的特性就是ACID

-   原子性Atomicity,即不可分割,发生错误会回滚
-   一致性Consistency,即所有读写的数据能够保持一致
-   隔离性Isolation,即事务之间隔离不互相依赖
-   持久性Durability,顾名思义一次性变化序列化到磁盘上

使用事务系统,就有可能会遇到三种现象

-   脏读 select到其他程序update的数据但未commit的数据

    脏读就是读到的数据不对

-   幻读 select到其他程序insert的数据但未commit的数据

    幻读就是读到原本不存在

-   不可重复读 两次select到其他程序commit前后的数据

四种事务隔离级别

-   READ_UNCOMMIT 读不提交,即不做任何操作,可能会
-   READ_COMMIT 读操作要在提交了之后才能执行,避免脏读
-   REPETABLE_READ 可重复读,可以避免脏读,幻读
-   SERIALIZABLE 序列化,可以避免脏读幻读不可重复读



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

methodA调用了调用了methodB,但是在methodA中并没有开启事务(由AOP的机制就可以知道).我们一般在springboot中的service层使用@Transaction.且在一原子性Service中描述集体调用的方法.

从上面的写法我们也能猜出其实现原理,是完全通过AOP来实现的,所以关于各种事务,需要有spring管理的bean来进行调用.如果想要在一个事务中调用另一个事务,那么该方法要标注事务,且需要被spring管理(进行AOP增强).

```java
@Service
class TransactionService{
  @Autowired
  XXXService s; // AOP代理了,具有事务特性
  
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



