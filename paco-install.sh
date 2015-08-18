#!/usr/bin/env bash 
set -x #Pring every line of commands out


export KS_INST_DIR=~/ks_inst
export KS_INST_SOURCE_DIR=~/ks-installation

if [ ! -d "$KS_INST_DIR" ]; then
   sudo mkdir $KS_INST_DIR
fi
if [ -f "$KS_INST_DIR/ks-inst.log" ]; then
   sudo rm $KS_INST_DIR/ks-inst.log
fi


sudo chown stack $KS_INST_DIR
# Set fd 1 and 2 to write the log file
exec 1> >( tools/outfilter.py -v -o "$KS_INST_DIR/ks-inst.log" ) 2>&1

#Downloading kinetic-swift source
cd ~
sudo apt-get install -y git
git clone https://github.com/swiftstack/kinetic-swift.git
export KS_SOURCE_DIR=~/kinetic-swift
cd $KS_SOURCE_DIR
git pull
git submodule update --init
read -p "Microwise: Downloaded kinetic-swift source." var

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install -y ntp 

cd $KS_INST_DIR

#Prerequisites
if [ ! -f "ez_setup.py" ]; then
    wget https://bootstrap.pypa.io/ez_setup.py
fi
sudo python ez_setup.py
if [ ! -f "get-pip.py" ]; then
    wget https://bootstrap.pypa.io/get-pip.py
fi
sudo python get-pip.py

read -p "Microwise: ez_setup and get-pip." var

sudo apt-get install -y python-dev
sudo apt-get install -y build-essential   #尽管上一步会安装gcc等安装包，但是还是需要安装build-essentials比较好
sudo apt-get install -y libffi-dev
sudo apt-get install -y protobuf-compiler
sudo apt-get install -y memcached
sudo apt-get install -y unzip
read -p "Microwise: Prerequisites." var


#Install PyEClib
sudo apt-get install -y autoconf automake libtool
cd ~
git clone https://bitbucket.org/tsg-/liberasurecode.git
cd liberasurecode
./autogen.sh
./configure
make
sudo make test
sudo make install
cd ~
git clone https://bitbucket.org/kmgreen2/pyeclib.git
cd pyeclib
sudo python setup.py install
read -p "Microwise: PyEClib installed." var

#Install protobuf 3.0 . 默认安装是2.5，太low了，对于新的kinetic固件不支持
cp $KS_INST_SOURCE_DIR/protobuf.3.0.tar $KS_INST_DIR
cd $KS_INST_DIR
tar -xf protobuf.3.0.tar
cp $KS_INST_SOURCE_DIR/gmock-1.7.0.zip $KS_INST_DIR/protobuf/
cd $KS_INST_DIR/protobuf/
unzip -q gmock-1.7.0.zip
mv gmock-1.7.0 gmock
./autogen.sh
./configure
make
sudo make check
sudo make install
read -p "Microwise: Installed protobuf 3.0." var

#Install kinetic-java source
#KS(kinetic-swift) need kinetic-java to communicate with kinetic devices 
cd ~
export JAVA_HOME=~/jdk1.8.0_45
if [ ! -d "$JAVA_HOME" ]; then   
	if [ ! -f "~/jdk-8u45-linux-x64.tar.gz" ]; then
		wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz
	fi
	tar -xf jdk-8u45-linux-x64.tar.gz
fi
read -p "Microwise: Installed jdk." var


sudo apt-get install -y maven
read -p "Microwise: Installed maven." var



cd $KS_SOURCE_DIR
cd kinetic-java
mvn clean package
read -p "Microwise: Installed kinetic-java." var



#Installing from source
cd ~/kinetic-swift
sudo python setup.py develop
sudo apt-get install -y swift swift-proxy swift-account swift-container swift-object
#cd swift
#git checkout stable/kilo
#sudo python setup.py develop
#cd ../python-swiftclient/
#sudo python setup.py install
sudo apt-get install -y python-swiftclient
#cd ../kinetic-py/
#git submodule init
#git submodule update
#sudo sh compile_proto.sh 
#sudo python setup.py develop
#cd ..
read -p "Microwise: Installing from source." var


#make the DIRs
export SWIFT_DIR=/swift
if [ ! -d "$SWIFT_DIR" ]; then
   sudo mkdir $SWIFT_DIR
