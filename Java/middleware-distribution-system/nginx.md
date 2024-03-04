# nginx

---

brew install nginx

`/usr/local/Cellar/nginx` 是home brew的安装目录

`nginx -s reload` 重启nginx服务器

`nginx -s stop` 停止服务器 记得加sudo

配置文件 `/usr/local/etc/nginx/nginx.conf`

web的文件目录`/usr/local/Cellar/nginx/1.17.9/`

## 部署vue

打包vue会有大大小小的坑

```note
config/index.js assetsPublicPath: './', // build 
router.js mode: "history", // 去除#
publicPath: '../../' // build add // element.ui 报错解决
```

打包好后dist扔到nginx上

```conf
	upstream man-backend {
        ip_hash;
        server localhost:9001;
        server localhost:9002;
        server localhost:9003;
    }
		# 负载均衡服务器集群
    
    server {
        listen 8000;
        server_name localhost;
        location / {
            proxy_pass http://man-backend;
            proxy_redirect default;
        }
    }
    # nginx 映射8080
    
    server {
        listen 80;
        location / {
            root dist;
            index index.html;
            try_files $uri $uri/ /index.html; // vue中#的文件不认官方解决方案
        }

        location ^~/api/ {
            proxy_pass http://127.0.0.1:8000/;
            proxy_redirect default;
        }
        // 反向代理localhost:80/api/接口到127.0.0.1:8080/
        // 如果proxy_pass后面有/那么就跟到api的路径后面，其他就带上原路径代理
    }
```

