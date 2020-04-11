# 基础方法

```java
.toString()
Integer.parseInt(String)
string相关
StringBuffer sb = new StringBuffer("");
sb.append();
double...dbarray //封装成数组自己遍历吧
```
## 正则表达式
		Pattern p=Pattern.compile(pattern);
		Matcher m=r.matcher(string);
		m.group(group_num);
		//寻找下一个以及统计出现位置方法
		while(m.find()){
			//count++;
			m.start();
			m.end();
		}
## String类中能适用正则的方法
	replaceAll()
	replaceFirst()
## 修饰类的关键字
		default介于protected和private之间
		可以在同一包中的类
		protected在不同包中的子类
		public/private
		.java文件中只能又一个public的类
## 关键字
		类 class 
		继承 extends
		接口 interface //继承接口implements
		抽象类 abstract class

## 引用
		this//this是指向自己
		super//super是指向父类
		thts.function();//调用自己函数
		this()//调用自身构造函数
		super.function()//调用父类方法
		super()//调用父类构造函数
## 复用与调用
		class Animal{
			public void eat();
		}
		class Dog extends Animal{
			@Override
			public void eat();
			public void run();
		}
		Animal a=new Dog();
		a.eat();//调用的是Dog类的方法
		a.run();//不可以调用除非做类型转换
		这是java多态的一个典型案例
		关键字instanceof可以做动态类型判断
## 抽象类与接口
		抽象类可以没有抽象方法,但还有抽象类特性
		但是包含抽象方法就是抽象类
	
		接口一定没有方法体
		接口中方法可以用abstract修饰但是多余
		默认就是abstract interface
		abstract不能用static修饰
		接口只有static final成员
## 内部类局部内部类与匿名内部类
		内部类的机制类似于闭包
		1.成员内部类
			class A{
				class B{
	
				}
			}
			//外部调用
			A.B instance = new A().new B();
		2.局部内部类
			class B{
	
			}
			public getInstance(){
				class A extends B{
	
				}
				return new A();
			}
		3.匿名内部类
			//匿名内部类一般是对类的内部进行某些修改
			new OnClickListener() {
	            @Override
	            public void onClick(View v) {
	                // TODO Auto-generated method stub
	                 
	            }
	    	}
	    	//其等价于继承或者实现接口
	    	//其没有构造器由系统命名
## 泛型
		泛型语法和模版一样在编译期确定类型
		public static <T> void func(T[] arr);
		泛型类
		public class ClassName<T>{
			//使用T当成类型
			//instanceof可动态类型判断
		}
		类型通配符?
		<?>代替所有类
## lambda表达式
		(,)->{} //瞬间想起箭头函数
		(String s)->System.out.println(s);
		//可以不写类型,但不能直接这么写
		//其本质为函数接口
		@FunctionalInterface
		public interface TypeF{
			void func(params...);
		}
		TypeF t=()->{};//可以用来实现一些匿名内部类干的事
## 默认方法
		interface it{
			default void func(){
	
			}
			static void func2(){
	
			}
		}
		//接口可以添加默认方法的实现
## 方法引用
		collections的list
		list.forEach(()->{});//本质上是实现接口
		list.forEach(System.out::println)
		//方法引用,函数式编程
## 包装类
		包装类赋予了基本数据类型面向对象的特性
		比如Object类的参数不能传int
		应用场景
			1.集合类的泛型只能是包装类
			2.成员变量不能有默认值可以用对象设为null
			3.方法参数允许定义空值
			4.实现装箱和拆箱
		注意的点就是128以下的对象是用数组进行缓存的
		也就是相同对象的不同引用而已
