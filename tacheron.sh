#!/bin/bash

# ------------------------------------------------------------------- #
# --------------------------VARIABLE AREA---------------------------- #
# ------------------------------------------------------------------- #
TACHERONPATH='/etc/tacheron'
TACHERONFILE='/etc/tacheronfileroot'
LOGPATH='/var/log/tacheron/'
TACHERONLOG='/var/log/tacheron/tacheronlog'
TACHERONERR='/var/log/tacheron/tacheronerr'

# PIDFILE store the PID of this program, PIPEPROGRAM kill -15
# to inform a change of tacheron files
PIDFILE='/etc/tacheron_15.pid'
PIPEPROGRAM='/etc/tacheronpipe.sh'

# store commands that need to be excuted within 1h
TACHE_FILE='/etc/tachefile'
# store commands that need to be excuted within 10min, ordered by time
COMMAND_FILE='/etc/commandfile'

# store a list of username that is allowed to use tacheron
ALLOW_FILE='/etc/tacheron.allow'

# ------------------------------------------------------------------- #
# ----------------------------FUNTION AREA--------------------------- #
# ------------------------------------------------------------------- #

# End the name of the log file with month-year
function changeLogFile {
    TACHERONLOG=$LOGPATH'LOG'$(date +'%m-%y')
    if [ ! -f $TACHERONLOG ]
    then
        touch $TACHERONLOG
    fi
}


# initialization
function init {
    if [ ! -d $TACHERONPATH ]
    then
	mkdir $TACHERONPATH
	chmod a+wr  $TACHERONPATH
    fi

    if [ ! -f $ALLOW_FILE ]
    then
	touch $ALLOW_FILE
    fi

    if [ -f $PIDFILE ]
    then
	echo "Already run a tachron or unexcepted exit last time; try rm $PIDFILE"
	exit
    fi

    if [ -f $PIPEPROGRAM ]
    then
	rm $PIPEPROGRAM
    fi

    if [ ! -d $LOGPATH ]
    then
	mkdir $LOGPATH
    fi

    touch $PIDFILE
    echo -e "$$" > $PIDFILE
    trap "load" 15

    cp ./pipeline $PIPEPROGRAM
    chmod u+x $PIPEPROGRAM
    sudo bash $PIPEPROGRAM &
    pid=$(cat $PIDFILE | head -2 | tail -1)
    trap "kill -15 $pid;rm $PIDFILE;echo '$(date) ##LOG:SIGINT' >> $TACHERONLOG;exit" 1 SIGINT

    changeLogFile

    touch $TACHEPATH"/tacheronfile"
    chmod a=wr $TACHEPATH"/tacheronfile"

    load
}

################################################################################
# read usernames from ALLOW_FILE and load their tacheronfiles under /etc/tacheron
function load {

    # log load
    echo "$(date) ##LOG: (re)load tacheronfile" >>  $TACHERONLOG

    if [ -f $TACHERONFILE ]
    then
	rm $TACHERONFILE
    fi

    touch $TACHERONFILE
    # changeLogFile every month
    echo '1 1 1 1 * * * changeLogFile' >> $TACHERONFILE

    while read  -r i
    do
	filename=$TACHERONPATH"/tacheronfile"$i
	if [ -s $filename ]
	then
	    cat $filename >> $TACHERONFILE
	fi
    done < $ALLOW_FILE

    # replace * with \*
    sed -i 's/\*/\\\*/g' $TACHERONFILE

    writeTacheFile
}

###################################################
# sort out commands that should be excuted in 1 hours
function writeTacheFile {
    if [ -f $TACHE_FILE ]
    then
	rm $TACHE_FILE
    fi

    touch $TACHE_FILE

    hour=$(date '+%H')
    day=$(date '+%d')
    month=$(date '+%m')
    week=$(date '+%w')

    while read -r line
    do
	# skip void lines
	if [[ $line =~ ^\s*$ ]]
	then
	    continue
	fi

	# split
	shour=$(echo $line | cut -d ' ' -f3)
	sday=$(echo $line | cut -d ' ' -f4)
        smonth=$(echo $line | cut -d ' ' -f5)
	sweek=$(echo $line | cut -d ' ' -f6)
	match $hour $shour 1
	match_h=$?

	match $day $sday 0
        match_d=$?

	match $month $smonth 0
        match_m=$?

	match $week $sweek 0
        match_w=$?

	if [ $match_h -eq 1 -a $match_d -eq 1 -a $match_m -eq 1 -a $match_w -eq 1 ]
	then
	    echo $line >> $TACHE_FILE
	fi
    done < $TACHERONFILE
    writeCommandFile

}

