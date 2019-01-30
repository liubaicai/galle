# Galle
基于Ruby on Rails的，开源项目代码部署平台

## Feature
- 项目管理
- 服务器管理
- 用户管理
- 发布管理

## Installation
### development
~~~~
git clone https://github.com/liubaicai/galle.git
cd galle
rake dev:install
puma
~~~~
### production
~~~~
git clone https://github.com/liubaicai/galle.git
cd galle
bash galle install
bash galle start
~~~~

## Configuration
### production
项目目录添加.env文件(可选): 
~~~~
SQLITE3=/your/path/to/db/db.sqlite3
SSH_KEY_PATH=/your/path/to/.ssh
RAILS_SERVE_STATIC_FILES=true
PORT=10088
~~~~
- SQLITE3: 数据库文件地址,默认'db/production.sqlite3'
- SSH_KEY_PATH: 项目SSH密钥存储地址,默认'tmp/.ssh'
- RAILS_SERVE_STATIC_FILES: 是否服务静态文件,默认'false'
- PORT: 使用galle start启动时的端口号,默认'8080'

## TODOLIST
- 区分测试和线上环境
- 项目编辑时更友好的ui
---
- ~~支持Docker部署~~
- ~~历史发布备份~~
- ~~项目复制功能~~
- ~~各种表单项详细的提示和示例~~
- ~~选择服务器选项放到项目配置里~~
- ~~项目添加‘仅包含某些文件’模式~~
- ~~服务器采用ssh-key登录~~
- ~~项目自动排除.git~~
- ~~项目自动默认master分支~~
- ~~查看当前部署程序的ssh-key.pub~~
