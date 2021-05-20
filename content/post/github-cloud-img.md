---
title: "Github Cloud Img"
date: 2021-05-05T15:33:43+08:00
description: ""
draft: true
tags: [tools]
---

写博客时，文字描述始终没有图片来的直观，有时候一张好的图示胜过千言万语，但是发布到blog时本地图片如何在网站正常显示是一个比较麻烦的问题。
目前使用的方案是使用github搭建图床，使用picgo作为图床上传工具。
<!--more-->

## blog图床的选择

1. 图片直接放在blog项目中，问题是blog项目过大
2. 使用免费图床，风险是第三方图床关停全部图片都丢失
3. 使用[asciiflow](https://asciiflow.com/)画图，可以用来画简单的示意图，方便放在markdown
4. 使用github搭建图床，可靠但国内访问速度慢

目前我画图的习惯是，简单的图片使用asciiflow画，简洁轻巧；复杂的图使用OmniGraffle绘制，博客中用到就将图片放在github图床。

## github图床搭建和使用
1. 创建一个public的仓库repository
2. 安装[picgo](https://github.com/Molunerfinn/PicGo)
3. github生成token并填写到picgo中
4. cdn加速 https://cdn.jsdelivr.net/gh/[你的github用户名]/仓库名@分支名

配置图：
![](https://cdn.jsdelivr.net/gh/meetbetter/cloudimg@main/img/20210505195655-picgo设置.png)
