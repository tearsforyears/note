# xpath

-   这是一种比css选择器更加简单的语言,css选择器在python中借助`pyquery`去实现,而xpath需要借助`lxml`去实现.
-   除了在vue的数据驱动比较少用外,基本`js`,`jquery`,`dom`,`vue`,`chrome`等也对xpath进行了支持
-   xpath比起css拥有更加近似路径解析节点的优势,更容易去记忆和查询,而不是使用复杂的伪类选择器

## 基本使用

我们对下面的xml文档遍历出带href属性的a节点

```xml
<html>
	...
  <span href="success"></span>
  <a href="javascript:void(0)">click for nothing</a>
  <a>just an a tag</a>
	...
</html>
```

在chrome的debug中即可这样使用

```js
$("a[@href]") // css选择器 .是类选择 #是id选择 直接写是标签选择
$x("//a[@href]") // xpath选择器
```

js的使用相对复杂

```js
domcument.queryselector("a[@href]");

var result = document.evaluate("//a[@href]", document, null, XPathResult.ANY_TYPE, null);
var nodes = result.iterateNext(); //枚举第一个元素
while (nodes){
    // 对 nodes 执行操作;
    nodes=result.iterateNext(); //枚举下一个元素
}
```

使用python原生(scrapy对xpath也有良好的支持)

```python
from lxml import etree

tree = etree.parse("test.xml") # HTML文档路径或者类似对象或link
# tree = etree.HTML("<root></root>") # 参数只能是txt
tags = tree.xpath('//root')

for tag in tags:
  print(tag)
```

## 基本语法

```xml
<bookstore>
<book>
  <title lang="eng">Harry Potter</title>
  <price>29.99</price>
</book>
<book>
  <title lang="jp">Learning XML</title>
  <price>39.95</price>
</book>
</bookstore>
<bookshop>
<book>
  <title lang="eng">Harry Potter</title>
  <price>29.99</price>
</book>
<book>
  <title lang="jp">Learning XML</title>
  <price lang="nm">39.95</price>
</book>
</bookshop>
```

-   基本路径分级
    -   `/` 从根节点选取 开头不写默认是/
    -   `//` 从任意子孙节点选取
    -   `.`选取当前节点
    -   `..`选取上级节点
    -   `*` 选取所有节点
    -   `@attr`选取属性值

```js
$x("/bookshop") // 选取根节点下的bookshop节点
$x("bookshop//book") // 选取bookshop所有book节点
$x("//title/..") // 选取所有book节点(title的上级节点)
$x("//price/../title/@lang") // 选取title的lang属性值
$x("//book/*") // 选取book下的所有节点
$x("//title/@*") // 选取title标签的所有属性
```

-   选取内容
    -   `[@attr]`过滤是否含有属性
    -   `[@attr="val"]` 过滤属性值
    -   `[1]` 选取第一个元素
    -   `text()` 选取innerHTML文本内容

```js
$x("//book[2]") // 选取两个书店的第二本书(从1开始而不是从0)
$x("//title[@*]/text()") // 选取带有任何属性的title
$x("//title[@lang='en']/text()") // 选取title标签lang属性的值为en的
$x("//title/text()") // 选取标题内容
$x("//title[text()='Harry Potter']/@lang") // 选取title里标签为harry potter的
$x("//book/*[@lang]/text()") // 选取book下所有带有lang属性的标签的内容
/**
	在每个同级节点内[]中可以访问到该节点的属性@attr
	可以访问到节点的下级元素比如下面的book和price
**/
$x("//book[price/text()>35]/title/text()")  
```

-   利用函数完成更强大的功能
    -   normalize-space(str) str转换成不带空格的字符串
    -   contains(a,b) 字符串a中是否含有字符串b

```js
$x("//title[contains(@lang,'en')]/text()") // title的lang属性里面以en开头的元素的text值 这个用法还可以用在其他的class类的字符串匹配上

$x("//book[normalize-space(price/text())='39.95']/title/text()")
// book底下的price等于39.95的书的标题的内容
```

