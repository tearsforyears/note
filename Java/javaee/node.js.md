# node.js

---

node 是 js的运行环境 基于Google V8

web框架 express来看和python-flask比起来 get请求的代码更加简洁 可是post处理的并不好 依然是专门定位于写非常小型的 最好全部是get请求的程序 最好最好不要有文件上传 和 flask定位相似

不建议使用太过于复杂的数据层 sqlite 这种数据库 更加适合node.js 

定位是应用型组件

[TOC]

## index

-   ECMAScript 6
-   node.js

### ECMAScript6

js本质是单线程执行的函数 一些事件机制由轮训执行 所以js有其本身的特性 

比如简单 不易于异步等

-   let和var的运行机制:let 局部生成 var 编译时预定义

-   箭头函数()=>{} 这个this机制符合人类习惯 

    ***箭头函数不绑定this，会捕获其所在的上下文的this值，作为自己的this值 而普通函数只向上层对象***

-   基本数据结构

```javascript
new Map(); new Array(); new Set(); []
```

-   class面向对象

```javascript
class Pojoclass Rectangle extends Shape{
    constructor(height, width) {
        this.height = height;
        this.width = width;
    }
  	static hello(){alert("hello")}
}
new Rectangle(3,4);
```



-   Json 写法与调用

    ​	从其他语言我们知道json是种key-value都是string的字符串

    ​	而在js其原生环境中json的key直接映射了属性,而非字典结构的字符串

```javascript
var json ={
  key:"value",
  print:()=>{console.log("hello json")}
}
// 遍历json的key
for(let key in json)
  console.log(key)
```

-   Timer执行机制:setInterval setTimeout clearTimeout clearInterval

    典型的js异步机制 js是单线程语言其执行事件的机制是利用事件消息队列

    第一次调用的时候都是先延时后执行的 等全部加入队列之后按顺序启动定时器

    setTimeout是在事件完成后去调用下一次定时器

    setInterval是到达规定事件就忘事件队列里面插一个事件

    其执行机制是直接执行

```javascript
var intervalId, timeoutId;

timeoutId = setTimeout(function () {
    console.log("out"+1);
}, 300);

setTimeout(function () {
    clearTimeout(timeoutId);
    console.log("out"+2);
}, 100);

setTimeout(()=>{console.log("out"+"5")},400);

intervalId1 = setInterval(function () {
    console.log("out"+4);
    clearInterval(intervalId1);
}, 201)

intervalId2 = setInterval(function () {
    console.log("out"+3);
    clearInterval(intervalId2);
}, 200)
```

-   可变长度参数和默认参数:和java类似 function(...param){} ...param可以引动list转换成相应长度的参数,有类似python中的默认参数机制
-   按位置拆箱,类似python中 a,b = b,a的机制

```javascript
var f=()=>{return [1,2,3]};
let [a,b,c] = f();
```

-   占位符变量替换${}

```javascript
let i = 3;
console.log("i=${i}")
```

-   Generator语法

    和python几乎一致 或者手动调用.next 方法

-   ***Promises***

    这个类涉及到异步 非常重要 在使用axios的时候 基本都用到这个类的一些子类

    下面简单说明下axios的执行逻辑

```javascript
var p = new Promise(function(resolve, reject) {  
  if (/* timeout or request success*/) {
    resolve(response);  
  } else {
    reject(error);  
  }
});
p.then((response)=>{
  	console.log(response.data);
    console.log(response.status);
    console.log(response.statusText);
    console.log(response.headers);
    console.log(response.config);
}).catch((error)=>{
  	console.log("请求失败");
})
```

-   import export 和export default

    这三个东西是ES6模块化的核心

    import 导入 export 导出 export default 默认导出 一个js里面只能有一个

    在vue中以name属性命名导入

```js
import {function_name} from 'path/filename' // import filename.js
import {function_name1,function_name2} from 'path/filename' // import muti
```

```js
export function login(){} // 导出函数
export var name='hey' // 导出变量
var username=''
var key={}
export {username,key} // import {username,key} from ...
```

```js
export default var name='hey' // import name from ... do not need {}
export default {} // import * from
```

### Node.js

Node 是 js 独立于浏览器的运行环境 npm install 和 pip install 有类似的功能

