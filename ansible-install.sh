dateStr=`date +%Y%m%d`
loggerFile='install_'${dateStr}'.log'
libDir='lib/'
logDir='log/'
installDir='package/'
if [ ! -d "$logDir" ];then
    mkdir $logDir
fi
if [ ! -d "$installDir" ];then
    mkdir $installDir
fi
function logger(){
   echo `date`"..."$1 >>${logDir}$loggerFile
}
function install_python_27(){
    logger '开始安装python 2.7'
    version=`python -V 2>&1`
    if [ $? -eq '0' -a "$version" = 'Python 2.7' ];then
        logger '检测到python2.7已经存在，跳过此步骤'
    else
        tar zxvf ${libDir}Python-2.7.tgz -C $installDir
        cd ${installDir}Python-2.7
        ./configure --prefix=/usr/local
        make --jobs=`grep processor /proc/cpuinfo|wc -l`
        make install
        cd -
        if [ $? -eq '0' ];then
            logger 'python2.7安装成功'
            cd /usr/local/include/python2.7
            cp -a ./* /usr/local/include/
            cd -
            #备份旧的Python
            cd /usr/bin
            mv python python2.6
            ln -s /usr/local/bin/python
            cd -
        else
            logger 'python2.7安装失败'
        fi
    fi
}

#安装Python相关模块
function install_python_module(){
    moduleName=$1
    if [ ! -n "$2" ];then
        packageName=$moduleName
    else
        packageName=$2
    fi
    #1. 检测模块是否已安装
    python -c "import $packageName"
    if [ $? -eq 0 ];then
        logger "$moduleName 已安装，跳过此步骤"
    else
        zipFile=`ls ${libDir}|grep $moduleName`
        unzipDir=${zipFile%.tar.gz}
        if [ -f "${libDir}$zipFile" ];then
           tar zxvf ${libDir}$zipFile -C $installDir  #解压到指定安装目录
           cd $installDir
           mv $unzipDir $moduleName
           cd $moduleName
           python setup.py install
           if [ $? -eq 0 ];then
                cd ../../
                logger "$moduleName 安装成功"
           else
                cd ../../
                logger "$moduleName 安装失败"
                exit 1
            fi
           
        else
            logger "$moduleName 安装目录下未找到对应安装文件" 
            exit 1
        fi
    fi
}

#安装必要的动态链接库
function install_lib(){
    libName=$1
    ls /usr/local/lib|grep $libName
    if [ $? -eq 0 ];then
        logger "$libName 已安装，跳过此步骤"
    else
        zipFile=`ls ${libDir}|grep $libName`
        unzipDir=${zipFile%.tar.gz}
        if [ -f ${libDir}$zipFile ];then
            tar zxvf ${libDir}$zipFile -C $installDir
            cd $installDir
            mv $unzipDir $libName
            cd $libName
            ./configure --prefix=/usr/local
            make --jobs=`grep process /proc/cpuinfo|wc -l`
            make install
            if [ $? -eq 0 ];then
                cd ../../
                logger "$libName 安装成功"
            else
                cd ../../
                logger "$libName 安装失败"
                exit 1
            fi            
         else
            logger "$libName 安装目录下未找到对应安装文件" 
            exit 1
        fi
    fi
}
# 添加环境变量
function add_env_path(){
    echo $PATH|grep /usr/local/bin
    if [ $? -eq 0 ];then
        logger '环境变量已存在，跳过配置'
    else
        echo 'export PATH=$PATH:/usr/local/bin' >>/etc/profile
        source /etc/profile
        logger '添加/usr/local/bin到PATH环境变量'
    fi
}

echo '开始安装...'
echo '安装日志见：'${logDir}${loggerFile}
install_python_27
install_python_module 'setuptools'
install_python_module 'crypto' 'Crypto'
install_lib 'sshpass'
install_lib 'yaml'
install_python_module 'PyYAML' 'yaml'
install_python_module 'MarkupSafe' 'markupsafe'
install_python_module 'Jinja2' 'jinja2'
install_python_module 'ecdsa'
install_python_module 'paramiko'
install_python_module 'simplejson'
install_python_module 'ansible'
add_env_path
if [ ! -d '/etc/ansible' ];then
    mkdir /etc/ansible
fi
cp ansible.cfg /etc/ansible/
echo '安装结束...'


