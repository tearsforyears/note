# Vue.js

---

前置知识是node 当然脱离了node也能开发 属于视图层的组件

和spingboot能完美配合

Vue.js/请求库 是前后端分离的核心组件

Vue.js响应式的Listener模式使得应用可以脱离开本身

程序员只用专注处理数据和渲染

Vue 是一个渐进式框架 支持声明式渲染

## 使用感受

更像是一套管理命名空间和形成组件化的机制

动态分离数据和应用而不做单独渲染

更贴近html本身的语法而并非应用大量js

也不像其他渲染模板乱七八糟的语法规则 而是利用html的属性来实现

就好比SpringMVC在web中的实现而并非structs 设计理念即是轻量级

[TOC]

## code-review

-   安装导入
-   生命周期
-   基础指令格式
-   **v-bind** 数据绑定
-   v-once final
-   v-style 样式绑定
-   v-html 解释为html
-   **v-if** 条件渲染
-   v-show 条件可见
-   **v-for** 循环 v-key 唯一表示
-   v-on /@ 绑定事件
-   v-model 语法糖 双向绑定
-   组件 Vue.component
-   单组件文件 *.vue 文件详解
-   webpack-vue项目的基本结构与打包

## 安装或导入

```html
<script src="https://cdn.jsdelivr.net/npm/vue@2.6.11"></script>
```

```shell
npm install vue
```

helloworld程序

```html
<div id="app">
    {{message}} {{name}} {{nick}}
</div>
<script>
  	var data = {
      message: "hello vue",
      name:"app",
    }
    var app = new Vue({
        el: "#app",
        data: data
    });
    // new Vue();传入一个json对象指定其el元素选择器 以及变量即可
  	data.name = "new vue1"; // 会改变值  
  	data.nick = "new vue2"; // 不会改变值 因为在new的时候没这个属性
</script>
```

这个el的机制只针对找到的第一个元素剩下都不归vue管理 所以建议全部使用id不要使用class和标签 **vue对象的命名空间只能有一个** 哪怕data换成function f(){return {}}的形式也不行

## 生命周期属性

实例化-创建(观测)-挂载-更新

```js
new Vue({
  el:"",
  data:{}, // 除了两个最常见的属性之外 还有一些调用函数 如下按顺序
  beforeCreate:function(){}, // 实例初始化之后 数据观测之前
  create:function(){}, // 实例创建完成后
  beforeMounted:function(){}, // 挂载前调用
  mounted:function(){},
  
  beforeUpdated:function(){},
  updated:function(){},
})
```

除此之外还有其他一些actived,deactivated,beforeDestory

## 指令格式

带有v-开头的被称为vue里面的指令 下面的v-bind就是一个典型的指令 其格式如下

***v-指令名字:参数.修饰符***

## v-bind:attribute="var_name"

v-bind指令动态绑定html标签的属性,可以是Vue里面的数据或者类

```html
<div class="app">
  <p v-bind:class="p_class"></p> <!--动态绑定类名-->
</div>
<script>
  new Vue({
    el:".app", // 其实说是元素 其实理解为作用域更好
    data:{
      p_class = "p", // 作用域下的变量导入作用域中的{{}}或者v-bind等
    }
  })
</script>
<script>
  new Vue({
    el:".app", // 其实说是元素 其实理解为作用域更好
    data:function(){
      return {
      	p_class = "p", // 作用域下的变量导入作用域中的{{}}或者v-bind等
    	}
    }
  })
</script>
```

上面我们看到了v-bind 和普通的new vue()可以给html绑定动态属性 或者添加vue中变量的值

除了普通的值之外我们还可以绑定方法

```html
<div class="app">
  <div @click.stop="click1"> 
    <!--如果外侧还有点击事件会连续触发 这里.stop修饰符阻断了其他事件的触发-->
    aabbcc
  </div>
</div>
<script>
  new Vue({
    el:".app",
    methods:{
      click1:function(){},
    }
  })
</script>
```

v-bind除了直接绑定vue命名空间的变量以外还提供以下的绑定方式

```html
<div v-bind:src="url"></div>
<div v-bind:class="{value:bool}"></div> 
<!--bool 是vue命名空间的boolean变量 决定要不要用value-->
<div v-bind:class="{value1:bool1,value2,bool2}"></div> 
<!--绑定多个-->
<div v-bind:class="['value1','value2']"></div> 
<!--支持数组绑定多个-->
<div v-bind:class="[bool1 ? 'value1':'' , bool2 ? 'value2':'']"></div> 
<!--动态绑定-->
```