# sort out the commands that should be excuted in 10 minutes
function writeCommandFile {
    if [ -f $COMMAND_FILE ]
    then
	rm $COMMAND_FILE
    fi

    touch $COMMAND_FILE

    minute=$(date '+%M')

    while read -r line
    do
	smin=$(echo $line | cut -d ' ' -f2)
	match $minute $smin 10
	match_min=$?
	if [ $match_min -eq 1 ]
	then
	    echo $line >> $COMMAND_FILE
	fi

    done < $TACHE_FILE
}

########################################################################################
# compare current time with given time; usage: match current_time schedule_time gap_time 
function match {

    current_time=$1
    schedule_time=$2
    gap_time=$3

    # if there is /
    if [[ $schedule_time =~ / ]]
    then
	f1=$(echo $schedule_time | cut -d '/' -f1)
	f2=$(echo $schedule_time | cut -d '/' -f2)

	# case */2
	if [[ $f1 =~ ^\*$ ]]
	then
	    for((i=0;i<=$gap_time;i++));
	    do
		t=$(expr $(expr $current_time + $i) % $f2)
		if [ $t -eq 0 ]
		then
		    return 1
		fi
	    done
	    return 0
	# case 1-6/2
	elif [[ $f1 =~ ^[1-6]?[0-9]-[1-6]?[0-9]$ ]]
	then
	    c1=$(echo $f1 | cut -d '-' -f1)
	    c2=$(echo $f1 | cut -d '-' -f2)
	    for((i=0;i<=$gap_time;i++));
            do
		caltime=$(expr $current_time + $i)
                t=$(expr $(expr $caltime - $c1) % $f2)
                if [ $t -eq 0 -a $caltime -ge $c1 -a $caltime -le $c2 ]
                then
                    return 1
                fi
            done
	    return 0
	else
	    echo -e "$(date) ERROR: Ilegel use of /, $schedule_time" >> $TACHERONERR
	    return 0
	fi
    fi


    # split and recurse if there is ~
    if [[ $schedule_time =~ \~ ]]
    then
	f1=$(echo $schedule_time | cut -d '~' -f1)
	f2=$(echo $schedule_time | cut -d '~' -f2)
	match $current_time $f1 $gap_time
	res1=$?
	res2=1
	# Before return 0, we should make sure that all time in [ct, ct+gt] is banned
	for((i=0;i<=$gap_time;i++));
	do
	    match $(expr $current_time + $i) $f2 0
	    if [ $? -eq 0 ]
	    then
		res2=0
	    fi
	done

	if [ $res1 -eq 1 -a $res2 -eq 0 ]
	then
	    return 1
	else
	    return 0
	fi
    fi

    # If there is *
    if [ ! -z $(echo $schedule_time | grep \* ) ]
    then
        return 1
    fi

    # if there is ',' split and recurse
    if [[ $schedule_time =~ , ]]
    then
        array=(${schedule_time//,/ })
        for field in ${array[@]}
        do
            match $current_time $field $gap_time

            if [ $? == 1 ]
            then
                return 1
            fi
        done
    fi

    # if it's just a number
    if [[ $schedule_time =~ ^[1-6]?[0-9]$ ]]
    then
	timebound=$(expr $current_time + $gap_time)
	if [ $current_time -le $schedule_time -a $timebound -ge $schedule_time ]
	then
	    return 1
	fi
    fi

    # if there is -
    if [[ $schedule_time =~ - ]]
    then
        start=$(echo $schedule_time | cut -d '-' -f1)
        end=$(echo $schedule_time | cut -d '-' -f2)
        if [ $current_time -le $end -a $(expr $current_time + $gap_time) -ge $start ]
        then
            return 1
        fi
    fi
    return 0
}

# --------------------------------------------------------------------- #
# --------------------------------Main--------------------------------- #
# --------------------------------------------------------------------- #

init

while [ 1 ]
do
    if [ $(date '+%M') -eq 0 ]
    then
	writeTacheFile
    elif [ $(expr $(date '+%M') % 10) -eq 0 ]
    then
	writeCommandFile
	if [ ! -s $COMMAND_FILE ]
	then
	    sleep 60
	fi
    fi

    while read -r line
    do
	command=$(echo $line | cut -d ' ' -f 7-)
	second=$(expr $(date '+%S') / 15 + 1)
	minute=$(date '+%M')

	ssecond=$(echo $line | cut -d ' ' -f1)
	sminute=$(echo $line | cut -d ' ' -f2)

	match $second $ssecond 0
	match_second=$?
	match $minute $sminute 0
	match_minute=$?

	if [ $match_second -eq 1 -a $match_minute -eq 1 ]
	then
	    eval $command &
	    echo "$(date) ##LOG: excute command: $command" >> $TACHERONLOG
	fi
	sleep 15
    done < $COMMAND_FILE
done
