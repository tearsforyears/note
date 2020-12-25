# java数据结构的实现

[TOC]

---

## ArrayList

顾名思义是利用Array去存储的list,对于ArrayList我们需要关注其扩容机制

```java
transient Object[] elementData;
private int size;
```

ArrayList里面大量使用了`java.util.Arrays.copyOf`来赋值两个数组

其初始化逻辑如下

```java
public ArrayList(int initialCapacity) { 
if (initialCapacity > 0) {
   this.elementData = new Object[initialCapacity]; // initialCapacity=10
 } else if (initialCapacity == 0) {
   this.elementData = EMPTY_ELEMENTDATA; // 空数组 不带参数的构造函数相当于此
 } else {
   throw new IllegalArgumentException("Illegal Capacity: "+
                                      initialCapacity);
 }
}
```

add

```java
public boolean add(E e) {
  ensureCapacityInternal(size + 1);
  elementData[size++] = e;
  return true;
}
private void ensureCapacityInternal(int minCapacity) {
  if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) { // 是否为空
    minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity); // 最小为10
  }
  ensureExplicitCapacity(minCapacity);
}
private void ensureExplicitCapacity(int minCapacity) {
  // 该字段定义在ArrayList的父类AbstractList,用于存储结构修改次数,这确保了快速失败机制。
  modCount++;
  if (minCapacity - elementData.length > 0)
    grow(minCapacity);
}
private void grow(int minCapacity) {
  int oldCapacity = elementData.length;
  int newCapacity = oldCapacity + (oldCapacity >> 1);

  if (newCapacity - minCapacity < 0)
    newCapacity = minCapacity;
  if (newCapacity - MAX_ARRAY_SIZE > 0)
    // 调整新容量上限或者抛出OutOfMemoryError
    newCapacity = hugeCapacity(minCapacity);
  elementData = Arrays.copyOf(elementData, newCapacity);
}
private static int hugeCapacity(int minCapacity) {
  if (minCapacity < 0) // overflow
    throw new OutOfMemoryError();
  return (minCapacity > MAX_ARRAY_SIZE) ?
    Integer.MAX_VALUE :
  MAX_ARRAY_SIZE; // 初始化为最大数组长度
}
```

`System.arraycopy`和`Arrays.copyOf`方法

前者是native方法,用于已经有了两个数组把一个复制到另一个上,而copyOf则是在其内部new了个数组.

```java
public static native void arraycopy(Object src,  int  srcPos,Object dest, int destPos,int length);
// 数组复制 src->dest
// 从srcPos和destPos开始,src数组的srcPos以后的内容都赋值到dest相应的位置上了
// length要复制的元素的个数,(参考c++的复制)
// 其底层是用while直接操作内存地址 其还是一个原子操作,其根据复制类型的不同会引用不同的
// 复制函数
```

```java
public static int[] copyOf(int[] original, int newLength) {
  int[] copy = new int[newLength]; // 多分配了内存空间
  System.arraycopy(original, 0, copy, 0,
                   Math.min(original.length, newLength));
  return copy;
}
```

我们看下其remove方法的实现

```java
public E remove(int index) {
  rangeCheck(index);

  modCount++;
  E oldValue = elementData(index);

  int numMoved = size - index - 1;
  if (numMoved > 0)
    System.arraycopy(elementData, index+1, elementData, index,
                     numMoved); // 从这里可以看到其本质上还是用了向后缩紧的办法
  elementData[--size] = null; // clear to let GC do its work

  return oldValue;
}
```



## Vector

相比于ArrayList还多了一个`capacityIncrement`属性

```java
public synchronized boolean add(E e) {
  modCount++;
  ensureCapacityHelper(elementCount + 1);
  elementData[elementCount++] = e;
  return true;
}


private void ensureCapacityHelper(int minCapacity) {
  if (minCapacity - elementData.length > 0)
    grow(minCapacity);
}


private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;


private void grow(int minCapacity) {
  int oldCapacity = elementData.length;
  int newCapacity = oldCapacity + ((capacityIncrement > 0) ?
                                   capacityIncrement : oldCapacity);
  // 增长曲线在这,如果增长>0才有用,不然就默认扩充一倍
  if (newCapacity - minCapacity < 0)
    newCapacity = minCapacity;
  if (newCapacity - MAX_ARRAY_SIZE > 0)
    newCapacity = hugeCapacity(minCapacity);
  elementData = Arrays.copyOf(elementData, newCapacity);
}
```

除了synchronized我们可以看到其代码和ArrayList一样.因为其性能关系,其后续不再被建议使用,如果要考虑线程安全的问题,移步到ConpyOnWriteArrayList

## Stack

```java
public class Stack<E> extends Vector<E> {}
public E push(E item) {
    addElement(item);
    return item;
}
public synchronized E pop() {
    E obj;
    int len = size();
    obj = peek();
    removeElementAt(len - 1);
    return obj;
}
```

其本质上就是个Vector,不被建议使用主要方法如上.

## LinkedList