## v-style

和v-bind类似 用于绑定属性

有两种写法

```html
<div v-style="color:red;"></div>
<div v-style="{color:'red'}"></div>
```



## v-once 相当于final 只允许第一次赋值

## v-html 和 {{text}} 渲染

```note
{{text}} 把 text 当成一个变量去vue组件里面找对应data的text属性
此外还可以当js表达式的输出框使用 例如{{ 3 + 1 * 2 }}
但只支持一些简单的可输出的表达式而非完整的js代码
```

```note
<p v-html="text"></p> 表示把 text的内容当成html 塞进p标签里面
```

## v-if 条件渲染

只有为真的时候才渲染

```html
<div class="app">
  <div v-if="age<12">
    儿童
  </div>
  <div v-else-if="age<16">
    少年
  </div>
  <div v-else-if="age<18">
    青年
  </div>
  <div v-else>
    成年
  </div>
</div>
<script>
	var app=new Vue({
    el:".app",
    data:{
      age:16,
    }
  })
</script>
```

## v-show 

可见渲染和v-if差不多 不过是改变display属性的可见并不像v-if的加载

v-show = true时才可见 由vue管理命名空间

## v-for

```html
<table class="table">
    <thead>
        <td v-for="data in th">{{data}}</td>
    </thead>
    <tr v-for="item in list" v-bind:key="item">
        <td>{{item.r1}}</td>
        <td>{{item.r2}}</td>
    </tr>
</table>
<script>
    new Vue({
        el: ".table",
        data: {
            th: ["r1", "r2"],
            list: [{r1: "r11", r2: "r22"}, {r1: "r11", r2: "r22"}]
        },
    });
</script>
```

这里还指定了v-bind:key="item" 这并不会改变html代码 但是有利于Vue的虚拟dom维护

利用其它api可以重新渲染 如果js有多次渲染在vue中不会直接渲染而是会通过计算之后渲染

v-for可以嵌套遍历js list 但是对于json对象的属性有个反人类的设计 

```html
<tr v-for="item in list">
    <td v-for="value in item">{{value}}---{{item}}</td>
</tr>
<script>
	new Vue({
    el:"",
    data:{
      list: [{r1: "r11", r2: "r22"}, {r1: "r11", r2: "r22"}]
    }
  })
</script>
```

以下为其5中方式

```html
<div v-for = "item in list"> <!--遍历list-->
<div v-for = "(item,index) in list"> <!--遍历list-->
<div v-for = "value in json"> <!--遍历json-->
<div v-for = "(value,key) in json"> <!--遍历json-->
<div v-for = "(value,key,index) in json"> <!--遍历json-->
```

## v-on

v-on用于绑定事件 methods属性可以完成方法名 也可以用@click="click1" 绑定

```html
<div id="app">
    <p>{{msg}}</p>
    <button v-on:click="click1">反转</button>
</div>
<script>
    new Vue({
        el: "#app",
        data: {
            msg: "hello world",
        },
        methods: {
            click1: function () {
                console.log(this);
                this.msg = this.msg.split("").reverse().join("");
            }
        }
    });
</script>
```

## v-model

v-model v-model.lazy 一般用于绑定在input组件上 

之前像checkbox并不好用 vue2.x改变使得input监听oninput checkbox监听onchange

v-model实现了双向绑定 这里需要注意的是

radio在vue中声明变量需要用字符串去存v-model

而checkbox 需要用[]的形式去存v-model

其本质是语法糖(和泛型一样的轻编译)

```html
<input v-model="sth" />
<input v-bind:value="sth" v-on:input="sth = $event.target.value" />
<!--oninput事件 输入时触发 -->
```

一个生成表单的demo

提交函数可以通过@click="submit" 或者@submit.prevent="submit($event)" 指定

或者是使用最原始的方式

```html
<form id="form">
  <input v-model="msg"/>
  <button @click="submit">submit</button>
</form>
<form id="form" @submit.prevent="submit($event)">
  <input v-model="msg"/>
  <input type="submit" value="login" />
</form>
<script>
new Vue({
  el:"#form",
  methods:{
    submit:function(){
      let form = new FormData();
      form.append(this.msg)
      axios.post('/user',form).then(res => {
            // success callback
      }).catch(err => {
            // error callback
      });
    }
  }
})
</script>
```

## 组件

高度复用html代码 模块化程度提高 是vue的核心技术 使其逐步脱离纯粹的页面渲染形成高效组件配置的代码模式

