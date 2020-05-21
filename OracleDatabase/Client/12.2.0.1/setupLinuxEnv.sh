#!/bin/bash
mkdir -p $ORACLE_BASE && \
mkdir -p $ORACLE_HOME && \
mkdir -p $ORACLE_INV && \
#czu to wszystko jest poyrzebne? czy nie wystarczy utworzyć użytkownika?
#yum -y install oracle-database-server-12cR2-preinstall openssl && \
#rm -rf /var/cache/yum && \

yum -y install bc binutils compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 glibc glibc.i686 glibc-devel glibc-devel.i686 ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make && \
rm -rf /var/cache/yum && \

groupadd -g 54323 oper && \
groupadd -g 54322 dba && \
groupadd -g 54321 oinstall && \
useradd -u 54321 -g oinstall -G dba,oper oracle && \
echo oracle:oracle | chpasswd && \
chown -R oracle:oinstall /u01 && \
chmod -R 775 /u01 && \
chown -R oracle:oinstall $ORACLE_INV
