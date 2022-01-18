# mysql优化

---

优化的方向有两个sql结构优化,索引,存储过程(因数据库迁移问题等很少使用)


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

#### 其他

- show full columns from table
- show index from table 
- show variables like '%char%'
- show variables like '%bin%'
- show engine innodb status 查看锁的状态等



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

> ***\*in通常是走索引的\**，当in后面的数据在数据表中超过\**\*30%\**\*（上面的例子的匹配数据大约6000/16000 = 37.5%）的匹配时，会走全表扫描，即不走索引，因此\**in走不走索引和后面的数据有关系\**。**

可以用 Explain 查看,所以使用 in 字段也会寻找索引进行路由

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

对于普通索引，当我们找到k=1的记录之后，首先需要通过索引上的id字段"回表"查询聚集索引上其他字段的内容，然后要接着向后寻找其他k=1的值，重复这个过程。因为普通索引可能有重复的现象发生。

对于唯一索引，查找到第一个满足条件的记录后，查找的过程就会停止。

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

分库分表带来的问题点有以下几个

-   数据操作的准确性,重命名,聚合
-   分布性事务(强一致性事务,柔性事务)

### mycat

mycat是基于Cobar演变而来,其是实现了MySQL协议的一个Server.如下我们可以看到其主要功能

![](https://img-blog.csdnimg.cn/20200514152508518.png?#pic_center)

其主要作为一个代理访问数据库的中间件使用,可以看到其是用中间层聚合的方式来合并各个mysql之间的结果的,其主要完成路由选择的功能.作为数据库访问的中间件,其主要实现以下的功能

-   分库分表 (特性:单库多表,多库单表,多表 join)
-   支持聚合
-   支持降级
-   支持主从切换
-   无侵入性

### ShardingSphere

ShardingSphere 和 Mycat 类似也是分库分表的中间件,不同点是 ShardingSphere 的性能更高,对 java 的支持更好,其侵入性更强.ShardingSphere 由以下组件组成,其最终加入了 Apache 项目

-   Sharding-JDBC 增强版本的 JDBC 驱动,兼容各种 orm 框架,对于 Java 侵入式的修改驱动,对代码无侵入
-   Sharding-Proxy 对标 mycat 作为前端
-   Sharding-Sidecar

#### shardingSphere JDBC

![](https://img-blog.csdnimg.cn/2020051313400524.png?#pic_center)

可以看到是在 Java 的 JDBC 的层面就通过路由实现了不同 database 的访问,



```yml
sharding:
  jdbc:
    datasource:
      names: ds0,ds1
      # 数据源ds0
      ds0:
        driver-class-name: com.mysql.jdbc.Driver
        url: jdbc:mysql://localhost:3306/order1
        username: root
        password: 123456
      # 数据源ds1
      ds1:
        driver-class-name: com.mysql.jdbc.Driver
        url: jdbc:mysql://localhost:3306/order2
        username: root
        password: 123456
    config:
      sharding:
        props:
          sql.show: true
        tables:
          t_user:  #t_user表
            key-generator-column-name: id  #主键
            actual-data-nodes: ds${0..1}.t_user${0..1}    #数据节点,均匀分布
            database-strategy:   #分库策略
              inline:
                sharding-column: city_id        #列名称，多个列以逗号分隔
                algorithm-expression: ds${city_id % 2}    #按模运算分配
            table-strategy:  #分表策略
              inline:
                sharding-column: sex
                algorithm-expression: t_user${sex % 2}
          t_address:
            key-generator-column-name: id
            actual-data-nodes: ds${0..1}.t_address
            database-strategy:
              inline:
                sharding-column: lit
                algorithm-expression: ds${lit % 2}
```





#### shardingSphere Proxy

Sharding-Proxy 属于和 Mycat 对标的产品，它定位为透明化的数据库代理端，提供封装了数据库二进制协议的服务端版本，用于完成对异构语言的支持。

![](https://img-blog.csdnimg.cn/20200513134505921.png?#pic_center)



#### Sharding-Sidecar

![](https://img-blog.csdnimg.cn/20200513142155785.png?#pic_center)

其为 k8s 的云原生代理,sidecar 用于对接 docker 容器内的 sidecar,在容器内的访问通过 sidecar 来路由到对应的数据库.





---

> 上文所述基本是实现业务相关内容,下文主要探讨 mysql 服务器实现相关内容
>
> 此处特别鸣谢 @wudayuan 分享,拜读其[文章](),整理出的下面一部分知识点

---

## mysql 服务器结构（innodb base）

### 一些常见的问题

- mysql 的刷盘时机
  - buffer pool lfu (flush list) 无可用页面的时候刷盘,定期10s 刷盘
  - redolog LSN 超过检查点太多 三个级别 0,1,2
  - buffer pool lru 淘汰页面一般是读取的不会进行刷盘

### introduction

研究 mysql 的服务器架构主要关注以下一些点,内存管理,事务,其中内存管理的部分主要是与磁盘I/O相关的 buffer pool 包括 change buffer,宏观上看,服务器的本质无非是读和写,对 mysql 而言,重要的操作其实有四个,即所谓的CRUD,这四个操作除了 Select 是读操作之外,其他操作都是写操作

读操作会利用到 buffer pool 的 LRU list 进行淘汰,而写操作一般涉及到 change buffer,事务,MTR(mini-transcation), buffer pool 的 LFU list.所以对于不同的操作应该分离来看,尤其是读和写之间的分离,他们的日志行为,锁的控制,缓存做法均不同,要特别注意 

### 存储架构

mysql 的存储架构主要分为以下几个点

- [内存] change buffer / buffer pool 
- [磁盘] ibd (innodb data)
- [逻辑] tablespace 主要为一个表的命名空间,每个 space 都有一个 32 位的 int id

![](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-architecture.png)

<img src="https://images2018.cnblogs.com/blog/1062001/201808/1062001-20180806105300673-894487905.png" alt="70%" style="zoom:60%;" />

从上图我们看出其主要结构是由段页式的内存管理组成的结构,tablespace id是 32 bit 的设计.而 page 是基本的管理单位.page size 默认大小为 16k,其页号大小是 32 bit,我们可以算出 space 的空间大小 `2^32x16KB=64TB`

Code

- https://github.com/mysql/mysql-server/tree/3e90d07c3578e4da39dc1bce73559bbdf655c28c/storage/temptable/src
- https://github.com/mysql/mysql-server/tree/3e90d07c3578e4da39dc1bce73559bbdf655c28c/sql

### 线程

- Master Thread 主要负责把 buffer pool 中的数据异步刷新到磁盘,包括脏页刷新,change buffer 合并,(undo-log 页回收)
- IO Thread 负责 AIO 的回调,1.0 时使用 read,write,insert buffer,log IO Thread 四个线程
- Purge Thread 事务被提交后 undo-log 可能不在被需要,purge 来回收 undo-log 页面,1.1之后独立出 master thread
- Page Cleaner Thread 1.2 之后把脏页刷新独立出来进行单独刷新



### tablespace [逻辑]

space 是个主要的命名空间.又叫 tablespace.

![](https://img-blog.csdnimg.cn/2020032114540277.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTA2NDcwMzU=,size_16,color_FFFFFF,t_70#pic_center)

如上图,我们可以知道 table space是表的元数据空间用于存储一些表的共有信息,

#### system tablespace

其主要内容包括，8.0之后 doible write buffer 和 undo log 不存储在这里,默认情况下每张表会创建一个 ibdata1 文件,innodb_file_per_table 用于控制其开关,避免 idbdata 过大.

- 表数据页
- 表索引页
- 数据字典,表的元信息(结构索引列信息)组成的内部表
- MVCC控制数据
- Undo space （回滚段） 用于存放多个 undo log,如果自定义了 undo log space 即会失效
- Double write buffer 用于作为恢复
- Insert buffer

![](https://img-blog.csdnimg.cn/2020032115580176.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTA2NDcwMzU=,size_16,color_FFFFFF,t_70#pic_center)

- 第0页是 FSP_HDR 页，主要用于跟踪表空间，空闲链表、碎片页以及区等信息。其只能保存 256 个extent 信息,所以**这样的结构在表空间会有很多个**
- 第1页是 IBUF_BITMAP 页，保存Change Buffer的**位图**(在下会详述)。
- 第2页是 INODE 页，用于存储区和单独分配的碎片页信息，包括FULL、FREE、NOT_FULL 等页列表的基础结点信息，这些结点指向的是 FSP_HDR 页中的项，用于记录页的使用情况，它们之间关系如下图所示。
- 第3页开始是索引页 INDEX(B-tree node)，从 0xc000(每页16K) 开始，后面还有些分配的未使用的页。聚簇索引的root页
- 第4页是二级索引的root页

#### file-per-table space

顾名思义就是一个表一个文件,由 innodb_file_per_table 控制

![](https://img-blog.csdnimg.cn/20200321155727967.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTA2NDcwMzU=,size_16,color_FFFFFF,t_70#pic_center)

![](https://img-blog.csdn.net/20180819202403910?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)



#### 系统表

系统表的Page 7
这些系统表即数据字典SYS_TABLES,SYS_COLUMNS,SYS_INDEXES,SYS_FIELDS,SYS_TABLESPACES,SYS_TABLEFILES
Page 7保存了这些表的根页面页号
SYS_TABLES,SYS_COLUMNS,SYS_INDEXES,SYS_FIELDS

在 Information_schema 库里面就保存着这些信息

```sql
use Information_schema
select * from `COLUMNS` where TABLE_NAME='table_name'
select * from COLUMN where column like 'download%'
```

```shell
| TABLE_CATALOG | TABLE_SCHEMA | TABLE_NAME          | COLUMN_NAME    | ORDINAL_POSITION | COLUMN_DEFAULT | IS_NULLABLE | DATA_TYPE  | CHARACTE
R_MAXIMUM_LENGTH | CHARACTER_OCTET_LENGTH | NUMERIC_PRECISION | NUMERIC_SCALE | DATETIME_PRECISION | CHARACTER_SET_NAME | COLLATION_NAME     |
COLUMN_TYPE   | COLUMN_KEY | EXTRA | PRIVILEGES                      | COLUMN_COMMENT | GENERATION_EXPRESSION |
+---------------+--------------+---------------------+----------------+------------------+----------------+-------------+------------+---------
-----------------+------------------------+-------------------+---------------+--------------------+--------------------+--------------------+-
--------------+------------+-------+---------------------------------+----------------+-----------------------+
| def           | Plugin       | developer           | downloadCount  | 6                | 0              | NO          | int        | <null>
                 | <null>                 | 10                | 0             | <null>             | <null>             | <null>             |
int(11)       |            |       | select,insert,update,references |                |                       |
| def           | Plugin       | plugin              | downloadKey    | 25               | <null>         | YES         | varchar    | 255
                 | 1020                   | <null>            | <null>        | <null>             | utf8mb4            | utf8mb4_general_ci |
varchar(255)  |            |       | select,insert,update,references |                |                       |
```

| 表名                                  | 注释                                                         |
| ------------------------------------- | ------------------------------------------------------------ |
| SCHEMATA                              | 提供了当前mysql实例中所有数据库的信息。是show databases的结果取之此表 |
| TABLES                                | 提供了关于数据库中的表的信息（包括视图）。详细表述了某个表属于哪个schema、表类型、表引擎、创建时间等信息。是show tables from schemaname的结果取之此表 |
| COLUMNS                               | 提供了表中的列信息。详细表述了某张表的所有列以及每个列的信息。是show columns from schemaname.tablename的结果取之此表 |
| STATISTICS                            | 提供了关于表索引的信息。是show index from schemaname.tablename的结果取之此表 |
| USER_PRIVILEGES                       | 用户权限表:给出了关于全程权限的信息。该信息源自mysql.user授权表。是非标准表 |
| SCHEMA_PRIVILEGES                     | 方案权限表:给出了关于方案（数据库）权限的信息。该信息来自mysql.db授权表。是非标准表 |
| TABLE_PRIVILEGES                      | 表权限表:给出了关于表权限的信息。该信息源自mysql.tables_priv授权表。是非标准表 |
| COLUMN_PRIVILEGES                     | 列权限表:给出了关于列权限的信息。该信息源自mysql.columns_priv授权表。是非标准表 |
| CHARACTER_SETS                        | 字符集表:提供了mysql实例可用字符集的信息。是SHOW CHARACTER SET结果集取之此表 |
| COLLATIONS                            | 提供了关于各字符集的对照信息                                 |
| COLLATION_CHARACTER_SET_APPLICABILITY | 指明了可用于校对的字符集。这些列等效于SHOW COLLATION的前两个显示字段。 |
| TABLE_CONSTRAINTS                     | 描述了存在约束的表。以及表的约束类型                         |
| KEY_COLUMN_USAGE                      | 描述了具有约束的键列                                         |
| ROUTINES                              | 提供了关于存储子程序（存储程序和函数）的信息。此时，ROUTINES表不包含自定义函数（UDF）。名为“mysql.proc name”的列指明了对应于INFORMATION_SCHEMA.ROUTINES表的mysql.proc表列 |
| VIEWS                                 | 给出了关于数据库中的视图的信息。需要有show views权限，否则无法查看视图信息 |
| TRIGGERS                              | 提供了关于触发程序的信息。必须有super权限才能查看该表        |

可以看到在这个库里面还有 innodb 的信息

```sql
| INNODB_LOCKS                          |
| INNODB_TRX                            |
| INNODB_SYS_DATAFILES                  |
| INNODB_FT_CONFIG                      |
| INNODB_SYS_VIRTUAL                    |
| INNODB_CMP                            |
| RDS_EVENTS_THREADS_WAITS_CURRENT      |
| INNODB_CMP_RESET                      |
| INNODB_CMP_PER_INDEX                  |
| INNODB_CMPMEM_RESET                   |
| INNODB_FT_DELETED                     |
| INNODB_BUFFER_PAGE_LRU                |
| INNODB_LOCK_WAITS                     |
| INNODB_TEMP_TABLE_INFO                |
| INNODB_SYS_INDEXES                    |
| INNODB_SYS_TABLES                     |
| INNODB_SYS_FIELDS                     |
| INNODB_CMP_PER_INDEX_RESET            |
| INNODB_BUFFER_PAGE                    |
| INNODB_FT_DEFAULT_STOPWORD            |
| INNODB_FT_INDEX_TABLE                 |
| INNODB_FT_INDEX_CACHE                 |
| INNODB_SYS_TABLESPACES                |
| INNODB_METRICS                        |
| INNODB_SYS_FOREIGN_COLS               |
| INNODB_CMPMEM                         |
| INNODB_BUFFER_POOL_STATS              |
| INNODB_SYS_COLUMNS                    |
| INNODB_SYS_FOREIGN                    |
| INNODB_SYS_TABLESTATS                 |
```

我们可以从 TABLESPACE 中可以看到相对应的文件信息

```sql
| SPACE | NAME                  | FLAG | FILE_FORMAT | ROW_FORMAT | PAGE_SIZE | ZIP_PAGE_SIZE | SPACE_TYPE | FS_BLOCK_SIZE | FILE_SIZE | ALLOCATED_SIZE |
+-------+-----------------------+------+-------------+------------+-----------+---------------+------------+---------------+-----------+----------------+
| 3004  | mysql/plugin          | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 98304     | 98304
| 5893  | video/Plugins         | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 229376    | 233472
| 6291  | Plugin/plugin         | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 180224    | 184320
| 6295  | Plugin/report         | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 98304     | 98304
| 6310  | Plugin/pluginLang     | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 98304     | 98304
| 6320  | Plugin/mail           | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 147456    | 151552
| 6322  | Plugin/plugin_info    | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 114688    | 114688
| 6323  | Plugin/plugin_version | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 131072    | 135168
| 6328  | Plugin/developer      | 33   | Barracuda   | Dynamic    | 16384     | 0             | Single     | 4096          | 131072    | 131072
+-------+-----------------------+------+-------------+------------+-----------+---------------+------------+---------------+-----------+-------
```

另外一个比较重要的库是 sys



### Page / Block [磁盘]

参考

- https://github.com/mysql/mysql-server/blob/beb865a960b9a8a16cf999c323e46c5b0c67f21f/storage/ndb/src/kernel/blocks/diskpage.hpp 该文件定义了 page 存放的一些 header 信息
- mysql 技术内幕 innodb 存储引擎,姜承尧

Innodb 使用数据页来管理所有的结构,数据页是真实管理的数据结构,页可以在磁盘中随便存,他们只是用来维系**逻辑结构**.基本结构也分为很多类型,而下面的某些字段则兼容了所有类型的页的实现

- 数据页 (B-tree Node)
- undo 页
- 系统页
- 事务数据页

![](https://img-blog.csdnimg.cn/img_convert/0cb46c3f208a53b359beb7fd2eee3dba.webp?x-oss-process=image/format,png)

<img src="https://cdn.learnku.com/uploads/images/201909/09/16304/1ACHqlVSda.png" alt="3r0skn55wi" style="zoom:50%;" />

#### file header 文件头

参考

- https://blog.csdn.net/weixin_34364239/article/details/114329240

用于描述状态页的状态信息

- checksum 数据页的校验和
- offset 相对 tablespace 的 便宜
- FIL_PAGE_PREV / FIL_PAGE_NEXT 页面的头尾指针
- LSN(log sequence number) for last page modification: 该也最近一次修改对应redo log的LSN，用于保持redo log 幂等性，恢复时不处理LSN小于该值的redo log
- page type
- Flush LSN：ibdata文件第一个数据页才有意义，记录ibdata成功刷到磁盘的lsn
- tablespace id

#### page header 

<img src="https://img-blog.csdn.net/20180202152835200?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvamg5OTM2Mjc0NzE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast" alt="60" style="zoom:80%;" />

#### Infimum/Supremum

翻译为上确界和下确界,虚拟记录区域用于记录用户的记录范围,除此之外还记录了最大最小记录

#### User Record 用户记录区域

从上面的图中我们看到 用户记录区域无非就是一行一行的数据 row.用户插入的数据记录以链表的形式保存在这块区域，包括了所有正常数据记录和被标记删除的记录,每个记录有指向下一个记录的指针.

![](https://img-blog.csdnimg.cn/img_convert/7fd6c3d36f2f20ed85607320b47d3a3d.webp?x-oss-process=image/format,png)

由此也可以看出 mysql 是 row-oriented 的数据库,而部分数仓使用的事 column-oriented 数据库

##### 行记录

- Compact 压缩的数据结构
- Redundant 兼容之前的数据版本

行记录的头信息(compact)

- roll pointer (hideen)
- transaction id (hidden)
- deleted_flag 是否被删除
- min_rec_flag 是否是最小记录
- n_owned 该记录拥有的记录数,最后一个记录表示该组内总共有的记录数
- heap_no 索引堆中该记录的排序记录
- record_type 记录类型 000 表示不同 001表示b+树节点 010表示 infimum 011表示 spremum
- next_record 页中下一条记录的信息
- total

![](https://images2018.cnblogs.com/blog/919737/201804/919737-20180408164927757-867511928.png)

行溢出现象

> MySQL对一条记录占用的最大存储空间是有限制的，除了BLOB或者TEXT类型的列之外，**其他所有的列（不包括隐藏列和记录头信息）占用的字节长度加起来不能超过65535个字节**。可以不严谨的认为，**mysql一行记录占用的存储空间不能超过65535个字节**。

如果一行存储特别大,会截取前 786 个字节存入页中,其余的存储 BLOB Page 中.

每个页中至少要有两个行记录,如果只有一个记录就退化成链表了

![](https://images2018.cnblogs.com/blog/919737/201804/919737-20180408164025591-158405878.jpg)



#### Page Directory 页目录

该字段记录着二叉查找的相关信息

> 需要注意的是，B + 树索引并不能找到具体的一条记录，能找到的只是该记录的页，数据库把页加载到内存，然后通过页目录进行二叉查找，因为二叉查找时间复杂度非常低，又在内存中进行查找，所以这部分的查找时间可以忽略不计。

> **mysql规定对于最小记录所在的分组只能有 1 条记录，最大记录所在的分组拥有的记录条数只能在 1-8 条之间，剩下的分组中记录的条数范围只能在是 4-8 条之间**

在 page header 中有记录着这页有多少个条数,

![](https://img-blog.csdnimg.cn/img_convert/e1454abe9d15929e66bee3664610146a.png)

可以看到最开始的 slot 和最后的 slot 分别指向开始和结束的两条记录,有点类似跳表的结构,都是类似于二分查找,顺带一提B+树的索引结构如下

<img src="https://img.snaptube.app/image/em-video/177a232d554f199c26e4615b8c96d64a_1122_590.png" style="zoom:80%;" />

> 通过以上对非数据页节点的分析，可以发现数据页上存放的是完整的每行的记录，而在非数据页的索引页中，存放的仅仅是键值及指向数据页的偏移量，而不是一个完整的行记录。

#### File Trailer

从上图看就是 checksum 和 lsn

> The final part of a page, the fil trailer (or File Page Trailer), exists because InnoDB's architect worried about integrity. It's impossible for a page to be only **half-written**, or corrupted by crashes, because the log-recovery mechanism restores to a consistent state. But if something goes really wrong, then it's nice to have a checksum, and to have a value at the very end of the page which must be the same as a value at the very beginning of the page.



### buffer pool [内存]

buffer pool 的最主要的功能是加速度和加速写,其主要的数据结构就是上面介绍的 page 16k

- 读即是每次读取数据页面的时候有限访问已经存在的缓冲池,否则择取磁盘加载
- 写是修改一个页面的时候,直接修改缓冲区,然后记录下相关的 redo-log 等待后台线程刷盘

 因为内存的使用原因,所以 buffer pool 设置了 LRU 算法进行淘汰提高缓存的命中率.页面在进行访问的时候.会先去buffer pool中找,根据 page_no 和 space_id 找到对应的 page_hash 进行快速校验,如果没有则表示要从磁盘读取快速失效.加入内存时需要访问空闲链表去找空闲块,如果没有 free 的内存则需要想办法生成空闲块

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/7/3/17313a29a971c3fd~tplv-t2oaga2asx-watermark.awebp)

- instance,每个 instance 有自己的信号量, 锁，可以并发读写
  - chunk 默认大小 128MB,保存数据页和数据页的控制块,如上绿色和蓝色,这些控制信息包括该页所属的表空间编号,页号,页在 Buffer Pool 中的地址等
  - 三个链表
    - FREE list 保存可用的(包括满空间和不满空间的)缓存页面,一般指向 free 类型的 page 
    - LRU list LRU 维护最近使用的页的链表,数据不够用了就使用从LRU链表中淘汰,存储 clean dirty 由 page cleaner 处理
    - LFU list 存储 dirty 的 page, 使用 oldest_modification 排序,刷新链表尾部的页面,存储 dirty

#### LRU 页面置换算法

其实就是页面读取的算法

![](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-buffer-pool-list.png)

- 新的数据是从 midpoint 开始插入
- 尾部是很少使用的 page,需要被淘汰
- 当一个页面在列表被读取的时候会移动到头部

**innodb_old_blocks_pct**: 老区域占比，0-100，默认 37 即 3/8
**innodb_old_blocks_time**: 首次加入链表后需要经过多长时间后才有资格加入 new sublist，毫秒值，默认是 0

当一次读取大量数据进入到页面的时候,old sublist就进行了内部的环形缓冲他就不会让一部分热点页面失效,进而要刷新整个 buffer pool.

#### 脏页刷新

[参考](https://zhuanlan.zhihu.com/p/65811829)

即时刷新,free list 为空时怎么办?

1. LRU 列表扫描可替换的页面，第一次最多扫描100 个，第二次会扫描整个列表
2. 仍然没有找到可以替换的页，就进行单页刷新，即刷新一个脏页进入空闲列表(为了尽快获取空闲页面，所以只刷新一个)
3. 有可能空闲块被其他线程抢占，需重复执行上面的流程

> 如果需要刷新脏页来产生空闲页面或者需要扫描整个LRU列表来产生空闲页面的时候，查找空闲内存块的时间就会延长，这个是一个bad case，是我们希望尽量避免的。

后台刷新

当脏页的占有率达到了innodb_max_dirty_pages_pct (默认为75) 的设定值的时候，InnoDB就会强制刷新buffer pool pages。另外当free列表小于innodb_lru_scan_depth值时也会触发刷新机制，innodb_lru_scan_depth控制LRU列表中可用页的数量，该值默认为1024。

刷新的具体过程

> 1. 调用page_cleaner_flush_pages_recommendation建议函数，对每个缓冲池实例生成脏页刷新数量的建议。在执行刷新之前，会用建议函数生成每个buffer pool需要刷新多少个脏页的建议。
> 2. 生成刷新建议之后，通过设置事件的方式，向刷新线程（Page Cleaner线程）发出刷新请求。后台刷新线程在收到请求刷新的事件后，会执行pc_flush_slot函数对某个缓存池进行刷新，刷新的过程首先是对lru列表进行刷新，执行的函数为buf_flush_LRU_list，完成LRU列表的刷新之后，就会根据建议函数生成的建议对脏页列表进行刷新，执行的函数为buf_flush_do_batch。
> 3. 后台刷新的协调线程会作为刷新调度总负责人的角色，它会确保每个buffer pool都已经开始执行刷新。如果哪个buffer pool的刷新请求还没有被处理，则由刷新协调线程亲自刷新，且直到所有的buffer pool instance都已开始/进行了刷新，才退出这个while循环。
> 4. 当所有的buffer pool instance的刷新请求都已经开始处理之后，协调函数（或协调线程）就等待所有buffer pool instance的刷新的完成，等待函数为pc_wait_finished。如果这次刷新的总耗时超过4000ms，下次循环之前，会在数据库的错误日志记录相关的超时信息。它期望每秒钟对buffer pool进行一次刷新调度。如果相邻两次刷新调度的间隔超过4000ms ，也就是4秒钟，MySQL的错误日志中会记录相关信息，意思就是“本来预计1000ms的循环花费了超过4000ms的时间。

评估函数会使用下面两个参数估算本机I/O的能力,这两个值需要自己设置

- innodb_io_capacity
- innodb_io_capacity_max

除此之外还会计算脏页的平均刷新速度 `平均值计算规则就是新平均速度=(当前的平均速度+最近这段期间平均速度)/2。`

刷新的 checkpoint

- Sharp Checkpoint
  - 数据库关闭时将所有脏页刷新到磁盘
- Fuzzy Checkpoint
  - Master 线程以没每秒或每10秒的速度刷新一定比率脏页回磁盘
  - 当脏页的占有率达到了innodb_max_dirty_pages_pct的设定值的时候，InnoDB就会强制刷新buffer pool pages。另外当free列表小于innodb_lru_scan_depth值时也会触发刷新机制，innodb_lru_scan_depth控制LRU列表中可用页的数量，该值默认为1024。
  - 当前checkpoint lsn 落后redo log lsn 超过redo log 文件大小 75%、90%时，分别执行 sync/async flush，使得刷新后的脏页小于总大小的75%

从这里也可以也可以看出,刷新脏页落盘,可以定时调度去完成一部分,另一部分如 buffer pool 会根据阈值触发,log buffer会根据事务提交而进行落盘.

#### 预读

```shell
show engine innodb status
```

<img src="https://images2018.cnblogs.com/blog/1062001/201808/1062001-20180806105300673-894487905.png" alt="70%" style="zoom:60%;" />

预读是一种优化读取的方法 extend 的设计就是专门给预读准备的.InnoDB 在 I/O 优化上,会异步地在缓冲池中读取这些页面,预读分为两种

- 线性预读
- 随机预读

根据操作系统的I/O读取到相应的数据.读取的时候如果是磁盘不同的数据可能会分多次读取,而请求队列会判断后面几个数据读请求,根据自身系统I/O带宽处理量进行预读,进行读请求的合并处理.

![](https://images2017.cnblogs.com/blog/1113510/201708/1113510-20170819191007209-586174344.png)

线性预读把一整个 extent 加入到内存中.而随机预读当前 extent 中剩余的 page 读到 buffer pool 中

##### 线性预读

**innodb_read_ahead_threshold**,控制触发 innodb 执行预读操作的时间.如果一个 extent 中的被顺序读取的 page 超过或者等于该参数变量时,Innodb 会异步的把下一个 extent 读到 buffer pool.其值可以设置为 0-64,表示读取的阈值(一个 extent 中只有64页)

> 例如，如果将值设置为48，则InnoDB只有在顺序访问当前extent中的48个pages时才触发线性预读请求，将下一个extent读到内存中。如果值为8，InnoDB触发异步预读，即使程序段中只有8页被顺序访问。

在没有该变量的时候由 innodb 决定是否把下一个 extent 放入到 buffer pool 中.

##### 随机预读

随机预读方式表示当同一个 extent 中一些 page 在 buffer poo 发现时,Innodb 会把 extent 中剩余的 page 一并读到 buffer pool 中.5.5 之后废弃了这种方式默认是 off

```shell
show variables like 'innodb_random_read_ahead';
```

评价预读机制

```shell
mysql> show global status like '%read_ahead%';
+---------------------------------------+-------+
| Variable_name                         | Value |
+---------------------------------------+-------+
| Innodb_buffer_pool_read_ahead_rnd     | 0     |
| Innodb_buffer_pool_read_ahead         | 2303  | # 通过后台线程读入 innodb buffer pool 中的数据页数
| Innodb_buffer_pool_read_ahead_evicted | 0     | # 无效查询的 pages
+---------------------------------------+-------+
3 rows in set (0.01 sec)
```

#### 预热

Buffer Pool 预热.Buffer Pool 在一开始的时候并没有什么数据,所以在 mysql 关闭前,会把 Buffer Pool 的页面信息保存到磁盘,等 mysql 在启动时根据之前保存的信息把磁盘中的数据加载到 buffer pool 中.其主要分为两种操作

- buffer pool dump
- buffer pool load

每个数据页的定位可以通过 space_id 和 page_no 唯一定位到,然后写到外部文件中,load 的时候会把所有数据读入到内存,然后使用归并排序对数据进行排序,以64个数据页(1个extent)为单位进行I/O合并,然后发起一次真正的读取操作.



### change buffer [内存]

![](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-architecture.png)

> The change buffer is a special data structure that **caches changes to secondary index pages** when those pages are **not in the buffer pool**. The buffered changes, which may result from INSERT, UPDATE, or DELETE operations (DML), are merged later when the pages are loaded into the buffer pool by other read operations.
>
> 简而言之：Change buffer的主要目的是将对二级索引的数据操作缓存下来，以此减少二级索引的随机IO，并达到操作合并的效果。

可以看到其实对二级索引页的缓冲池.所谓的二级索引就是非聚集索引或者辅助索引,在 innodb 中指的是除了主键索引以外的索引.值得注意的是,普通索引的更新会用到 change buffer,唯一索引不会用到 change buffer. change buffer 在读多写少的时候能发挥出很大的作用,其主要目的就是为了减少磁盘次数

- innodb_change_buffer_max_size 指定占用 buffer pool 的百分比

#### change buffer 的更改过程

> **可以看到 insert 一条语句执行的时候, 如果数据页在内存中,那么就按照内存的修改就行.如果数据页不在内存中,那么更新的操作就会被缓存到 change buffer 中,当下次访问数据页时,就会应用 change buffer 上的操作,这种方式只要进行一次磁盘访问,没有数据一致性的问题.避免更新的时候读入需要更新的页,因为更新之后可能不会被读到,不用浪费磁盘空间.**
>
> ```mermaid
> sequenceDiagram
> participant U as User
> participant B as Buffer Pool
> participant C as Change Buffer
> participant D as Disk
> U ->> B: DML
> alt 更改数据在内存
> B -->> D: 写入磁盘
> else
> B ->> C: 保存在Buffer
> end
> U ->> B: SELECT 请求
> B ->> D: 从磁盘读取
> D ->> B: 返回数据
> B -> C: Merge
> ```

上面的过程称之为 merge.merge 操作在下面的场景会触发,一次性 merge 的操作越多(访问磁盘I/O少)收益越大,需要注意写后读的场景使用 change buffer 会比较吃力.

- 数据页访问的时候
- 后台线程每秒都会 merge
- 数据库正常关闭的情况下

change buffer 的设计师为了应对读多写少的一种设计

**为什么唯一索引不能使用 change buffer?** 

因为唯一索引需要判断**唯一性**,那就会把数据加载到内存进行判断.(不能直接插入),所以还不如直接改这个被加入内存的页.

**redo log & change buffer**

![](https://img.snaptube.app/image/em-video/1eabb2397aa201eae151957c9c30ebf2_400_300.png)

更新完change buffer后会在 redo log 记录下 change buffer的修改,事务计算完成了,后续binlog 落盘,redo log commit.在磁盘上索引一般是存在于表空间的idb文件中.

> 当有许多受影响的行和许多要更新的二级索引时，Change Buffer合并可能需要几个小时。在此期间，磁盘I / O会增加，这会导致磁盘绑定查询显着减慢。在提交事务之后，甚至在服务器关闭并重新启动之后，更改缓冲区合并也可能继续发生

#### change buffer btree

[参考](https://blog.csdn.net/bohu83/article/details/81837872)

ibuf (insert buffer) 简单理解即可看成 change buffer, insert buffer 是之前版本的叫法,我们所谓的索引就是颗B+树也是由于这个区域

<img src="https://img-blog.csdnimg.cn/20190422232450491.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM2NjUyNjE5,size_16,color_FFFFFF,t_70" alt="50" style="zoom:80%;" />

这个 counter 的初始值是 0xffff

- 用户设置了选项innodb_change_buffering；（即ibuf_use != IBUF_USE_NONE）
- 只有叶子节点才会去考虑是否使用ibuf；
- 对于聚集索引，不可以缓存操作；
- 对于唯一二级索引(unique key)，由于索引记录具有唯一性，因此无法缓存插入操作，但可以缓存删除操作；
- 表上没有flush 操作，例如执行flush table for export时，不允许对表进行 ibuf 缓存 （通过dict_table_t::quiesce 进行标识）

#### Change Buffer Bitmap

该bitmap存储于 tablespace 中,**用于追踪每个 page 的空闲范围**.其大小为 16k,即其能追踪 16kb/4=4kb page

>  当文件页在buffer pool中时，就直接操作文件页，而不会去考虑ibuf

| 名称                 | 大小（bit） | 说明                                                         |
| -------------------- | ----------- | ------------------------------------------------------------ |
| IBUF_BITMAP_FREE     | 2           | 该辅助索引页可用空间数量: 0表示无可用空间 1表示可用空间大于1/32 2表示大于1/16 3表示大于1/8 |
| IBUF_BITMAP_BUFFERED | 1           | 1表示该页有记录被保存在change buffer中                       |
| IBUF_BITMAP_IBUF     | 1           | 1表示该页为change buffer B+树的索引页                        |

- 优点
  - 若相关数据页不在磁盘，会先保存的Buffer，减少磁盘访问，能够保证数据一致性
  - 数据页读到内存需要占用空间，提供空间使用率
- merge 时机
  - 访问数据页
  - 后台线程每秒进行一次
  - 数据库正常关闭
  - 检测到插入记录后所用空间小于1/32
- 使用场景
  - 写多读少
  - 索引大部分都是非唯一索引
  - 数据写入后会立马读取，建议不要使用
- 更新完 change buffer，会在 redo log 进行相应记录

change buffer 会对三种类型的操作进行缓存,`INSERT,DELETE-MARK,DELETE操作,前两种对应用户线程操作，第三种则由purge操作触发`.

```c
/** Allowed values of innodb_change_buffering */
static const char* innobase_change_buffering_values[IBUF_USE_COUNT] = {
        "none",         /* IBUF_USE_NONE */
        "inserts",      /* IBUF_USE_INSERT */
        "deletes",      /* IBUF_USE_DELETE_MARK */
        "changes",      /* IBUF_USE_INSERT_DELETE_MARK */
        "purges",       /* IBUF_USE_DELETE */
        "all"           /* IBUF_USE_ALL */
};
```

 innodb_change_buffering默认值为all,表示缓存所有操作.注意由于在二级索引上的更新操作总是先delete-mark,再insert新记录,因此其ibuf实际有两条记录IBUF_OP_DELETE_MARK+IBUF_OP_INSERT.

![](https://img-blog.csdn.net/20180819211623886?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![](https://img-blog.csdn.net/20180819212610304?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)





### Adaptive Hash Index

(AHI)Adaptive Hash Index 自适应 hash 索引

> The adaptive hash index enables InnoDB to perform more like an in-memory database on systems with appropriate combinations of workload and sufficient memory for the buffer pool without sacrificing transactional features or reliability.
>
> 自适应哈希索引使 InnoDB 能够在具有适当的工作负载组合和缓冲池足够内存的系统上执行更像内存数据库,而不会牺牲事务特性或可靠性.

AHI 为了解决的问题是

> - 随着 MySQL 单表数据量增大，（尽管 B+ 树算法极好地控制了树的层数）索引 B+ 树的层数会逐渐增多；
> - 随着索引树层数增多，检索某一个数据页需要沿着 B+ 树从上往下逐层定位，时间成本就会上升；
> - 为解决检索成本问题，MySQL 就想到使用某一种缓存结构：根据某个检索条件，直接查询到对应的数据页，跳过逐层定位的步骤。这种缓存结构就是 AHI。

其实就是作为二级索引的缓存.保存`条件->数据页`的映射.作为内存的缓存,其设计的核心的就是不能太大(二级缓存).所谓的自适应是其大小会根据实际情况发生变化.

![](https://pic1.zhimg.com/80/v2-c5306994ed483755bdd37184f0890a44_720w.jpg)

简单来说就是得使用到两列以上的索引且使用的次数足够多才会建立 AHI 索引.建立 AHI 对应三个条件

- 某个索引树要被使用足够多次
- 该索引树上的某个检索条件要被经常使用
- 该索引树上的某个数据页要被经常使用

建立起 AHI 后使用就如同传统的 map 结构

<img src="https://pic1.zhimg.com/80/v2-d0728f73a388498d557465bd59b481a0_1440w.jpg" alt="50" style="zoom:50%;" />

hash info 中三个字段

- 检索条件与索引匹配的列数
- 第一个不匹配的列中，两者匹配的字节数
- 匹配的方向是否从左往右进行

#### 使用时注意事项

1. 只支持等值查询和 IN
2. 数据保存在内存中，会占用 Buffer Pool 资源
3. 开启后无法人为干预



### log buffer [内存]

![](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-architecture.png)

> The log buffer is the memory area that holds data to be written to the log files on disk. Log buffer size is defined by the innodb_log_buffer_size variable. The default size is 16MB.

可以通过 **innodb_log_buffer_size** 来控制日志缓冲区的大小.

说起日志缓存可能就不得不提,关于日志的数据结构我们在此略过

- redo log 预写日志
- undo log 重做日志

前两者和事务又有很大关系,较大的事务缓冲区可以运行大型事务.如果涉及到更新插入删除多行的事务则增加缓冲区的大小

- innodb_flush_log_at_trx_commit 控制如何把日志缓冲区的内容写入并刷新到磁盘
  - 0 每秒进行一次缓存写入和更新磁盘的操作，未完成刷盘的数据可能丢失
  - 1 默认值。每次事务提交时会写入buffer并更新到磁盘
  - 2 每次事务提交时会写入system cache，每秒进行一次刷盘操作
- innodb_flush_log_at_timeout 控制日志刷新的频率
- 只要缓冲区已满就会刷新到磁盘



### buffer pool 的角度看待 sql

从上面我们知道了这些语句的执行过程,在此总结

#### select 

根据索引或者扫描到对应的起始数据页,把对应的数据页加入buffer pool,根据 page directory 进行二分查找,定位到需要的目录,然后再根据指针线性查找对应的记录或者是 page

#### delete
1. 如果是最后一条记录，直接初始化为空页
2. 不是的话，首先记录 redo log
3. 重置PAGE_LAST_INSERT和递增block的modify clock。后者主要是为了让乐观的查询失效。
4. 找到记录的前驱和后驱记录，前驱指针指向后驱
5. 如果有目录指向这条记录，将该目录指向这条记录的前驱，见效own值
6. 把记录放到 Page_Free 链表头部，增加Page_Garbage 大小，减小Page_N_Recs的数量
7. 重新均衡目录，可能需要删除某些目录。具体算法也比较简单，首先判断是否可以从周围的目录中挪一条记录过来，如果可以直接调整一下前后目录的指针即可。这种简单的调整要求被挪出记录的目录own的记录数量足够多，如果也没有足够的记录，就需要删除其中一个目录，然后把后面的目录都向前平移

#### insert


1. 从记录中获取记录长度的元数据
2. 尝试从 Page_Free 链表获取空间，只会比较表头的一个节点
3. 匹配不上就从*PAGE_HEAP_TOP*分配，如果仍然空间不足，就返回空。分配成功，则递增*PAGE_N_HEAP*
4. 拷贝记录到指定空间，并修改前驱、后驱记录的next指针
5. 若有目录超过最大值，则调整数据目录，算法比较简单，就是找到中间节点，然后用这个中间节点重新构建一个新的目录，为了给这个新的目录腾空间，需要把后续的所有目录都平移
6. 写入redo log日志，持久化



## 日志系统

[参考](https://blog.csdn.net/bohu83/article/details/81481184),[参考](https://blog.csdn.net/bohu83/article/details/81568341),[参考](http://mysql.taobao.org/monthly/2015/05/01/)

主要分为以下几个日志

- redo-log(重做日志)
- undo-log
- binlog(归档日志,这个日志在server层的)

<img src="https://www.linuxidc.com/upload/2018_11/181121105137362.png" alt="50" style="zoom:33%;" />

Mysql 中 redolog 和  undolog 这两个日志是相对比较重要的,两者直接关系 mysql 事务的实现,所以可以简单认为所有搜索相关的都不涉及 redo-log 和 undolog 两个日志.

- redo-log 保证其持久性,用于数据库数据异常回复和重启时数据页的同步回复
- undo-log 保证原子性和 MVCC

和大多数关系型数据库一样,Innodb 总是保证日志先行(WAL)(log write ahead),即日志的落盘要优先于数据的持久化.

LSN(log sequence number) 用于记录日志的序列号,是一个不断递增的主键,**它既用于表示修改脏页时的日志序号，也用于记录checkpoint**,通过LSN可以定位其在 redo-log 中的具体位置.LSN的含义是储存引擎向重做日志系统写入的日志量（字节数）这个日志量包括写入的日志字节 + LOG_BLOCK_HDR_SIZE + LOG_BLOCK_TRL_SIZE.

flush list 上的 page 按照修改这些 page 的LSN号进行排序,我们看到了这里脏页的刷新是从拥有最小LSN的page开始刷新到磁盘的,延迟脏页的刷新可以应用多次合并的结果避免多次写入造成性能问题.



### redo-log(内存/磁盘上)

redo-log 用于记录对**物理文件的数据变更**,按照 buffer pool 的理解 redo-log 是所有对页有变更的操作都会记录到该日志中.

- 内存中 redo-log-buffer 缓冲区
- 磁盘上 redo log file 持久化在磁盘

redo-log是存储引引擎层的日志,用于记录**事务**操作的变化,记录的是数据修改后的值,无论事务是否提交都会被记录下来.如果数据库宕机,redo-log就可以恢复.每条insert语句都会**被记录下来,然后更新内存**,这是条完整的语句执行.redo-log实在空闲时或者是按照设定的更新策略把redo-log的内容更新到磁盘,redo-log的缓冲区大小是固定的写完了就得从头写.从头写的时候数据库就会把日志持久化到磁盘上.一般触发持久化的条件为 512MB 即块的大小,由 `innodb_log_file_size` 控制

redo log是建立在在mini transaction基础上。数据库在执行事务时，通过minitransaction产生redo log来保证事务的持久性

在 5.6 的时候 redo-log 可以以多份文件的形式存在,在 5.7移除了该特性.Redo log 以顺序的方式写入文件文件,写满时则回溯到第一个文件,进行覆盖写,即环形缓冲区.

![](https://img-blog.csdn.net/20180807180732199?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

Redo log可能产生的速度非常快，导致频繁的刷脏操作，进而导致性能下降，通常在未做checkpoint的日志超过文件总大小的76%之后，InnoDB 认为这可能是个不安全的点，会强制的preflush脏页

#### log block

即日志的数据结构,日志的写入以 512 byte 为单位,以字节对齐的形式写入磁盘

![](https://img-blog.csdn.net/20180807183324473?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

> Block no 的最高位是描述block是否flush磁盘的标识位.通过lsn可以blockno,具体的计算过程是lsn是多少个512的整数倍，也就是no = lsn / 512 + 1;为什么要加1呢，因为所处no的块算成clac_lsn一定会小于传入的lsn.所以要+1。其实就是block的数组索引值
>
> LOG_BLOCK_HDR_DATA_LEN   2个字节，表示当前页面存储日志的长度，通常是满的0X200，因为日志在相连的块上市连续存储的，中间不会有空闲空间，如果不满表示日志已经扫描完成（crash recovery的工作 ）
>
> LOG_BLOCK_FIRST_REC_GROUP 占用2个字节，表示log block中第一个日志所在的偏移量。如果该值的大小和LOG_BLOCK_HDR_DATA_LEN相同，则表示当前log block不包含新的日志

#### checkpoint

当日志缓冲区写入的日志LSN距离上一次生成检查点的LSN达到一定差距的时候，就会开始创建检查点，创建检查点首先会将**内存中的表的脏数据**写入到硬盘,让后再将**redo log buffer中小于本次检查点的LSN的日志**也写入硬盘

所以我们其实可以看到 redo-log 并不是无限大的,所以需要 buffer pool 中的内存脏页和一个有限大小的日志,这及时检查点技术的使用场景.让日志失效(当page成功写回磁盘的时候它的redo-log就失效了),同时尽量减少对磁盘的I/O操作.

#### MTR

mini-transaction(mtr),是逻辑事务实现的基础,只要涉及到物理文件的修改,该事务就会使用

![](https://img-blog.csdn.net/20180808124552157?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

```c
/** Mini-transaction handle and buffer */
struct mtr_t {
 
  /** State variables of the mtr */
  struct Impl {

    /** memo stack for locks etc. */
    mtr_buf_t	m_memo;

    /** mini-transaction log */
    mtr_buf_t	m_log;

    /** true if mtr has made at least one buffer pool page dirty */
    bool		m_made_dirty;

    /** true if inside ibuf changes */
    bool		m_inside_ibuf;

    /** true if the mini-transaction modified buffer pool pages */
    bool		m_modifications;

    /** Count of how many page initial log records have been
		written to the mtr log */
    ib_uint32_t	m_n_log_recs;

    /** specifies which operations should be logged; default
		value MTR_LOG_ALL */
    mtr_log_t	m_log_mode;
    
    #ifdef UNIV_DEBUG
    /** Persistent user tablespace associated with the
		mini-transaction, or 0 (TRX_SYS_SPACE) if none yet */
    ulint		m_user_space_id;
    #endif /* UNIV_DEBUG */
    /** User tablespace that is being modified by the
		mini-transaction */
    fil_space_t*	m_user_space;
    /** Undo tablespace that is being modified by the
		mini-transaction */
    fil_space_t*	m_undo_space;
    /** System tablespace if it is being modified by the
		mini-transaction */
    fil_space_t*	m_sys_space;

    /** State of the transaction */
    mtr_state_t	m_state; // 包含 MTR_STATE_INIT、MTR_STATE_COMMITTING、 MTR_STATE_COMMITTED

    /** Flush Observer */
    FlushObserver*	m_flush_observer;

    #ifdef UNIV_DEBUG
    /** For checking corruption. */
    ulint		m_magic_n;
    #endif /* UNIV_DEBUG */

    /** Owning mini-transaction */
    mtr_t*		m_mtr;
  };
}
```

其中有 mtr_log_mode

> MTR_LOG_ALL：默认模式，记录所有会修改磁盘数据的操作；
>
> MTR_LOG_NONE：不记录redo，脏页也不放到flush list上；
>
> MTR_LOG_NO_REDO：不记录redo，但脏页放到flush list上；
>
> MTR_LOG_SHORT_INSERTS：插入记录操作REDO，在将记录从一个page拷贝到另外一个新建的page时用到，此时忽略写索引信息到redo log中。

**这里提前插一嘴,在 mysql 中 s 锁和 x 锁分别代表了共享锁和排他锁.**

系统在载入页面的时候,需要开启一个 mtr,这个 mtr 需要知道开启的时候该页面是用来修改的还是用来读取的,会给该页面加上相应的 x 锁或者 s 锁.(也可以指定不加锁).获取到页面的访问权之后对页面进行操作,如果开启了日志记录则会记录日志.最后提交事务,物理事务的提交主要是将所有这个物理事务产生的日志写入到innodb的日志系统的日志缓冲区中,然后等待srv_master_thread线程定时将日志系统的日志缓冲区中的日志数据刷到日志文件中.如果一个物理事务的日志是不完整的,则它对应的所有日志都不会重做.在提交的时候会在日志后面写一些特殊日志代表事务结束.

现在都已经知道这个数组中存储的是这个物理事务所有访问过的页面，并且都已经上了锁，那么在它提交时，如果发现这些页面中有已经被修改过的，则这些页面就成为了脏页，这些脏页需要被加入到innodb的buffer缓冲区中的更新链表中

#### redolog刷盘

之前我们说过了,日志刷盘的时机可能是提交事务或者是定时调度,我们细看下,有几种场景可能会触发redo log写文件：

1. Redo log buffer空间不足时
2. 事务提交
3. 后台线程
4. 做checkpoint
5. 实例shutdown时
6. binlog切换时

![](https://img-blog.csdn.net/20180808132716515?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

我们所熟悉的参数innodb_flush_log_at_trx_commit 作用于事务提交时，这也是最常见的场景：

- 当设置该值为1时，每次事务提交都要做一次fsync，这是最安全的配置，即使宕机也不会丢失事务；(默认)
- 当设置为2时，则在事务提交时只做write操作，只保证写到系统的page cache，因此实例crash不会丢失事务，但宕机则可能丢失事务；
- 当设置为0时，事务提交不会触发redo写操作，而是留给后台线程每秒一次的刷盘操作，因此实例crash将最多丢失1秒钟内的事务。

这个值可以在高峰期设置事务的提交为2,保证写入到操作系统的缓存,用来提高性能.写入过程可以简化成下图

<img src="https://img-blog.csdn.net/20180808133049184?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70" alt="7" style="zoom:80%;" />

看上面主要有三个指针控制

- flushed_to_disk_lsn
- write_lsn
- buffer_free

当 flushed_to_disk_lsn 和当前 lsn 的值相等时,则证明所有的 log 已经被全部刷到磁盘上了

一个很形象的图,可以看到 log buffer 也使用了 page 字节对齐的设计,其所谓的指针指的是内部的逻辑连续而不是页之间地址的连续.

<img src="https://img-blog.csdnimg.cn/20210220142446368.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21hc2hhb2thbmcxMzE0,size_16,color_FFFFFF,t_70" alt="5" style="zoom:80%;" />

除了 redo-log 的刷盘之外,修改后的页面会**根据 LSN 放到 flush list 的头部**,即可以看到页面的 LSN 可以确定其作为脏页被修改的顺序,LSN 越小就越容易被淘汰(刷盘).

redo-log 不是全部记录的,在文件中也可以被覆盖,可以被覆盖的前提条件是 checkpoint,即**脏页已经被完全刷新到磁盘中**.脏页刷新的时候除了删除对应的 lfu list 上的 page 之外,还会删除对应的控制块,这个时候就可以覆盖对应的 redo-log,checkponit_lsn 该变量指示了哪些 redo-log 可以被覆盖.

<img src="https://img-blog.csdnimg.cn/20210221101333116.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21hc2hhb2thbmcxMzE0,size_16,color_FFFFFF,t_70" alt="50" style="zoom:80%;" />

#### 恢复

redo-log 最主要的作用就是故障恢复,前文有提到,是通过checkpoint然后通过 redo-log 进行重放来恢复数据.确定恢复的起点就是checkpoint对应的lsn,恢复的终点 LOG_BLOCK_HDR_DATA_LEN 可以确定恢复到哪一个 block.

![](https://img-blog.csdnimg.cn/20210221103644841.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21hc2hhb2thbmcxMzE0,size_16,color_FFFFFF,t_70)

利用 hashtable 稍微进行加速,跳过已经刷新到磁盘里面的页面,需要注意的是,对于单一页面,其恢复的顺序需要用 redo-log 进行确定,如下,不然会发生错误

![](https://img-blog.csdnimg.cn/20210221103946617.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21hc2hhb2thbmcxMzE0,size_16,color_FFFFFF,t_70)

page 中有个字段 FIL_PAGE_LSN 用于记录日志最近一次刷盘时候的LSN,这个时候就可以确定有哪些 page 在崩溃的时候被刷新进磁盘



### undo-log回滚日志

[undo tablespace truncate参考](http://mysql.taobao.org/monthly/2015/05/01/),[参考](http://mysql.taobao.org/monthly/2015/04/01/)

undo-log是innodb事务的重要的实现基础.**undo-log 的研究必须建立在对事物和MVCC版本控制有一定的理解上,如果读者不了解事物请回过头来读本章节的信息**。undo-log 又名回滚日志,用来保存多版本信息.

undo-log又叫回滚日志.提供向前滚的操作.同时其提供MVCC版本的读.undo-log是在表的记录发生变更的时候会记录的日志,在5.6之后也开始使用独立的 undo-log 空间而不是记录到 ibdata 的物理文件中.**insert**是不用维护undo-log的,因为 undo-log 维护的是 **数据变更的版本信息**,而 insert 没有之前的版本所以不需要维护 undo-log

- redo-log通常是物理操作,记录的是数据页的物理修改.用它来恢复到提交后的物理数据页
- undo用来回滚到某个版本,且undo-log是逻辑日志.

redo-log用来保证事物的持久性,防止有些脏页未写入磁盘,再重启mysql的时候,根据redo-log进行重做,从而达到实物持久性.undo-log保存了事务发生之前的版本用于回滚,同时提供MVCC,undo-log对于每一个insert存一个delete,update执行相反的update，当事务提交的时候，InnoDB 不会立即删除 undo log，因为后续还可能会用到 undo log.但 redo-log 可以通过 LSN 和 page 刷新确定 redo-log 是或否会被覆盖掉.undo-log 的删除时机是在事务提交完成之后.undo-log 在 5.6 存储在 tablespace 中(即idbdata中),在 5.7 之后也拥有了自己独立的空间。undo-log 维护的对象其实是 update.delete语句,因为 insert 语句对当前事务可见在 innodb 中没有历史版本. update 和 delete 在 undo-log 的类型上都是属于 update_undo. undo-log 实际存放的事修改了哪些字段的值. redo-log 更像记录执行了何种语句

**需要注意的是 undo-log 不存在单独的文件,在 innodb 中以回滚段的形式存在.**我们看事务中两个重要机制

#### 活跃事物链表

事务链表`trx_sys->rseg_array`中保存的都是未提交的事务,其大小为128,一旦事务被提交则会从事务链表中去除,RR 下在每个事务开启的时候会维护这么一个链表,RC 状态下每个语句开始的时候会维护这么一个链表.事务提交后需要purge的回滚段会被放到回滚队列上.

#### readview

其是一个结构体 read_view_struct

```c
/** The read should not see any transaction with trx id >= this
value. In other words, this is the "high water mark". */
trx_id_t    m_low_limit_id; // 前者表示事务id大于此值的行记录都不可见
/** The read should see all trx ids which are strictly
smaller (<) than this value.  In other words, this is the
low water mark". */
trx_id_t    m_up_limit_id; // 后者表示事务id小于此值的行记录都可见
/** trx id of creating transaction, set to TRX_ID_MAX for free
views. */
trx_id_t    m_creator_trx_id;
```

![](https://img-blog.csdn.net/20180706150245253?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2JvaHU4Mw==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

- low_limit_id 前者表示事务id大于此值的行记录都不可见
- up_limit_id  后者表示事务id小于此值的行记录都可见.
- (up_trx_id, low_trx_id) 中的事务id需要根据隔离级别来定是否看到
  - read-uncommit 是中间间都可见
  - read-commit 是提交后的事务课件
  - read-repeatable 会根据写某一行的记录去更新 read-view

从这个角度看,所有的数据 innodb 都会存一分,只是如何去读写是由不同字段去控制的.数据和控制变成了数据结构.

#### 文件结构

回滚段一般存储在第6个页面,用于存储事务相关信息的,主要包括

- TRX_SYS 系统保留字段
- TRX_SYS_TRX_ID_STORE 持久化的最大的事务ID
- TRX_SYS_FSEG_HEADER 管理事务系统的段所在的位置
- TRX_SYS_RSEGS 128 个混辊锻的位置

innodb 的回滚段可以在 ibdata 中,也可以在独立的 undo 表空间中,或者在 ibtmp临时表空间中.

![](http://mysql.taobao.org/monthly/pic/2015-04-01/01.png)

回滚段的实质就是 undo-log slot 的组织形式.每个 slot 则可以对应一个 undo-log 对象,默认是`TRX_RSEG_N_SLOTS = 1024`,前32个回滚段放在表空间中,往后的97个回滚段则放在额外的undo-log空间中.我们看下 header 信息

<img src="http://mysql.taobao.org/monthly/pic/2015-04-01/03.png" style="zoom:75%;" />

insert log

![](http://mysql.taobao.org/monthly/pic/2015-04-01/04.png)

update log

![](http://mysql.taobao.org/monthly/pic/2015-04-01/05.png)

可以看到其可以找到新旧两个值.





### binlog 复制日志

binlog,即二进制日志,其记录了所有数据库的改变,以二进制形式保存在磁盘中.其用于查看数据库变更历史,增量备份和恢复,mysql 的主从复制.

binlog 有三种格式

- Row 记录下每行的修改细节,不记录上下文信息,alter table的时候每行数据都会发生改变就会产生大量数据
- Statement 每一条修改的语句会记录下,减少日志的记录,缺点就是需要执行所有的语句需要上下问信息
- Mixed 上面两种的混合,例如在alter语句使用 Statement

#### statement

每一条会修改数据的 sql 都会记录到 binlog,优点是不需要记录每一行的变化,缺点是,记录语句时需要保存一些相关信息,保证所有语句能在 slave得到和master执行相同的结果.

#### row

row 顾名思义,保存那条记录被更改,优点是不需要记录了上下文的相关信息,缺点是,记录时候可能需要保存非常多的数据

#### mixed

这是上面两种模式的结合,取上面两者的优点,MIXED 一般修改语句会用 statement 保存,如一些函数无法用 statement 完成则使用 row 格式进行保存,Mysql 对于日志保存的粒度是每句sql,会在 Statement 和 Row 之间选择一种格式进行保存.

`show variables like 'binlog_format'`可以看到其存储的格式

<img src="https://upload-images.jianshu.io/upload_images/12619159-eea89551711c22be.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp" alt="50" style="zoom:50%;" />

#### 主从复制

- Master 把数据变更记录记录到二进制日志中(主节点必须启用二进制日志)
- Slave 通过 I/O线程读取 Master 中 bin-log events 并写入中继日志(relay log),这个过程中是可以带位置参数,如果不带则是发送全部
- Slave 重做中继日志中的事件,会记录到具体哪一个二进制日志的哪一个位置
- Slave 开启另一个线程,把中继日志的时间一条条在本地执行(数据重放)

![](https://img2018.cnblogs.com/blog/1297933/201907/1297933-20190705153223795-497941446.png)

其实我们看下主从同步,就是一种典型的增量同步的实现过程



### Others

- 慢查询日志
- 错误日志
- 中继日志(slave 配合 master 进行 binlog 复制)
- 一般查询日志(general log)



## mysql的并发控制 (old version)

---

此处多部分图生效加之对 Mysql 理解的深入,此部分知识点分别在 mysql 服务器结构 日志系统以及下文的事务中去了.

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

MVCC(MultiVersion Concurrency Control)多版本并发控制.InnoDB 是通过 undo log 实现的MVCC,通过undolog可以找回数据的历史版本,按照用户的隔离级别,看到对应的版本,回滚的时候覆盖数据页上的数据.MVCC多版本并发控制指的是 “维持一个数据的多个版本,使得**读写操作**没有冲突” 

MVCC 不解决写写冲突之间的问题.读读之间没有冲突问题.

>   MVCC模型在MySQL中的具体实现则是由 `3个隐式字段`，`undo日志` ，`Read View` 等去完成的

##### 当前读和快照读

-   当前读指的是select lock in share mode(`共享锁`), select for update ; update, insert ,delete(`排他锁`) 这种访问**最新**数据版本的读操作
-   快照读是不加锁的 select,在非串行的前提下读到的内容,串行时,快照读退化成当前读

##### 实现

每行记录除了我们自定义的字段外，还有数据库隐式定义的`DB_TRX_ID`,`DB_ROLL_PTR`,`DB_ROW_ID`等字段

-   `DB_TRX_ID`
    6byte，最近修改(`修改/插入`)事务ID：记录创建这条记录/最后一次修改该记录的事务ID
-   `DB_ROLL_PTR`
    7byte，回滚指针，指向这条记录的上一个版本（存储于rollback segment里）
-   `DB_ROW_ID`
    6byte，隐含的自增ID（隐藏主键），如果数据表没有主键，InnoDB会自动以`DB_ROW_ID`产生一个聚簇索引
-   实际还有一个删除flag隐藏字段, 既记录被更新或删除并不代表真的删除，而是删除flag变了

![](https://img-blog.csdnimg.cn/20190313213705258.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1NuYWlsTWFubg==,size_16,color_FFFFFF,t_70)



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



## 事务

上面说了事务的一些基本特性,下面从设计事务的角度说明白事务.注意到数据库是I/O密集型系统,对于该种系统提高其并发度则可以提高系统的吞吐量

### 并发设计理念

[参考](https://nxwz51a5wp.feishu.cn/docs/doccn9j1QIJp2f81Ty8Q2JHtEbg#KEdQD6)

此章节无局限于 mysql ,讨论各类事务的并发协议,并非 mysql 的行为,需要注意

对比传统并发的加锁逻辑,事务本身更多是维护了一种执行的偏序关系.尽量减少锁的使用,如序列化执行,其偏序关系即是事务设计考虑的点.设有下列两事务

> 假设 用户A 余额 1000元，B 余额1000元
>
> T1： A给B转账100元
>
> T2：分别给A和B增加6%的利息

```sql
// T1
BEGIN
A = A - 100
B = B + 100
COMMIT
// T2 
BEGIN
A = A * 1.06
B = B * 1.06
COMMIT
```

无所谓执行的先后,从直觉上我们说这个系统最终的钱不能变.如下操作不会让钱的总数发生改变

<img src="https://img.snaptube.app/image/em-video/ebff270fd1f876ff2d719ad74ab15663_1536_850.png" alt="8" style="zoom:50%;" />

<img src="https://img.snaptube.app/image/em-video/fdd8f2eeb4f25e05b285ff657fe520aa_1542_848.png" alt="80" style="zoom:50%;" />

我们看到改变执行顺序不影响结果则可以被接受（类似重排序）,其和串行执行的结果一致这称为**可串行调度(serializable schedule)**.我们可以去考虑哪些情况造成不可串行调度.还是上面的例子

什么情况会造成钱凭空出现呢？可以看到其原因是对**同一记录多次读取值不一致**,如上面 AB 转账的时候,B应该为开始的 1000 块,但是其读到了事务T2提交的1060块,这就造成了数据的不一致.这种情况称为 **不可重复读**. 我们假设 T1 开始的时候读到了A 1000 B 1000块,那么当事务T2读时,如果T1提交了,那么就是执行了T1,T2,如果T1没提交,那么最终执行的结果是 T1 或者 T2.类似上面的机制,MVCC 就是试图解决上面的问题.且上述情况还发生了**脏读**,即读到了未提交事务的数据

这两者都是读写冲突,而还有一种情况是**幻读**即读到了insert进的数据,这种数据也是一种读写冲突

除了读写冲突外,还有写写冲突,两句update语句放到一起,起先后就引起了写写冲突.其实这就是一种偏序问题.为了追求性能,有些不可串行的调度也是能被接受的,这被称之为**事务的隔离**,下图为事务的隔离级别

<img src="https://img.snaptube.app/image/em-video/841cde60a21a248b825f229934cfd7c8_1538_868.png" alt="4" style="zoom:50%;" />

对 CPU 或者开发者而言,只有知道当前所有将要执行的事务,才能确定他们的偏序关系,然后事务开启的特点,使得某一时刻执行的事务无法被确定,这个时候一个直觉的做法是加锁,读写锁用于提高并发.

<img src="https://img.snaptube.app/image/em-video/8e5b7680bab1949bdccb50ab13c4463e_1642_862.png" alt="50" style="zoom:50%;" />

但实际上哪怕是加锁也可能会出现上面的情况.对整个事务加锁又非常影响性能.

#### 二阶段锁定

> 锁在真正被使用时才会获取，同时在操作全部执行完毕后再释放保证了串行化的约束，因此2PL 并发控制协议可以保证调度的可串行化，但会引出级联终止的问题。
>
> A事务的终止事件会被广播到依赖A事务写入数据的其他事务上，由于DBMS要避免冲突行为(这里一般指脏读)，则必须将此事务同时终止，而终止有可能会被级联传递，对性能造成雪崩式影响。

<div>
  <img src="https://img.snaptube.app/image/em-video/50e9c94de9642b35c64731dab9cf214c_1162_1324.png" alt="5" style="zoom:40%;float:left" />
  <img src="https://img.snaptube.app/image/em-video/b6484c32bc8f28d066d7cbeb46655cf1_1212_1332.png" alt="50" style="zoom:40%;" /></div>

如上图分别为**两阶段锁定**和**严格的两阶段锁定**，可以看到上面的思路是使用到锁才加释放锁要么是在完全不使用资源A之后要么在事务的最后才一起释放.

用到多种锁就一定会遇到死锁问题,mysql 的解决方式是维护了一个wait-graph结构,当出现环的时候就会死锁.事务尝试获取其它事务持有的锁时直接决定是否需要将其中一个事务中止.事务的时间戳越老其优先级越高.可以按照这个优先级指定淘汰策略.其实就是一个锁的使用策略排序.

我们看到一些中间件的设计是少加锁,尽量使用无锁结构(例如JDK的偏向锁),事务中使用了时间戳作为这一机制的实施.和MVCC中LSN一样,在实际环境中,使用事务绝大多数都不会发生冲突.

#### Timestamp Ordering (T/O) 

这是一种乐观的并发控制协议,其优点是无锁,T/O 的优势在于不会死锁,但对于OLAP负载大量事务之间冲突数据的占比过高,乐观策略会导致大量执行了很长时间的事务回滚,重试成本过高,因此不适用于长事务过多的情况

> **如果 TS(Ti)<TS(Tj) ，那么数据库必须保证实际的 schedule 与先执行 Ti ，后执行 Tj 的结果等价**
>
> **如果 TS(Ti)<TS(Tj) ，那么数据库必须保证实际的 schedule 与先执行 Ti ，后执行 Tj 的结果等价**
>
> **如果 TS(Ti)<TS(Tj) ，那么数据库必须保证实际的 schedule 与先执行 Ti ，后执行 Tj 的结果等价**

那么需要做的唯一控制就是保证事务的执行顺序和事务开始的时间顺序一致.

##### Basic T/O

1. 每个**数据记录**都要携带两个时间戳，RT标示最后一次读发生的时间，WT标示最后一次写发生的时间
2. 在事务结束的时候，检查该事务中每个操作是否存在读取或写入了未来的数据，一旦发生立即中止

```go
// WT 表示最后一次写的时间 RT 表示最后一次读的时间
/**
如果事务 Ti 发生在 W-TS(X) 之前，即尝试读取未来的数据，则中止 Ti ；
如果事务 Ti 发生在 W-TS(X) 之后，意味着它正在读取过去的数据，符合规范。
Ti 读取数据后，如果有必要，则更新 R-TS(X)，同时保留一份 X 的副本，
用来保证 Ti 结束之前总是能读到相同的 X。
*/
func read(X) val {
  	// TS 表示事务的时间戳,W_TS 表示要写的这条记录的时间戳
  	// 如果下面的不等号成立则证明写入了未来的数据
    if TS(T_i) < W_TS(X) {
        abort_and_restart(T_i)
    } else {
        val := read_data(X)
        R_TS(X) = max(R_TS(X), TS(T_i))
        // make a local copy of X to ensure repeatable reads for T_i
        return val
    }
}

/**
如果事务 Ti 发生在 W-TS(X) 或 R-TS(X) 之前，
即尝试写入已经被未来的事务读取或写入的数据，则中止 Ti ；
反之，意味着它正尝试修改过去的数据，符合规范。 Ti 写入数据后，
如果有必要，则更新 W-TS(X)，同时保留一份 X 的副本，
用来保证 Ti 结束之前总是能读到相同的 X。
*/
func write(X, val) {
     if TS(T_i) < R_TS(X) || TS(T_i) < W_TS(X) {
         abort_and_restart(T_i) 
     } else {
         X = val
         W_TS(X) = max(W_TS(X), TS(T_i))
     // make a local copy of X to ensure repeatable reads for T_i
     }
}
```

T/O 的优势在于不会死锁,但对于OLAP负载大量事务之间冲突数据的占比过高,乐观策略会导致大量执行了很长时间的事务回滚，重试成本过高,因此不适用于长事务过多的情况,实际上 mysql 也没有采用这样的设计方式.因为T/O 还有一个致命的缺点**无法产生可恢复的事务**.

#### Optimistic Concurrency Control (OCC)

> OOC 将所有被读取的数据都维护到自己的私有空间中，所有的修改都在私有空间中完成。

OOC 分为3个控制阶段

1. Read Phase：追踪、记录每个事务的读、写集合，并存储到私有空间中
2. Validation Phase：当事务提交时，检查冲突
3. Write Phase：如果校验成功，则合并数据；否则中止并重启事务

看下图可知 OOC 就是 CAS 的变种,其事务结束的时候就会校验自己的时间戳是不是和数据库的数据有冲突,如果有冲突则终止重启事务,否则就会合并数据

<img src="https://img.snaptube.app/image/em-video/8a1f9d81c4f936c8ff0f7ef4504fd41b_1560_924.png" alt="4" style="zoom:50%;" />

其和上面的T/O思想其实类似,其适用范围和OOC类似

- 大部分事务都是读事务
- 大部分事务之间访问的数据间没有交集

其是一种无锁的设计,但其开销会几种在数据合并上,事务的终止成本比较高.

#### insert 对数据集的影响

上面两种事务的考虑多是在静态数据集上的,然而实际上根据CRUD会有更多情况.Insert 就是一种需要上锁的记录.自然可以想到在每条插入时上锁.

##### Predicate Locking

每条数据记录条件都需要判断,但这种方式非常消耗性能,一般的DBMS都不采用这种形式去做.

##### index locking

>  如果在 `status` 字段上有索引，那么我们可以锁住满足 `status = 'lit'` 的 index page，如果尚未存在这样的 index page，我们也需要能够找到可能对应的 index page，锁住它们

##### 全局的锁

如果在 status 上没有索引,则会执行如下操作

> 如果在 `status` 字段上没有索引，那么事务就需要执行以下操作：
>
> - 获取 table 的每个 page 上的锁，防止其它记录的 `status` 被修改成 `lit` 
>
> - 获取 table 本身的锁，防止满足 `status = 'lit'` 的记录被插入或删除

#### MVCC

多版本并发控制,也是 mysql 采用的并发控制协议

参考

> - [Snapshot Isolation综述](https://zhuanlan.zhihu.com/p/54979396)
> - [快照隔离](https://zh.wikipedia.org/wiki/快照隔离)

##### 快照隔离

- 事务的读操作从Committed快照中读取数据，快照时间可以是事务的第一次读操作之前的任意时间，记为StartTimestamp
- 事务准备提交时，获取一个CommitTimestamp，它需要比现存的StartTimestamp和CommitTimestamp都大
- 事务提交时进行冲突检查，如果没有其他事务在[StartTS, CommitTS]区间内提交了与自己的WriteSet有交集的数据，则本事务可以提交；这里阻止了Lost Update异常
- SI允许事务用很旧的StartTS来执行，从而不被任何的写操作阻塞，或者读一个历史数据；当然，如果用一个很旧的CommitTS提交，大概率是会Abort

##### 可串行快照隔离

> 是指两个事务(T1与T2)并发读取一个数据集(例如包含 V1 与 V2)，然后各自修改数据集中不相交的数据项(例如 T1 修改 V1, T2 修改 V2)，最后并发提交事务。如果事物是串行执行，这种异常不会发生。而快照隔离允许这种异常发生。例如，设想 V1 与 V2是 Phil的个人银行账户。银行允许V1或V2是空头账户，只要两个账户总和非负(即 V1 + V2 ≥ 0). 两个户头的初值各是 $100. Phil启动两个事务，T1从V1取出$200，T2从V2取出$200。

SSI 解决了写倾斜问题.而 MVCC 是 SSI 的具体实现.

简而言之，实现 MVCC 的 DBMS 在内部维持着单个逻辑数据的多个物理版本，当事务修改某数据时，DBMS 将为其创建一个新的版本；当事务读取某数据时，它将读到该数据在事务开始时刻之前的最新版本，通过之前的描述我们知道多个副本在 mysql 中 通过 LSN 在 redo-log 中串联起来成为了可提供多版本读的数据结构.如下则是使用MVCC的数据库,如 undo-log 中所介绍

<img src="https://img.snaptube.app/image/em-video/8e55b6af412d8a5ea40ba15e2261aedb_1856_678.png" alt="50" style="zoom:50%;" />

其实这里可以考虑一个问题是,MVCC 是否能够不需要锁,既然都维护了一个稳定的版本链条,那我完全可以采用读旧版本,无视 insert 的语句(LSN太大),修改的时候只需要产生该行记录即可,答案是可以的,但为什么不这样做呢,因为如同上面T/O的做法一样,其可以看做一种大型的 CAS,大量事务的修改会被 abort 掉重来(为了保证一致性),对于mysql的使用场景(多个事务共同活跃修改同一个数据)不如靠锁进行等待.

MVCC 可以通过 T/O 或者 OOC 实现,但在业务逻辑上得加一些限制,mysql 就是通过锁的方式去解决.MVCC 需要实现下面 4 点

> 1. 并发控制协议
> 2. 版本的存储
> 3. 垃圾收集
> 4. 索引管理

并发控制协议如上面所讲

##### 版本的存储

Append-Only Storage

新版本以追加的方式存在同一张表中

- 写的时候追加,读的时候就需要遍历整个链表
- 写的时候更新索引指针,读的时候就不需要遍历整个链表(最新数据)

<img src="https://img.snaptube.app/image/em-video/21509666dde028e217aafefb39c689bb_1538_1184.png" style="zoom:30%;" />

Time-Travel Storage

老版本被存在同一张表中,pointer 被指向另一张表,然后根据另一张表去查询版本.

<img src="https://img.snaptube.app/image/em-video/7e7fa9393a0f4b329c7a36063132dd26_1558_470.png" alt="4" style="zoom:50%;" />

Delta Storage

值记录字段的修改.DBMS 会根据这张表逆向修改恢复历史版本的数据(undo-log)

<img src="https://img.snaptube.app/image/em-video/97e2d73095e72e90478b5668dd4f404c_1534_458.png" style="zoom:50%;" />

##### 垃圾回收 GC

旧版本的数据需要被回收不然使用的空间会无限大.下列就是可被回收的,其实这是一种冷热分离的思想,

- 已经没有活跃的事务需要看到该版本
- 该版本是被一个已经中止的事务创建

和 jvm 的垃圾回收思想一致,其需要明确两个问题,如何查找过期的数据版本,如何确定某版本数据是否可以被安全回收,在 jvm 中使用的是 gc-root trace 的标记算法.MVCC 的 GC 从下面出发

1. Tuple-level
   - Background Vacuuming 直接检查每条数据的旧版本数据,小于当前活跃事务的最小版本的数据,  线程在后台清理这些数据,DBMS 采用了bitmap对上述过程就进行了加速,这个bitmap 用于维护最近修改的数据.
   - Cooperative Cleaning 读取时候顺便删除这些数据
2. Transaction-level
   - 每个事务负责跟踪数据的旧版本,DBMS 不需要亲自检查单条数据,由事务自己决定要删哪些数据,等删除时候根据事务的read/write set 进行删除即可

##### MVCC 数据结构

为了实现 MVCC , Innodb 会把每个行记录增加三个字段,这三个字段能在 page 定义的 row 中看到

- DB_ROW_ID,行 id 用于指示主键,主键没有这行数据
- DB_TRX_ID,事务 id
- DB_ROLL_PTR,回滚指针,该字段写于首记录和 undo-log ,每次更新该行则会记录到 undo-log 用于形成版本链条,结构如下

<img src="https://img-blog.csdnimg.cn/img_convert/63b1dbd65c2e9a08e07a29664c11047f.png" alt="5" style="zoom:70%;" />

##### 写操作的理解

基于上面的理解我们看看 mysql 的写操作做了什么事

**更新数据**

- 加锁, gap lock 或者 record lock
- 写 undo-log
- 更新 row 上的数据,回滚指针等
- 写 redo-log
- 释放锁

**删除**

和更新一致,标志状态为删除即可,也是用的版本链

**插入**

和更新数据一样会带有 lock,同样需要写入 redo-log 和 undo-log.



### 实验方法和记录

开多个数据库链接然后开启事务执行观察其可见性.下面观察到一些现象,只有基于这些可见到的事实才能去推演 mysql 为何如此设计

```sql
select @@global.tx_isolation
+-----------------------+
| @@global.tx_isolation |
+-----------------------+
| REPEATABLE-READ       | # 默认隔离级别
+-----------------------+
1 row in set
Time: 0.068s
```

```sql
show engine innodb status # 可以看到事务的多少和锁的使用状态等
```

#### 测试脏读不可重复读

等值 where

-  **[锁的现象]**开启事务1,2, 1 执行 update,2 执行 update,这个时候2就卡住了不在往下执行,等提交1的时候2才能够提交
  - 可见MVCC对数据的修改(删除属于同一类型)是有加锁的.

- **[数据可见性]** 开启事务1,2, 1 执行 select, 2 update 然后执行提交,1 执行 select 可以看到使用的是快照读, 1 执行 update 同行数据的不同字段,可以看到被事务 2 修改的数据,此时进行回滚,可以看到事务 2 的修改,回滚了事务 1 的修改,**仅限于两个事务都修改同一行的数据记录**
  - MVCC 在事务写入的时候刷新了**写入行**的快照读的版本
  - 结合上面锁的现象,写入的时候,如果是修改同一行的记录不提交的话,先修改的获取到了锁,后修改的等待,如果是修改了不同行的数据则根据锁持有的不同其会不进行修改.

- **[不同数据记录]** 可以测得是互不影响的,可读性也是不更新的.

范围 where

- 其行为特性和每条数据记录加了锁是一样的

#### 测试幻读

幻读的影响主要是 insert 语句,我们可以用插入数据看看可不可读以及有没有加锁来确认该数据锁的控制权等.

- **[数据可见性]** 开启事务1,2 事务1 进行查询,事务2 中 insert,事务1进行查询,可以发现事务1查不到 insert 的语句
  - **[间隙锁]** 此时在事务1中更新不存在的行,发现程序进入阻塞,insert 语句有给数据加锁,事务1获取不到在进行等待了一段时间后放弃获得锁
  - **[间隙锁]** 在事务1中范围更新行(id>=1),此时事务2 insert 会尝试获取锁,此时如果事务不提交则修改不会成功
  - 从上面我们也能看到间隙锁的作用就是对某个范围的数据进行加锁的这么一个逻辑

#### 死锁

innodb 是有死锁检测的

```sql
(1213, 'Deadlock found when trying to get lock; try restarting transaction')
```

- 开启两个事务 T1,T2,分别执行
- update mail set email='bbb' where id>=5,update mail set email='bbb' where id<=2
- update mail set email='aaab' where id=2,update mail set email='bbba' where id=5

其实我们看这个就能看到死锁现象了,mysql 对死锁自己维护了 wait-lock 的数据结构进行检测



综上我们可以看到 RR 在整体的处理逻辑

- insert 和 update 都要去获取对应的锁来获取更新,锁的粒度到行的级别
- MVCC 多版本当前可见的版本为事务开始时或读取数据时的最新版本

#### mysql RR 有没有解决幻读问题?

显然利用上面的知识我们知道只要在 insert 完成后,在查询的事务里面 update 到这一行记录, RR 就会存在幻读问题,单纯的读写 mysql 是不会存在上面的幻读问题的.可以说 mysql 解决了幻读问题但没有完全解.



#### 从现象的角度再理解隔离级别

我们主要讨论 RR 和 RC, RU 并不需要多版本控制,Serializable 的完全串行是两个不同的极端.

首先,两者都解决了脏读问题,其通过的手段是MVCC/快照读取完成这一目的的.

RC 在其他事务提交之后的行为是能读到其他事务提交到的数据,所以显然其读到的还是数据库中最新的数据.而 RR 只有在写该数据的时候会刷新当前行的快照读,不可重复读会在READ COMMIT情况下出现,可以参照上面的测试去看到这一现象.**写操作会使得RR更新数据版本,从而获得最新的快照.**



### 锁

[参考](https://www.cnblogs.com/yang417/p/14882256.html),[参考](cnblogs.com/janehoo/p/5621241.html)

主要针对 RR,RC 级别用到的锁算法,锁本身的是什么的理解不在赘述,在 mysql 中,锁主要维持事务的部分偏序关系使得事务执行满足业务需要.完全偏序关系(序列化)的维持是一种性能损失行为,使用锁本质上要使用CPU空转资源(CAS)或者操作系统调度信号量(内核态切换).

锁有以下三种

- Record Lock：单个行记录上的锁
- Gap Lock：锁定一个范围，但不包含记录本身
- Next-Key Lock：Gap Lock + Record Lock，锁定一个范围，并且锁定记录本身

间隙锁的表现是允许 update **不允许 insert**. 而 record lock 则是会都锁住,不允许 update 也不允许 insert

我们利用`show engine innodb status`查看即可看到使用的 lock mode,就有我们树熟知的 X 锁和 S 锁.

```sql
---TRANSACTION 6974, ACTIVE 90 sec
2 lock struct(s), heap size 360, 1 row lock(s)
MySQL thread id 14, OS thread handle 0x7fdfc8c19700, query id 242 10.0.0.51 root cleaning up
TABLE LOCK table `test`.`l` trx id 6974 lock mode IX
RECORD LOCKS space id 11 page no 3 n bits 80 index `PRIMARY` of table `test`.`l` trx id 6974 lock_mode X locks rec but not gap # 这个表示在主索引上加锁,都能看到其 tablespace 和 page no
Record lock, heap no 4 PHYSICAL RECORD: n_fields 6; compact format; info bits 0
 0: len 4; hex 8000000f; asc     ;; --表示主键a，4个字节，hex 8000000f表示十进制15
 1: len 6; hex 000000001b13; asc       ;; --6个字节事务id
 2: len 7; hex 90000001560110; asc     V  ;; --固定7个字节回滚指针
 3: len 4; hex 8000000f; asc     ;;  --表示b列，hex 8000000f表示十进制15
 4: len 4; hex 8000000f; asc     ;;  --表示c列，hex 8000000f表示十进制15
 5: len 4; hex 8000000f; asc     ;;  --表示d列，hex 8000000f表示十进制15
```

IX 锁表示,在锁定一条记录时需要在对应的表上加入 IX 锁.可以枚举下我们遇到的情况,用 for update 即可用select 简单测试加锁

等值索引

- 默认的加锁单位是 Next-Key Lock,等值查询会从 Next-Key Lock 退化为行锁.
- 主键唯一索引,加 record lock
- 普通索引,加 next key lock,即会有间隙锁,因为无法做到唯一性,会访问下一个值,接着会加一个 next lock,比如 col = 10,那么 next lock 会访问 col = 10 然后会向右扫描,访问二级索引,最终加的索引是回表主键索引col=10的 record lock,以及二级索引上(10,下一个值)的间隙锁,从语义上理解就是不允许插入这个范围的数据

总结起来就是

- 不加索引的等值查找,加 next key lock,会通过主键进行全表扫描(类似全表锁)索引把每个 gap 都锁起来
- 二级索引上的等值查询，向右遍历时且最后一个值不满足等值条件的时候，next-key lock退化为间隙锁
- 二级索引上加了Record Lock 或Next-Key Lock ，则对应的主键加Record Lock ；
- 二级索引加Gap Lock ，则对应的主键不加锁
- 在 RR 的隔离级别下，**当查询的列没有索引时，会锁住所有记录**

相对来讲范围索引就要简单很多,其会对相应的区间加上 next-lock,而插入索引使用的是 record 也可以简单想到.从这个角度下来说,我们看下 RC 做了什么,RC 只有 **record lock**.所以我们能够理解为什么 RC 会出现幻读的现象.认识到这点之后可以回过头在看日志系统会有不一样的理解.





## 存储引擎优化

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

### 关于扫描

索引优化的思路是尽可能多的**使用索引**,在毫无索引的情况下可以考虑 id

表中的数据大概是千万级别,下面一句 sql 来自我司运营

```sql
select count(*) from
(select id,a,creation,b from t
order by id desc
limit 2200000
) tmp
where date(creation) >='2021-08-01'
and a >20
and b is not null
```

上述 sql 犯病的地方在于以下几个,首先目测得上述 sql 在进行全表扫描, where 条件是优化的终点,上面的问题逐个分析

- 全局范围差距,等值匹配仅有b
- creation 这个字段一般也不会建立索引,还加个函数,嗯,全表扫描
- a 这个字段具体含义是一个评分,根据业务逻辑,这个范围只包含四个值

当范围查找不可避免的时候,我们就需要观测到是否有些记录可以利用顺序的特性,先看优化后的 sql

```sql
select count(1) from t 
where id>=(select min(id) from t where creation between '2021-08-01 00:00:00' and '2021-08-01 00:05:00')
and b is not null
and (a =30 or a=80 or a=90 or a=100)
```

显然确定一个开始的 id 可以极大的降低搜索的成本,根据时间字段我们的问题就变成了找那一天最小的id,然后把范围查询化为等值查询,就有如上sql