一定要在Vue管理的命名空间之下才可以使用组件

```html
<div id="div">
    {{test}}
    <button-counter title="hello "></button-counter>
    <br>
    <button-counter title="hello "></button-counter>
    <br>
</div>
<script>
    Vue.component("button-counter", {
        props: ['title'], // 为组件定义属性 在上面就可以调用
        data: function () { // 定义数据
            return {
                count: 0,
                style: "color:red;",
            }
        },
        template:
            '<div>' +
            '<button v-on:click="clickFunc" v-bind:style="style">' +
            '{{title}} count : {{count}} times' +
            '</button>' +
      			'<solt></solt>' + // solt是一个插槽 可以内嵌html
            '</div>',
        // 模板的html代码 但一定得是只有一个根节点的元素
        methods: {
            clickFunc: function () {
                this.count++;
            }
        }
    });
    var vm = new Vue({
        el: "#div",
        data: function () {
            return {
                test: 3,
            }
        },
    });
</script>
```

关于为什么组件的data是个函数 那是因为 按传入方法我们可以知道component是静态函数

其data所对应的东西如果是**{ }**的话 那么所有组件都持有一样的属性 自然不可以 所以要每多一个组件多一份数据 使用function(){return **{ }** }等形式包裹数据而非使用原来的普通json对象而其他Vue({})时 命名空间内的属性应该是共享的故可以直接写之前我们写的形式

this.$emit("function_name",...param) // 可以调用全局的函数

## 组件注册

Vue.component 这种组件是全局注册的

所以我们需要局部注册 如下

```js
new Vue({
  el:"",
  data:{},
  methods:{},
  components:{
      comp1:{ // 以局部注册的方式去注册组件 只要在当前命名空间下组件都可用标签直接写
        template:"<h1>hello</h1>",
        methods:{},
        props:[],
        data:function(){return {}},
      },// 标签就用<comp1></comp1> 这种形式使用
    	
   }
})
```

## *.vue单文件组件

单组件文件 对于大型项目的构建很有用

单组件文件是独立的vue组件由如下三个标签构成的html组件就是vue的意义

```html
<template></template> <script></script> <style></style> 
```

这里需要理解import,export,export default 由其构建基本的组件环境

App.vue 的例子 尽量不要在export default 以外写代码 

```vue
<template>
  <div id="app">
    <img id="img" src="./assets/logo.png">
    <HelloWorld/>
    <el-button @click="logClick">Button</el-button>
  </div>
</template>

<script>
import HelloWorld from './components/HelloWorld'
import $ from 'jquery'
alert('hello page') 
// 编写一些加载代码 比如登录判断定向之类的 但是这类代码也只在页面一级的组件时候编写

export default {
  name: 'App',
  components: {HelloWorld},
  methods: {
    logClick: function () {
      console.log($('#img').attr('src'))
    }
  }
}
</script>

<style>
  #app {
    font-family: 'Avenir', Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
  }
</style>
```



## vue的项目基本结构的创建与打包

vue项目与平常的web项目有很大区别 不要用webstorm去创建

构建vue+element-ui+axios整合前端

基础环境 node.js axois库

brew install brew

npm install axios --save

npm install vue-cli -g 安装vue-cli 方便创建脚手架

cnpm install vue

cnpm install webpack -g 安装webpack

***基础环境准备完毕 开始创建项目***

