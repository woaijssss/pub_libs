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

#----------------------------------------------------------------------------------------------
# 标识是否需要安装对应的数据库
MYSQL=0
REDIS=0
#----------------------------------------------------------------------------------------------

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
	cd databases
	if [ ${REDIS} == 1 ] ; then
		# 安装redis
		#wget http://download.redis.io/releases/${REDIS}${TARGZ_SUFFIX}
		#tar -zxvf ${REDIS}${TARGZ_SUFFIX}
		#cd ${REDIS}
		#make BUILD=release
		#mkdir /usr/redis  
		#cp src/redis-server /usr/redis  
		#cp src/redis-benchmark /usr/redis  
		#cp src/redis-cli /usr/redis  
		#cp redis.conf /usr/redis  
		
		#echo "/usr/redis/redis-server /usr/redis/redis.conf &" > /etc/init.d/redis_start.sh
		#chmod 755 /etc/init.d/redis_start.sh
		#ln -sf /etc/init.d/redis_start.sh /etc/rc.d/rc2.d/S100redis_start
		#ln -sf /etc/init.d/redis_start.sh /etc/rc.d/rc3.d/S100redis_start
		#ln -sf /etc/init.d/redis_start.sh /etc/rc.d/rc4.d/S100redis_start
		#ln -sf /etc/init.d/redis_start.sh /etc/rc.d/rc5.d/S100redis_start
		echo "install redis"
	fi
	
	if [ ${MYSQL} == 1 ] ; then
		# 安装mysql
		#wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
		#rpm -ivh mysql-community-release-el7-5.noarch.rpm
		#yum update -y
		#yum install -y mysql-server
		#chown mysql:mysql -R /var/lib/mysql	# 这个好像有问题
		#chown mysql.mysql /var/run/mysqld/
		#mysqld --initialize
		#systemctl start mysqld
		#sleep 1
		#systemctl status mysqld
		echo "install mysql"
	fi
	
	cd $ROOT_DIR
}


if [ $# -lt 2 ] ; then
	echo "Usage such as: ./build.sh 0 0"
	exit 0
fi

NEW_SH="install"
if [ $0 == "./build.sh" ] ; then
	cd apps
	if [ ! -e "shc-3.8.9b.tgz" ] ; then
		wget http://www.datsi.fi.upm.es/~frosal/sources/shc-3.8.9b.tgz
		tar -zxf shc-3.8.9b.tgz
		cd shc-3.8.9b
		make
	fi
	cd $ROOT_DIR

	# 加密shell脚本
	shc -rf $0
	mv $0".x" $NEW_SH
	rm -f build.sh.x.c
	#rm -f build*
	
	./$NEW_SH $1 $2
	#rm -f $0
	exit 0
fi

if [ $1 -eq 1 ] ; then
	REDIS=1
fi

if [ $2 -eq 1 ] ; then
	MYSQL=1
fi
	
#installLibs
installDBs