```java
public class LinkedList<E> extends AbstractSequentialList<E> implements List<E>, Deque<E>, Cloneable, java.io.Serializable{
}
```

其主要维护的数据结构

```java
transient int size = 0;
transient Node<E> first;
transient Node<E> last;
private static class Node<E> {
  E item;
  Node<E> next;
  Node<E> prev;

  Node(Node<E> prev, E element, Node<E> next) {
    this.item = element;
    this.next = next;
    this.prev = prev;
  }
}
```

其方法实现和数据结构上的基本一致

```java
public boolean add(E e) {
    linkLast(e);
    return true;
}

void linkLast(E e) {
    final Node<E> l = last;
    final Node<E> newNode = new Node<>(l, e, null);
    last = newNode;
    if (l == null)
        first = newNode;
    else
        l.next = newNode;
    size++;
    modCount++;
}
public void add(int index, E element) {
    checkPositionIndex(index);
    if (index == size)
        linkLast(element);
    else
        linkBefore(element, node(index));
}
/*这里有个思想是如果节点的index大于一半就从后面开始找*/
Node<E> node(int index) {
    if (index < (size >> 1)) {
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}
void linkBefore(E e, Node<E> succ) {
    final Node<E> pred = succ.prev;
    final Node<E> newNode = new Node<>(pred, e, succ);
    succ.prev = newNode;
    if (pred == null)
        first = newNode;
    else
        pred.next = newNode;
    size++;
    modCount++;
}
```

其remove实现如下

```java
public E removeFirst() {
    final Node<E> f = first;
    if (f == null)
        throw new NoSuchElementException();
    return unlinkFirst(f);
}

private E unlinkFirst(Node<E> f) {
    final E element = f.item;
    final LinkedLisNode<E> next = f.next;
    f.item = null;
    f.next = null;
    first = next;
    if (next == null)
        last = null; // 一个元素的时候,认为是没有尾节点的
    else
        next.prev = null;
    size--;
    modCount++;
    return element;
}

public E remove(int index) {
    checkElementIndex(index);
    return unlink(node(index));
}

E unlink(Node<E> x) {
    final E element = x.item;
    final Node<E> next = x.next;
    final Node<E> prev = x.prev;
    if (prev == null) {
        first = next;
    } else {
        prev.next = next;
        x.prev = null;
    }
  	
  	// 如果下个节点是空,则该节点是尾结点
    if (next == null) {
        last = prev;
    } else {
        next.prev = prev;
        x.next = null;
    }

    x.item = null;
    size--;
    modCount++;
    return element;
}
```

## ArrayDeque

```java
public class ArrayDeque<E> extends AbstractCollection<E> implements Deque<E>, Cloneable, Serializable{
}
```

可以看到其没有实现List接口

```java
transient Object[] elements; // 可以看到数据结构仍是数组形式
transient int head; // 头的索引
transient int tail; // 尾索引
private static final int MIN_INITIAL_CAPACITY = 8;
// 最小容量为8,其容量必须是2的幂
```

其初始化最大为$$2^{30}$$最小为8,如果初始化的数值不为2的幂,那么就就近取2的幂,下面是追加到队尾

```java
public void addLast(E e) {
    if (e == null)
        throw new NullPointerException();
    // 将元素存放在tail位置,即原尾节点的下一个空节点位置
    elements[tail] = e;
   // 下面这个运算是如果tail超过8就会都变成8,否则就全归零
    if ((tail = (tail + 1) & (elements.length - 1)) == head)
        // 扩容的方法
        doubleCapacity();
}
```

这里如果`elements.length`不是2的幂,那么其位与就不会是`0b1111`的形式,也就相当于%运算了,如果到头了就扩容,同理添加到头部

```java
public void addFirst(E e) {-10
    if (e == null)
        throw new NullPointerException();
    elements[head = (head - 1) & (elements.length - 1)] = e;
    // 负数的位与需要注意一定要换成补码去进行计算,否则没有任何意义
  	// 逻辑和上面一样不够了就扩容
    if (head == tail)
        doubleCapacity();
}
```

知道了计算坐标其删除就比较简单了

```java
public E pollFirst() {
    int h = head;
    @SuppressWarnings("unchecked")
    E result = (E) elements[h];
    if (result == null)
        return null;
    elements[h] = null;    
    head = (h + 1) & (elements.length - 1);
    return result;
}
public E pollLast() {
    int t = (tail - 1) & (elements.length - 1);
    @SuppressWarnings("unchecked")
    E result = (E) elements[t];
    if (result == null)
        return null;
    elements[t] = null;
    tail = t;
    return result;
}
```



## *HashMap

hashmap的在JDK1.7和JDK1.8有着不同的实现,在JDK1.7数据结构用的是链表加数组,而1.8用的是链表加数组加红黑树,红黑树用于解决hash冲突性能上要比链表更高.除此之外,JDK1.8在容量升级上进行了优化,使得扩容时候数组迁移的效率大大提高(参考下文位运算和HashMap的关系)

```java
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable{}
```

