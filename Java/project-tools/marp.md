# marp

---

这是一个markdown2ppt的工具

5分钟搞出ppt的神器

---

## boot

### terminal使用

`npm install --save-dev @marp-team/marp-cli` npm安装

`npx marp --pptx --allow-local-files 文件名` 转ppt

`marp 文件名` 转html (可演示版本)

### vscode使用

下载vscode插件Marp for VS Code即可

如果要导出则用GUI的方式找到`Export slice desk`

---

## 基本语法

```marp
---
marp: true
size: 16:9
color: #000
paginate: true
theme: gaia
header: '**header**'
footer: '** footer**'
# yaml comment
```

marp头标记 标定整个文件的属性信息

单页可以用`<!-- _size: 4:3-->` 这种注释方式来标定属性

如果想让全局使用可以换成`$`即`<!-- $size: 4:3-->`

`---`换slice页面

## 插入图片

`![w:200px, h:400px](image.png)` 带长宽的图片和markdown语法一致

`![bg cover](background.png)`图片覆盖方式为背景

## 自定义css

一般而言自己能操控css就能解决绝大部分布局了

只要知道渲染成最后html的格式就知道css该给哪些元素加上css

```css
<style scoped>
    h1{
        color:red;
        text-align:center;
    }
    h5{
        text-align:center;
    }
    li{
        color:white;
        text-align:center;
    }
</style>
```

在每页前面加上去即可控制单独的页面





