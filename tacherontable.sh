#!/bin/bash

TACHERONFILE='/etc/tacheron/tacheronfile'
PIPEFILE='/tmp/tachepipe'


function EchoWrong {
    echo -e "Wrong Input !\nUsage: tacherontable [-u username] {-l | -r | -w}"
}

if [ $# -ne 1 -a $# -ne 3 ]
then
    EchoWrong
    exit 0
fi

if [ $1 == '-u' ]
then
    username=$2
    cmd=$3
    TACHERONFILE=$TACHERONFILE$username
else
    cmd=$1
fi

if [ ! -f $TACHERONFILE ]
then
    touch $TACHERONFILE
    chmod 644 $TACHERONFILE
fi

if [ $cmd == '-l' ]
then
    cat $TACHERONFILE
elif [ $cmd == '-r' ]
then
    rm $TACHERONFILE
elif [ $cmd == '-w' ]
then
    touch /tmp/temp
    cat $TACHERONFILE > /tmp/temp
    nano /tmp/temp
    cat /tmp/temp > $TACHERONFILE
    if [ -p $PIPEFILE ]
    then
	echo " " > $PIPEFILE
    fi
else
    EchoWrong
fi
    