1.socket
	HTTP:80 FTP:21 Telnet:23
	ip+端口号组成了所谓的Socket
	socket是在运输层的通信单元
	通信原理
		1.通信两端有socket
		2.数据在两个Socket间进行IO传输
	java中对运输层应用的支持
		import java.net.*;
		InetAddress//标识网络上的硬件资源主要是IP
		URL//可以通过URL打开资源
		Sockets//TCP协议实现通信
		Datagram//UDP协议,实现通信
	InetAddress
		//获取本机的InetAddress实例
		InetAddress address =InetAddress.getLocalHost();
		address.getHostName();//获取计算机名
		address.getHostAddress();//获取IP地址
		byte[] bytes = address.getAddress();//获取字节数组形式的IP地址,以点分隔的四部分

		//获取其他主机的InetAddress实例
		InetAddress address2 =InetAddress.getByName("其他主机名");
		InetAddress address3 =InetAddress.getByName("IP地址");	
	URL
		URL url = new URL("http://www.baidu.com/s?kw=java&nosence=python");
	    println(url.getHost());
	    println(url.getPort());//-1使用默认端口
	    println(url.getPath());//相对路径
	    println(url.getProtocol());
	    println(url.getRef());//获取锚点#后的内容
	    println(url.getQuery());//获得查询字符串
	
		url.openStream();//可以获取流进行读取
		//意味这URL就可以进行小型爬虫的编写


    TCP编程
    	Socket通信模型
    	S/C通信模式
    	连接建立
        	S:建立服务端倾听socket
        	S:等待并接受连接请求
        	C:创建连接socket向服务器端发送请求
        	S:接受请求后创建连接socket
        开始通信
        	打开stream进行通信
        结束通信
        	关闭socket和相关资源
        服务器端具体发生:
        	1.创建ServerSocket对象,绑定监听端口
        	2.通过accept()方法监听客户端请求
        	3.建立连接后通过输入流读取客户端的请求
        	4.通过输出流发送响应
        	5.关闭相关资源
        //相关方法和具体实现
    	    ServerSocket ss=new ServerSocket(port);
    	    
    	    //serversocket是本地开启服务器端口
    	    Socket so=ss.accept();//等待客户端请求
    	    Socket soc=new Socket("host","port")
    	    //直接打开套接字连接
    	    so.getInputStream();//得到输入流
    	    so.shutdownInput();//关闭输入流
    	    so.getOutputStream();//得到输出流
    
    	   	//有了输入流和输出流自然就可以操作了
    	   	//注意客户端和服务器端获取的流的顺序
    	//发送请求实例
    		Socket socket=new Socket("www.baidu.com",80);
            OutputStream os=socket.getOutputStream();
            OutputStreamWriter osw=new OutputStreamWriter(os);
            BufferedWriter bw=new BufferedWriter(osw);
            bw.write("GET / HTTP/1.1\r\n");
            bw.write("Host: www.baidu.com\r\n");
            bw.write("\r\n");
            bw.flush();
    
            InputStream is=socket.getInputStream();
            InputStreamReader isr=new InputStreamReader(is,"UTF-8");
            BufferedReader br=new BufferedReader(isr);
            String str=null;
            while((str=br.readLine())!=null){
                print(str);
                if(str.length()==0)break;
            }
            br.close();
            isr.close();
            is.close();
            socket.close();
