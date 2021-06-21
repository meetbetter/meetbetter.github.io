#!/bin/bash

gitFunc() {
        pwd
        message=`date "+%Y%m%d %H:%M:%S"`
        git add -A
        git commit -m "${message}"
        git push
}

echo '生成public'
pwd
hugo


echo '【提交submodules,部署pages...】'
cd public
gitFunc


echo '【提交soure...】'
cd ..
gitFunc


echo '【OK】'
