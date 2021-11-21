# mysql优化

---

优化的方向有两个sql结构优化,索引,存储过程(因数据库迁移问题等已经弃用)

[TOC]

总结下mysql这个数据系统的几个方面

-   数据流与系统结构
-   数据结构(文件结构,索引结构,优化)
-   日志系统(内存管理)
-   并发控制与实现MVCC,事务

## 高级语法及命令

一些语句

- `alter table Video add columzhege1n videoLevel int(11)`
- `mysql -h {host/Ip} -P 3306 -u username -p password`链接远程数据库

varchar和char的区别

- char是长度固定的,varchar的长度是不固定的
- char(10) 表示存储的字符占10个字节
- varchar(10) 表示只占3个字节,最大值是10
- char的效率要更高点,varchar比char更节省空间

datetime和varchar查询效率在2倍左右[全表扫描]

数据注入思路:如果要注入数据,大型的可以考虑python脚本,小型的考虑生成insert语句而不直接通过java去操作数据库.



### in 的用法

```sql
select * from plugin where (pluginId,versionCode) in
(select * from (select pluginId,max(versionCode) from plugin
where (minFrameworkVersion <= ?1 and frameworkVersion >= ?2)
group by pluginId limit ?3 offset ?4) as t)
```



### JDBCTemplate

正如 Dao 一样,Springboot 对 JDBC 的操作也进行了封装,让我们可以使用 JDBCTemplate 去操作数据库.同理可以使用 hibernate 的 entityManager 去完成类似的操作.

```java
@Autowired
@PersistenceContext
private EntityManager entityManager;

private List<BanWord> searchByCondition(String condition, String blackword, String whiteword,
                                        int limit, int offset) {
  String sql = "select * from ban_word where morphemeId in (select * from "
    + "(select t.morphemeId from "
    + "(select morphemeId from ban_word where type=1 and word like '%" + blackword + "%' "
    + condition + " ) as t "
    + "INNER JOIN "
    + "(select morphemeId from ban_word where type=0 and word like '%" + whiteword + "%' "
    + condition + " ) as b "
    + "on t.morphemeId = b.morphemeId group by morphemeId limit " + limit + " offset " + offset
    + ") as v)";
  System.out.println(sql);
  Query q = entityManager.createNativeQuery(sql, BanWord.class);
  List<BanWord> results = q.getResultList();
  System.out.println(results);
  return results;
}
```

### 调试命令

- explain
- show processlist

#### explain

explain 命令有一点 个 extra 属性

- using index 指完全覆盖索引
- using index condition 查询的列不全在索引中,是一个前导列的范围
- using where;using index; 覆盖索引,但并不是前导列
- using where 可能需要全表扫描 或者扫描索引

前导列及using where和 using index 的区别

```sql
create index idx(a,b,c) on table
```

那么前导列就是 a,ab.abc,而单独的b是不会使用索引的

#### show processlist

表示用来查看正在进行的线程,但一般只能用来查看自己执行的线程,所以需要通过同一身份登录或者赋予权限.如下数据结构