2.多线程
	0.基础
		1.时间轮训算法
			分时调度模型,按优先级进行分配
			抢占式调度模型(java使用此类),多级优先队列算法
		2.生命周期
			.start() //就绪状态
			.run() //可阻塞
			//死亡状态
			.stop()&.destory() //可终止线程
			//执行以下方法可能造成阻塞
			.wait() //等待阻塞
			.sleep() .join() //其他阻塞
			synchronized同步锁失败
		2.5 方法详解
			Thread.currentThread();//获得当前线程 Thread.currentThread().getName()
			Thread t = new Thread();
			t.start(); // 加入就绪队列
			t.sleep(msec); t.interrput(); //睡眠和打断,也可以用Thread.sleep()
			// sleep方法会抛出Interrput异常,在调用t.interrput的时候捕捉异常
			.yield() 与sleep() 类似 不进行阻塞 回到就绪队列
			

			.join() //当前线程可以调用另一线程的join方法 等另一线程执行结束
		//join
			Thread t1 = new Thread(()->{});
			Thread t2 = new Thread(()->{t2.start();t2.join();//...});
			//t2 必须等t1执行结束才会继续执行
			
			.wait() .notify() .notifyAll() //等待唤醒
			
		//wait
			//wait和notify依赖对象的同步锁
			.wait() // 等待其他线程调用对象notify
			.wait(timeout) //被notify或者 超时
			.wait(timeout,nanos) //被notify 超时或者被interrupt
			//wait会让对象释放其持有的锁,
			.notify()
			.notifyAll()
			//一个例子
				//本质就是PV操作 就是通过访问临界区资源而实现的
				Thread t1 = new Thread(new Runnable() {
		            @Override
		            public void run() {
		                synchronized (this) { //如果不加锁无法使用notify和wait
		                    System.out.println(Thread.currentThread() + " call notify");
		                    notify();
		                }
		            }
		        });
		        synchronized (t1) { //获取了对象的锁之后才能对t1进行wait操作,临界区资源
		            t1.start();
		            try {
		                System.out.println(Thread.currentThread() + " wait");
		                t1.wait();//释放锁 允许其他线程修改
		                System.out.println("end");
		            } catch (InterruptedException e) {
	
		            }
		        }
	
		3.优先级
			.setPriority();
			1-10, Thread.MIN_PRIORITY-Thread.MAX_PRIORITY
			Thread.NORM_PRIORITY=5 //普通优先级
		4.线程和线程共享方法区内存,但栈是独立的
		5.线程安全
			同一段代码被执行,结果不变被称为线程安全
		6.synchronized关键字
			synchronized 是对对象加锁,称同步锁
				可以对方法或者代码块加锁
				同步普通方法,锁的是当前对象。
				同步静态方法,锁的是当前 Class 对象。
				同步块,锁的是 {} 中的对象。
				synchronized(this) // 获取当前对象的锁
	
			synchronized规则
				第一条: 当一个线程访问“某对象”的“synchronized方法”或者“synchronized代码块”时，其他线程对“该对象”的该“synchronized方法”或者“synchronized代码块”的访问将被阻塞。
				第二条: 当一个线程访问“某对象”的“synchronized方法”或者“synchronized代码块”时，其他线程仍然可以访问“该对象”的非同步代码块。
				第三条: 当一个线程访问“某对象”的“synchronized方法”或者“synchronized代码块”时，其他线程对“该对象”的其他的“synchronized方法”或者“synchronized代码块”的访问将被阻塞。
	
				第三条意味着synchronized依赖对象而存在
				synchronized和非synchronized是两种不同的系统
	
			//demo
				Thread t = new Thread(() -> {
		            for (int i = 0; i < 5; i++) {
		                System.out.println(Thread.currentThread() + "--->" + i);
		            }
		        });
		        Thread t1 = new Thread(t);
		        Thread t2 = new Thread(t);
	
		        Thread t0 = new Thread(new Runnable() {
		            @Override
		            public void run() {
		                synchronized (this) {
		                    for (int i = 0; i < 5; i++) {
		                        System.out.println(Thread.currentThread() + "--->" + i);
		                    }
		                }
		            }
		        });
		        Thread t3 = new Thread(t0);
		        Thread t4 = new Thread(t0);
		        t3.start();
		        t4.start();
		    明显注意到一点 同步只允许该代码块同时被一个线程访问
		    synchronized 代码块比 synchronized方法更加高效
		7.锁
			同步锁已经讲述完毕
				synchronized(this) 这句代码的意思是给当前代码段加锁,
				也是获取了当前对象this的锁之后可以访问代码段
				加锁即使不允许同时访问同一段代码段
				释放锁的意思是允许其他程序竞争该锁以获得代码的执行权
				获取某一对象的锁指的是线程获取了某一对象中某段代码的执行权
				当线程访问被同步的代码时，必须首先竞争代码所属的类的【对象上的锁】，否则线程将等待(阻塞)，直到锁被释放.


			实例锁和全局锁
				实例:锁在某一instance上,如果是单例效果等同于全局锁
				对应的关键字是 synchronized
				全局锁:锁在类上对应static synchronized


​				
​				对synchronized规则进行补充
​					因为static synchronized是锁在类上的
​					按照内存含义 static应该有共同的代码段
​					故不同instance不能访问处于同一堆内存的
​					static synchronized 方法
​					
​					虽然不同instance不能访问
​					同一static synchronized代码段
​					但 class_name.static_method() 和 instance.method()
​					却可以被同时访问 因为其存在于不同的方法区中 加锁的对象不同
​	
​				//例子
​					pulbic class Something {
​					    public synchronized void isSyncA(){}
​					    public synchronized void isSyncB(){}
​					    public static synchronized void cSyncA(){}
​					    public static synchronized void cSyncB(){}
​					}
​					能否同时访问
​					(01) x.isSyncA()与x.isSyncB() //不可以 规则3
​					(02) x.isSyncA()与y.isSyncA() //可以
​					(03) x.cSyncA()与y.cSyncB()	//不可以,同时访问类的静态代码区
​					(04) x.isSyncA()与Something.cSyncA() 
​					//可以,静态代码和普通方法存放在类的静态代码区和对象的普通方法区
​		8.守护进程
​			守护线程相当于太监,主进程执行完了守护线程要陪葬
​			t.setDaemon(true)
​		9.volatile关键字
​			volatile变量规则：对一个变量的写操作先行发生于后面对这个变量的读操作
​			保证并发编程中的可见性 即内存修改的值立刻flush到内存里
​			也可以保证一定程度上的有序性
​			volatile的两层语义
​				1.保证了不同线程对这个变量进行操作时的可见性，即一个线程修改了某个变量的值，这新值对其他线程来说是立即可见的。
​				2.禁止进行指令重排序。
​			保证可见性的同时也要保证操作的原子性
​			否则还是有可能出错 //可以通过是手动加锁的方式去
​	1.实现线程的是4种方法
​		1.实现runnable接口
​			Thread(Runnable threadOb);
​			Thread(Runnable threadOb,String threadName);
​			Thread(new MyThead());
​			new Thread(new Runnable(){
​				@Override
​				public void run(){
​					//线程执行代码
​				}
​			});
​			//demo
​				Thread[] threads = new Thread[3];
​		        for (int j = 0; j < threads.length; j++) {
​		            threads[j] = new Thread(() -> {
​		                for (int i = 0; i < 20; i++) {
​		                    System.out.println(Thread.currentThread().getName() + "----->" + i);
​		                }
​		            });
​		        }
​		        for(int j=0;j<threads.length;j++){
​		            threads[j].start();
​		        }
​		        //易知其为抢占方式运行
​		        当然也可以用类然后override那种方式去写无所谓了
​		2.继承Thread
​			class Processor extends Thread {
​			    @Override
​			    public void run() {
​			        for (int i = 0; i < 50; i++) {
​			            System.out.println(Thread.currentThread().getName() + "----------->" + i);
​			        }
​			    }
​			}
​			Thread t1=new Processor();
​			Thread t2=new Processor();
​			t1.start();
​			t2.start();
​		3.通过Callable和Future
​			Callable和FutureTask针对有返回值的情况
​			Callable<Integer> t = new ThreadDemo();
​	    	FutureTask<Integer> res = new FutureTask<>(t);
​			new Thread(res).start(); //执行线程
​			res.get(); //获取结果
​			
​			实现callable接口
​			class ThreadDemo implements Callable<Object> {
​			    @Override
​			    public Object call() throws Exception {
​			        return null;
​			    }
​			}
​		4.通过线程池创建
​			jdk1.5 Executor线程池框架
​			Executors接口可以创建四种进程池
​			newCachedThreadPool创建一个可缓存线程池，如果线程池长度超过处理需要，可灵活回收空闲线程，若无可回收，则新建线程。 
​			newFixedThreadPool 创建一个定长线程池，可控制线程最大并发数，超出的线程会在队列中等待。 
​			newScheduledThreadPool 创建一个定长线程池，支持定时及周期性任务执行。 
​			newSingleThreadExecutor 创建一个单线程化的线程池，它只会用唯一的工作线程来执行任务，保证所有任务按照指定顺序(FIFO, LIFO, 优先级)执行。
​	
​			//此处仅进行简单的demo
​			ExecutorService executorService = Executors.newFixedThreadPool(5);
​			for(int i=0;i<10;i++){
​				executorService.excute(()->{}));
​			}
​			executorService.shutdown();
​			//excute()是无返回值的 submit(Runnable)是有返回值的 也即是callable对象
​			//下面给出submit的时使用方法
​	
​			List<Future<String>> results=new ArrayList<Future<String>>();
​			ExecutorService executorService = Executors.newFixedThreadPool(5);
​			for(int i=0;i<10;i++){
​				results.add(executorService.submit(()->{return null})));
​				//利用list保存值
​			}
​			executorService.shutdown();
​			for(Future<String> fs : results)
​				fs.get(); //获取结果 如果异步计算还没有完成的话 方法会阻塞直到计算完成
​	2.并发编程
​		详细可能考虑单独开一章或者写在后面		
3.JDBC使用
4.IO
​	//相关类
​		流
​			inputstream/outputstream
​			reader/writer
​			bufferreader/bufferwriter
​		字符串拼接
​			stringbuffer
​	//字符流和字节流
​		Bytes---Stream
​		字节流是原始数据,需要进行编码转换.
​		字节流处理1个字节 操作字节和字节数组
​		Chars---Reader&Writer
​		字符流是自动转换.
​		字符流是处理2个字节的Unicode字符,字符数组或者字符串
​	// inputstream和outputstream是相对于程序而言的
​	
​	//控制台读写bufferedreader inputstreamreader
​		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
​		br.read();//读入字符注意是字符char
​		br.readLine();//读入一行字符串string
​	//文件读写
​		InputStream,OutputStream,Writer,Reader都是抽象类
​		
		###bytes
		InputStream fis = new FileInputStream("path");
			//InputStream主要方法
			read(int)//读指定字节
			read(byte[])//读入byte所有
		OutputStream os = new FileOutputStream("path");
			//OutputStream主要方法
			FileOutputStream("path",true);
			//第二个参数是否覆盖前面文件
			write(int)//写入指定字节
			write(byte[])//str.getBytes()进行字符数组转换
		
		###chars
		Writer w=FileWriter(new File("path"));
			FileWriter的第二个参数指定为true和Stream类似
			w.write(str);
		Reader r=FileReader(new File("path"));
			r.read(byte[]);
			r.read(byte[],start,end);
		//close()记得关闭流
	
		//利用buffer进行reader和writer的优化
			//InputStreamReader也是Reader的一个派生
			Reader r=FileReader(new File("path"));
			BufferedReader bfr=new BufferedReader(r);
			//用StringBuffer进行连接
			StringBuffer sb=new StringBuffer("");
			String str=null;
			while(1){
				str=bfr.readLine();
				if(str!=null){
					sb.append(str);
				}else{
					break;
				}
			}
		//关闭文件流
			简单的close()明显是不行的,因为close本身出现异常或者之上的代码出现异常就无法关闭
			所以应该用Closeable接口的方法进行关闭,且下述方法得在代码块中进行关闭
			public static void closeQ(Closeable c){
				try{
					if(c!=null)
						c.close();
				}catch(){
					//do nothing
				}
			}
