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
		if (bean instanceof EnvironmentAware) {
			((EnvironmentAware) bean).setEnvironment(this.applicationContext.getEnvironment());
		}
		if (bean instanceof EmbeddedValueResolverAware) {
			((EmbeddedValueResolverAware) bean).setEmbeddedValueResolver(this.embeddedValueResolver);
		}
		if (bean instanceof ResourceLoaderAware) {
			((ResourceLoaderAware) bean).setResourceLoader(this.applicationContext);
		}
		if (bean instanceof ApplicationEventPublisherAware) {
			((ApplicationEventPublisherAware) bean).setApplicationEventPublisher(this.applicationContext);
		}
		if (bean instanceof MessageSourceAware) {
			((MessageSourceAware) bean).setMessageSource(this.applicationContext);
		}
		if (bean instanceof ApplicationContextAware) {
			((ApplicationContextAware) bean).setApplicationContext(this.applicationContext);
		}
	}

}
```

从上面我们看到 aware 接口是某些前置器的一部分,只要实现了某些 aware 的子接口,那么其子接口的实现类会被执行

我们如果要使用 aware 接口带来的感知能力,我们使用如下的方式

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





## core

---

