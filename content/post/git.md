---
title: "Git"
date: 2021-05-25T20:27:08+08:00
description: ""
draft: true
tags: [tools]
---

<!--more-->


## 大文件
apt-get install git-lfs 
git lfs install
git lfs track plugged.tar.gz # 必须是文件名不含路径
git add .
git commit -m "git lfs for large file"
git lfs ls-files
git lfs clone git@github.com:meetbetter/useful-scripts.git

## 修改历史提交的用户名和邮箱
https://blog.csdn.net/u013202238/article/details/81557710

修改公司邮箱为个人邮箱
```shell
#!/bin/sh

git filter-branch --env-filter '

OLD_EMAIL="xx@xx.com"
CORRECT_NAME="newname"
CORRECT_EMAIL="newemail"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags

```

## 彻底删除git中的较大文件（包括历史提交记录）
https://blog.csdn.net/xiaosongluo/article/details/84194792

删除本地记录
```shell
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now
git push origin master --force
```
让远端仓库变小
```shell
git remote prune origin
```
如果还没有变小则可能是还有其他分支，删除其他分支或者按上面的操作清理分支大文件记录


# 巨人的肩膀
https://zzz.buzz/zh/2016/04/19/the-guide-to-git-lfs/