5.Collections
	//常用集合
		LinkedList,ArrayList
		HashMap,TreeSet
		java.util下
		Vector,Stack,Hashtable
	//List
		List<String> list=new ArrayList<String>();
		Iterator<String> iter=list.iterator();
		while(iter.hasNext()){
			it.next();
		}
	//Map
		Map<String,String> map = new HashMap<String,String>();
		map.put("key","value");
		for(String key:map.keySet()){
			map.get(key);
		}
		for(String v:map.values()){
			v;
		}
		//用iterator遍历的时候使用getKey()和getValue()进行遍历
	//迭代器的实现
		核心方法 next hasNext remove
		remove可以删除当前元素

		//迭代器的数据结构	
		private class Itr implements Iterator<E>{
			int cursor;//下一元素的位置
			int lastRet=-1;//上一索引的位置
			int expectedModCount=modCount;//预期被修改的次数
		}
	//sort实现
		//简单数组排序
		Array.sort();
		//比较排序
		Collections.sort(data_set,compare);
			//compare编写
			new Comparator<data_type>(){
				@Override
				public int compare(int a,int b){return a-b}
				//自定义规则 1> 0= -1<
			}
6.反射
	获取class的三种方式
	1.instace.getClass();
	2.ClassName.class;
	3.Class.forName("package.className");//ClassNotFoundException
	4.类内调用getClass(); //直接调用运行时的class
	//Class 相关操作
		getMethods();//获得所有public方法
		getDeclaredMethods();//获得所有方法
		getMethod("methodName")
		newInstance()//调用不带参数的构造方法创建一个对象
		getSuperclass() //获取父类的Class对象
		getModifiers();//获取修饰符

	//获取Method
		Method m=class_instance.getMethod("name");
		m.invoke(instance);//调用方法
	//获取Field
		Field f=class_instance.getField("name");
		f.get(instance);
		f.set(instance,value);
	反射能使java的动态化程度提高,ORM等动态框架的编写需要反射
