#!/usr/bin/env bash 
set -x #Print every line of commands out


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
sudo apt-get install -y autoconf automake libtool
read -p "Microwise: Prerequisites." var



#Install protobuf 3.0 . 默认安装是2.5，太low了，对于新的kinetic固件不支持

#wget protobuf3.0 and gmock 1.7.0 from qslab website
cd $KS_INST_SOURCE_DIR

if [ ! -f "$KS_INST_SOURCE_DIR/protobuf.3.0.tar" ]; then
   #wget ......
fi
if [ ! -f "$KS_INST_SOURCE_DIR/gmock-1.7.0.zip" ]; then
   #wget ......
fi



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



cd bin
screen -dmS kinjava ./startSimulator.sh
read -p "Microwise: a simulator is launched." var


