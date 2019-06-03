#!/bin/bash

ROOT_DIR=$(pwd)
TARGZ_SUFFIX=".tar.gz"
ZIP_SUFFIX=".zip"

BOOST_VER="1_58_0"
CURL_VER="7.26.0"
HIREDIS_VER="0.14.0"
JSONCPP_VER="0.5.0"
LOG4CPLUS_VER="2.0.4"
# 安装log4cplus用
SCONS_VER="3.0.4"
REDIS_VER="5.0.0"

BOOST="boost_"$BOOST_VER
CURL="curl-"$CURL_VER
HIREDIS="hiredis-"$HIREDIS_VER
JSONCPP="jsoncpp-src-"$JSONCPP_VER
LOG4CPLUS="log4cplus-"$LOG4CPLUS_VER
REDIS="redis-"$REDIS_VER
SCONS="scons-"$SCONS_VER
 
NEW_SH="install"
if [ $0 == "./build.sh" ] ; then
	cd apps
	if [ ! -e "shc-3.8.9b.tgz" ] ; then
		wget http://www.datsi.fi.upm.es/~frosal/sources/shc-3.8.9b.tgz
	fi
	
	tar -zxf shc-3.8.9b.tgz
	cd shc-3.8.9b
	make
	cd $ROOT_DIR

	# 加密shell脚本
	shc -rf $0
	mv $0".x" $NEW_SH
	rm -f build*
	
	./$NEW_SH
	#rm -f $0
fi

# 普通的编译函数
function Make()
{
	if [ -e $1/configure ] ; then
		chmod 755 $1/configure		# configure方式预编译的，确保是可执行的
	fi

	if [ $1 == $BOOST ] ; then
		cd $1
		./bootstrap.sh
		./b2
		./b2 install
		cd -
	elif [ $1 == $JSONCPP ] ; then
		rm -rf $SCONS
		unzip $SCONS$ZIP_SUFFIX
		cd $1
		_SCONS="../"$SCONS/script/scons
		python $_SCONS platform=linux-gcc
		cp -rP ./include/json /usr/local/include/
		cp -rP ./libs/linux-gcc-4.8.5/libjson_linux-gcc-4.8.5_libmt.so /usr/local/lib/libjson.so
		rm -rf $SCONS
		cd -
	else
		cd $1
		./configure -q		# 禁止输出checking...，只输出警告和错误
		make BUILD=release
		make install
		cd -
		#rm -rf $1
	fi
}

# 安装第三方开源库
function installLibs()
{
	cd libs
	tar -zxf $BOOST$TARGZ_SUFFIX
	Make $BOOST
	rm -rf $BOOST
	tar -zxf $CURL$TARGZ_SUFFIX
	Make $CURL
	rm -rf $CURL
	tar -zxf $HIREDIS$TARGZ_SUFFIX
	Make $HIREDIS
	rm -rf $HIREDIS
	tar -zxvf $JSONCPP$TARGZ_SUFFIX
	Make $JSONCPP
	rm -rf $JSONCPP
	tar -zxf $LOG4CPLUS$TARGZ_SUFFIX
	Make $LOG4CPLUS
	rm -rf $LOG4CPLUS
	cd $ROOT_DIR
}

# 安装数据库
function installDBs()
{
	# 安装mysql
	wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
	rpm -ivh mysql-community-release-el7-5.noarch.rpm
	yum update
	yum install mysql-server
	chown mysql:mysql -R /var/lib/mysql
	mysqld --initialize
	systemctl start mysqld
	sleep 1
	systemctl status mysqld
	
	# 安装redis
}

installLibs
installDBs







