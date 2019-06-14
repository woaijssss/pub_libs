# pub_libs
## Description
- This is a public third-party library, a common database, and some application deployment programs.
```
	boost-1.58
	curl-7.26
	hiredis-0.14
	jsoncpp-0.5.0
	log4cplus-2.0.4
```

- databases：
```
	mysql
	redis
```

- apps
```
	nginx
```
- Tested environment：
```
	centos6.5
	centos7.3
	centos7.5
	ubuntu16.04
	LinuxMint18.2
```
## Instructions
- Clone the code to the local：
```
	git clone https://github.com/woaijssss/pub_libs.git
```
- Enter the directory and execute the .sh script：
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