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

#------databases
REDIS_VER="5.0.0"
MYSQL_VER="5.5.62"

#------apps
NGINX_VER="1.10.3"

BOOST="boost_"${BOOST_VER}
CURL="curl-"${CURL_VER}
HIREDIS="hiredis-"${HIREDIS_VER}
JSONCPP="jsoncpp-src-"${JSONCPP_VER}
LOG4CPLUS="log4cplus-"${LOG4CPLUS_VER}
SCONS="scons-"${SCONS_VER}
REDIS="redis-"${REDIS_VER}
MYSQL="mysql-"${MYSQL_VER}

#----------------------------------------------------------------------------------------------
# 标识是否需要安装相应的服务
#------databases
USE_MYSQL=0
USE_REDIS=0

#------apps
USE_NGINX=0
#----------------------------------------------------------------------------------------------

# 普通的编译函数
function Make()
{
	if [ -e $1/configure ] ; then
		chmod 755 $1/configure		# configure方式预编译的，确保是可执行的
	fi

	if [ $1 == ${BOOST} ] ; then
		cd $1
		./bootstrap.sh
		./b2
		./b2 install
		cd -
	elif [ $1 == ${JSONCPP} ] ; then
		rm -rf ${SCONS}
		unzip ${SCONS}${ZIP_SUFFIX}
		cd $1
		_SCONS="../"${SCONS}/script/scons
		python ${_SCONS} platform=linux-gcc
		cp -rP ./include/json /usr/local/include/
		cp -rP ./libs/linux-gcc-4.8.5/libjson_linux-gcc-4.8.5_libmt.so /usr/local/lib/libjson.so
		rm -rf ${SCONS}
		cd -
	else
		cd $1
		./configure -q		# 禁止输出checking...，只输出警告和错误
		make BUILD=release
		make install
		cd -
		#rm -rf ${1}
	fi
}

# 安装第三方开源库
function installLibs()
{
	cd libs
	tar -zxf ${BOOST}${TARGZ_SUFFIX}
	Make ${BOOST}
	rm -rf ${BOOST}
	tar -zxf ${CURL}${TARGZ_SUFFIX}
	Make ${CURL}
	rm -rf ${CURL}
	tar -zxf ${HIREDIS}${TARGZ_SUFFIX}
	Make ${HIREDIS}
	rm -rf ${HIREDIS}
	tar -zxvf ${JSONCPP}${TARGZ_SUFFIX}
	Make ${JSONCPP}
	rm -rf ${JSONCPP}
	tar -zxf ${LOG4CPLUS}${TARGZ_SUFFIX}
	Make ${LOG4CPLUS}
	rm -rf ${LOG4CPLUS}
	cd ${ROOT_DIR}
}

# 安装数据库
function installDBs()
{
	cd databases
	if [ ${USE_REDIS} == 1 ] ; then
		# 安装redis
		echo "Installing redis service..."
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
		echo "installed redis"
	fi
	
	if [ ${USE_MYSQL} == 1 ] ; then
		# 安装mysql
		echo "Installing mysql service..."
		tar -zxf ${MYSQL}${TARGZ_SUFFIX}
		cd ${MYSQL}
		mkdir -p build
		cd build
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
			  -DDEFAULT_CHARSET=utf8 \
			  -DDEFAULT_COLLATION=utf8_general_ci \
			  -DWITH_EXTRA_CHARSETS=all \
			  -DSYSCONFDIR=/etc \
			  -DMYSQL_DATADIR=/home/mysql/ \
			  -DMYSQL_UNIX_ADDR=/home/mysql/mysql.sock \
			  -DWITH_MYISAM_STORAGE_ENGINE=1 \
			  -DWITH_INNOBASE_STORAGE_ENGINE=1 \
			  -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
			  -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
			  -DENABLED_LOCAL_INFILE=1 \
			  -DWITH_SSL=system \
			  -DMYSQL_TCP_PORT=3306 \
			  -DENABLE_DOWNLOADS=1 \
			  -DWITH_SSL=bundled \
			  --no-warn-unused-cli \
			  .. > cmake.log
		#make BUILD=release
		#make install
		#cp support-files/my-medium.cnf /etc/my.cnf 
		#/usr/local/mysql/scripts/mysql_install_db --user=mysql --ldata=/var/lib/mysql --basedir=/usr/local/mysql --datadir=/home/mysql 
		##echo "PATH=$PATH:/usr/local/mysql/bin/" >> /etc/profile 
		##source /etc/profile
		#cp support-files/mysql.server /etc/init.d/mysqld
		#chmod +x /etc/init.d/mysqld    # 设置执行权限
		#chkconfig --add mysqld         # 添加mysqld服务
		#chkconfig --level 35 mysqld on
		#service mysqld start
		cd ../../
		rm -rf ${MYSQL}
		echo "installed mysql!"
	fi
	
	cd ${ROOT_DIR}
}

function installApps()
{
	cd apps
	if [ ${USE_NGINX} == 1 ] ; then
		tar -zxf nginx-${NGINX_VER}${TARGZ_SUFFIX}
		cd nginx-${NGINX_VER}
		
		# configure的参数可以自由改动
		./configure --with-stream
		make BUILD=release
		make install
		cd ..
		rm -rf nginx-${NGINX_VER}
		ln -sf /usr/local/nginx/sbin/nginx /usr/sbin/nginx
	fi

	cd ${ROOT_DIR}
}

# 运行脚本要带上是否安装数据库标识(Release版需要)
if [ $# -lt 3 ] ; then
	echo "Usage such as: "$0" 0 0 0"
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
	cd ${ROOT_DIR}

	# 加密shell脚本
	shc -rf $0
	mv $0".x" ${NEW_SH}
	rm -f build.sh.*
	
	./${NEW_SH} $1 $2 $3
	#rm -f $0
	exit 0
fi

if [ $1 -eq 1 ] ; then
	USE_REDIS=1
fi

if [ $2 -eq 1 ] ; then
	USE_MYSQL=1
fi

if [ $3 -eq 1 ] ; then
	USE_NGINX=1
fi
	
#installLibs
#installDBs
installApps