![](https://pic3.zhimg.com/80/v2-eb4254945a43d5fdc0e8718da8183aa6_1440w.jpg)

这个信息其实是来自于 information_schema 这张表,其中 time 表示线程处于当前状态的时间.info 会用于记录当前执行的语句,可以用来排查慢查询,其中time的时间单位是s

Command 的值：

- Binlog Dump: 主节点正在将二进制日志 ，同步到从节点
- Change User: 正在执行一个 change-user 的操作
- Close Stmt: 正在关闭一个Prepared Statement 对象
- Connect: 一个从节点连上了主节点
- Connect Out: 一个从节点正在连主节点
- Create DB: 正在执行一个create-database 的操作
- Daemon: 服务器内部线程，而不是来自客户端的链接
- Debug: 线程正在生成调试信息
- Delayed Insert: 该线程是一个延迟插入的处理程序
- Drop DB: 正在执行一个 drop-database 的操作
- Execute: 正在执行一个 Prepared Statement
- Fetch: 正在从Prepared Statement 中获取执行结果
- Field List: 正在获取表的列信息
- Init DB: 该线程正在选取一个默认的数据库
- Kill : 正在执行 kill 语句，杀死指定线程
- Long Data: 正在从Prepared Statement 中检索 long data
- Ping: 正在处理 server-ping 的请求
- Prepare: 该线程正在准备一个 Prepared Statement
- ProcessList: 该线程正在生成服务器线程相关信息
- Query: 该线程正在执行一个语句
- Quit: 该线程正在退出
- Refresh：该线程正在刷表，日志或缓存；或者在重置状态变量，或者在复制服务器信息
- Register Slave： 正在注册从节点
- Reset Stmt: 正在重置 prepared statement
- Set Option: 正在设置或重置客户端的 statement-execution 选项
- Shutdown: 正在关闭服务器
- Sleep: 正在等待客户端向它发送执行语句
- Statistics: 该线程正在生成 server-status 信息
- Table Dump: 正在发送表的内容到从服务器
- Time: Unused

查看执行时间特别长的线程

```sql
select * from information_schema.processlist where Command != 'Sleep' order by Time desc;
```

分组查看客户端的连接数

```sql
select client_ip,count(client_ip) as client_num from (select substring_index(host,':' ,1) as client_ip from processlist ) as connect_info group by client_ip order by client_num desc;
```

生成 kill 语句用于消灭5分钟以上的线程

```sql
select concat('kill ', id, ';') from information_schema.processlist where Command != 'Sleep' and Time > 300 order by Time desc;
```

#### 慢查询相关

```sql
SHOW VARIABLES LIKE '%query%' # 查询慢查询日志
SHOW STATUS LIKE '%slow_queries%' # 查看慢查询状态
```

需要开启慢查询日志 `slow_query_log = on`,然后通过慢查询日志 tail -f 就可以分析相应的状态,慢查询的时间可以自己定义,默认是10秒,但可以进行设置 `long_query_time`



## JDBC

---

我们先从JDBC的优化开始说起,要清楚JDBC的读取细节,先看下面代码

### 加载驱动

```java
public class Driver extends NonRegisteringDriver implements java.sql.Driver {
    public Driver() throws SQLException {
    }

    static {
        try {
            DriverManager.registerDriver(new Driver());
        } catch (SQLException var1) {
            throw new RuntimeException("Can't register driver!");
        }
    }
}
```

可以看到我们每次加载驱动只要触发 static 块就行了,驱动本身需要去获取操作系统的信息等相关字段来进行驱动的加载



### PrepareStatement和Statement

```java
Connection conn=null;
PrepareStatement ps=null;

Class.forName(driver);
conn = DriverManager.getConnection(url, user, password);

String sql="insert into users_info values(?,?,?)";
ps=conn.prepareStatement(sql); // 预编译sql,防止sql注入

ps.setInt(1,id);
ps.setString(2,username);
ps.setDate(3, new java.sql.Date(java.util.Date().getTime()));

Boolean res = ps.executeUpdate() > 0;
// 注意Statement是能获取结果集的
// 如果想要获取结果集且用的是查询语句可以使用下面的代码
// ResultSet rs = ps.executeQuery(); 
// 这里不需要再写语句通过statement预编译传入sql,如果是普通的statement对象每次都要写
```

PrepareStatement承自Statement接口.处理任务时候效率更高,因为采用预编译的手段处理sql,PrepareStatement也叫**JDBC存储过程**,Statment用于一次性存取.PrepareStatement对象开销比Statement大,

我们平时用的比较多的是PrepareStatement,因为其除了执行固定化sql的功能之外,还能够防止sql注入,预编译能判断参数是否合法.

另外需要注意在JDBC存储过程中,应当尽量使用`executeUpdate`和`executeQuery`来完成系统的判别,execute有其他语义.



### 自动提交问题与setAutoCommit

在提及之前我们先看下下面两个性质

-   **默认情况下setAutoCommit的值为1(true)**
-   **MyISAM不支持事务,该属性针对InnoDB**
-   MyISAM只要执行sql就是锁全表

顾名思义我们能从api中看到其设置让session自动提交,下面介绍的都是基于InnoDB的锁.因为只有InnoDB有基于事务的特征



#### setAutoCommit(true) 不开启事务

其语义为**不使用事务**,每一句写sql使用表的时候都要加锁.默认情况,自动提交,每次执行sql的时候都会让数据库执行操作.所以也可以理解为**每一句sql都执行事务**.

自然我们知道不使用事务的mysql针对于每一句执行的sql而言是线程安全的,但是对于整体的sql块不是线程安全的.对于每一句sql,根据sql内容的不同InnoDB可能会采用表锁或者行级锁(需要索引).

不使用事务对于语句块来讲可能会发生**脏读幻读不可重复读**.下面有更为详细的介绍这三种形式,避免方式自然是开启事务,另外就算在MyISAM引擎中开启事务也没有作用,因为MyISAM不支持事务.

另外根据mysql的特性,**不使用for update InnoDB只会对写操作加锁**



#### setAutoCommit(false) 开启事务

单单用这一句无法完成事务,但其语义表明是**开启事务**即**关闭自动提交/手动提交**.

其逻辑如下

```java
try{
  conn.setAutoCommit(false);
  
  stmt = conn.createStatement(); 
  stmt.execute(sql1);
  stmt.execute(sql2);
  
  // 提交事务
  conn.commit();
}catch(SQLException sqle){
  conn.rollback();
}finally{
  // close
}
```

可以看到其使用了`.commit()`此种api,我们即可知道,其把每一句执行的sql都当成事务的不同不同,整体一次性提交保证了这些操作执行的数据一致性,根据mysql的事务级别,这里一般是不可重复读,并且使用了`.rollback()`进行回滚.一方面是要保证**数据的一致性**,另一方面回滚是**解除锁**.

一般来讲关掉conn即可释放锁,但是在采用数据库连接池的环境下,就可能会造成大规模的死锁,故一定要记得回滚.



### mysql实现的锁

所谓的锁,同步信息本质上一些数据.依照CAS抢占字段的逻辑,所谓的字段就是同步信息.mysql实现锁的思路就是利用mysql这个数据系统本身的数据一致性.我们只需要利用JDBC对数据库操作,就可以实现锁了.

我们借助InnoDB的执行引擎对数据行进行加锁,MyISAM不支持事务且不能单独对行进行加锁粒度大.我们借助JDBC事务实现锁.

我们看下加锁和解锁的逻辑

```sql
INSERT INTO database_lock(resource, description) VALUES (1, 'lock')
```

```sql
DELETE FROM database_lock WHERE resource=1
```

这两个逻辑加锁不能重复加,因为插入不止一次的话会报错,这里可以不用选择主键,主键只是一个展示可以加锁的逻辑字段.

我们利用JDBC把其变成应用程序,首先我们开启事务把操作变成原子性.

```java
static class MysqlLock {
  public static String url = "jdbc:mysql://127.0.0.1:3306/test?characterEncoding=UTF-8";
  public static String user = "root";
  public static String pass = "root";
  public static Connection conn = null;

  static {
    try {
      Class.forName("com.mysql.jdbc.Driver");
      conn = DriverManager.getConnection(url, user, pass);
    } catch (SQLException | ClassNotFoundException throwables) {
      throwables.printStackTrace();
    }
  }

  private final String method;

  MysqlLock(String method) {
    this.method = method;
  }

  MysqlLock() {
    this.method = "testLock";
  }

  public boolean tryLock() throws SQLException {
    PreparedStatement st = conn.prepareStatement("select * from `lock` where method_name = ? for update");
    st.setString(1, method);
    ResultSet rs = st.executeQuery();
    return !rs.next();

  }

  public void lock() {
    try {
      conn.setAutoCommit(false);
      while (true) {
        try {
          PreparedStatement statement = conn.prepareStatement("insert into `lock` (method_name,description) values (?,?)");
          statement.setString(1, method);
          statement.setString(2, "a lock for test");
          if (!tryLock()) {
            // 尝试获取锁失败(数据库有记录)就一直等待获取
            Thread.sleep(100);
            continue;
          }
          statement.executeUpdate(); // 写上锁记录
          conn.commit();
          break;
        } catch (SQLException | InterruptedException e) {
        }
      }
    } catch (SQLException e) {
      System.out.println("系统出错");
      e.printStackTrace();
    }
  }

  public void unlock() {
    // 逆向操作删除记录
    try {
      conn.setAutoCommit(false);
      PreparedStatement statement = conn.prepareStatement("delete from `lock` where method_name = ?");
      statement.setString(1, method);
      if (statement.executeUpdate() == 1) {

      } else { // equals 0
        throw new RuntimeException("没上锁不能解锁");
      }
      conn.commit();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
}

public static final ExecutorService pool = Executors.newFixedThreadPool(4);
static int i = 0;
static final MysqlLock lock = new MysqlLock("test");
static final int n = 10000;
static final CountDownLatch latch = new CountDownLatch(n);

@Test
public void test() throws InterruptedException {
  for (int j = 0; j < n; j++) {
    pool.submit(() -> {
      lock.lock();
      try {
        //                    System.out.println(Thread.currentThread().getName() + "获取了锁");
        i++;
      } finally {
        //                    System.out.println(Thread.currentThread().getName() + "释放了锁");
        lock.unlock();
      }
      latch.countDown();
    });
  }
  latch.await();
  System.out.println(i);
}
```

上面的锁可以实现,但是由于其存储位置,效率比较低,加上存储于数据库我们更倾向于用zookeeper或者redis实现更高效更好用的分布式锁,但道理想通,下面介绍另一种设计方式,乐观锁设计.

```sql
CREATE TABLE `optimistic_lock` (
	`id` BIGINT NOT NULL AUTO_INCREMENT,
	`resource` int NOT NULL COMMENT '锁定的资源',
	`version` int NOT NULL COMMENT '版本信息',
	`created_at` datetime COMMENT '创建时间',
	`updated_at` datetime COMMENT '更新时间',
	`deleted_at` datetime COMMENT '删除时间', 
	PRIMARY KEY (`id`),
	UNIQUE KEY `uiq_idx_resource` (`resource`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据库分布式锁表';
```

加锁和解锁的逻辑

```sql
INSERT INTO optimistic_lock(resource, version, created_at, updated_at) VALUES(20, 1, CURTIME(), CURTIME());
```

-   STEP1 - 获取资源:

    ```sql
    SELECT resource, version FROM optimistic_lock WHERE id = 1
    ```

-   STEP2 - 执行业务逻辑

-   STEP3 - 更新资源:

    ```sql
    UPDATE optimistic_lock SET 
    resource = resource -1, 
    version = version + 1 
    WHERE id = 1 AND version = oldVersion
    ```

我们看到这个逻辑和CAS加锁逻辑一致,只有一个线程能修改成功,修改不成功的没有任何反应,或者说在java端要判断,我们利用该锁,把mysql当成缓冲池,做一个生产者消费者模型

```java
static class MysqlLock {
  public static String url = "jdbc:mysql://127.0.0.1:3306/test?characterEncoding=UTF-8";
  public static String user = "root";
  public static String pass = "root";
  public static Connection conn = null;

  static {
    try {
      Class.forName("com.mysql.jdbc.Driver");
      conn = DriverManager.getConnection(url, user, pass);
    } catch (SQLException | ClassNotFoundException throwables) {
      throwables.printStackTrace();
    }
  }

  private final Integer id;

  MysqlLock(Integer resourse) {
    this.id = resourse;
  }

  MysqlLock() {
    this.id = 1;
  }

  /**
         * 这里表的结构,id全局标识了唯一的锁
         * version表示该字段的更改版本,也是CAS修改依据之一
         */
  static final String sql1 = "SELECT resource, version FROM optimistic_lock WHERE id = ?";
  static final String sql2 = "" +
    "UPDATE optimistic_lock " +
    "SET resource = resource - 1,version = version + 1 " +
    "WHERE id = ? AND version = ?";

  public boolean tryLock() throws SQLException {
    PreparedStatement statement = conn.prepareStatement(sql1);
    statement.setInt(1, id);
    ResultSet rs = statement.executeQuery();
    rs.next();
    int oldVersion = rs.getInt("version");
    int resource = rs.getInt("resource");
    PreparedStatement st = conn.prepareStatement(sql2);
    st.setInt(1, id);
    st.setInt(2, oldVersion);
    if (resource > 0) {
      // compute (in this case reduce resource) resource-=1
      return st.executeUpdate() > 0;
    } else {
      return false;
    }
  }

  private void safeSleep(long time) {
    try {
      Thread.sleep(time);
    } catch (InterruptedException ex) {
      ex.printStackTrace();
    }
  }

  public void consumer() {
    for (; ; ) {
      try {
        if (tryLock()) { // cas
          // 执行想要的操作
          break;
        } else {
          // 其他锁修改了资源,重新尝试
          safeSleep(10);
        }
      } catch (SQLException e) {
        // 上锁失败,有概率资源不够,wait
        safeSleep(100);
      }
    }
  }

  static final String sql3 = "" +
    "UPDATE optimistic_lock " +
    "SET resource = resource + 1,version = version + 1 " +
    "WHERE id = ? AND version = ?";

  public boolean tryUnlock() throws SQLException {
    PreparedStatement statement = conn.prepareStatement(sql1);
    statement.setInt(1, id);
    ResultSet rs = statement.executeQuery();
    rs.next();
    int oldVersion = rs.getInt("version");
    int resource = rs.getInt("resource");
    PreparedStatement st = conn.prepareStatement(sql3);
    st.setInt(1, id);
    st.setInt(2, oldVersion);
    // compute (resource++)
    return st.executeUpdate() > 0;
  }

  public void produce() {
    for (; ; ) {
      try {
        if (tryUnlock()) { // cas
          // 执行想要的操作
          break;
        } else {
          // 其他锁修改了资源,重新尝试
          safeSleep(10);
        }
      } catch (SQLException e) {
        // 上锁失败,有概率资源不够,wait
        safeSleep(100);
      }
    }
  }


}

public static final ExecutorService pool1 = Executors.newFixedThreadPool(4);
public static final ExecutorService pool2 = Executors.newFixedThreadPool(4);
static final int n = 1000;
static final CountDownLatch latch = new CountDownLatch(n);
public static final MysqlLock lock = new MysqlLock();

@Test
public void test() throws InterruptedException {
  for (int j = 0; j < 100; j++) {
    pool1.submit(() -> {
      System.out.println(Thread.currentThread().getName()+"消费");
      lock.consumer();
    });
  }
  for (int j = 0; j < 200; j++) {
    pool2.submit(() -> {
      System.out.println(Thread.currentThread().getName()+"生产");
      lock.produce();
    });
  }
  Thread.sleep(1000);
}
```



### spring-jdbc

spring对jdbc的支持体现在以下几个库

-   springboot-starter
-   spring-jdbc
-   JdbcTemplate

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
```

springboot 加载 jdbc 主要是通过上面的 starter 完成的,starter主要加载了两个东西

-   spring-jdbc
-   hikariCP 一个连接池

我们看下 spring-jdbc 的作用







## 索引

---

索引本质上就是一种数据结构 用来存储某一个key的数据结构

常用的索引结构BST AVLTree 红黑树 B树等 为的是让查找次数更少

索引是根据表来的而不是根据数据库 引擎也是根据表来的 引擎决定了表的结构

建立索引意味着可以通过数据结构去找到相应的节点

### 索引和存储引擎

存储引擎及代表索引

-   聚簇索引InnoDB
-   二级索引MyISAM
-   Hash索引Memory (只有Memory存储引擎支持hash索引,hash用于精确索引)

![](https://images2015.cnblogs.com/blog/851461/201703/851461-20170306202857781-1607368004.png)

其中MyISAM和InnoDB用的多是B+树,是为磁盘上文件系统设计的索引结构,而Memory是内存型的数据库Hash索引则是用的hash方法查找具体的数据,由于是非线性结构所以不支持排序等.

一些不常见的索引

-   R-Tree空间索引 MyISAM对一些地理数据进行索引支持
-   Full-Text全文索引 MyISAM支持的另一个索引,顾名思义是进行全文索引用的,即查询文本中的关键词





### 索引覆盖(Using index)

---

覆盖索引指的是索引切实被用上了的意思,指的是查询数据的时候不用扫描行 扫描索引

看下论坛的解释如下

解释一： 就是select的数据列只用从索引中就能够取得，不必从数据表中读取，换句话说查询列要被所使用的索引覆盖。

解释二： 索引是高效找到行的一个方法，当能通过检索索引就可以读取想要的数据，那就不需要再到数据表中读取行了。如果一个索引包含了（或覆盖了）满足查询语句中字段与条件的数据就叫做覆盖索引。

解释三：是非聚集组合索引的一种形式，它包括在查询里的Select、Join和Where子句用到的所有列（即建立索引的字段正好是覆盖查询语句[select子句]与查询条件[Where子句]中所涉及的字段，也即，索引包含了查询正在查找的所有数据.



### 数据库索引原理

---

InnoDB: 其文件为聚集索引,及叶子节点的索引存储的是数据本身而非数据的地址

MyISAM: 其文件为非聚集索引,叶子节点存储的是数据的地址

B+树支持叶子节点的前驱后继指针非常良好的支持范围查找(where id>20) 减少磁盘I/O 



下面要考虑的问题主要分为两个层次

-   多个索引条件的查询索引
-   Mysql的实际存储逻辑



#### 详解B+树

B+树是由BST,AVLTree和B树演化而来的,BST和AVL是内存中基本的索引树,这里就不在赘述了.我们介绍B树,其是一种专门为磁盘I/O设计的树结构,其有一非常优秀的特点就是,树的高度不高,也就是说其在索引磁盘I/O的次数会远比AVL小,且保持了BST的向下索引特性.

##### B树(Balance Tree)

![](http://www.liuzk.com/wp-content/uploads/2019/11/5.jpg)

可以看到B树只是多路的AVL,其在mysql中对应的是准确索引.其中的增加删除节点结构我们不作深究.我们作为研究B+树的一个前置知识.

##### B+树

B+树是对B树的一种改进

![](http://www.liuzk.com/wp-content/uploads/2019/11/6.jpg)

-   B+树的非叶子节点是不存储数据的 (InnoDB默认是16k) 
    -   这么做的好处是,页的大小固定键值数就增加了
-   B+数的叶子节点按照顺序存储数据
    -   使得范围查询,排序查找,分组查询,以及去重变得简单
    -   叶子节点通过单向链表连接,页通过双向列表连接

#### 聚簇索引和非聚簇索引

从上面B树,B+树我们基本知道了索引的实现方式,而B+树主要实现的就是聚簇索引和非聚簇索引(辅助索引/二级索引),其是一种**数据存储的方式**,而非某一种具体的索引.

-   Innodb中的主键索引是一种聚簇索引,非聚簇索引都是辅助索引,像复合索引,前缀索引,唯一索引.
-   Innodb使用的是聚簇索引,MyISam使用的是非聚簇索引
-   Innodb通过主键聚集数据,如果没有定义主键,innodb会选择非空的唯一索引代替.如果没有这样的索引,innodb会隐式的定义一个主键(6个字节,长整形)来作为聚簇索引.

InnoDB的非聚簇索引在聚簇索引的前提下创建

![](https://img2018.cnblogs.com/i-beta/1464190/201911/1464190-20191106145143172-1760681728.png)

![](https://img2018.cnblogs.com/i-beta/1464190/201911/1464190-20191106151527647-152458631.png)



其数据不在如同主键索引那般保存整个行的值,而是索引的key值和相应行数据的聚簇索引键.由上图的辅助索引知,其是单独建立的,和主键索引基本是独立的,所以一张表中可能有多个辅助索引.基于以上的索引实现我们来谈下优化问题

-   不宜选用过长字段作为主索引
-   使用单调递增的字段

我们来描述两种概念

-   覆盖索引(Cover Index/Using Index)
-   回表查询

回表查询指的是从上面索引中找到了相应的字段(key值和表中row的id)如果只是为了查询key值就没必要按照主索引在找一遍,如上红线的过程,这个过程就叫**回表**,是属于辅助索引特有的状态

所谓的覆盖索引,即是只利用了辅助索引没有出现回表查询的即是少了一轮I/O操作,这个称之为索引覆盖.

那其中一个优化点已经可以出来了,就是**防止回表查询**,即所谓的**建立联合索引**.

#### 索引过程

##### 聚集索引索引过程

![](http://www.liuzk.com/wp-content/uploads/2019/11/7.jpg)

```sql
select * from user where id>=18 and id <40
```

-   跟节点一般是常驻内存的,所以首先读取内存
-   然后找到`id>=18 and id<40`的首范围18,即p2指针,以及p1指针定位到页8
-   然后这里是个顺序存储的链表,按照二分法去找到18,因为各个节点是顺序连接的,那么就按照顺序查找到下一页,加入内存在找,知道找到id<40

##### 非聚集索引索引过程

![](http://www.liuzk.com/wp-content/uploads/2019/11/9-1024x626.jpg)

`x-y x表示非聚簇的key,y表示主键的key`

![](http://www.liuzk.com/wp-content/uploads/2019/11/921.jpg)

那我们就看到了这个回表查询的过程



#### 联合索引的最左匹配原则

最左匹配原则就是指在**联合索引**中,如果你的SQL语句中用到了联合索引中的最左边的索引,那么这条SQL语句就可以利用这个联合索引去进行匹配.

```sql
select * from t where a=1 and b=1 and c =1;     
# 这样可以利用到定义的索引（a,b,c）,用上a,b,c
select * from t where a=1 and b=1;     
# 这样可以利用到定义的索引（a,b,c）,用上a,b
select * from t where b=1 and a=1;     
# 这样可以利用到定义的索引（a,b,c）,用上a,c（mysql有查询优化器）
select * from t where a=1;     
# 这样也可以利用到定义的索引（a,b,c）,用上a

select * from t where b=1 and c=1; # 因为没用(a,b,c)中的a所以匹配不上不走索引     
# 这样不可以利用到定义的索引（a,b,c）

select * from t where a=1 and c=1;     
# 这样可以利用到定义的索引（a,b,c），但只用上a索引，b,c索引用不到
```

通过上面的sql,我们看到了所谓的最左匹配是指联合索引中最左侧的key需要匹配上

**值得注意的是，当遇到范围查询(>、<、between、like)就会停止匹配**

```sql
select * from t where a=1 and b>1 and c =1; 
# 这样a,b可以用到（a,b,c），c索引用不到
select * from t where a=1 and b >1 and c=1;  
# 如果是建立(a,c,b)联合索引，则a,b,c都可以使用索引
```

-   以index （a,b,c）为例建立这样的索引相当于建立了索引a、ab、abc三个索引。(因为查询时候只有左侧是a,ab或者abc三个条件的时候才会去走上面的联合索引)一个索引顶三个索引当然是好事，毕竟每多一个索引，都会增加写操作的开销和磁盘空间的开销。

#### 最左匹配原理

首先我们要知道联合索引是怎么构建B+树的,构建B+树只能通过一个键来进行构建,所以数据库会按照联合索引的最左key来进行B+树的构建.

![](https://img2020.cnblogs.com/blog/867078/202007/867078-20200703134853993-1354025866.png)

最后一部分表代表(a,b,c)三个索引的位置信息.可以看到的是,当a相同的时候,b是有序的,但c是无序的,当a和b都相同的时候c是有序的,这就是之前说的原理,

即以index （a,b,c）为例建立这样的索引相当于建立了索引a、ab、abc三个索引。



---

### 优化

多个单列索引:多个单列字段加上索引 mysql在分析的时候只取最有用的一个 而这种时候 根据where字句的情况完全可以用来判别 是应该采用联合索引还是单个索引

联合索引:多个字段有先后顺序的索引 但本质相当于一个索引 其本质内容就是 按照key1排序然后在按照key2排序然后在按照key3以此类推

一般而言优化主要

分为几个方面

-   建立索引
-   建立联合索引

关于上面的建立优化我们通过索引查询原理基本已经得知,下面介绍一些选择的问题

-   创建单列索引还是多列索引
    -   如果查询语句中的where、order by、group 涉及多个字段，一般需要创建多列索引
-   多列索引的顺序如何选择
    -   一般情况下，把选择性高的字段放在前面
-   尽量避免使用范围查询
-   尽量避免查询不需要的数据
-   查询的数据类型要正确



#### 回表优化

考虑如下sql,其中tid是主索引(主键字段)

```sql
select tid,return_date from t1 order by inventory_id limit 50000,10;
```

```shell
explain select tid,return_date from t1 order by inventory_id limit 50000,10*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 1023675
        
1 row in set (0.00 sec)
```

全表扫描加上order by性能损耗严重.且没有任何索引,如果我们尝试给inventory_id加上索引为了查找return_date就要进行回表操作,会非常的慢.因此我们考虑不用回表操作的联合索引

```sql
alter table t1 add index liu(inventory_id,return_date);
```

```shell
explain select tid,return_date from t1 order by inventory_id limit 50000,10\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t1
         type: index
possible_keys: NULL
          key: liu
      key_len: 9
          ref: NULL
         rows: 50010
　　　　Extra: Using index
1 row in set (0.00 sec)
```

#### 排序Order by优化

通过EXPLAIN我们可以看到Order by的字句有两种排序

-   Using Index
-   Using filesort

Using index不必多说,Using filesort是指利用额外的空间(磁盘I/O)进行,我们要做的就是按照聚合索引的最左匹配原则进行,另外在后续的版本中优化了`order by ... limit n,m`使用的本质是堆排序.



#### Like优化

`like %a%`这样形式的字句是不走索引以及产生大量性能消耗,而对于`like %a`或者`like a%`这两种形式的字句explain发现其是使用索引的.

对`table.field like '%AAA%' `我们可以用locate函数改写成`locate ('AAA' , table.field) > 0`的形式,locate函数相当于返回`'AAA'`在`table.field`中出现的第一个位置,如果未出现则返回0.



#### 子查询和IN优化

从前面我们知道IN是用不到索引的,子查询的时候又大量使用到IN

```mysql
create table test_table2
(
    id int auto_increment primary key,
    pay_id int, # 有索引
    pay_time datetime,
    other_col varchar(100)
)
```

当有如下sql查询,查询时间段在之间支付记录大于一条的信息

```sql
select * from test_table2 force index(idx_pay_id) 
# 如果mysql没使用索引的话force index强制使用索引
where pay_id in (
　　select pay_id from test_table2 
　　where pay_time>="2016-06-01 00:00:00" 
　　　　AND pay_time<="2017-07-03 12:59:59" 
　　group by pay_id 
　　having count(pay_id) > 1
);
```

可以改成如下写法,利用join对同张表进行连接,其效率比上面要快

```sql
select t1.* from test_table2 t1, 
(
     select pay_id 
     from test_table2 
      WHERE pay_time>="2016-07-01 00:00:00" 
     AND pay_time<="2017-07-03 12:59:59" 
     group by pay_id 
     having count(pay_id) > 1
) t2 
where t1.pay_id=t2.pay_id
```

我们可以看到,哪怕是join只要使用上了索引,其连接速度就会加快.可以得到以下优化的推论

```note
在范围判断时，尽量不要使用not in和not exists，使用 left join on xxx is null代替。
```

所以对于mysql的in索引我们要谨慎使用









### 索引类型

-   普通索引

    NORMAL

-   唯一索引(字段的值必须唯一)

    UNIQUE

-   全文索引(这个和我们认知差不多 mysql会预分词(国外)等索引的时候就按照词去索引就快了)

    FULLTEXT 只能标注在 char varchar上

-   空间索引(支持一些比较新的openGIS类型的空间数据的索引)

    SPATIAL

---

mysql 在建立表的时候已经为主键和外键建立了索引 剩下的查询字段我们自己手动建立索引

查看表的索引

show index from tablename;

创建索引 删除索引

```sql
# 创建普通索引
ALTER table tableName ADD INDEX indexName(columnName) USING BTREE;
# 创建联合索引
ALTER TABLE `test`.`user` ADD INDEX `combine_index`(`id`, `user_name`(3)) USING BTREE;
ALTER TABLE `test`.`user` 
DROP INDEX `combine_index`;
```

创建之后我们可以看到表的结构信息变了

```sql
| user  | CREATE TABLE `user` (
  `id` bigint(20) NOT NULL,
  `pass_word` varchar(255) NOT NULL,
  `user_name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `name_index` (`user_name`(10)) USING BTREE, # 索引
  KEY `pass_index` (`pass_word`(3)) USING BTREE  # 索引
  KEY `combine_index` (`id`,`user_name`(3)) USING BTREE # 联合索引
) ENGINE=InnoDB DEFAULT CHARSET=utf8 |
```

查看运行分析

```java
EXPLAIN select * from users
```



### 索引下推

索引下推是5.6版本的优化,称为ICP(index condtion pushdown),在原来的时候我们一般是从存储引擎拉取所有日志在服务器做判断数据数据是否复合条件.

ICP解决的问题,服务器把这部分条件判断下推到存储引擎,由存储引擎来做这部分条件的判断,索引下推减少存储引擎查询基础表的次数.减少存储引擎的数据量.

![](https://pic3.zhimg.com/80/v2-04b4a496ab53eccc5feba150bf9fb7ea_720w.jpg)

这是原来的数据查询,利用某个索引查到id进行回表查询.不使用ipc的情况下,第一次搜到name就查询到了对应的id然后返回服务器,服务器在查询到对应的id然后根据id去继续查找索引.所以其本身使用的索引有效字段是1个.

![](https://pic1.zhimg.com/80/v2-211aaba883221c81d5d7578783a80764_720w.jpg)

使用了 IPC 之后就用到了2个,此过程由存储引擎完成,返回的数据只有一个

explain  可以通过 `Using index condition` 来确定是否使用索引下推

>```sql
>SELECT * from user where  name like '陈%' and age=20
>```
>
>组合索引满足最左匹配，但是遇到非等值判断时匹配停止。
>name like '陈%' 不是等值匹配，所以 age = 20 这里就用不上 (name,age) 组合索引了。如果没有索引下推，组合索引只能用到 name，age 的判定就需要回表才能做了。5.6之后有了索引下推，age = 20 可以直接在组合索引里判定。

### 在线DDL

[参考](https://www.cnblogs.com/xinysu/p/6732646.html)

5.6.7 以前 InnoDB支持两种表的DDL方式

- copy table
- inplace

#### copy table

- 创建临时表,在临时表上执行DDL
- 锁表,不允许DML,允许查询
- 数据逐行写入临时表中
- 写入后原表停止读取
- rename 重命名表完成DDL

#### inplace

仅针对索引的创建和删除,不支持其他表结构的修改

- 新建frm临时文件
- 锁原表,不允许DML,允许查询
- 按照聚集索引的顺序,查询数据,找到需要的索引列数据,排序后插入到新的**索引页**中
- 禁止原表读写
- 进行 rename 操作替换 frm 文件

inplace 在 copy table 的基础上进行了一个改进就是不需要取所有的数据,但是其相当于重构索引,这个时候数据是变少了但是也只能够去修改索引而不能修改表的结构,因为修改表的结构需要额外的操作支持不像索引比较简单

对于线上而言无论是上面那种都只是支持查找,在DDL期间写将会失效.在5.6.7以后 mysql 支持动态 DDL

5.6.7以后其会按照下面的形式支持,如果是不支持 online ddl 的 sql 会走 copy table的路径 

![](https://images2015.cnblogs.com/blog/608061/201704/608061-20170419114223009-2125010920.png)

ddl 以类似事务的方式执行,但不需要记录 redo-log 和 undo-log

- 需要rebuild: 利用 row_log 对象记录增量, **row_log** 记录的增量最后会放到一个 block 中
- 不需要rebuild: 生成临时的 idb 文件,重建索引块
- 提交

在 ddl 期间如果数据发生修改数据本身是会直接刷到 idb 文件中, row_log 应该是记录了主键,然后通过主键来确定新增的数据

## 分库分表

常用的数据库中间件有 mycat 和 shardingsphere,两者之间的对比[参考](https://blog.csdn.net/yiyihuazi/article/details/107836304),从性能的角度看 Sharding-JDBC的侵入式稍微强点,性能也稍微高点.

### mycat

mycat是基于Cobar演变而来,其是实现了MySQL协议的一个Server.如下我们可以看到其主要功能

![](https://img-blog.csdnimg.cn/20200514152508518.png?#pic_center)

其主要作为一个代理访问数据库的中间件使用







---

> 上文所述基本是实现业务相关内容,下文主要探讨 mysql 服务器实现相关内容
>
> 此处特别鸣谢 @wudayuan 分享,整理的下面一部分知识点,参考自 mysql 的官网和 innodb

---

## mysql 服务器结构





## 日志系统

主要分为以下几个日志

- redo-log(重做日志)
- undo-log
- binlog(归档日志,这个日志在server层的)

![](https://www.linuxidc.com/upload/2018_11/181121105137362.png)

我们看到server层面的东西都是mysql的sql实现

### innodb存储日志

#### redo-log(内存/磁盘上)

- 内存中 redo-log-buffer 缓冲区
- 磁盘上 redo log file 持久化在磁盘

redo-log是存储引引擎层的日志,用于记录**事务**操作的变化,记录的是数据修改后的值,无论事务是否提交都会被记录下来.如果数据库宕机,redo-log就可以恢复.每条insert语句都会**被记录下来,然后更新内存**,这是条完整的语句执行.redo-log实在空闲时或者是按照设定的更新策略把redo-log的内容更新到磁盘,redo-log的缓冲区大小是固定的写完了就得从头写.从头写的时候数据库就会把日志持久化到磁盘上.一般触发持久化的条件为 512MB 即块的大小,由 `innodb_log_file_size` 控制

#### undo-log回滚日志

undo-log和redo-log是innodb事务的重要的实现基础.又叫回滚日志.提供向前滚的操作.同时其提供MVCC版本的读.

- redo-log通常是物理操作,记录的是数据页的物理修改.用它来恢复到提交后的物理数据页
- undo用来回滚杭机路到某个版本,且undo-log是逻辑日志.

redo-log用来保证实物的持久性,防止有些脏页未写入磁盘,再重启mysql的时候,根据redo-log进行重做,从而达到实物持久性.undo-log保存了事务发生之前的版本用于回滚,同时提供MVCC,undo-log对于每一个insert存一个delete,update执行相反的update

当事务提交的时候，InnoDB 不会立即删除 undo log，因为后续还可能会用到 undo log，如隔离级别为 repeatable read 时，事务读取的都是开启事务时的最新提交行版本，只要该事务不结束，该行版本就不能删除，即 undo log 不能删除。

当事务提交之后，undo log 并不能立马被删除，而是放入待清理的链表，由 purge 线程判断是否有其他事务在使用 undo 段中表的上一个事务之前的版本信息，决定是否可以清理 undo log 的日志空间。

#### 一般一个事务的执行过程是

1. 开启事务
2. 查询待更新的记录到内存，并加 X 锁
3. 记录 undo log 到内存 buffer
4. 记录 redo log 到内存 buffer
5. 更改内存中的数据记录
6. 提交事务，触发 redo log 刷盘**真正写入表中**
7. 记录 bin log
8. 事务结束

所以观看其存储设计,我们会发现内存文件和磁盘文件的结构和ES很类似.所有文件都以内存和磁盘两种形式去存储



### binlog日志 记录所有更新语句 用于复制

其本身是以二进制形式记录这个语句的原始逻辑.binlog可以用作为数据恢复使用,主从复制搭建.即类比redis的rdb和aof,rdb对应redo-log,aof对应binlog.

binlog 有三种格式

- Row 记录下每行的修改细节,不记录上下文信息,alter table的时候每行数据都会发生改变就会产生大量数据
- Statement 每一条修改的语句会记录下,减少日志的记录,缺点就是需要执行所有的语句需要上下问信息
- Mixed 上面两种的混合,例如在alter语句使用 Statement

### Others

- 慢查询日志
- 错误日志
- 中继日志(slave 配合 master 进行 binlog 复制)
- 一般查询日志(general log)



## mysql的并发控制

---

### 事务实现原理

#### 事务

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

#### JDBC事务

```java
try{
  conn.setAutoCommit(false);
  stmt = conn.createStatement(); 
  // 将 A 账户中的金额减少 500 
  stmt.execute("update t_account set amount = amount - 500 where account_id = 'A'");
  // 将 B 账户中的金额增加 500 
  stmt.execute("update t_account set amount = amount + 500 where account_id = 'B'");
  // 提交事务
  conn.commit();
}catch(SQLException sqle){
  conn.rollback();
  // close
}
```

可以看到JDBC事务是以Connection为基础进行回滚的.JDBC的特点是不能跨数据库进行,多数据或者分布式的话.JDBC事务就没啥用处了.



#### 日志

redo-log重做日志 / undo-log 回滚日志

redo-log分为两部分,在内存中的redo-log-buffer和磁盘中的redo-log,事务的提交之后所有修改信息会保存在日志中.例如有表

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2ff3e4c3b8b46?w=2368&h=788&f=png&s=226339)

```sql
start transaction;
select balance from bank where name="zhangsan";
// 生成 重做日志 balance=600
update bank set balance = balance - 400; 
// 生成 重做日志 amount=400
update finance set amount = amount + 400;
commit;
```

其执行方式如下

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2fdae04c7dc6f?w=4016&h=1892&f=png&s=1010471)

redo-log的作用是用来恢复数据的,在宕机的时候我们丢掉的只是红色部分的信息.这一日志用来保证系统的持久性.

---

undo-log 又叫回滚日志,顾名思义是用来回滚记录的.和redo-log记录数据不同,undo-log是用来记录对数据的操作的操作.

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2fe552145e2c1?w=4652&h=1848&f=png&s=867671)

undo-log用来保证事务的原子性.



#### MVCC

MVCC(MultiVersion Concurrency Control)多版本并发控制.

>   InnoDB的 MVCC ,是通过在每行记录的后面保存两个隐藏的列来实现的.这两个列,一个保存了行的创建时间,一个保存了行的过期时间,存储的并不是实际的时间值,而是系统版本号.

#### 事务的实现

-   事务的原子性是通过 undo log 来实现的
-   事务的持久性性是通过 redo log 来实现的
-   事务的隔离性是通过(读写锁+MVCC)来实现的
-   事务的一致性是通过上面三个特性实现的

原子性由undo-log实现,显然是通过回滚操作去实现,每条写操作都要写入undo-log,我们可以通过相应操作的逆向操作rollback,那么对应的insert语句就是delete,delete是insert,update是update,即可以逆向操作.

持久性的实现是通过redo-log,一旦事务提交,所有的修改都会被持久化到数据库上,此时系统即使崩溃也不会丢失数据.显然我们看到了redo-buffer的作用,在持久化区域起到缓冲,所有的读写都会经过这个缓冲区.这种缓冲区虽然极大地提高了速度,但本身没有持久化的功能即redo-log解决了这一问题,记录操作和记录操作的数据显然操作需要的I/O更小,也能被接受.

隔离性的实现,我们平常看到的四种隔离级别

-   READ_UNCOMMIT
-   READ_COMMIT
-   REPEATABLE_READ
-   SERILIAZABLE

隔离性的重点就在于并发控制,我们可以看到其是用读写锁和MVCC实现的充满了Concurrent的味道.

READ_UNCOMMIT

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2ed4dbd348a68?w=4284&h=1288&f=png&s=731191)

读未提交仅有写会加上锁,读不加锁所以就能够看到写到一半的数据就发生了脏读.

READ_COMMIT

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2f05d63f388d0?w=3612&h=1512&f=png&s=816439)

InnoDB采用了此种机制,写的时候加上锁,读的时候通过MVCC来确定字段的修改,这种操作从读上来讲就相当于读没有修改的副本自然不会出现中间的状态,不会出现幻读,但是仍有可能出现不可重复读的现象(有点类似Copy-On-Write的设计思路).可以看到其读的不是并不是同一个副本.

REPEATABLE_READ (Mysql默认)

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2c351eb03fc24?w=1082&h=290&f=png&s=120400)

这种默认的级别用两种方式可以实现,读写锁和MVCC,上面就是采用读写锁,即读共享锁,只要没有释放锁就可以读一样的数据,这样一来并发性能下降严重.一般是使用下面的方法实现,InnoDB就是利用下面方法实现的.

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2f054474b394b?w=3584&h=1512&f=png&s=756027)

如上面和COW类似的机制,读取修改前的副本即可保证读不重复,即通过读副本的方式.其可以用空间换并发效率.该版本的实现依然会存在幻读问题.但能从另外的方式解决.

SERILIZABLE

![](https://user-gold-cdn.xitu.io/2019/4/18/16a2f56d34ff739e?w=3528&h=1060&f=png&s=414467)

即全部串行来读.全部采用独占锁.



### 事务线程安全

---

#### 快照读和当前读

通过上面的MVCC我们可以知道

-   当前读,读数据最新版本,要对数据进行加锁
-   快照读,读快照snapshot-v1根据不同版本有不同的读的结果

从另一个角度

当前读会在读的过程中加锁,快照读不会加锁.



#### 幻读和不可重复读

这两东西的定义在上面可能过于浅薄了.我们重新定义下幻读.

-   事务A 按照一定条件进行数据读取,期间事务B 插入了相同搜索条件的新数据,事务A再次按照原先条件进行读取时,发现了事务B 新插入的数据称为幻读.

我们可以看到这个定义和不可重复读类似,两次读了按相同读了不同的数据.**在快照读时,我们是不需要考虑幻读的在当前读时我们才会遇到幻读.**

来看如下例子 [引用](https://zhuanlan.zhihu.com/p/103580034?utm_source=wechat_session)

-   T1时刻 读取年龄为20的数据， Session1拿到了2条记录。
-   T2时刻 另一个进程Session2插入了一条新的记录，年龄也为20
-   T3时刻，Session1再次读取年龄为20的数据，发现还是2条数据，貌似 Session2新插入的数据并未影响到Session1的事务读取。

>   对于T1 -- T3 时刻的情形，从结果来看，在可重复度读隔离级别下似乎解决了幻读的问题。

-   T4时刻，Session1 修改年龄为20的数据， 发现影响行数为3条。 为什么T3时候只能查到2条数据，但现在修改确修改了3条数据？
-   T5时刻，Session1 再次读取年龄为20的数据，发现结果变成了3条,我们知道被修改的第三条就是Session2在T2时刻新增的一条。

>   T4,T5 的结果来看，Session1 读到了 Session2 新插入的数据。产生了幻读现象

如果只使用快照读就不会出现幻读,但同时使用当前读和快照读就会出现问题.



#### 事物线程安全

我们先来看一下事物的线程安全问题

-   提交,数据生效到数据库的过程(写回)
-   未提交,数据修改发生在线程内部,未写回数据库

理解了以上两点我们再来看mysql的锁和事物的锁,我们知道mysql的select语句一般是不加锁的,insert语句一般加表锁或者是行锁.所以事物内部的读写之间是线程安全的.我们要做的是解决事物之间的线程安全问题.

显然我们可以轻易知道,让事物在线程内部进行修改,然后一次性写回,我们**只要保证这个写回过程是线程安全的那么事物就是线程安全的**.

上面所说的脏读幻读不可重复读,全部都是对写回过程时***正在执行事务的其他线程的读写***会出现的问题.有了这个思路之后我们看下是如何通过各种机制解决问题,遇到问题的.



从上面可以知道读写锁和mysql事务隔离等级的关系.在此总结,mysql的事务隔离级别也是不同读写锁的一个体现

-   写加排他锁,读不加锁(READ_COMMIT,READ_UNCOMMIT)
-   写加排他锁,读加共享锁 (REPEATEABLE_READ)
-   写加排他锁,读加排他锁 (SERELIZABLE)

#### 写加排他,读不加锁.

读写不互斥,写写互斥.好处在于读写可以共同进行,两种实现方式**读提交**和**读未提交**的区别仅在于,读未提交是直接读取数据(**脏读**),而读提交就可以解决脏读问题(方法用的是多版本控制MVCC读取内存快照snapshot).其思路要其他事务线程提交结束(写回)之后再进行读.

从这里我们分析下问题出现的原因,是因为**读写不互斥**,那读的过程中,可能会发生事务线程读到别的写进程(写回进程)里面修改到一半的中间数据(脏读,按上面进行读提交之后不会有(也可以说是版本控制)),会出现同一线程两次读的内容不同的问题(重复读).当然还可能出现当其他事务insert语句插入数据时,就可能产生新的数据,原读事务线程读不到(因为本事务加锁的时候就没考虑这些凭空出现的数据).



#### 写排它锁,读共享锁.

即读写之间互斥,读读之间共享,写写互斥.这样的好处是,读的时候就不可以更改内容了,保证读语句不会出现问题(REPEATEABLE_READ),mysql的默认选择.他保证了读数据的版本一致,即不会出现不可重复读的问题,因为读的都是统一数据版本读两次数据也是一致(**但需要注意mysql用的是单一版本的读不加锁,共享锁实现也是一种方案**)

但同样这样也有其问题幻读无法解决,这是因为在**不同事物交替进行的过程中,同样还可能会出现读进程无法获取到新插入的数据.**幻读问题虽然发生的比较少,但是确是难以解决,一般使用间隙锁去解决这个问题.



#### 写排他锁,读排它锁

串行化(SERELIZABLE)可以解决上面的问题,因为读写,写写,读读都是互斥的.这就导致了最多只有一个进程在读或在写,这样来看基本不会出现问题.





### 锁定方式

-   表级锁定table-level

    表级别的锁定是mysql中粒度最大的锁定,使用表级MyISAM,csv,memory等引擎

-   行级锁定row-level

    行级锁定在并发处理上有最小的粒度,行级锁最容易发生死锁,在InnoDB上使用

-   页级锁定page-level

    这个级别是Mysql中特有的级别,其介于行级锁和表级锁之间,主要用于BerkeleyDB

他们的适用范围

表级锁适合于带有少量条件的查询,行级锁更适合有大量索引条件,且并发更新不同的数据,如在线处理事务系统.

### sql加锁

**在MyISAM中**,表级锁有两种共享读锁和独占写锁.其互斥形式和ReentrantReadWriteLock一致即读中不能写,写中不能读写.这个锁是**表级的锁**,MyISAM使用的是隐式加锁,即自动加锁,在select前面加读锁,在update,delete,insert之间加的是写锁.我们需要让MyISAM加锁的时间尽可能的小,其锁定级别不可轻易改变.我们也能看出来**MyISAM是写优先的**

mysql里面有专门两组变量计算锁的争用情况,分别表示锁定的次数和等待的次数.

```shell
mysql> show status like 'table%';
+----------------------------+---------+
| Variable_name              | Value   |
+----------------------------+---------+
| Table_locks_immediate      | 100     |
| Table_locks_waited         | 11      |
+----------------------------+---------+
```

而在其他引擎中,例如**NDBCluster(分布式)和InnoDB**中他们自己实现了行级锁,下面主要介绍InnoDB的控制方式.InnoDB是目前广泛使用的事务存储引擎.InnoDB的行级锁也分为共享锁和排他锁.中还要涉及到一个概念叫意向锁如下.

![](https://images2015.cnblogs.com/blog/1033231/201701/1033231-20170118181153984-1417117507.png)

如果是兼容的,那么InnoDB会给请求的事务授予锁,否则,则会等待前一把锁释放.加锁逻辑是

-   如果该资源没被加锁,可以加共享锁和排它锁
-   如果该资源被加共享锁,可以加共享锁但不能加排它锁
-   如果该资源被加了排他锁,就不能加共享锁,也不能加排它锁,但可以加意向锁

仅当被加资源排它锁之后,才会加意向锁,根据后续进程想要加的锁,分为共享意向锁,排他意向锁.意向共享锁可以存在多个,意向排他锁只能存在一个.意向锁是InnoDB自己加的,不需要用户干预.

-   **对于Select,InnoDB不会加共享锁**,在事务中利用MVCC(类似COW)机制控制并发
-   对于Update,Delete,Insert等,InnoDB会给加排它锁

我们可以利用下面的sql语句实现加锁

```sql
SELECT * FROM table_name WHERE ... LOCK IN SHARE MODE # 加共享锁
SELECT * FROM table_name WHERE ... FOR UPDATE # 加排它锁
```

select加排他锁的语义是为了确保没有其他线程对其修改,InnoDB是通过给索引项加锁来实现行级锁的,只有索引索引条件才能使用行级锁,否则就相当于使用表锁.如果是**相同的索引键**就可能会发生冲突.且用EXPLAIN我们可以知道在一些小的表里面,mysql是会使用全表扫描的,必须通过索引才会触发行级锁,否则使用的都是表锁.

除此之外mysql还有一种间隙锁(Next Key).例如

```shell
mysql> select * from emp where empid > 100 for update;
```

mysql会对大于100的所有记录加锁,即如果只有101条记录,也会对不存在的其他记录加锁.这个锁的目的

-   防止幻读,如果其他事务插入了>100以上的数据,那么就会读到本不存在的数据,破坏事务的原子性,在下面我们会详细介绍事务

除此之外需要注意的是间隙锁可能会对性能造成很大的影响,当Query无法利用索引时就会使用全表锁,Query的过滤条件会导致某些数据无法正确插入



### 锁表

- alter table 会锁表,新增一个字段会造成表级锁
- 加索引时,如果有慢查询在执行也会超时 `Waiting for table metadata lock`该锁其实有三种情况
  - 长事务运行,阻塞DDL
  - 未提交事务,阻塞DDL

无锁添加索引，mysql 5.6之后提供了解决方式

```sql
ALTER TABLE tbl_name ADD PRIMARY KEY (column), ALGORITHM=INPLACE, LOCK=NONE; # 该种方式不能用于 ADD COLUMN
```

```note
LOCK=DEFAULT：默认方式，MySQL自行判断使用哪种LOCK模式，尽量不锁表
LOCK=NONE：无锁：允许Online DDL期间进行并发读写操作。如果Online DDL操作不支持对表的继续写入，则DDL操作失败，对表修改无效
LOCK=SHARED：共享锁：Online DDL操作期间堵塞写入，不影响读取
LOCK=EXCLUSIVE：排它锁：Online DDL操作期间不允许对锁表进行任何操作

ALGORITHM=INPLACE 
更优秀的解决方案，在当前表加索引，步骤：
1.创建索引(二级索引)数据字典
2.加共享表锁，禁止DML，允许查询
3.读取聚簇索引，构造新的索引项，排序并插入新索引
4.等待打开当前表的所有只读事务提交
5.创建索引结束

ALGORITHM=COPY
通过临时表创建索引，需要多一倍存储，还有更多的IO，步骤：
1.新建带索引（主键索引）的临时表
2.锁原表，禁止DML，允许查询
3.将原表数据拷贝到临时表
4.禁止读写,进行rename，升级字典锁
5.完成创建索引操作
```

该种方式能够解决在 update,insert级别的锁,但如果是事务持有了表锁,创建索引就需要等待事务提交完成,事务提交完成之后才进行索引的建立.

在数据量很大的表新增一个字段或者索引不锁表的解决方案

- 单一结构数据库
  - 新建一个表,dump表的结构过去,新表加字段或者索引,dump数据库的内容
  - 会造成部分损失,用 log 或者在 service 上控制完成数据的迁移
- 主从结构的数据库
  - 这个有一个前置知识,从库会根据 binlog 同步数据
  - 先额外申请一个从库,在从库上完成修改(同步机制存在数据会同步到从库)
  - 主从切换



### MVCC间隙锁





### 死锁

MyISAM是不会发生死锁的,因为他每次就用那一把锁,用完就释放,不存在其他行为,缺点就是性能低下.即deadlock free,显然InnoDB中获取到了对面事务资源需要的锁就会造成死锁.InnoDB自身可以检测到自己的死锁,并且回滚掉带较小的事务

>   但是有一点需要注意的就是，当产生死锁的场景中涉及到不止InnoDB存储引擎的时候，InnoDB是没办法检测到该死锁的，这时候就只能通过锁定超时限制参数InnoDB_lock_wait_timeout来解决。
>   需要说明的是，这个参数并不是只用来解决死锁问题，在并发访问比较高的情况下，如果大量事务因无法立即获得所需的锁而挂起，会占用大量计算机资源，造成严重性能问题，甚至拖跨数据库。我们通过设置合适的锁等待超时阈值，可以避免这种情况发生。

这也告诉了我们在JUC包中获得锁设置等待事件的意义,如果没获取到锁尽早进入异常处理,提示系统繁忙是比直接傻等着获取锁要好很多,哪怕JDK1.8对synchronized做出了相应的优化,其在系统的可靠性上远远不及JUC工具中自己实现的可中断的等待队列.

我们可以使用如下方法来避免死锁

>-   在应用中，如果不同的程序会并发存取多个表，应尽量约定以相同的顺序来访问表，这样可以大大降低产生死锁的机会。
>-   在程序以批量方式处理数据的时候，如果事先对数据排序，保证每个线程按固定的顺序来处理记录，也可以大大降低出现死锁的可能。
>-   在事务中，如果要更新记录，应该**直接申请足够级别的锁**，即排他锁，而不应先申请共享锁，更新时再申请排他锁，因为当用户申请排他锁时，其他事务可能又已经获得了相同记录的共享锁，从而造成锁冲突，甚至死锁。
>-   在REPEATABLE-READ隔离级别下，如果两个线程同时对相同条件记录用SELECT...FOR UPDATE加排他锁，在没有符合该条件记录情况下，两个线程都会加锁成功。程序发现记录尚不存在，就试图插入一条新记录，如果两个线程都这么做，就会出现死锁。这种情况下，将隔离级别改成READ COMMITTED，就可避免问题。
>-   当隔离级别为READ COMMITTED时，如果两个线程都先执行SELECT...FOR UPDATE，判断是否存在符合条件的记录，如果没有，就插入记录。此时，只有一个线程能插入成功，另一个线程会出现锁等待，当第1个线程提交后，第2个线程会因主键重出错，但虽然这个线程出错了，却会获得一个排他锁。这时如果有第3个线程又来申请排他锁，也会出现死锁。对于这种情况，可以直接做插入操作，然后再捕获主键重异常，或者在遇到主键重错误时，总是执行ROLLBACK释放获得的排他锁。



### 乐观锁

这是一种加锁的方式,即CAS-loop的lock-free,可以参考AtomicInteger的设计思想.

mysql使用数据库版本号来控制

![mysql版本控制](https://upload-images.jianshu.io/upload_images/4461377-d7472568e615e335.png)

```sql
# 订单系统的基本cas加锁逻辑,但
select (quantity,version) from items where id=100; # 存version
insert into orders(id,item_id) values(null,100);
update items set quantity=quantity-1,version=version+1 where id=100 and version=#{version}; # 典型的CAS,失败就回滚
```

如果是主从分离的数据库select一般是用于访问从数据库的 但是如果把select放在了事务中 访问的是主数据库 另外 如果并发操作很高的时候 从数据库同步可能不及时也会导致查询失败

秒杀系统的核心代码(细粒度的乐观锁)

```sql
# step1: 查询出商品信息
select (inventory) from items where id=100;
# step2: 根据商品信息生成订单
insert into orders(id,item_id) values(null,100);
# step3: 修改商品的库存
update items set inventory=inventory-1 where id=100 and inventory-1>0;
# 如果库存数量不够就会失败,失败进行回滚的时候就可以通知用户下单失败
```

这种如果对行操作version字段保持着相当高的冲突,如果竞争强烈的话建议直接换成悲观锁.

我们可以采用更加细粒度的直接对字段加锁 一般数据库有类似quantity这样的高并发的字段的时候 我们可以命名quantity_cc 单独控制一个字段的高并发



### 悲观锁

认为所有操作都会修改数据库的数据 重量级锁全锁定读写

mysql想使用悲观锁得 set autocommit=0;

然后sql语句得写成这样

```sql
# step1: 查出商品状态
select quantity from items where id=100 for update;
# step2: 根据商品信息生成订单
insert into orders(id,item_id) values(null,100);
# step3: 修改商品的库存
update Items set quantity=quantity-2 where id=100;
```

这个for update 是mysql使用悲观锁的方式 其他事务得等到该事务提交之后才能使用

这个锁的是扫描过的所有字段 如果不加索引 相当于全表锁,



## innodb 的存储结构

- frm 文件是表的结构描述文件
- idb 文件,innodb 特有的文件存储数据和索引
- par 文件是分区之后的信息存储文件

如果是 myisam 的结构,其数据和索引是分开存放的分别存放于 `MYD` 和 `MYI`文件中







## 存储引擎和 sql 优化

### 谓词下推 ICP

```sql
select *
from sbtest t1 join snapshot t2 on t1.id=t2.id
where t2.snap_id=1420637262
```

```sql
select *
from sbtest t1 join (select * from snapshot where snap_id=1420637262) t2
on t1.id=t2.id
```

看两个查询,如果按照顺序执行sql,那么下面的要比上面的快,因为其子查询决定了其链接时候数据小,但实际执行的时候两者的效率相差不大

这是因为我们写的sql被进行了优化,选择相关的条件尽可能的早做,这个优化在Spark Sql中有大量的应用.优化器自动帮我们实现了这种优化.

