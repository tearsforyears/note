# Spring

[toc]

---

![](https://docs.spring.io/spring-framework/docs/4.3.16.RELEASE/spring-framework-reference/html/images/spring-overview.png)

[created at:2021年11月11日20:51:33]

由springboot来看spring其实很多结构我们是有使用的

前有 webflux 后有 spring-core 两者皆对 spring 生态缠身了很大的影响,下文主要分析 core 相关的原理

## production

---

这里我们会讨论 production 层面的应用,spring bean的生命周期如下

![创建过程2](https://images2017.cnblogs.com/blog/256554/201709/256554-20170919234704353-487869759.png)

这个图可能有点复杂我们从中间(init-method)看起

从上图看 bean 的初始化经历了几个阶段

- bean 的 java 构造
- bean 的装载(Instantiation)
  - bean 的属性注入
  - bean 的 init-method 

spring 利用了以下几个接口实现了对其生命周期的控制(只要实现接口内的方法就可以控制器具体阶段的生命周期)

- BeanPostProcessor 对 init-method 进行控制
- InstantiationAwareBeanPostProcessor 对 bean 的装载阶段进行控制,也包括了 BeanPostProcessor
- BeanFactoryPostProcessor 对 bean meta信息的控制

### BeanPostProcessor 接口

```java
public interface BeanPostProcessor {

	/**
	 * 初始化方法调用前要进行的处理逻辑
	 */
	@Nullable
	default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}

	/**
	 * 在初始化方法指定后要进行的处理逻辑
	 */
	@Nullable
	default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}

}
```

该过程对应spring使用时候的相关注解

-   @PostConstruct 用于指定init-method

-   @PreDestory 用于指定destory-method

这个类围绕在bean的init-method周围,**注意此处init-method并非构造器 对照上面的图**,可以在bean使用前后添加方法 对bean进行改造代理什么的,如下图则是 BeanPostProcessor 执行的时机

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

### InstantiationAwareBeanPostProcessor 接口

同理我们实现下列接口即可对装载过程进行控制,可以看到其也需要对BeanPostProceesor进行实现

```java
public interface InstantiationAwareBeanPostProcessor extends BeanPostProcessor {
  @Nullable
  default Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException {
    return null;
  }

  default boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException {
    return true;
  }

  @Nullable
  default PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) throws BeansException {
    return null;
  }

  /** @deprecated */
  @Deprecated
  @Nullable
  default PropertyValues postProcessPropertyValues(PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) throws BeansException {
    return pvs;
  }
}

```



### BeanFactoryPostProcessor 接口

该Processor的切入点只有一个 为bean工厂注入bean的信息

```java
public class MyBeanFactoryPostProcessor implements BeanFactoryPostProcessor {
    public MyBeanFactoryPostProcessor() {
        super();
        System.out.println("这是BeanFactoryPostProcessor实现类构造器！！");
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory arg0)
            throws BeansException {
        System.out.println("BeanFactoryPostProcessor调用postProcessBeanFactory方法");
        BeanDefinition bd = arg0.getBeanDefinition("person");
        bd.getPropertyValues().addPropertyValue("phone", "110");
    }

}
```

我们可以看下其默认实现类

- `org.springframework.beans.factory.support.DefaultListableBeanFactory`

![](https://images2015.cnblogs.com/blog/299855/201608/299855-20160810195634074-1487475708.png)

```java
public class DefaultListableBeanFactory extends AbstractAutowireCapableBeanFactory implements ConfigurableListableBeanFactory, BeanDefinitionRegistry, Serializable {
  // **
}
```

```java
public interface ConfigurableListableBeanFactory extends ListableBeanFactory, AutowireCapableBeanFactory, ConfigurableBeanFactory {
  void ignoreDependencyType(Class<?> var1);

  void ignoreDependencyInterface(Class<?> var1);

  void registerResolvableDependency(Class<?> var1, @Nullable Object var2);

  boolean isAutowireCandidate(String var1, DependencyDescriptor var2) throws NoSuchBeanDefinitionException;

  BeanDefinition getBeanDefinition(String var1) throws NoSuchBeanDefinitionException;

  Iterator<String> getBeanNamesIterator();

  void clearMetadataCache();

  void freezeConfiguration();

  boolean isConfigurationFrozen();

  void preInstantiateSingletons() throws BeansException;
}

```

其实就是实现了注册的功能,autowired等

### Aware 接口

```java
public interface Aware {
}
```

```java
public interface BeanClassLoaderAware extends Aware {
  void setBeanClassLoader(ClassLoader var1);
}
```

```java
public interface BeanFactoryAware extends Aware {
  void setBeanFactory(BeanFactory var1) throws BeansException;
}
```

```java
public interface ApplicationContextAware extends Aware {
	void setApplicationContext(ApplicationContext applicationContext) throws BeansException;
}
```

观察下列接口,aware本身没有实现任何方法,更多的只是规定如何获取到这么一个对象

```java
class ApplicationContextAwareProcessor implements BeanPostProcessor {
	private final ConfigurableApplicationContext applicationContext;
	private final StringValueResolver embeddedValueResolver;
	/**
	 * 将Context注入进来
	 */
	public ApplicationContextAwareProcessor(ConfigurableApplicationContext applicationContext) {
		this.applicationContext = applicationContext;
		this.embeddedValueResolver = new EmbeddedValueResolver(applicationContext.getBeanFactory());
	}
	/**
	 * 接口beanPostProcessor规定的方法，会在bean创建时，实例化后，初始化前，对bean对象应用
	 */
	@Override
	@Nullable
	public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		if (!(bean instanceof EnvironmentAware || bean instanceof EmbeddedValueResolverAware ||
				bean instanceof ResourceLoaderAware || bean instanceof ApplicationEventPublisherAware ||
				bean instanceof MessageSourceAware || bean instanceof ApplicationContextAware)){
			return bean;
		}
		AccessControlContext acc = null;
		if (System.getSecurityManager() != null) {
			acc = this.applicationContext.getBeanFactory().getAccessControlContext();
		}
		if (acc != null) {
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
				// 检测bean上是否实现了某个aware接口，有的话进行相关的调用
				invokeAwareInterfaces(bean);
				return null;
			}, acc);
		}
		else {
			invokeAwareInterfaces(bean);
		}

		return bean;
	}

	/**
	 * 如果某个bean实现了某个aware接口，给指定的bean设置相应的属性值
	 *
	 * @param bean
	 */
	private void invokeAwareInterfaces(Object bean) {
		if (bean instanceof EnvironmentAware) { // 处理系统资源,环境变量
			((EnvironmentAware) bean).setEnvironment(this.applicationContext.getEnvironment());
		}
		if (bean instanceof EmbeddedValueResolverAware) { // 处理 spel 表达式
			((EmbeddedValueResolverAware) bean).setEmbeddedValueResolver(this.embeddedValueResolver);
		}
		if (bean instanceof ResourceLoaderAware) { // 处理动态加载的资源
			((ResourceLoaderAware) bean).setResourceLoader(this.applicationContext);
		}
		if (bean instanceof ApplicationEventPublisherAware) { // 获取资源加载器
			((ApplicationEventPublisherAware) bean).setApplicationEventPublisher(this.applicationContext);
		}
		if (bean instanceof MessageSourceAware) {
			((MessageSourceAware) bean).setMessageSource(this.applicationContext);
		}
		if (bean instanceof ApplicationContextAware) { // 注入 application context 用于完成  
     // @Autowired getBean 的操作用来注入对象
			((ApplicationContextAware) bean).setApplicationContext(this.applicationContext);
		}
	}

}
```

从上面我们看到 aware 接口是某些前置器的一部分,只要实现了某些 aware 的子接口,那么其子接口的实现类会被执行,同时上文也解释了 @Autowired 关键字获取 bean 的关键是 ApplicationContextAware 接口的实现提供了全文获取.这个 AOP 由工厂类在构造 bean 的时候实现.

#### 实例

-   全局代理 bean

我们可以用这种方法监控各个 bean 的行为

```java
@Component // 内部初始化上下文发现了 ApplicationContextAware,会对实现了该类的所有 Processor 进行加载
// 可以理解为全局代理增强
public class PostProcessor implements ApplicationContextAware, BeanPostProcessor {
    ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }

    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("init bean before:"+beanName);
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        System.out.println("init bean after:"+beanName);
        return bean;
    }
}
```

每个 bean 在初始化的时候都会执行

-   BeanPostProcessor 用于对方法的前置修饰
-   Aware 用于对变量的注入

全局变量的注入,理解了上文之后我们可以使用该变量注入不同的值,比如 session,可以用类似下文的方法,注入值

```java
public interface GlobalSessionAware extends Aware {
    /**
     * 注入全局的session
     *
     * @param session
     */
    public void setGlobalSession(GlobalSession session);
}
```

```java
@Component
public class GlobalSessionAwarePostProcessor implements BeanPostProcessor, ApplicationContextAware {
    private ApplicationContext applicationContext;
    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        Object session = this.applicationContext.getBean("globalSession");
        if (session == null) {
            return bean;
        }
      	// 全局前置(ApplicationContextAware) 的时候需要判断 只针对实现了 这个接口的类进行注入,或者换句话说
      	// 在执行前置构造的时候注入到类里面
        if (session instanceof GlobalSession && bean instanceof GlobalSessionAware) {
            ((GlobalSessionAware) bean).setGlobalSession((GlobalSession) session);
        }
        return bean;
    }
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
}
```

```java
@Component
public class WebTT implements GlobalSessionAware {
    private GlobalSession session;

    /**
     * GlobalSession
     *
     * @param session
     */
    @Override
    public void setGlobalSession(GlobalSession session) {
        this.session = session;
    }
}
```





## core

---

spring 的核心无非就是 ApplicationContext 的实现,我们先看其核心的接口的继承关系

-   BeanFactory 接口
    -   ApplicationContext 接口 积极加载,lazy 加载对单例
        -   ClassPathXmlApplicationContext
        -   FileSystemXMLApplicationContext
        -   **XmlWebApplicationContext** 加载 web 根目录下的配置
    -   DefaultListableBeanFactory 具体实现类 消极加载

我们来看下一spring是如何管理的bean的,涉及到以下实现

-   BeanFactory 的实现
-   ApplicationContext 的实现

循环依赖问题

spring 帮我们实现的是非构造器依赖的解耦

```java
@Component
public class A {
    @Autowired
    B b;

    {
        System.out.println("init a " + b);
    }
}

@Component
public class B {
    @Autowired
    A a;

    {
        System.out.println("init b "+a);
    }
}

/*控制台输出*/
/**
init a null
init b null
**/
```

制造个构造器依赖

```java
@Component
public class A {
    @Autowired
    public A(B b){

    }
}

@Component
public class B {
    @Autowired
    public B(A a){

    }
}


/*控制台输出*/
/**
***************************
APPLICATION FAILED TO START
***************************

Description:

The dependencies of some of the beans in the application context form a cycle:

┌─────┐
|  a defined in file [/Users/zhanghaoyang/IdeaProjects/springboot_workspace/distribution-component/target/classes/com/example/distcomponents/redundant/A.class]
↑     ↓
|  b defined in file [/Users/zhanghaoyang/IdeaProjects/springboot_workspace/distribution-component/target/classes/com/example/distcomponents/redundant/B.class]
└─────┘

**/
```

上面描述了 spring 的一些基本问题,我们来看其如何实现

### DefaultListableBeanFactory 的实现

主要数据结构

```java
public class DefaultListableBeanFactory extends AbstractAutowireCapableBeanFactory
		implements ConfigurableListableBeanFactory, BeanDefinitionRegistry, Serializable {
  /** Map of bean definition objects, keyed by bean name. */
	private final Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<>(256);
  
  /** List of bean definition names, in registration order. */
	private volatile List<String> beanDefinitionNames = new ArrayList<>(256);
  
}
```

主要方法

```java

@Override
public <T> T getBean(Class<T> requiredType, @Nullable Object... args) throws BeansException {
  Assert.notNull(requiredType, "Required type must not be null");
  Object resolved = resolveBean(ResolvableType.forRawClass(requiredType), args, false);
  if (resolved == null) {
    throw new NoSuchBeanDefinitionException(requiredType);
  }
  return (T) resolved;
}

@Nullable
private <T> T resolveBean(ResolvableType requiredType, @Nullable Object[] args, boolean nonUniqueAsNull) {
  NamedBeanHolder<T> namedBean = resolveNamedBean(requiredType, args, nonUniqueAsNull);
  // 这里是根据名字获取 bean 的重要函数
  // 我们追踪下下列方法 其调用链路如下
  // DefaultListableBeanFactory#resolveNamedBean -> DefaultListableBeanFactory#resolveNamedBean
  // -> DefaultListableBeanFactory#resolveNamedBean -> AbstractBeanFactory#getBean
  // -> AbstractBeanFactory#doGetBean -> AbstractBeanFactory#getObjectForBeanInstance
  // -> FactoryBeanRegistrySupport#getObjectFromFactoryBean [见下文]
  if (namedBean != null) {
    return namedBean.getBeanInstance();
  }
  BeanFactory parent = getParentBeanFactory(); // 获取其父工厂调用
  if (parent instanceof DefaultListableBeanFactory) {
    return ((DefaultListableBeanFactory) parent).resolveBean(requiredType, args, nonUniqueAsNull); 
  }
  else if (parent != null) {
    ObjectProvider<T> parentProvider = parent.getBeanProvider(requiredType);
    if (args != null) {
      return parentProvider.getObject(args); 
      // 这里可以从 BeanProvider 看到其是匿名内部类的实现,本质上还是使用了 resolveBean 去解决问题
      /*
      DefaultListableBeanFactory#getBeanProvider 的代码段如下
      ...
      @Override
			public T getObject() throws BeansException {
				T resolved = resolveBean(requiredType, null, false);
				if (resolved == null) {
					throw new NoSuchBeanDefinitionException(requiredType);
				}
				return resolved;
			}
			*/
    }
    else {
      return (nonUniqueAsNull ? parentProvider.getIfUnique() : parentProvider.getIfAvailable());
    }
  }
  return null;
}

// AbstractBeanFactory
```



### ClassPathXmlApplicationContext 的实现

```java
public ClassPathXmlApplicationContext(
			String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
			throws BeansException {

		super(parent); // 调用父类的构造器,设置父环境
		setConfigLocations(configLocations); // 设置环境变量
		if (refresh) {
			refresh(); // 刷新上下文,核心方法,真正的创建容器
		}
	}
```

### refresh 方法

我们重点关注 refresh 方法

该方法可以装载 spring 的容器

```java
@Override
	public void refresh() throws BeansException, IllegalStateException {
		synchronized (this.startupShutdownMonitor) {
			StartupStep contextRefresh = this.applicationStartup.start("spring.context.refresh");

			// Prepare this context for refreshing.
      // 初始化容器的状态,设置 spring 的启动日期,活动标志及验证必须
			prepareRefresh();

			// Tell the subclass to refresh the internal bean factory.
      // 销毁 BeanFactory 重新创建,把配置文件(包括注解)中的 bean 定义封装成 BeanDefinition
      // BeanDefinition 注册到 BeanFactory 的相关缓存中
      // 其中使用到的 BeanFactory 就是 DefaultListableFactory
			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

			// Prepare the bean factory for use in this context.
      // 准备 BeanFactory,进行配置 [见下文]
			prepareBeanFactory(beanFactory);

			try {
				// Allows post-processing of the bean factory in context subclasses.
        // 埋点让子类实现
				postProcessBeanFactory(beanFactory);

				StartupStep beanPostProcess = this.applicationStartup.start("spring.context.beans.post-process");
				// Invoke factory processors registered as beans in the context.
        // 实例化 BeanFactory 的所有 PostProcessor 并且**执行回调方法**
				invokeBeanFactoryPostProcessors(beanFactory);

				// Register bean processors that intercept bean creation.
        // 实例化 Bean 的所有 PostProcessor 
        // 这里只是注册还没有到真正的执行
				registerBeanPostProcessors(beanFactory);
				beanPostProcess.end();

				// Initialize message source for this context.
				initMessageSource();

				// Initialize event multicaster for this context.
				initApplicationEventMulticaster();

				// Initialize other special beans in specific context subclasses.
        // 空实现,埋点
				onRefresh();

				// Check for listener beans and register them.
        // 注册所有的 Listener
				registerListeners();

				// Instantiate all remaining (non-lazy-init) singletons.
        // 实例化所以剩余的普通非延迟的 bean 核心方法 [见下文]
				finishBeanFactoryInitialization(beanFactory);

				// Last step: publish corresponding event.
        // 发布事件,回调SmartLifecycle.start()
				finishRefresh();
			}

			catch (BeansException ex) {
				if (logger.isWarnEnabled()) {
					logger.warn("Exception encountered during context initialization - " +
							"cancelling refresh attempt: " + ex);
				}

				// Destroy already created singletons to avoid dangling resources.
				destroyBeans();

				// Reset 'active' flag.
				cancelRefresh(ex);

				// Propagate exception to caller.
				throw ex;
			}

			finally {
				// Reset common introspection caches in Spring's core, since we
				// might not ever need metadata for singleton beans anymore...
				resetCommonCaches();
				contextRefresh.end();
			}
		}
	}
```

### prepareBeanFactory

该方法在 obtainFreshBeanFactory 中使用

```java
// 准备 BeanFactory
// BeanFactory 是制造 bean 的工厂,生产 bean 的时候需要注意
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
		// Tell the internal bean factory to use the context's class loader etc.
		beanFactory.setBeanClassLoader(getClassLoader());
		if (!shouldIgnoreSpel) {
			beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
		}
		beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, getEnvironment()));

		// Configure the bean factory with context callbacks.
  	// bean 的前置加载器从这里被添加进去
  	// 忽略一些 aware 接口,这些 aware 接口可以通过更顶层的忌口进行加载(例如在context里而不是BeanFactory)
  	// 这个忽略不是 @Autowired
		beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
		beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
		beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
		beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
		beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
		beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
		beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);
		beanFactory.ignoreDependencyInterface(ApplicationStartupAware.class);

		// BeanFactory interface not registered as resolvable type in a plain factory.
		// MessageSource registered (and found for autowiring) as a bean.
  	// registerResolvableDependency 是如果接口由多个实现加载哪一个类,如果没有指定这个 spring 可能会报错
    // 或者选择不同的类去变成该接口的实现 (name,类型注入) 可能导致错误
  	// 这里相当于指定唯一的实现类
		beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
		beanFactory.registerResolvableDependency(ResourceLoader.class, this);
		beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
		beanFactory.registerResolvableDependency(ApplicationContext.class, this);

		// Register early post-processor for detecting inner beans as ApplicationListeners.
    // 添加前置处理器,可以添加多个,
		beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));

		// Detect a LoadTimeWeaver and prepare for weaving, if found.
		if (!NativeDetector.inNativeImage() && beanFactory.containsBean(LOAD_TIME_WEAVER_BEAN_NAME)) {
			beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
			// Set a temporary ClassLoader for type matching.
			beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
		}

		// Register default environment beans.
		if (!beanFactory.containsLocalBean(ENVIRONMENT_BEAN_NAME)) {
			beanFactory.registerSingleton(ENVIRONMENT_BEAN_NAME, getEnvironment());
		}
		if (!beanFactory.containsLocalBean(SYSTEM_PROPERTIES_BEAN_NAME)) {
			beanFactory.registerSingleton(SYSTEM_PROPERTIES_BEAN_NAME, getEnvironment().getSystemProperties());
		}
		if (!beanFactory.containsLocalBean(SYSTEM_ENVIRONMENT_BEAN_NAME)) {
			beanFactory.registerSingleton(SYSTEM_ENVIRONMENT_BEAN_NAME, getEnvironment().getSystemEnvironment());
		}
		if (!beanFactory.containsLocalBean(APPLICATION_STARTUP_BEAN_NAME)) {
			beanFactory.registerSingleton(APPLICATION_STARTUP_BEAN_NAME, getApplicationStartup());
		}
	}
```

### finishBeanFactoryInitialization

该方法用于初始化 beanFactory 和 bean 的初始化

```java
String CONVERSION_SERVICE_BEAN_NAME = "conversionService";	
/**
	 * Finish the initialization of this context's bean factory,
	 * initializing all remaining singleton beans.
	 */
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
  // Initialize conversion service for this context.
  // 这里通常是配合 springmvc 去做类型的装换,用于初始化转换的服务
  if (beanFactory.containsBean(CONVERSION_SERVICE_BEAN_NAME) &&
      beanFactory.isTypeMatch(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class)) {
    beanFactory.setConversionService(
      beanFactory.getBean(CONVERSION_SERVICE_BEAN_NAME, ConversionService.class));
  }

  // Register a default embedded value resolver if no BeanFactoryPostProcessor
  // (such as a PropertySourcesPlaceholderConfigurer bean) registered any before:
  // at this point, primarily for resolution in annotation attribute values.
  // 对值进行处理的 resolver 注入,否则就使用默认的
  if (!beanFactory.hasEmbeddedValueResolver()) {
    beanFactory.addEmbeddedValueResolver(strVal -> getEnvironment().resolvePlaceholders(strVal));
  }

  // Initialize LoadTimeWeaverAware beans early to allow for registering their transformers early.
  // 这里一般是 AspectJ 在 class 文件加载的时候就继续拿给你动态的织入
  String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
  for (String weaverAwareName : weaverAwareNames) {
    getBean(weaverAwareName);
  }

  // Stop using the temporary ClassLoader for type matching.
  // 停用临时加载器
  beanFactory.setTempClassLoader(null);

  // Allow for caching all bean definition metadata, not expecting further changes.
  // 冻结定义,不允许修改
  beanFactory.freezeConfiguration();

  // Instantiate all remaining (non-lazy-init) singletons.
  // 实例化所有非延迟加载的 bean
  beanFactory.preInstantiateSingletons();
}
```

```java
/***
	初始化使用 getBean 获取对象
	afterSingletonsInstantiated 进行方法回调
**/
@Override
public void preInstantiateSingletons() throws BeansException {
  if (logger.isTraceEnabled()) {
    logger.trace("Pre-instantiating singletons in " + this);
  }

  // Iterate over a copy to allow for init methods which in turn register new bean definitions.
  // While this may not be part of the regular factory bootstrap, it does otherwise work fine.
  List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);

  // Trigger initialization of all non-lazy singleton beans...
  for (String beanName : beanNames) {
    // 合并 parent 的 beanDefinition
    RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
    if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
      if (isFactoryBean(beanName)) {
        Object bean = getBean(FACTORY_BEAN_PREFIX + beanName); // 工厂列的加载
        if (bean instanceof FactoryBean) {
          FactoryBean<?> factory = (FactoryBean<?>) bean;
          boolean isEagerInit;
          if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
            isEagerInit = AccessController.doPrivileged(
              (PrivilegedAction<Boolean>) ((SmartFactoryBean<?>) factory)::isEagerInit,
              getAccessControlContext());
          }
          else {
            isEagerInit = (factory instanceof SmartFactoryBean &&
                           ((SmartFactoryBean<?>) factory).isEagerInit());
          }
          if (isEagerInit) {
            getBean(beanName);
          }
        }
      }
      else {
        getBean(beanName); // 核心方法初始化
      }
    }
  }

  // Trigger post-initialization callback for all applicable beans...
  for (String beanName : beanNames) {
    Object singletonInstance = getSingleton(beanName);
    if (singletonInstance instanceof SmartInitializingSingleton) {
      StartupStep smartInitialize = this.getApplicationStartup().start("spring.beans.smart-initialize")
        .tag("beanName", beanName);
      SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
      if (System.getSecurityManager() != null) {
        AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
          smartSingleton.afterSingletonsInstantiated(); // 回调
          return null;
        }, getAccessControlContext());
      }
      else {
        smartSingleton.afterSingletonsInstantiated(); // 回调
      }
      smartInitialize.end();
    }
  }
}
```

### 通用获取对象方法 getBean

下面涉及到 AbstractBeanFactory,DefaultSingletonBeanRegistry

```java
// AbstractBeanFactory
@Override
public Object getBean(String name) throws BeansException {
  return doGetBean(name, null, null, false);
}


// DefaultSingletonBeanRegistry

/** Cache of singleton objects: bean name to bean instance. */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

/** Cache of early singleton objects: bean name to bean instance. */
private final Map<String, Object> earlySingletonObjects = new ConcurrentHashMap<>(16);

/** Cache of singleton factories: bean name to ObjectFactory. */
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);

/**
下面三个都是用于创建过程中的标志性缓存
**/
/** Set of registered singletons, containing the bean names in registration order. */
private final Set<String> registeredSingletons = new LinkedHashSet<>(256);

/** Names of beans that are currently in creation. */
private final Set<String> singletonsCurrentlyInCreation =
  Collections.newSetFromMap(new ConcurrentHashMap<>(16));

/** Names of beans currently excluded from in creation checks. */
private final Set<String> inCreationCheckExclusions =
  Collections.newSetFromMap(new ConcurrentHashMap<>(16));

/**
	 * Return the (
	 ) singleton object registered under the given name.
	 * <p>Checks already instantiated singletons and also allows for an early
	 * reference to a currently created singleton (resolving a circular reference).
	 * @param beanName the name of the bean to look for
	 * @param allowEarlyReference whether early references should be created or not
	 * @return the registered singleton object, or {@code null} if none found
	 */
/**
 doGetBean 方法的支持方法,从缓冲中获取单例对象,下同
*/
@Nullable
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
  // Quick check for existing instance without full singleton lock
  Object singletonObject = this.singletonObjects.get(beanName);
  if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
    singletonObject = this.earlySingletonObjects.get(beanName);
    if (singletonObject == null && allowEarlyReference) {
      // 对缓存进行加锁,只允许一个线程操作这些缓存
      synchronized (this.singletonObjects) {
        // Consistent creation of early reference within full singleton lock
        // 下面分别从是三个缓存中尝试获取对象,依次是
        // singletonObjects,earlySingletonObjects,singletonFactories
        // 如果还获取不到直接使用工厂类创建对象然后移除工厂类内创建对象的缓存
        singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
          singletonObject = this.earlySingletonObjects.get(beanName);
          if (singletonObject == null) {
            ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
            if (singletonFactory != null) {
              singletonObject = singletonFactory.getObject(); // 创建对象
              this.earlySingletonObjects.put(beanName, singletonObject);
              this.singletonFactories.remove(beanName);
            }
          }
        }
      }
    }
  }
  return singletonObject;
}
/**
	 * Return the (raw) singleton object registered under the given name,
	 * creating and registering a new one if none registered yet.
	 * @param beanName the name of the bean
	 * @param singletonFactory the ObjectFactory to lazily create the singleton
	 * with, if necessary
	 * @return the registered singleton object
	 */
public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
  Assert.notNull(beanName, "Bean name must not be null");
  synchronized (this.singletonObjects) {
    Object singletonObject = this.singletonObjects.get(beanName);
    if (singletonObject == null) {
      if (this.singletonsCurrentlyInDestruction) {
        throw new BeanCreationNotAllowedException(beanName,
                                                  "Singleton bean creation not allowed while singletons of this factory are in destruction " +
                                                  "(Do not request a bean from a BeanFactory in a destroy method implementation!)");
      }
      if (logger.isDebugEnabled()) {
        logger.debug("Creating shared instance of singleton bean '" + beanName + "'");
      }
      // 添加到创建的缓存
      beforeSingletonCreation(beanName);
      boolean newSingleton = false;
      boolean recordSuppressedExceptions = (this.suppressedExceptions == null);
      if (recordSuppressedExceptions) {
        this.suppressedExceptions = new LinkedHashSet<>();
      }
      try {
        singletonObject = singletonFactory.getObject(); // 和上面一致调用 getObject 方法获取对象
        newSingleton = true;
      }
      catch (IllegalStateException ex) {
        // Has the singleton object implicitly appeared in the meantime ->
        // if yes, proceed with it since the exception indicates that state.
        singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
          throw ex;
        }
      }
      catch (BeanCreationException ex) {
        if (recordSuppressedExceptions) {
          for (Exception suppressedException : this.suppressedExceptions) {
            ex.addRelatedCause(suppressedException);
          }
        }
        throw ex;
      }
      finally {
        if (recordSuppressedExceptions) {
          this.suppressedExceptions = null;
        }
        afterSingletonCreation(beanName);
      }
      if (newSingleton) {
        addSingleton(beanName, singletonObject);
      }
    }
    return singletonObject;
  }
}

protected <T> T doGetBean(
			String name, @Nullable Class<T> requiredType, @Nullable Object[] args, boolean typeCheckOnly)
			throws BeansException {

		String beanName = transformedBeanName(name);
		Object beanInstance;

		// Eagerly check singleton cache for manually registered singletons.
  	// 如上方法从单例的缓存中获取单例,该方法可以解决非构造器的循环依赖
		Object sharedInstance = getSingleton(beanName);
		if (sharedInstance != null && args == null) {
			if (logger.isTraceEnabled()) {
				if (isSingletonCurrentlyInCreation(beanName)) {
					logger.trace("Returning eagerly cached instance of singleton bean '" + beanName +
							"' that is not fully initialized yet - a consequence of a circular reference");
				}
				else {
					logger.trace("Returning cached instance of singleton bean '" + beanName + "'");
				}
			}
			beanInstance = getObjectForBeanInstance(sharedInstance, name, beanName, null);
		}

		else {
			// Fail if we're already creating this bean instance:
			// We're assumably within a circular reference.
			if (isPrototypeCurrentlyInCreation(beanName)) {
				throw new BeanCurrentlyInCreationException(beanName);
			}

			// Check if bean definition exists in this factory.
			BeanFactory parentBeanFactory = getParentBeanFactory();
			if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
				// Not found -> check parent.
				String nameToLookup = originalBeanName(name);
				if (parentBeanFactory instanceof AbstractBeanFactory) {
					return ((AbstractBeanFactory) parentBeanFactory).doGetBean(
							nameToLookup, requiredType, args, typeCheckOnly);
				}
				else if (args != null) {
					// Delegation to parent with explicit args.
					return (T) parentBeanFactory.getBean(nameToLookup, args);
				}
				else if (requiredType != null) {
					// No args -> delegate to standard getBean method.
					return parentBeanFactory.getBean(nameToLookup, requiredType);
				}
				else {
					return (T) parentBeanFactory.getBean(nameToLookup);
				}
			}

			if (!typeCheckOnly) {
				markBeanAsCreated(beanName);
			}

			StartupStep beanCreation = this.applicationStartup.start("spring.beans.instantiate")
					.tag("beanName", name);
			try {
				if (requiredType != null) {
					beanCreation.tag("beanType", requiredType::toString);
				}
				RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
				checkMergedBeanDefinition(mbd, beanName, args);

				// Guarantee initialization of beans that the current bean depends on.
				String[] dependsOn = mbd.getDependsOn();
				if (dependsOn != null) {
					for (String dep : dependsOn) {
						if (isDependent(beanName, dep)) {
							throw new BeanCreationException(mbd.getResourceDescription(), beanName,
									"Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
						}
						registerDependentBean(dep, beanName);
						try {
							getBean(dep); // 先创建需要依赖的对象
						}
						catch (NoSuchBeanDefinitionException ex) {
							throw new BeanCreationException(mbd.getResourceDescription(), beanName,
									"'" + beanName + "' depends on missing bean '" + dep + "'", ex);
						}
					}
				}
				// 创建完依赖的对象后开始创建本对象
				// Create bean instance.
				if (mbd.isSingleton()) {
					sharedInstance = getSingleton(beanName, () -> {
						try {
							return createBean(beanName, mbd, args);
						}
						catch (BeansException ex) {
							// Explicitly remove instance from singleton cache: It might have been put there
							// eagerly by the creation process, to allow for circular reference resolution.
							// Also remove any beans that received a temporary reference to the bean.
							destroySingleton(beanName);
							throw ex;
						}
					});
					beanInstance = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
				}

				else if (mbd.isPrototype()) {
					// It's a prototype -> create a new instance.
					Object prototypeInstance = null;
					try {
						beforePrototypeCreation(beanName);
						prototypeInstance = createBean(beanName, mbd, args);
					}
					finally {
						afterPrototypeCreation(beanName);
					}
					beanInstance = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
				}

				else {
					String scopeName = mbd.getScope();
					if (!StringUtils.hasLength(scopeName)) {
						throw new IllegalStateException("No scope name defined for bean ´" + beanName + "'");
					}
					Scope scope = this.scopes.get(scopeName);
					if (scope == null) {
						throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
					}
					try {
						Object scopedInstance = scope.get(beanName, () -> {
							beforePrototypeCreation(beanName);
							try {
								return createBean(beanName, mbd, args);
							}
							finally {
								afterPrototypeCreation(beanName);
							}
						});
						beanInstance = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
					}
					catch (IllegalStateException ex) {
						throw new ScopeNotActiveException(beanName, scopeName, ex);
					}
				}
			}
			catch (BeansException ex) {
				beanCreation.tag("exception", ex.getClass().toString());
				beanCreation.tag("message", String.valueOf(ex.getMessage()));
				cleanupAfterBeanCreationFailure(beanName);
				throw ex;
			}
			finally {
				beanCreation.end();
			}
		}

		return adaptBeanInstance(name, beanInstance, requiredType);
	}

// 下面连个方法是 createBean 的辅助方法,允许执行前置器
/**
	 * Apply before-instantiation post-processors, resolving whether there is a
	 * before-instantiation shortcut for the specified bean.
	 * @param beanName the name of the bean
	 * @param mbd the bean definition for the bean
	 * @return the shortcut-determined bean instance, or {@code null} if none
	 */
	@Nullable
	protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
		Object bean = null;
		if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
			// Make sure bean class is actually resolved at this point.
			if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
				Class<?> targetType = determineTargetType(beanName, mbd);
				if (targetType != null) {
					bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
					if (bean != null) {
						bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
					}
				}
			}
			mbd.beforeInstantiationResolved = (bean != null);
		}
		return bean;
	}
/**
	 * Apply InstantiationAwareBeanPostProcessors to the specified bean definition
	 * (by class and name), invoking their {@code postProcessBeforeInstantiation} methods.
	 * <p>Any returned object will be used as the bean instead of actually instantiating
	 * the target bean. A {@code null} return value from the post-processor will
	 * result in the target bean being instantiated.
	 * @param beanClass the class of the bean to be instantiated
	 * @param beanName the name of the bean
	 * @return the bean object to use instead of a default instance of the target bean, or {@code null}
	 * @see InstantiationAwareBeanPostProcessor#postProcessBeforeInstantiation
	 */
// 这里可以看到的是这里会执行所有的其中前置器执行相应的代理
@Nullable
protected Object applyBeanPostProcessorsBeforeInstantiation(Class<?> beanClass, String beanName) {
  for (InstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().instantiationAware) {
    Object result = bp.postProcessBeforeInstantiation(beanClass, beanName);
    if (result != null) {
      return result;
    }
  }
  return null;
}
```

### 通用创建对象 createBean 

```java
// createBean 方法在 AbstractAutowireCapableBeanFactory 里,最终调用 doGreateBean
	@Override
	protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
			throws BeanCreationException {

		if (logger.isTraceEnabled()) {
			logger.trace("Creating instance of bean '" + beanName + "'");
		}
		RootBeanDefinition mbdToUse = mbd;

		// Make sure bean class is actually resolved at this point, and
		// clone the bean definition in case of a dynamically resolved Class
		// which cannot be stored in the shared merged bean definition.
		Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
		if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
			mbdToUse = new RootBeanDefinition(mbd);
			mbdToUse.setBeanClass(resolvedClass);
		}

		// Prepare method overrides.
		try {
			mbdToUse.prepareMethodOverrides();
		}
		catch (BeanDefinitionValidationException ex) {
			throw new BeanDefinitionStoreException(mbdToUse.getResourceDescription(),
					beanName, "Validation of method overrides failed", ex);
		}

		try {
			// Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
      // 这里如上完成对 bean 的前置器的处理
			Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
			if (bean != null) {
				return bean;
			}
		}
		catch (Throwable ex) {
			throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
					"BeanPostProcessor before instantiation of bean failed", ex);
		}

		try {
			Object beanInstance = doCreateBean(beanName, mbdToUse, args);
			if (logger.isTraceEnabled()) {
				logger.trace("Finished creating instance of bean '" + beanName + "'");
			}
			return beanInstance;
		}
		catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
			// A previously detected exception with proper bean creation context already,
			// or illegal singleton state to be communicated up to DefaultSingletonBeanRegistry.
			throw ex;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
		}
	}

/**
	 * Actually create the specified bean. Pre-creation processing has already happened
	 * at this point, e.g. checking {@code postProcessBeforeInstantiation} callbacks.
	 * <p>Differentiates between default bean instantiation, use of a
	 * factory method, and autowiring a constructor.
	 * @param beanName the name of the bean
	 * @param mbd the merged bean definition for the bean
	 * @param args explicit arguments to use for constructor or factory method invocation
	 * @return a new instance of the bean
	 * @throws BeanCreationException if the bean could not be created
	 * @see #instantiateBean
	 * @see #instantiateUsingFactoryMethod
	 * @see #autowireConstructor
	 */
	protected Object doCreateBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
			throws BeanCreationException {

		// Instantiate the bean.
		BeanWrapper instanceWrapper = null;
		if (mbd.isSingleton()) {
			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
		}
		if (instanceWrapper == null) {
      // 创建 bean 对象的 wrapper
			instanceWrapper = createBeanInstance(beanName, mbd, args);
		}
		Object bean = instanceWrapper.getWrappedInstance();
		Class<?> beanType = instanceWrapper.getWrappedClass(); // 得到 warp 的对象内容
		if (beanType != NullBean.class) {
			mbd.resolvedTargetType = beanType;
		}

		// Allow post-processors to modify the merged bean definition.
		synchronized (mbd.postProcessingLock) {
			if (!mbd.postProcessed) {
				try {
          // 执行前置器合并,同上执行
					applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
				}
				catch (Throwable ex) {
					throw new BeanCreationException(mbd.getResourceDescription(), beanName,
							"Post-processing of merged bean definition failed", ex);
				}
				mbd.postProcessed = true;
			}
		}

    /**
    	通过缓存区获取提前暴露的对象的引用
    **/
		// Eagerly cache singletons to be able to resolve circular references
		// even when triggered by lifecycle interfaces like BeanFactoryAware.
		boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
				isSingletonCurrentlyInCreation(beanName));
		if (earlySingletonExposure) {
			if (logger.isTraceEnabled()) {
				logger.trace("Eagerly caching bean '" + beanName +
						"' to allow for resolving potential circular references");
			}
			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
		}

		// Initialize the bean instance.
		Object exposedObject = bean;
		try {
      // 通过 setter 注入 bean,根据反射注入属性值
      // 这里执行了
      // (埋点) postProcessPostInstantiation
      // BeanPostProcessor
      // (埋点) postProcessAfterInstantiation
      // 这三个方法 可对应上图,下文会详细讲述这个方法
			populateBean(beanName, mbd, instanceWrapper);
      // 初始化 bean
			exposedObject = initializeBean(beanName, exposedObject, mbd);
		}
		catch (Throwable ex) {
			if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
				throw (BeanCreationException) ex;
			}
			else {
				throw new BeanCreationException(
						mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
			}
		}

		if (earlySingletonExposure) {
			Object earlySingletonReference = getSingleton(beanName, false);
			if (earlySingletonReference != null) {
				if (exposedObject == bean) {
					exposedObject = earlySingletonReference;
				}
				else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
					String[] dependentBeans = getDependentBeans(beanName);
					Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
					for (String dependentBean : dependentBeans) {
						if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
							actualDependentBeans.add(dependentBean);
						}
					}
					if (!actualDependentBeans.isEmpty()) {
						throw new BeanCurrentlyInCreationException(beanName,
								"Bean with name '" + beanName + "' has been injected into other beans [" +
								StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
								"] in its raw version as part of a circular reference, but has eventually been " +
								"wrapped. This means that said other beans do not use the final version of the " +
								"bean. This is often the result of over-eager type matching - consider using " +
								"'getBeanNamesForType' with the 'allowEagerInit' flag turned off, for example.");
					}
				}
			}
		}

		// Register bean as disposable.
		try {
			registerDisposableBeanIfNecessary(beanName, bean, mbd);
		}
		catch (BeanDefinitionValidationException ex) {
			throw new BeanCreationException(
					mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
		}

		return exposedObject;
	}
```



### 创建单例 getObject

关键方法是 getObject,我们看到其类型如下,ObjectProvider

```java
@FunctionalInterface
public interface ObjectFactory<T> {

	/**
	 * Return an instance (possibly shared or independent)
	 * of the object managed by this factory.
	 * @return the resulting instance
	 * @throws BeansException in case of creation errors
	 */
	T getObject() throws BeansException;

}
public interface ObjectProvider<T> extends ObjectFactory<T>, Iterable<T> {
  //...
}
/**
	 * Serializable ObjectFactory/ObjectProvider for lazy resolution of a dependency.
	 */
private class DependencyObjectProvider implements BeanObjectProvider<Object> {
  
  @Override
  public Object getObject() throws BeansException {
    if (this.optional) {
      return createOptionalDependency(this.descriptor, this.beanName);
    }
    else {
      Object result = doResolveDependency(this.descriptor, this.beanName, null, null);
      if (result == null) {
        throw new NoSuchBeanDefinitionException(this.descriptor.getResolvableType());
      }
      return result;
    }
  }
  
  
  @Override
  public Object getObject(final Object... args) throws BeansException {
    if (this.optional) {
      return createOptionalDependency(this.descriptor, this.beanName, args);
    }
    else {
      DependencyDescriptor descriptorToUse = new DependencyDescriptor(this.descriptor) {
        @Override
        public Object resolveCandidate(String beanName, Class<?> requiredType, BeanFactory beanFactory) {
          return beanFactory.getBean(beanName, args);
        }
      };
      Object result = doResolveDependency(descriptorToUse, this.beanName, null, null);
      if (result == null) {
        throw new NoSuchBeanDefinitionException(this.descriptor.getResolvableType());
      }
      return result;
    }
  }
}


@Nullable
	public Object doResolveDependency(DependencyDescriptor descriptor, @Nullable String beanName,
			@Nullable Set<String> autowiredBeanNames, @Nullable TypeConverter typeConverter) throws BeansException {

		InjectionPoint previousInjectionPoint = ConstructorResolver.setCurrentInjectionPoint(descriptor);
		try {
			Object shortcut = descriptor.resolveShortcut(this);
			if (shortcut != null) {
				return shortcut;
			}

			Class<?> type = descriptor.getDependencyType();
      // 读取 @Value 的值进行注入
			Object value = getAutowireCandidateResolver().getSuggestedValue(descriptor);
			if (value != null) {
				if (value instanceof String) {
					String strVal = resolveEmbeddedValue((String) value);
					BeanDefinition bd = (beanName != null && containsBean(beanName) ?
							getMergedBeanDefinition(beanName) : null);
					value = evaluateBeanDefinitionString(strVal, bd);
				}
				TypeConverter converter = (typeConverter != null ? typeConverter : getTypeConverter());
				try {
					return converter.convertIfNecessary(value, type, descriptor.getTypeDescriptor());
				}
				catch (UnsupportedOperationException ex) {
					// A custom TypeConverter which does not support TypeDescriptor resolution...
					return (descriptor.getField() != null ?
							converter.convertIfNecessary(value, type, descriptor.getField()) :
							converter.convertIfNecessary(value, type, descriptor.getMethodParameter()));
				}
			}
			// 解析结合依赖
			Object multipleBeans = resolveMultipleBeans(descriptor, beanName, autowiredBeanNames, typeConverter);
			if (multipleBeans != null) {
				return multipleBeans;
			}

			Map<String, Object> matchingBeans = findAutowireCandidates(beanName, type, descriptor);
			if (matchingBeans.isEmpty()) {
				if (isRequired(descriptor)) {
					raiseNoMatchingBeanFound(type, descriptor.getResolvableType(), descriptor);
				}
				return null;
			}

			String autowiredBeanName;
			Object instanceCandidate;

			if (matchingBeans.size() > 1) {
				autowiredBeanName = determineAutowireCandidate(matchingBeans, descriptor);
				if (autowiredBeanName == null) {
					if (isRequired(descriptor) || !indicatesMultipleBeans(type)) {
						return descriptor.resolveNotUnique(descriptor.getResolvableType(), matchingBeans);
					}
					else {
						// In case of an optional Collection/Map, silently ignore a non-unique case:
						// possibly it was meant to be an empty collection of multiple regular beans
						// (before 4.3 in particular when we didn't even look for collection beans).
						return null;
					}
				}
				instanceCandidate = matchingBeans.get(autowiredBeanName);
			}
			else {
				// We have exactly one match.
				Map.Entry<String, Object> entry = matchingBeans.entrySet().iterator().next();
				autowiredBeanName = entry.getKey();
				instanceCandidate = entry.getValue();
			}

			if (autowiredBeanNames != null) {
				autowiredBeanNames.add(autowiredBeanName);
			}
			if (instanceCandidate instanceof Class) {
				instanceCandidate = descriptor.resolveCandidate(autowiredBeanName, type, this);
			}
			Object result = instanceCandidate;
			if (result instanceof NullBean) {
				if (isRequired(descriptor)) {
					raiseNoMatchingBeanFound(type, descriptor.getResolvableType(), descriptor);
				}
				result = null;
			}
			if (!ClassUtils.isAssignableValue(type, result)) {
				throw new BeanNotOfRequiredTypeException(autowiredBeanName, type, instanceCandidate.getClass());
			}
			return result;
		}
		finally {
			ConstructorResolver.setCurrentInjectionPoint(previousInjectionPoint);
		}
	}
```

### bean 生命周期的源码

如上 createBean 代码段

```java
try {
			// Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
      // 这里如上完成对 bean 的前置器的处理
			Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
			if (bean != null) {
				return bean;
			}
		}
		catch (Throwable ex) {
			throw new BeanCreationException(mbdToUse.getResourceDescription(), beanName,
					"BeanPostProcessor before instantiation of bean failed", ex);
		}

		try {
			Object beanInstance = doCreateBean(beanName, mbdToUse, args);
			if (logger.isTraceEnabled()) {
				logger.trace("Finished creating instance of bean '" + beanName + "'");
			}
			return beanInstance;
		}
		catch (BeanCreationException | ImplicitlyAppearedSingletonException ex) {
			// A previously detected exception with proper bean creation context already,
			// or illegal singleton state to be communicated up to DefaultSingletonBeanRegistry.
			throw ex;
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					mbdToUse.getResourceDescription(), beanName, "Unexpected exception during bean creation", ex);
		}
```

-   createBean
    -   执行了 BeanPostProcessor 的前置阶段埋点
    -   invoke populateBean 该方法对应下图 BeanPostProcessor 执行的后置阶段埋点
        -   执行bean构造器
        -   为bean注入属性
    -   invoke initializeBean
        -   执行 init 方法

![创建过程2](https://images2017.cnblogs.com/blog/256554/201709/256554-20170919234704353-487869759.png)

```java
/**
	 * Populate the bean instance in the given BeanWrapper with the property values
	 * from the bean definition.
	 * @param beanName the name of the bean
	 * @param mbd the bean definition for the bean
	 * @param bw the BeanWrapper with bean instance
	 */
	@SuppressWarnings("deprecation")  // for postProcessPropertyValues
	protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {
		if (bw == null) {
			if (mbd.hasPropertyValues()) {
				throw new BeanCreationException(
						mbd.getResourceDescription(), beanName, "Cannot apply property values to null instance");
			}
			else {
				// Skip property population phase for null instance.
				return;
			}
		}

		// Give any InstantiationAwareBeanPostProcessors the opportunity to modify the
		// state of the bean before properties are set. This can be used, for example,
		// to support styles of field injection.
    // 执行 bean 的前置依赖 在 bean 实例化之后，属性填充（初始化）之前，
    // 回调InstantiationAwareBeanPostProcessor后处理器的
    // postProcessAfterInstantiation方法,可用于修改bean实例的状态
		if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
			for (InstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().instantiationAware) {
        // 前置处理器的后置处理方法 postprocessAfterInstantiation
				if (!bp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
					return;
				}
			}
		}

		PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);

		int resolvedAutowireMode = mbd.getResolvedAutowireMode();
		if (resolvedAutowireMode == AUTOWIRE_BY_NAME || resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
			MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
			// Add property values based on autowire by name if applicable.
			if (resolvedAutowireMode == AUTOWIRE_BY_NAME) {
				autowireByName(beanName, mbd, bw, newPvs);
			}
			// Add property values based on autowire by type if applicable.
			if (resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
				autowireByType(beanName, mbd, bw, newPvs);
			}
			pvs = newPvs;
		}
    
		// 是否具有InstantiationAwareBeanPostProcessor这个后处理器
		boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
		boolean needsDepCheck = (mbd.getDependencyCheck() != AbstractBeanDefinition.DEPENDENCY_CHECK_NONE);

		PropertyDescriptor[] filteredPds = null;
		if (hasInstAwareBpps) {
			if (pvs == null) {
				pvs = mbd.getPropertyValues();
			}
			for (InstantiationAwareBeanPostProcessor bp : getBeanPostProcessorCache().instantiationAware) {
        // 执行 postProcessProperties
				PropertyValues pvsToUse = bp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
				if (pvsToUse == null) {
					if (filteredPds == null) {
						filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
					}
          // 执行 postProcessPropertyValues
					pvsToUse = bp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
					if (pvsToUse == null) {
						return;
					}
				}
				pvs = pvsToUse;
			}
		}
		if (needsDepCheck) {
			if (filteredPds == null) {
				filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
			}
			checkDependencies(beanName, mbd, filteredPds, pvs);
		}
		// 给bean注入值
		if (pvs != null) {
			applyPropertyValues(beanName, mbd, bw, pvs);
		}
	}
```

```java
/**
	 * Initialize the given bean instance, applying factory callbacks
	 * as well as init methods and bean post processors.
	 * <p>Called from {@link #createBean} for traditionally defined beans,
	 * and from {@link #initializeBean} for existing bean instances.
	 * @param beanName the bean name in the factory (for debugging purposes)
	 * @param bean the new bean instance we may need to initialize
	 * @param mbd the bean definition that the bean was created with
	 * (can also be {@code null}, if given an existing bean instance)
	 * @return the initialized bean instance (potentially wrapped)
	 * @see BeanNameAware
	 * @see BeanClassLoaderAware
	 * @see BeanFactoryAware
	 * @see #applyBeanPostProcessorsBeforeInitialization
	 * @see #invokeInitMethods
	 * @see #applyBeanPostProcessorsAfterInitialization
	 */
	protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
    // 从这里可以看到 aware 方法 在 bean 的 init-method 之前
		if (System.getSecurityManager() != null) {
			AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
				invokeAwareMethods(beanName, bean);
				return null;
			}, getAccessControlContext());
		}
		else {
			invokeAwareMethods(beanName, bean);
		}

		Object wrappedBean = bean;
		if (mbd == null || !mbd.isSynthetic()) {
      // init 方法前置处理器
			wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
		}

		try {
      // 调用 init 方法
			invokeInitMethods(beanName, wrappedBean, mbd);
		}
		catch (Throwable ex) {
			throw new BeanCreationException(
					(mbd != null ? mbd.getResourceDescription() : null),
					beanName, "Invocation of init method failed", ex);
		}
		if (mbd == null || !mbd.isSynthetic()) {
      // 调用 init 后置处理器
			wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
		}

		return wrappedBean;
	}
```



### 细节和疑问

-   循环依赖的解决方法
-   ASM(cglib) 和 JDK 动态代理的使用

#### 循环依赖

三级缓存,`getSingeton`中内部通过缓存依赖进行了保存

```java
/** Cache of singleton objects: bean name to bean instance. */
// 一级缓存
// 已经创建好的对象
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

/** Cache of early singleton objects: bean name to bean instance. */
// 二级缓存
// 正在被工厂创建的对象的引用,通过 addSingletonFactory -> getEarlyBeanReference 添加到该 map中
private final Map<String, Object> earlySingletonObjects = new ConcurrentHashMap<>(16);

/** Cache of singleton factories: bean name to ObjectFactory. */
// 三级缓存
// 创建对象的工厂的引用
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);
```

```java
@Nullable
protected Object getSingleton(String beanName, boolean allowEarlyReference) {
  Object singletonObject = this.singletonObjects.get(beanName);
  if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
    singletonObject = this.earlySingletonObjects.get(beanName);
    if (singletonObject == null && allowEarlyReference) {
      synchronized (this.singletonObjects) {
        singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
          singletonObject = this.earlySingletonObjects.get(beanName);
          if (singletonObject == null) {
            ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
            if (singletonFactory != null) {
              singletonObject = singletonFactory.getObject(); // 创建对象
              this.earlySingletonObjects.put(beanName, singletonObject);
              this.singletonFactories.remove(beanName);
            }
          }
        }
      }
    }
  }
  return singletonObject;
}
```

#### JDK 动态代理和 CGLIB

JDK 是基于接口实现的 proxy,CGLIB是通过 ASM 框架修改字节码实现的动态继承代理.spring 默认是使用 JDK 动态代理,当使用 AspectJ的时候使用CGlib进行代理.

关于二者性能,cglib 在代理性能上比 JDK 动态代理要快很多,但JDK动态代理在创建对象的性能上要比cglib要快,根据spring的应用场景,更加适合使用JDK.

