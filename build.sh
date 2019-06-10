#!/bin/bash

ROOT_DIR=$(pwd)

#----------------------------后缀名
TARGZ_SUFFIX=".tar.gz"
ZIP_SUFFIX=".zip"

#----------------------------开源库版本号 libs
BOOST_VER="1_58_0"
CURL_VER="7.26.0"
HIREDIS_VER="0.14.0"
JSONCPP_VER="0.5.0"
LOG4CPLUS_VER="2.0.4"
# 安装log4cplus用
SCONS_VER="3.0.4"

#----------------------------数据库 databases
REDIS_VER="5.0.0"
MYSQL_VER="5.5.62"

#----------------------------应用	apps
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
	tar -zxf $1${TARGZ_SUFFIX}
	cd $1
	
	if [ -e configure ] ; then
		chmod 755 configure		# configure方式预编译的，确保是可执行的
	fi

	if [ $1 == ${BOOST} ] ; then
		./bootstrap.sh
		./b2
		./b2 install
	elif [ $1 == ${JSONCPP} ] ; then
		unzip -o ../${SCONS}${ZIP_SUFFIX}
		python ${SCONS}/script/scons platform=linux-gcc
		cp -rP ./include/json /usr/local/include/
		cp -rP ./libs/linux-gcc-4.8.5/libjson_linux-gcc-4.8.5_libmt.so /usr/local/lib/libjson.so
		
	else
		./configure -q		# 禁止输出checking...，只输出警告和错误
		make BUILD=release
		make install
	fi
	
	cd ..
	rm -rf $1
}

# 安装第三方开源库
function installLibs()
{
	cd libs
	#Make ${CURL}
	#Make ${HIREDIS}
	Make ${JSONCPP}
	#Make ${LOG4CPLUS}
}

# 安装数据库
function installDBs()
{
	cd databases
	if [ ${USE_REDIS} == 1 ] ; then
		# 安装redis
		echo "Installing redis service..."
		if [ ! -e ${REDIS}${TARGZ_SUFFIX} ] ; then
			wget http://download.redis.io/releases/${REDIS}${TARGZ_SUFFIX}
		fi
		tar -zxf ${REDIS}${TARGZ_SUFFIX}
		cd ${REDIS}
		make BUILD=release
		make install
		
		cp utils/redis_init_script /etc/rc.d/init.d/redisd
		chkconfig --add redisd
		mkdir -p /etc/redis
		cp redis.conf /etc/redis/6379.conf
		systemctl enable redisd
		
		count=$(ps -ef | grep redis | wc -l)
		if [ $count -le 1 ] ; then
			systemctl start redisd
		else
			systemctl restart redisd
		fi
		
		cd ..
		rm -rf ${REDIS}
		echo -e "installed redis"
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
		make BUILD=release
		make install
		
		cp support-files/my-medium.cnf /etc/my.cnf 
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --ldata=/var/lib/mysql --basedir=/usr/local/mysql --datadir=/home/mysql 
		count=$(grep '/usr/local/mysql/bin' /etc/rc.local | wc -l)
		if [ $count -lt 1 ] ; then
			echo "PATH=$PATH:/usr/local/mysql/bin/" >> /etc/profile 
			source /etc/profile
		fi
		
		cp support-files/mysql.server /etc/init.d/mysqld
		chmod +x /etc/init.d/mysqld    # 设置执行权限
		chkconfig --add mysqld         # 添加mysqld服务
		chkconfig --level 35 mysqld on
		
		count=$(ps -ef | grep mysqld | wc -l)
		if [ $count -le 1 ] ; then
			systemctl start mysqld
		else
			systemctl restart mysqld
		fi
		
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
		cp -r ../config/nginx/nginx.conf /usr/local/nginx/conf
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
	fi
	
	tar -zxf shc-3.8.9b.tgz
	cd shc-3.8.9b
	make
	make install
	cd ..
	rm -rf shc-3.8.9b
	
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
	
installLibs
#installDBs
#installApps







