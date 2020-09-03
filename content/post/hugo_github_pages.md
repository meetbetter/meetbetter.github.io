---
title: "Hugo_github_pages"
date: 2020-08-30T23:03:59+08:00
description: ""
draft: false
tags: []
categories: []
---



记录将博客从hexo迁移到hugo的过程。hugo + github pages + typora，非常适合作为个人博客，记录自己，也分享给有需要的人。

<!--more-->



### github pages

不说概念，只说用途：在github创建一个名为xxx.github.io，里面有名为index.html的文件的话，你访问xxx.github.io域名，就可以看到index.html对应的静态页面。

hugo就是可以将你写的markdown生成对应的静态页面。

typora是非常好用的markdown编辑器。

### hugo安装和使用

[hugo](https://gohugo.io/)和hexo的对比不多介绍，迁移hugo主要是因为hugo是使用go开发的，但是主题数量和质量确实和hexo有差距。

#### mac安装hugo

```
brew install hugo
```

查看hugo版本：

```
hugo version
Hugo Static Site Generator v0.64.1/extended darwin/amd64 BuildDate: unknown
```

#### hugo使用

创建页面：

```
hexo new post/hugo-test.md
```

新建文章：

```
hugo new post/first.md
```

生成静态页面：

```
hugo
```

本地查看效果：

```
hugo server
```

打开` http://localhost:1313/`查看生成的页面。



修改default.md

```
---
title: "{{ replace .TranslationBaseName "-" " " | title }}"
date: {{ .Date }}
description: ""
draft: true
tags: []
categories: []
---

<!--more-->
```



#### hugo主题

使用[even]()主题，为方便修改，fork到了自己的仓库，并使用git submodules管理：

```
git submodule add git@github.com:meetbetter/hugo-theme-even.git themes/even
```

拷贝even配置，并按需修改：

```
cp themes/even/exampleSite/config.toml .
```

#### hugo配置





### git submodules管理静态页面和源文件

在项目根目录，初始化git仓库：

```
git init
```

创建关联：

```
git remote add origin git@github.com:meetbetter/meetbetter.github.io.git
```

将public添加到submodules：

```
git submodule add git@github.com:meetbetter/meetbetter.github.io.git public/
```

根目录新建source分支:

```
git checkout -b source
```

这样，public下就成为一个子仓库，对应默认分支master，根目录保存博客源文件。

hugo生成的静态页面在public目录，只需要在public将静态页面推送到master分支就可以在meetbetter.github.io看到对应博客。

在项目根目录可以将源文件推送到github source分支，方便备份原始markdown文件。

### shell脚本