HashMap的底层是用数组做的存储结构,同时支持链表和红黑树的操作方法,其实现方法也很简单我们看其主要数据结构,如下的Node结构和TreeNode结构

```java
transient Node<K,V>[] table; // 存储的结构
transient Set<Map.Entry<K,V>> entrySet; // 存放kv对的结构,即Node
transient int size;
static class Node<K,V> implements Map.Entry<K,V> {
  final int hash; // 存放key的hashCode
  final K key;
  V value;
  Node<K,V> next; // 链表指针指向下
} 

static final class TreeNode<K,V> extends LinkedHashMap.Entry<K,V> {
  TreeNode<K,V> parent;  // red-black tree links
  TreeNode<K,V> left;
  TreeNode<K,V> right;
  TreeNode<K,V> prev;    // needed to unlink next upon deletion
  boolean red;
}
// 下面这个类是LinkedHashMap里面的,把单向链表换成双向的
static class Entry<K,V> extends HashMap.Node<K,V> {
  Entry<K,V> before, after;
  Entry(int hash, K key, V value, Node<K,V> next) {
    super(hash, key, value, next); // 调用的是Node的构造
  }
}
```

![](https://img-blog.csdnimg.cn/20200622102700374.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80Mzc2NzAxNQ==,size_16,color_FFFFFF,t_70)

我们可以看到其三个数据结构,在HashMap内就只有Node管理的单向链表,TreeNode所管理的红黑树.从存储结构`Node<K,V>[] table;`看,这个Node可以是双向链表的Entry,也可以是红黑树的TreeNode,所以存储的节点通过继承通用.HashMap的容量扩大为16开始,每次扩容都是一倍.

HashMap一系里面的数据结构就四种

-   Node数组 或者叫哈希表
-   Node所代表的单链表
-   LinkedHashMap.Entry所代表的双链表
-   TreeNode所代表的红黑树

![](https://img-blog.csdnimg.cn/20200621201115134.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80Mzc2NzAxNQ==,size_16,color_FFFFFF,t_70)

我们在看一下其他数据结构

```java
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // 16 为默认容量
static final int MAXIMUM_CAPACITY = 1 << 30; // 2^30 最大容量
static final float DEFAULT_LOAD_FACTOR = 0.75f; // 负载因子(*)

static final int TREEIFY_THRESHOLD = 8; // 链表变成红黑树的阈值,这个阈值指的是
// 冲突的个数即存储节点,即存储冲突节点的链表长度而不是存储Node[]的实际长度
// 红黑树在用resize(),split()方法时才会用到该字段,在remove里面没有用到,所以在

// remove中判断普通链表的个数可能不是6个
static final int UNTREEIFY_THRESHOLD = 6; // 红黑树还原为链表的阈值

// 哈希表树化的最小容量,如果容量小于64就不允许树形化
static final int MIN_TREEIFY_CAPACITY = 64;

// 扩容阈值(实际个数),当数组实际元素小于该值,则数组就会扩容
// 同时这个数值也作为tableSizeFor的赋值存储,用于计算初始化时候的大小
// 主要看put的代码和resize的代码即可理解此部分
int threshold;
// 数组的加载因子,也就是说,这个数组最多元素的百分比
final float loadFactor;
```

`扩容阈值<容量*加载因子`就需要扩容,在每次put方法里都会判断到resize执行,其中加载因子可以大于1,来解释下这个大于1的意思,因为hashmap是一个数组作为主要存储的,数组的头结点又可以代表链表,这些链表元素不在数组里,但会在链表里,但是如果大于1那证明一定会发生冲突,如果设置hash大于1就有点损失性能.不符合hash表建立的初衷.

```java
// 其主要构造方法 
public HashMap(int initialCapacity, float loadFactor) {
  if (initialCapacity < 0)
    throw new IllegalArgumentException("Illegal initial capacity: " +
                                       initialCapacity);
  if (initialCapacity > MAXIMUM_CAPACITY)
    initialCapacity = MAXIMUM_CAPACITY;
  if (loadFactor <= 0 || Float.isNaN(loadFactor))
    throw new IllegalArgumentException("Illegal load factor: " +
                                       loadFactor);
  this.loadFactor = loadFactor;
  this.threshold = tableSizeFor(initialCapacity); // 设置扩容阈值
}
// 这个方法能返回一个数比cap大的且是2的指数
// 该算法首先让指定容量cap的二进制的最高位后面的数全部变成了1
static final int tableSizeFor(int cap) {
  int n = cap - 1;
  n |= n >>> 1;
  n |= n >>> 2;
  n |= n >>> 4;
  n |= n >>> 8;
  n |= n >>> 16;
  return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}
```

我们来看其主要方法

```java
// evict参数在其他用到,这里不做讨论
final void putMapEntries(Map<? extends K, ? extends V> m, boolean evict) {
  int s = m.size();
  if (s > 0) {
    
    if (table == null) { // 判断table是否已经初始化
      // s代表
      float ft = ((float)s / loadFactor) + 1.0F; // 计算了存储容量
      int t = ((ft < (float)MAXIMUM_CAPACITY) ?
               (int)ft : MAXIMUM_CAPACITY); // 如果存储容量合适就用这个初始化了
      if (t > threshold) // 如果容量比扩容阈值还大,那么下次就应该是这个值了
        threshold = tableSizeFor(t); // 计算得到的t大于阈值，则初始化阈值
      
    }else if (s > threshold) // 已初始化，并且m元素个数大于阈值，进行扩容处理
      // s是实际元素的个数,threshold是数组扩容阈值
      // (即数组中真实存在的元素而非数组大小)
      resize(); // * 这个方法需要关注
    
		/* 
		上面的扩容部分分为两个,一个是数组未初始化时,threashold表达的含义是给数组分配的内存的大小,并且在resize中完成初始化,二是数组初始化之后作为扩容的一个阈值,即大于这个值就扩容
    */
    for (Map.Entry<? extends K, ? extends V> e : m.entrySet()) {
      K key = e.getKey();
      V value = e.getValue();
      putVal(hash(key), key, value, false, evict); 
      // 该方法也会初始化数组,内部调用resize
    }
  }
}
```

我们看下resize,resize这个方法既可以初始化也可以扩容,这是哈希表使用的扩容方法

这个扩容是重点,包括扩充容量的大小,新hash值的计算等等,其数组的扩容如下按照2的倍数进行扩展,对于其他几个重要的参数,需要冲突大于8且数组整体大小大于64才进行树形化

从下面我们也可以看出,什么时候HashMap才需要扩容,即当**加入元素个数大于阈值的时候**,即所谓的阈值是用来限制一次加入的元素的数量的大小.其实从这个角度我们也能看出数组扩容的一些机制.resize要计算新的阈值,其无论是初始化还是扩容之后,threshold的含义都变更为数组扩充的阈值而不是分配内存的大小

```java
final Node<K, V>[] resize() {
  Node<K, V>[] oldTab = table;
  int oldCap = (oldTab == null) ? 0 : oldTab.length;
  int oldThr = threshold; 
  // 阈值存储,这里两个阈值都有用到,newCap的计算是最后内存分配的实际大小
  // 利用到threshold都是初始化
  int newCap, newThr = 0; // 新容量,新阈值

 
  if (oldCap > 0) { // oldCap是实际元素个数
    if (oldCap >= MAXIMUM_CAPACITY) {
      threshold = Integer.MAX_VALUE;
      return oldTab; // 不用扩容
      
    }else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
             oldCap >= DEFAULT_INITIAL_CAPACITY) {
      // 上面的elseif是有table存在正常状况的扩容,计算扩容大小
      // newCap = oldCap * 2
      // newThr = oldThr * 2
      newThr = oldThr << 1; 
    }
    // cap翻倍,阈值不变
  } else if (oldThr > 0) { // 走到这说明是没有初始化的,其阈值全是2的次方数
		// 这是 采用HashMap(int initialCapacity)、
    // HashMap(initialCapacity, loadFactor)这两个构造器创建Map对象
    // 第一次初始化哈希表，新容量newCap就设置为老的阈值
    newCap = oldThr; // 从这里就可以看出tableSizeFor临时存放的东西就是新的阈值
  }else {
  	// 否则，那就是oldThr等于0，oldCap等于0。
    // 实际上就是采用 无参构造器 HashMap() 创建Map对象
    // 容量和阈值都直接初始化为默认值
    newCap = DEFAULT_INITIAL_CAPACITY;
    newThr = (int) (DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
  }
  // 在上面的三种情况中走完之后，如果新阈值newThr还是等于0，那说明newCap >=MAXIMUM_CAPACITY  或者 oldCap < DEFAULT_INITIAL_CAPACITY 的时候都会走到这一步
  if (newThr == 0) {
    float ft = (float) newCap * loadFactor;
    // 第二个判断的原因是因为负载因子可以大于1
    newThr = (newCap < MAXIMUM_CAPACITY && ft < (float) MAXIMUM_CAPACITY ?
              (int) ft : Integer.MAX_VALUE);
  }
  
  
  // 经过重新计算得到新的阈值,这个阈值影响的是
  threshold = newThr;
  
  // 初始化分配孔融数组的内存内存
  Node<K, V>[] newTab = (Node<K, V>[]) new Node[newCap]; // 旧数组是oldTab
  table = newTab;
  
  // 开始转移原来map里面的值
  if (oldTab != null) {
    for (int j = 0; j < oldCap; ++j) {
      Node<K, V> e; // 暂时存放oldTable的Node节点
      if ((e = oldTab[j]) != null) {
        // 将旧数组该位置置空
        oldTab[j] = null;
     		// e.next通过链表查询下个节点是否为空,下个节点为空证明可以直接移动
        // 这里还涉及到两种情况,树的节点或者链表的节点(链地址法)
        if (e.next == null) {
          // 计算新的地址,
          newTab[e.hash & (newCap - 1)] = e;
        }else if (e instanceof TreeNode) {
          // 调用split方法，将红黑树节点也转移到新数组中
          // split方法中具有将红黑树还原为链表的方法
          ((TreeNode<K, V>) e).split(this, newTab, j, oldCap);
        }else {// 证明Node为链表节点
          // 这里我们注意一点前提就是数组扩容的时候每次都是*2相当于左移,
          // 下面的代码思考得带入二进制的补码进行思考
          Node<K, V> loHead = null, loTail = null;
          Node<K, V> hiHead = null, hiTail = null;
          Node<K, V> next;
          do {
            next = e.next;
             // 判断hash的最高位是0还是1,解释在下面
            if ((e.hash & oldCap) == 0) {
              // 高位为0的构成个链表
              if (loTail == null)
                loHead = e;
              else 
                loTail.next = e;
              loTail = e;
            }else { // hash高位是1
              // 高位为1的构成个链表
              if (hiTail == null)
                hiHead = e;
              else
                hiTail.next = e;。
              hiTail = e;
            }
          } while ((e = next) != null);
          
          // 这里我们讲个前提,index值的计算是 hash & cap-1 即计算出的哈希值
          // 取数组长度的模,而扩容每次又是两倍,可以知道新index和旧index之间的关系
          // index1 = hash & cap - 1
          // index2 = hash & 2 * cap -1
          // 以二进制思考上面两个算式 可知 cap-1和2*cap - 1在二进制都是一堆1
          // 唯一的不同是这两个数差了一位,hash值又相同的情况下,易知
          // index1的二进制头部加上一位=index2 => (index1 + oldCap=index2)
          // 例如hash = 0b1011 1010 cap-1=0b0111 2*cap-1=0b1111
          // index1 = 0b010,index2 = 0b1010 
          // 还有另一种情况是,如果index1的结果如下
          // hash = 0b1010 0010  则index1 = 0b010 index2=0b0010
          // 那么就是index1=index2了,这个条件是index2的最高位为0,这是由于hash的
          // 值所导致的,我们需要用如上的(e.hash & oldCap) == 0来获取其最高位
          if (loTail != null) {
            loTail.next = null;
            newTab[j] = loHead; // 计算新hash值且赋值
            // 这里只需要赋值一次的原因是一个链表(根据链地址的相同hash值)
          }
          if (hiTail != null) {
            hiTail.next = null;
            newTab[j + oldCap] = hiHead; //计算新hash值且赋值
          }
        }
      }
    }
  }
  return newTab;
}
```

我们看下普通的`putVal`的实现

```java
public V put(K key, V value) {
  return putVal(hash(key), key, value, false, true); 
  // 这里就确保了值必定会被替换
}

final V putVal(int hash, K key, V value, boolean onlyIfAbsent,boolean evict) {
  Node<K,V>[] tab; // 存放原来的table
  Node<K,V> p; // 存放索引所在的节点
  int n, i; // n用来存放table长度(实际元素个数),i用来记录index(由hash算出来)
  if ((tab = table) == null || (n = tab.length) == 0)
    n = (tab = resize()).length; // **如果为空初始化数组**
  if ((p = tab[i = (n - 1) & hash]) == null) // 这里不是取模而是&
    tab[i] = newNode(hash, key, value, null); // 不为空给封装成节点放入
  else {
    // 发生hash冲突了,来解决hash冲突,冲突分为3种情况
    Node<K,V> e; // 临时存放新节点
    K k;
    if (p.hash == hash &&
        ((k = p.key) == key || (key != null && key.equals(k))))
      // 如果key已经在相应的位置了就替换value
      e = p; // 此处的e已经拿到了对应的节点,后续才做修改
    else if (p instanceof TreeNode)
      e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
    	// 红黑树的话,自然是调用红黑树的节点放置进去
    else {
      // 这里是普通链表,我们得找一下该节点
      for (int binCount = 0; ; ++binCount){
        if ((e = p.next) == null){ // 遍历到不为空,就添加到节点上
          p.next = newNode(hash, key, value, null);
          if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
            // 如果大于此值则,则树形化
            treeifyBin(tab, hash); // 二叉树化链表
          break;
        }
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k))))
          // 如果此时某个节点的key值和要加入的key值相等
          break;
        p = e; // 获取节点引用
      }
    }
    
    if (e != null) { // existing mapping for key
      V oldValue = e.value;
      if (!onlyIfAbsent || oldValue == null)
        e.value = value; // 当onlyIfAbsent为false或oldValue为空时候进行替换
      // 否则则不进行替换,即其没有值的时候可以快速完成赋值
      afterNodeAccess(e); // 在HashMap没有实现,给LinkedHashMap等实现了
      return oldValue;
    }
  }
  
  // 如果走到这就是,
  ++modCount; // 这个字段是结构改变次数,即新建节点次数
  if (++size > threshold) // 如果大于阈值,则要进行扩容
    resize();
  afterNodeInsertion(evict); // 和上面同样是空实现
  return null;
}
```

关于红黑树,此处不多介绍.后会专门介绍该树的结构和运行机制,其是一颗高性能的AVLTree.

这里纯粹的代码的扩容研究可能不是很透彻和深刻,我们选择用数学的方法进行研究,利用下面代码导出数据在进行绘图,其threshold和capacity始终保持的关系是 threshold = capacity * loadFactor

```java
Class<HashMap> clz = HashMap.class;
HashMap<Integer, Double> map = clz.newInstance();
Field size = clz.getDeclaredField("size"); // 实际元素的大小
Field threshold = clz.getDeclaredField("threshold"); // 阈值
Field table = clz.getDeclaredField("table"); // 底层数组
size.setAccessible(true);
threshold.setAccessible(true);
table.setAccessible(true);

for (int i = 0; i < 10000; i++) {
  map.put(new Random().nextInt(), new Random().nextDouble());
  int sizeVal = size.getInt(map);
  int thresholdVal = threshold.getInt(map);
  int capacity = ((Object[]) table.get(map)).length;
  System.out.println("size=" + sizeVal + ",threshold=" + thresholdVal + ",capacity=" + capacity);
}
```

所以回答其何时会扩容时,应该是size超过了threshold时,也就是说loadFactor所代表的百分比一旦超过就会发生内存分配.从代码实现层面也是如此

我们来看其另一核心方法,remove如下

```java
public V remove(Object key) {
  Node<K,V> e;
  return (e = removeNode(hash(key), key, null, false, true)) == null ?
    null : e.value;
}
/*
	matchValue 是要key和value都匹配的情况才能移除
	movable 是否移动其他节点,此属性与红黑树有关
*/
final Node<K,V> removeNode(int hash, Object key, Object value,boolean matchValue, boolean movable) {
  Node<K,V>[] tab; // tab临时存放table
  Node<K,V> p; // p存放要修改的元素(利用hash值计算出的对应位置的节点)
  int n, index; // n表示table中的元素个数,index存放hash计算出的索引
  if ((tab = table) != null && (n = tab.length) > 0 &&
      (p = tab[index = (n - 1) & hash]) != null) {
    
    Node<K,V> node = null, e; // node记录清除节点的地址
    K k; V v; // 用来存放key和value即找出的节点的
    if (p.hash == hash && ((k = p.key) == key || (key != null && key.equals(k))))
      // 如果节点的key刚好就是我们要remove的key,那就是要修改的节点了
      node = p; 
    else if ((e = p.next) != null) { 
      // 走到这说明有hash冲突,且我们要找的key在hash冲突里面
      if (p instanceof TreeNode)
        // 如果是红黑树,就按照红黑树的方式去寻找节点
        node = ((TreeNode<K,V>)p).getTreeNode(hash, key); 
      else {
        // 说明是链表的节点,那就找到链表中对应的节点
        do {
          if (e.hash == hash && ((k = e.key) == key || (key != null && key.equals(k)))) {
            node = e;
            break;
          }
          p = e; // 根据循环,最后赋值实际结果是p = e.front;
        } while ((e = e.next) != null);
      }
    }
    
    // matchValue是要不要匹配所以这里有处断点表达,true才执行后面断点,
    // 否则其先决条件就是node!=null,否则触发v的赋值且如果value是空直接不执行
    if (node != null && (!matchValue || (v = node.value) == value ||
                         (value != null && value.equals(v)))) {
      if (node instanceof TreeNode)
        // 按照红黑树方法移除节点
        ((TreeNode<K,V>)node).removeTreeNode(this, tab, movable);
      else if (node == p)
        // 如果是无hash冲突节点,直接移除
        tab[index] = node.next;
      else
        // 这里按照上面逻辑走的话,p指的不再是刚开始的节点,而是和e只差一个
        // 即node = e = p.next,此时p代表的含义是e之前的节点,e的含义是匹配上
        // key的节点
        p.next = node.next; // 直接赋值,中间节点丢失,完成链表的remove
      ++modCount; // 改变结构
      --size;
      afterNodeRemoval(node); // 空实现,留给LinkedHashMap的接口
      return node;
    }
  }
  return null;
}
```

同样作为相对复杂的红黑树,这里不展开细节.其他方法相对简单不少,如get,containsKey

```java
public V get(Object key) {
    Node<K, V> e;
    return (e = getNode(hash(key), key)) == null ? null : e.value;
}
public boolean containsKey(Object key) {
    return getNode(hash(key), key) != null;
}
final Node<K, V> getNode(int hash, Object key) {
  Node<K, V>[] tab; // 存放table
  Node<K, V> first, e; // first存放hash对应index的Node指针
  // e存放first.next.next...的一个遍历用指针
  int n; // 存放table长度
  K k; // 存放e的key
  if ((tab = table) != null && (n = tab.length) > 0 &&
      (first = tab[(n - 1) & hash]) != null) {
    if (first.hash == hash && 
        ((k = first.key) == key || (key != null && key.equals(k))))
      // 如果是匹配上了头结点就返回(此时没有hash冲突)
      return first;
    if ((e = first.next) != null) {
      if (first instanceof TreeNode) // 红黑树的处理
        return ((TreeNode<K, V>) first).getTreeNode(hash, key);
      // 普通链表,找到冲突中能匹配上的节点
      do {
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k))))
          return e; // 返回匹配到的节点
      } while ((e = e.next) != null);
    }
  }
  // 没找到
  return null;
}
```

寻找value是一个低性能的方法,即全部遍历hash表

```java
public boolean containsValue(Object value) {
  Node<K, V>[] tab;
  V v;
  if ((tab = table) != null && size > 0) {
    for (int i = 0; i < tab.length; ++i) { 
      for (Node<K, V> e = tab[i]; e != null; e = e.next) {
        if ((v = e.value) == value ||
            (value != null && value.equals(v)))
          return true;
      }
    }
  }
  return false;
}
```

putAll

```java
public void putAll(Map<? extends K, ? extends V> m) {
    putMapEntries(m, true);
}

final void putMapEntries(Map<? extends K, ? extends V> m, boolean evict) {
    int s = m.size();
    if (s > 0) {
        if (table == null) {
            float ft = ((float) s / loadFactor) + 1.0F;
            int t = ((ft < (float) MAXIMUM_CAPACITY) ?
                    (int) ft : MAXIMUM_CAPACITY);
            if (t > threshold)
                threshold = tableSizeFor(t);
          // 这里其实就看出来,threshold就是临时存放初始化的大小
        }else if (s > threshold)
            resize();
        for (Map.Entry<? extends K, ? extends V> e : m.entrySet()) {
            K key = e.getKey();
            V value = e.getValue();
            putVal(hash(key), key, value, false, evict); // 循环调用putVal
        }
    }
}
```

## HashTable

这是JDK1.0实现的一个数据结构都不属于Collection接口,在此处不多加赘述,其用于线程安全上,但是因为synchronized粒度太大,所以不用.此处就不多介绍此类了,如果要线程安全的类使用下面的ConcurrentHashMap.

## LinkedHashMap

来自JDK1.4,直接继承了HashMap,其代码相对较少,主要是复用了父类的代码.其与HashMap最大的不同应该是底层的数据结构变成一张双链表.这张双链表维护着访问顺序,这样一来可以让LinkedHashMap同时具有链表和HashMap的特性.**其最主要的应用场景就是大型的LRU缓存的实现**.

先看其数据结构,出了hashmap的基本数据结构之外,LinkedHashMap还有如下结构,在前文中可以找到其继承关系

```java
static class Entry<K,V> extends HashMap.Node<K,V> {
  Entry<K,V> before, after; // 双向链表的结构基础
  Entry(int hash, K key, V value, Node<K,V> next) {
    super(hash, key, value, next);
  }
}
transient LinkedHashMap.Entry<K,V> head;
transient LinkedHashMap.Entry<K,V> tail;
final boolean accessOrder; // true 为按照访问顺序访问, false为按照插入顺序访问
```

默认是按照插入顺序进行访问的.通过下列构造器可以改变其accessOrder属性

```java
public LinkedHashMap(int initialCapacity,float loadFactor, boolean 
accessOrder) {
    super(initialCapacity, loadFactor);
    this.accessOrder = accessOrder;
}
```

其put,remove方法如下,可以看到其基本由父类实现方法

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
public V remove(Object key) {
    HashMap.Node<K,V> e;
    return (e = removeNode(hash(key), key, null, false, true)) == null ?
            null : e.value;
  // removeNode方法为HashMap里面的方法,其源码在HashMap里面,如上文提到
}
```

其自己实现的方法如下

```java
public V get(Object key) {
    Node<K, V> e;
    if ((e = getNode(hash(key), key)) == null)
        return null;
    // getNode找到节点之后通过判断标志位，来判断是否调用afterNodeAccess回调方法
    if (accessOrder)
        afterNodeAccess(e);
    return e.value;
}

public boolean containsValue(Object value) {
    for (LinkedHashMap.Entry<K, V> e = head; e != null; e = e.after) {
        V v = e.value;
        if (v == value || (value != null && value.equals(v)))
            return true;
    }
    return false;
}

public void clear() {
    super.clear();
    //自身维护的大链表头尾节点head、tail置空
    head = tail = null;
}
```

从containsValue中我们可以看到头指针在遍历,所以LinkedHashMap维护的链表结构不只是针对HashMap中的数组元素的,其针对的是所有加入HashMap中的元素,以他们的先后顺序维护起一个链表,这个方法就是通过实现HashMap中的一些空实现的函数接口实现的(例如afterNodeAccess)

这个做法让HashMap具有的链表的特性,使其可以通过链表的方法来进行索引,能够记录加入顺序.但因为其相当于多了额外的一些指针,所以所用的空间以及在执行这个链表的维护时候额外消耗的一些时间都要被考虑进去,如果是针对于一般场景使用HashMap足够了,如果需要快速索引,又需要额外的维护记录加入顺序(比如某些特殊的队列)就可以用该数据结构进行实现.

我们看下此链表的维护方法的实现

```java
private void linkNodeLast(LinkedHashMap.Entry<K, V> p) {
    LinkedHashMap.Entry<K, V> last = tail;
    tail = p;
    if (last == null)
        head = p;
    else {
        p.before = last;
        last.after = p;
    }
  // 很标准的双向链表的维护,没啥可说的
}
// putVal里面封装成节点的时候使用该方法
Node<K, V> newNode(int hash, K key, V value, Node<K, V> e) {
    LinkedHashMap.Entry<K, V> p =
            new LinkedHashMap.Entry<K, V>(hash, key, value, e);
    linkNodeLast(p);
    return p;
}
TreeNode<K, V> newTreeNode(int hash, K key, V value, Node<K, V> next) {
    TreeNode<K, V> p = new TreeNode<K, V>(hash, key, value, next);
    linkNodeLast(p);
    return p;
}

// 实现了父类的空实现,该方法在removeNode里面有被调用
void afterNodeRemoval(HashMap.Node<K, V> e) {
  LinkedHashMap.Entry<K, V> p = (LinkedHashMap.Entry<K, V>) e, 
  b = p.before, // 记录前驱
  a = p.after; // 记录后继
  p.before = p.after = null; // 删除该节点的前驱后继
  if (b == null)
    head = a; // 前驱为空则是头结点
  else
    b.after = a; // 否则删除前驱节点的后继指针
	
  // 同理如是维护该节点的后继节点即可
  if (a == null)
    tail = b;
  else
    a.before = b;
}
```

还有一方法比较重要单独拿出来说.afterNodeAccess,前文所述有两种顺序,一种是按照加入顺序进行访问,另一种是按照访问顺序进行访问,后者要表达的意思是,如果访问了某个节点,那么该节点的会被`提前`这个时候我们就可以解释afterNodeAccess方法是把最近访问的节点移到链表的尾部(因为在尾部的节点都是最新加入的节点)

```java
// 用于将被访问到的节点移动到大链表末尾
void afterNodeAccess(Node<K, V> e) { // move node to last
  LinkedHashMap.Entry<K, V> last;
  // 如果e不是尾节点，那么尝试移动e到尾部
  if (accessOrder && (last = tail) != e) {
    LinkedHashMap.Entry<K, V> p =(LinkedHashMap.Entry<K, V>) e, 
    b = p.before,
    a = p.after;
    // 移动到尾部的思路是删除节点的前后关系,然后在把尾节点.after=现在节点
    // 然后在更改尾部就可以了
    
    p.after = null;
    if (b == null) // p为头结点
      head = a;
    else
      b.after = a;
    
    if (a != null)
      a.before = b;
    else // p为尾结点
      last = b;
    
    
    if (last == null) // 当只有一个节点的时候会发生这个情况,即b=null且a=null
      head = p; //  至于尾部属于相同操作在后面
    else {// 就是正常节点,加入链表尾部
      p.before = last;
      last.after = p;
    }
    tail = p; 
    ++modCount; // 结构更改次数自增
  }
}
```



## 红黑树

-   未完待续

## LRU缓存的实现思路

其实看LinkedHashMap就给我们提供了一种实现,我们也知道作为一个双端链表如何实现,那就是如果访问元素的时候调用一个方法,把该元素放到链表/队列尾部.

而至于有限制大小的LRU缓存则更好实现,采取压栈的方式即可实现.不过考虑到数组的扩容问题,我们可以实现逻辑栈,即利用栈的指针,如果重复就冒泡上去可以解决问题,如果上面的操作经常遇到命中缓存的情况,我们可以按照循环队列的思路添加固定的元素,只要申请两倍于缓存大小的空间,便可通过循环队列来命中存在的元素,不过在命中过程中还是要进行搜索且空间复杂度更大.

如果是链表等链式结构要实现上面的栈,可以参考LinkedHashMap的思路,用LinkedList进行实现即可.相比较而言,双向链表具有更强大的性能,消耗的空间复杂度(指针数据的一倍).如果是链表很长,完全可以直接使用LinkedHashMap去实现.

## 关于数据结构的总结

从上面的种种数据结构中我们可以分为普通结构和索引结构,各种数据结构又可以互相融合即只要适当的增加指针域就能让数据结构具有其他数据结构的特性,上面的两种索引**红黑树**和**HashMap**更是可以极大的提高索引的效率.极大的优化了内存的访问,而其他的普通结构的数据结构解决的问题主要是扩容.总而言之,每个数据结构在不同的应用场景下有不同的性能合理的利用这些数据结构才能提高系统的整体性能

## JUC容器

JUC容器是一类特殊的数据结构,因为JUC就是为了解决线程安全而存在的,他们又基于AQS同步队列和基本的锁,这些工具共同作用着下面这些数据结构的形成,而下面这些数据结构也是为了解决线程安全而存在的,具有细粒度的锁和相对较高的性能,但无线程安全问题时,应当尽量使用上面的非线程安全的数据结构来解决问题

### CocurrentHashMap



### LinkedBlockingDeque



### CopyOnWriteArrayList