fi
sudo chmod 777 $SWIFT_DIR

cd $SWIFT_DIR
#$SWIFT_DIR/sdv is used to store container and account information, in a real enviornment, here should be real devices.
if [ ! -d "sdv" ]; then
   sudo mkdir $SWIFT_DIR/sdv
fi
sudo chmod 777 $SWIFT_DIR/sdv

if [ ! -d "/etc/swift" ]; then
   sudo mkdir /etc/swift
fi
sudo chmod 777 /etc/swift

if [ ! -d "/var/run/swift" ]; then
   sudo mkdir /var/run/swift
fi
sudo chmod 777 /var/run/swift

if [ ! -d "/var/cache/swift" ]; then
   sudo mkdir /var/cache/swift
fi
sudo chmod 777 /var/cache/swift
read -p "Microwise: Maked the DIRs." var


#copy the .conf samples
sudo cp $KS_SOURCE_DIR/swift/etc/account-server.conf-sample /etc/swift/account-server.conf
sudo cp $KS_SOURCE_DIR/swift/etc/object-server.conf-sample /etc/swift/object-server.conf
sudo cp $KS_SOURCE_DIR/swift/etc/container-server.conf-sample /etc/swift/container-server.conf
sudo cp $KS_SOURCE_DIR/swift/etc/proxy-server.conf-sample /etc/swift/proxy-server.conf
sudo cp $KS_SOURCE_DIR/swift/etc/swift.conf-sample /etc/swift/swift.conf
read -p "Microwise: copied the .conf files." var


#modify the .conf files
source $KS_INST_SOURCE_DIR/tools/ini-config
iniset /etc/swift/account-server.conf DEFAULT user stack
iniset /etc/swift/account-server.conf DEFAULT devices "$SWIFT_DIR"
iniset /etc/swift/account-server.conf DEFAULT mount_check false
iniset /etc/swift/account-server.conf pipeline:main pipeline "healthcheck account-server"

iniset /etc/swift/container-server.conf DEFAULT user stack
iniset /etc/swift/container-server.conf DEFAULT devices "$SWIFT_DIR"
iniset /etc/swift/contaienr-server.conf DEFAULT mount_check false
iniset /etc/swift/container-server.conf pipeline:main pipeline "healthcheck container-server"

iniset /etc/swift/object-server.conf DEFAULT user stack
iniset /etc/swift/object-server.conf DEFAULT devices "$SWIFT_DIR"
iniset /etc/swift/object-server.conf DEFAULT mount_check false
iniset /etc/swift/object-server.conf DEFAULT disk_chunk_size 1048576
iniset /etc/swift/object-server.conf pipeline:main pipeline "healthcheck object-server"
iniset /etc/swift/object-server.conf app:object-server use egg:kinetic_swift#object

iniset /etc/swift/proxy-server.conf DEFAULT user stack
iniset /etc/swift/proxy-server.conf DEFAULT object_single_process object-server.conf
iniset /etc/swift/proxy-server.conf DEFAULT account_autocreate true

read -p "Microwise: modified the .conf files." var



cd /etc/swift
swift-ring-builder account.builder create 10 1 1
swift-ring-builder account.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6002 --device sdv --weight 1
swift-ring-builder account.builder rebalance

swift-ring-builder container.builder create 10 1 1
swift-ring-builder container.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6001 --device sdv --weight 1
swift-ring-builder container.builder rebalance

#build the ring
echo "Microwise: If you believe this is a real world, you should stop here."
echo "Because the following is not real!"
read -p "Continue? [Y/N]" var
if [ $var = 'N' ]; then
   exit
fi

cd bin
screen -dmS kinjava ./startSimulator.sh
read -p "Microwise: a simulator is launched." var

swift-ring-builder object.builder create 10 1 1
swift-ring-builder object.builder add --region 1 --zone 1 --ip 127.0.0.1 --port 6000 --device 127.0.0.1:8123 --weight 1
swift-ring-builder object.builder rebalance

read -p "Microwise: builded the ring." var



#start swift
sudo swift-init start main
sudo swift-init account-auditor account-replicator container-auditor container-updater container-replicator start
screen -dmS ksreplicator kinetic-swift-replicator /etc/swift/object-server.conf