7.ORM/DAO
	DAO层和ORM框架
	DAO data access object
		DAO是一种设计思路
		可选用ORM框架也可以直接操作数据库
		主要分为4类
			1.DAO接口 PetDao
			2.DAO实现 PetDaoImpl //业务逻辑操作此类进行访问
			3.实体类 //用于存放和传输数据 Pet 又称为DTO
			4.数据库连接和关闭工具类 JDBCUtils BaseDao可以import并且使用
			ps:可以把数据库连接代码设置成static或用连接池进行优化
		//实体类用于充当数据结构,提供给service层操作的是是实现类

		public class BaseDao{}//基类连接数据库
		public interface PetDao{}//操作表的方法接口
		public class Pet{}//实体类 里面是各种字段和getset方法 DTO
	
		public class PetDaoImpl extends BaseDao implements PetDao{}
		//继承操作数据库的BaseDao,实现查询的接口
		//使用的时候service层是具体调用实现类进行操作
	
		//部分具体实现
			public class BaseDao {
			    private static String driver="com.mysql.jdbc.Driver";
			    private static String url="jdbc:mysql://127.0.0.1:3306/epet";
			    private static String user="root";
			    private static String password="root";
			        static {
			            try {
			                Class.forName(driver);
			            } catch (ClassNotFoundException e) {
			                e.printStackTrace();
			            }
			        }
			        
			    public static Connection getConnection() throws SQLException {
			        return DriverManager.getConnection(url, user, password);    
			    }
			    
			    public static void closeAll(Connection conn,Statement stmt,ResultSet rs) throws SQLException {
			        if(rs!=null) {
			            rs.close();
			        }
			        if(stmt!=null) {
			            stmt.close();
			        }
			        if(conn!=null) {
			            conn.close();
			        }
			    }


			    public int executeSQL(String preparedSql, Object[] param) throws ClassNotFoundException {
			        Connection conn = null;
			        PreparedStatement pstmt = null;
			        /* 处理SQL,执行SQL */
			        try {
			            conn = getConnection(); // 得到数据库连接
			            pstmt = conn.prepareStatement(preparedSql);
			            if (param != null) {
			                for (int i = 0; i < param.length; i++) {
			                    pstmt.setObject(i + 1, param[i]); // 为预编译sql设置参数
			                }
			            }
			        ResultSet num = pstmt.executeQuery(); // 执行SQL语句
			        } catch (SQLException e) {
			            e.printStackTrace(); // 处理SQLException异常
			        } finally {
			            try {
			                BaseDao.closeAll(conn, pstmt, null);
			            } catch (SQLException e) {    
			                e.printStackTrace();
			            }
			        }
			        return 0;
			    }
			}
	
	ORM object relationship mapping