-   基本运行

    node hello.js 就可以运行js程序了和python hello.py 差不多了

-   模块

    ```javascript
    // main.js
    var module = require('./hello'); // 创建模块 等同import ./hello.js
    module.f();
    // hello.js
    module.exports = function f(){} // 把自己的函数封装到模块中 就可以在main中调
    ```

-   异步IO

    ```javascript
    var fs = require("fs");
    // 异步读取
    fs.readFile('input.txt', function (err, data) {
       if (err) {
           return console.error(err);
       }
       console.log("异步读取: " + data.toString());
    });
    
    // 同步读取
    var data = fs.readFileSync('input.txt');
    console.log("同步读取: " + data.toString());
    ```

-   服务端程序

    ```javascript
    var http = require("http"); // 原生模块不用写文件路径
    http.createServer();
    ```

    一个简单的demo 启动飞速

    ```javascript
    var http = require("http");
    
    function onRequest(request, response) {
      response.writeHead(200, {"Content-Type": "text/plain"});
      response.write("Hello World");
      response.end();
    }
    
    http.createServer(onRequest).listen(8888);
    ```

    express框架 (webstrom支持)

    一个controller框架 像orm框架也有不少 爬虫也能使用这个发请求
    
    npm install express-generator -g
    
    ```js
    var express = require('express');
    var app = express();
     
    app.get('/', function (req, resp) {
       resp.send('Hello World');
    })
     
    var server = app.listen(8081, function () {})
    ```
    
    app的方法
    
    app.listen
    
    app.use('/static', express.static('static')); // 使用静态目录
    
    req的方法
    
    req.app 访问express对象
    
    req.hostname
    
    req.body
    
    req.cookies
    
    req.params // 路由param
    
    req.query // 请求字符串
    
    req.query.param // 获得请求参数的值 wdnmd太快了
    
    resp的方法
    
    resp.app
    
    resp.append // 追加http头
    
    resp.cookie(key,value)
    
    resp.json // 传送json响应
    
    resp.jsonp // 传送jsonp响应 
    
    resp.send // 传送 普通html代码
    
    
    
    ### express解析post请求
    
    post请求根据不同参数有4种 借助中间件body-paser来解析post
    
    1.表单**application/x-www-form-urlencoded**
    
    ```js
    var bodyParser = require("body-parse");
    var app = express();
    
    app.post('/urlencoded', bodyParser.urlencoded({extend:true}), function (req, res) {  
     var result = {
       name: req.body.name,    
       sex: '男',    
       age: 15  
     };  
     res.send(result);
    });
    ```
    
    2.文件上传**multipart/form-data** 借助**multiparty**插件 需要npm install
    
    ```js
    app.post('/formData2', function (req, res) {  
     // 解析一个文件上传  
    var form = new multiparty.Form();  
    //设置编辑  
    form.encoding = 'utf-8';  
    //设置文件存储路径  
    form.uploadDir = "upload/";  
     //设置单文件大小限制  
    form.maxFilesSize = 2000 * 1024 * 1024;  
    form.parse(req, function (err, fields, files) {    
       var obj = {};    
       Object.keys(fields).forEach(function (name) {      
         obj[name] = fields[name];    
       });    
       Object.keys(files).forEach(function (name) {      
         if (files[name] && files[name][0] && files[name][0].originalFilename) {        
           obj[name] = files[name];        
           fs.renameSync(files[name][0].path, form.uploadDir + files[name][0].originalFilename); 
         }    
       });    
       res.send(obj);  
      });
    });
    ```
    
    3.**application/json** post的json请求
    
    ```js
    app.post('/applicationJson', bodyParser.json(), function (req, res) {  
    var result = {    
      name: req.body.name,    
      sex: '男',    
      age: 15  
     };  
      res.send(result);
    });
    ```
    
    4.**text/xml** 比较少用
    
    ```js
    app.post('/textXml', bodyParser.urlencoded({extend:true}), function (req, res) {  
      var result = ''; 
      req.on('data', function (chunk) {    
      result += chunk;  
      });  
      req.on('end', function () {    
      res.send(result);  
      });
    });
    ```
    
    该程序还可以连接mysql和mongodb
    
    打包可以用webpack等
    
    是轻量级开发的必备组件
