# pub_libs
## 说明
- 此为公共第三方库、常用数据库和一些app应用的部署程序
```
	boost-1.58
	curl-7.26
	hiredis-0.14
	jsoncpp-0.5.0
	log4cplus-2.0.4
```

- 数据库：
```
	mysql
	redis
```

- 应用包
```
	nginx
```
- 测试过的环境：
```
	centos6.5
	centos7.3
	centos7.5
	ubuntu16.04
	LinuxMint18.2
```
## 使用方法
- 将代码克隆到本地：
```
	git clone https://github.com/woaijssss/pub_libs.git
```
- 进入目录，并执行脚本：
```
******************************************************************************************
*   Usage like this: ./build.sh redis_flag mysql_flag nginx_flag                         *
*           Such as: ./build.sh 0 0 0                                                    *
*      All this flags indicate whether you install the corresponding target!             *
*        <note>:                                                                         *
*             1: install target                                                          *
*             0: not install                                                             *
******************************************************************************************
```