8.序列化
	//序列化文件以.ser结尾
	1.实现序列化接口java.io.Serializable(隐式序列化)
		import java.io.Serializable;
		class class_name implements Serializable{
			int transient field; // transient 用于声明不可序列化的字段
		}
		ObjectOutputStream out = new ObjectOutputStream(new FileOutputStream())
		out.writeObject();
		ObjectInputStream in = new ObjectInputStream(new FileInputStream());
		in.readObject();
	2.实现Externalizable接口
		Externalizable接口继承Serializable接口
		必须实现接口方法
		writeExternal,readExternal
			@Override
			public void writeExternal(ObjectOutput out) throws IOException {
				out.writeObject(s);
				out.writeInt(i);
			}
			@Override
			public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException{
				s = (String)in.readObject();
				i = in.readInt();
			}
			//该方法对于实现一些对象内有对象的方法很合适
	3.实现Serializable接口+添加writeObject()和readObject()方法
		private void writeObject(ObjectOutputStream stream) throws IOException {
			stream.defaultWriteObject();
			stream.writeInt(age);
		}
		private void readObject(ObjectInputStream stream) throws ClassNotFoundException, IOException {
			stream.defaultReadObject();
			age = stream.readInt();
		}
9.常用的application接口
	javaMail实现邮件发送
		// 但是腾讯公司有拦截一些超链接
		// 
		// 对于函数签名的一些解释 to from 是邮箱地址, pswd是授权码,html是正文体
		public static void sendMail(String to, String from, String pswd,String title,String html) {
	        // 指定发送邮件的主机为 smtp.qq.com
	        String host = "smtp.qq.com";  //QQ 邮件服务器
	        // 获取系统属性
	        Properties properties = System.getProperties();
	        // 设置邮件服务器
	        properties.setProperty("mail.smtp.host", host);
	        properties.put("mail.smtp.auth", "true");
	        //设置ssl加密
	        try {
	            MailSSLSocketFactory sf = new MailSSLSocketFactory();
	            sf.setTrustAllHosts(true);
	            properties.put("mail.smtp.ssl.enable", "true");
	            properties.put("mail.smtp.ssl.socketFactory", sf);
	        } catch (GeneralSecurityException e) {
	            e.printStackTrace();
	            System.out.println("error:sll socket factory occur an error");
	        }
	        // 获取默认session对象
	        Session session = Session.getDefaultInstance(properties, new Authenticator() {
	            @Override
	            public PasswordAuthentication getPasswordAuthentication() {
	                return new PasswordAuthentication(from, pswd); //发件人邮件用户名、授权码
	            }
	        });

	        try {
	            // 创建默认的 MimeMessage 对象
	            MimeMessage message = new MimeMessage(session);
	            // Set From: 头部头字段
	            message.setFrom(new InternetAddress(from));
	            // Set To: 头部头字段
	            message.addRecipient(Message.RecipientType.TO, new InternetAddress(to));
	            // 多封电子邮箱
	            // message.addRecipient(Message.RecipientType.TO, new InternetAddress[]{new InternetAddress("address")});
	
	            // Set Subject: 头部头字段
	            message.setSubject(title);
	
	            // 可以发送html格式的问题 但是上面的消息体会被覆盖
	            message.setContent(html,"text/html;charset=utf8");
	
	            // 发送消息
	            Transport.send(message);
	            System.out.println("Sent message successfully....from " + from + " to " + to);
	        } catch (MessagingException mex) {
	            mex.printStackTrace();
	        }
	    }
	
	阿里云短信接口
		短信签名和短信模版
		public static String genRandomString() {
	        StringBuilder randString = new StringBuilder();
	        for (int i = 0; i < 4; i++) {
	            randString.append(Integer.toString((int) (Math.random() * 10)));
	        }
	        return randString.toString();
	    }
	
	    public static void send_msg() {
	        try {
	            String req_url = getRequestUrl("...", genRandomString());
	            System.out.println(req_url);
	            URL url = new URL(req_url);
	            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
	            conn.setRequestMethod("GET");
	            InputStream is = conn.getInputStream();
	            InputStreamReader isr = new InputStreamReader(is);
	            BufferedReader bfr = new BufferedReader(isr);
	            String line;
	            while ((line = bfr.readLine()) != null) {
	                System.out.println(line);
	            }
	            bfr.close();
	            isr.close();
	            is.close();
	        } catch (Exception e) {
	            e.printStackTrace();
	            System.out.println("there is an error occur when sending a message");
	        }
	    }
	
	    public static String getRequestUrl(String phone, String code) throws Exception {
	        String accessKeyId = "...";
	        String accessSecret = "...";
	        String SignName = "Gauss";
	        String templateParam = "{'code':'" + code + "'}"; //JSON格式字符串
	        String templateCode = "SMS_164508451"; // template code
	        return getRequestUrl(accessKeyId, accessSecret, phone, SignName, templateParam, templateCode);
	    }
	
	    public static String getRequestUrl(String accessKeyId, String accessSecret, String phoneNumber,
	                                       String SignName, String templateParam, String templateCode) throws Exception {
	        java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
	        df.setTimeZone(new java.util.SimpleTimeZone(0, "GMT"));// 这里一定要设置GMT时区
	        java.util.Map<String, String> paras = new java.util.HashMap<String, String>();
	        // 1. 系统参数
	        paras.put("SignatureMethod", "HMAC-SHA1");
	        paras.put("SignatureNonce", java.util.UUID.randomUUID().toString());
	        paras.put("AccessKeyId", accessKeyId);
	        paras.put("SignatureVersion", "1.0");
	        paras.put("Timestamp", df.format(new java.util.Date()));
	        paras.put("Format", "JSON");
	        // 2. 业务API参数
	        paras.put("Action", "SendSms");
	        paras.put("Version", "2017-05-25");
	        paras.put("RegionId", "cn-hangzhou");
	        paras.put("PhoneNumbers", phoneNumber);
	        paras.put("SignName", SignName);
	        paras.put("TemplateParam", templateParam);
	        paras.put("TemplateCode", templateCode);
	        paras.put("OutId", "123");
	        // 3. 去除签名关键字Key
	        if (paras.containsKey("Signature"))
	            paras.remove("Signature");
	        // 4. 参数KEY排序
	        java.util.TreeMap<String, String> sortParas = new java.util.TreeMap<String, String>();
	        sortParas.putAll(paras);
	        // 5. 构造待签名的字符串
	        java.util.Iterator<String> it = sortParas.keySet().iterator();
	        StringBuilder sortQueryStringTmp = new StringBuilder();
	        while (it.hasNext()) {
	            String key = it.next();
	            sortQueryStringTmp.append("&").append(specialUrlEncode(key)).append("=").append(specialUrlEncode(paras.get(key)));
	        }
	        String sortedQueryString = sortQueryStringTmp.substring(1);// 去除第一个多余的&符号
	        StringBuilder stringToSign = new StringBuilder();
	        stringToSign.append("GET").append("&");
	        stringToSign.append(specialUrlEncode("/")).append("&");
	        stringToSign.append(specialUrlEncode(sortedQueryString));
	        String sign = sign(accessSecret + "&", stringToSign.toString());
	        // 6. 签名最后也要做特殊URL编码
	        String signature = specialUrlEncode(sign);
	        // 最终打印出合法GET请求的URL
	        return "http://dysmsapi.aliyuncs.com/?Signature=" + signature + sortQueryStringTmp;
	    }
	
	    public static String specialUrlEncode(String value) throws Exception {
	        return java.net.URLEncoder.encode(value, "UTF-8").replace("+", "%20").replace("*", "%2A").replace("%7E", "~");
	    }
	
	    public static String sign(String accessSecret, String stringToSign) throws Exception {
	        javax.crypto.Mac mac = javax.crypto.Mac.getInstance("HmacSHA1");
	        mac.init(new javax.crypto.spec.SecretKeySpec(accessSecret.getBytes("UTF-8"), "HmacSHA1"));
	        byte[] signData = mac.doFinal(stringToSign.getBytes("UTF-8"));
	        return new sun.misc.BASE64Encoder().encode(signData);
	    }
11.并发编程
	并发编程的核心问题:变量共享的解决方式
	并发编程遇到的三个特性
	1.原子性 //原子性即是不可分割 要么一同完成要么rollback
		就是操作不可分割
	2.可见性 volatile关键字
		可见性是指当多个线程访问同一个变量时，一个线程修改了这个变量的值，其他线程能够立即看得到修改的值。
	3.有序性
		代码按照顺序执行