[element-ui](https://element.eleme.cn/2.0/#/zh-CN/component/quickstart)

### ***1. vue init webpack project_name 创建好vue项目***

这里创建的时候有一个坑ESLint不要选 这个会进行非常严格的检查

然后其实按照README.md其实已经可以运行大部分功能了

npm install babel-plugin-component -D 借助babel只要引入相应组件即可不用全部引入

vue add element  直接引入组件

npm install babel-preset-es2015 --save-dev  引入一个插件

项目的各个目录作用如下

![](https://img-blog.csdnimg.cn/20190611223319346.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjYwMzAwOQ==,size_16,color_FFFFFF,t_70)

***npm install 可以用于安装依赖***

修改.babelrc

```js
{
  "presets": [["es2015", { "modules": false }]],
  "plugins": [
    [
      "component",
      {
        "libraryName": "element-ui",
        "styleLibraryName": "theme-chalk"
      }
    ]
  ]
}
```

在main.js里面用axios

```js
import axios from 'axios'
Vue.prototype.axios=axios // 可以全局用了 以后只用this.axios.get()就行了
```

配置好之后 ***npm run dev*** // 启动开发服务器 开发vue项目

当写好了之后打包(***npm run build***) // 把/static换成./staitc 打开静态页面就可以了

## webpack-vue配置文件相关

.vue 运行机制 https://blog.csdn.net/uwenhao2008/article/details/80752642

webpack是加入了混淆压缩之后的package的打包 减少了前端请求的负载

其可以整合一些第三方的库 是前端大型架构的基础 等同于maven之于javaee

下面说一些项目里面的文件

-   package.json 第三包安装文件夹
-   dist 输出文件夹 `npm run build可以创建`
-   build webpack文件 配置
-   src/main.js 开发目录和程序入口 里面import了组件和初始化设置

可以先修改package.json文件中的devDependencies和dependencies，然后再输入npm install进行一次性安装

比如我要引入jquery

1.在dependencies  "jquery": "^2.2.3"

2.build/webpack.base.conf.js

```js
//注：...代表省略自有的，
//必定事先声明webpack，不然下面会不识别webpack
const webpack = require('webpack')
...
module.exports = {
    resolve: {
        ...
        alias: {
          ...
          'jquery': 'jquery' 
        }
    },
    plugins: [
        new webpack.ProvidePlugin({
          $: "jquery",
          jQuery: "jquery",
          "windows.jQuery": "jquery"
        })
    ],
    ...
}
```

3、在main.js中加入：import $ from 'jquery'

要打包的时候修改/config/index.js 把静态文件的路径修改 这样就不用修改最后的路径了

```js
build:{
		assetsSubDirectory: './static',
    assetsPublicPath: './',
}
```

## 多页面vue开发

本质上就是配置webpack 不过作为后端 使用这个还不如看文档

/build/webpack.base.conf.js

```js
// 文件路径更具自己的实际情况进行配置,我这仅是 demo
entry: {
    app: './src/main.js',
    one: './src/js/one.js', // 要配置页面的名字
    two: './src/js/two.js'
  },
```

/build/webpack.dev.conf.js

```js
new HtmlWebpackPlugin({
      filename: 'index.html',
      template: 'index.html',
      inject: true,
      chunks: ['app'] // 指的是webpack.base.conf里对应的变量名
    }), 
    new HtmlWebpackPlugin({
      filename: 'one.html',
      template: 'one.html',
      inject: true,
      chunks: ['one']
    }),
    new HtmlWebpackPlugin({
      filename: 'two.html',
      template: 'two.html',
      inject: true,
      chunks: ['two']
    }),
```

/config/index.js 打包之后dist形成的html文件 

开发模式的话要按照下面路径建立两个html

```js
index: path.resolve(__dirname, '../dist/index.html'),
one: path.resolve(__dirname, '../dist/one.html'),
two: path.resolve(__dirname, '../dist/two.html'),
```

/build/webpack.prod.conf.js

```js
	new HtmlWebpackPlugin({
        filename: config.build.index,
        template: 'index.html',
        inject: true,
        minify: {
            removeComments: true,
            collapseWhitespace: true,
            removeAttributeQuotes: true
            
        },
        chunksSortMode: 'dependency',
        //(在这里和你上面chunks里面的名称对应)
        chunks: ['manifest', 'vendor', 'app']
    }),
    new HtmlWebpackPlugin({
        filename: config.build.one,
        template: 'one.html',
        inject: true,
        minify: {
            removeComments: true,
            collapseWhitespace: true,
            removeAttributeQuotes: true
        },
        chunksSortMode: 'dependency',
        chunks: ['manifest', 'vendor', 'one']
    }),
    new HtmlWebpackPlugin({
        filename: config.build.two, // 这里改
        template: 'two.html', // 这里改
        inject: true,
        minify: {
            removeComments: true,
            collapseWhitespace: true,
            removeAttributeQuotes: true
        },
        chunksSortMode: 'dependency',
        chunks: ['manifest', 'vendor', 'two'] // 这里也要改成页面名字
    }),
```

多组件解决语法冲突

test.vue test_init.js 一定不要重名 debug3小时wdnmd

要加载ElementUI需要加载解析器什么的 得下载其他东西挺麻烦

可以一个个组件引入 挺好用

前端而言就用vue+elementui 挺够用的 在前后端分离而言

暂告一段落 结合spirngboot调试的时候补充

## 前后端整合

对后端程序员而言vue用的相对没那么多,主要针对vue进行一系列部署讲解

vue打包命令 `npm run build`