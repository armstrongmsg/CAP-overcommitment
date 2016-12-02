#!/bin/bash

function log {
	echo $1 >> $LOG_FILE
}

function factorial() 
  if (( $1 < 2 ))
  then
    echo 1
  else
    echo "$1 * $(factorial $(( $1 - 1 )))" | bc
  fi

function limit_affinity {
  INSTANCE_A=$1
  INSTANCE_B=$2

  virsh vcpupin $INSTANCE_A 0 0
  virsh vcpupin $INSTANCE_B 0 0
}

function reset_affinity {
  INSTANCE_A=$1
  INSTANCE_B=$2
  
  N_CPUS="`cat /proc/cpuinfo | grep processor | wc -l`"
  virsh vcpupin $INSTANCE_A 0 0-$(( $N_CPUS-1 ))
  virsh vcpupin $INSTANCE_B 0 0-$(( $N_CPUS-1 ))
}

function run {
	TIMES=$3

	virsh schedinfo $INSTANCE_A --set vcpu_quota=$(( $1*1000 )) > /dev/null
	virsh schedinfo $INSTANCE_B --set vcpu_quota=$(( $2*1000 )) > /dev/null

	for i in `seq 1 $TIMES`
	do
		echo "i=$i"
		echo "Starting applications"
		ssh $VM_A_USER@$INSTANCE_A_IP "$(typeset -f); { time -p factorial $N > /dev/null; } 2>&1 | grep "real" > log.txt" &
		ssh $VM_B_USER@$INSTANCE_B_IP "$(typeset -f); { time -p factorial $N > /dev/null; } 2>&1 | grep "real" > log.txt" &

		CPU_USAGE=""

		echo "Waiting for applications to finish"
		while [ "`ssh $VM_A_USER@$INSTANCE_A_IP cat log.txt`" = "" ]
		do
			sleep 1
			CPU_IDLE=`sar -P 0 1 1 | awk 'NR==4 { print $8 } ' | awk -F "," '{ print $1 }'`
			CPU_USAGE="$CPU_USAGE $(( 100 - $CPU_IDLE ))"
		done
	
		TOTAL_TIME_A="`ssh $VM_A_USER@$INSTANCE_A_IP cat log.txt | awk '{ print $2}' | awk -F "," '{print $1}'`"
		ssh $VM_A_USER@$INSTANCE_A_IP rm log.txt
	
		while [ "`ssh $VM_B_USER@$INSTANCE_B_IP cat log.txt`" = "" ]
		do
			sleep 1
		done
	
		TOTAL_TIME_B="`ssh $VM_B_USER@$INSTANCE_B_IP cat log.txt | awk '{ print $2 }' | awk -F "," '{print $1}'`"
	
		ssh $VM_B_USER@$INSTANCE_B_IP rm log.txt

		CPU_USAGE="`echo $CPU_USAGE | xargs`"
		log "$1,$2,$TOTAL_TIME_A,$TOTAL_TIME_B,$CPU_USAGE"
	done
}

N=$1
TIMES=$2
INSTANCE_A_IP="192.168.122.94"
INSTANCE_B_IP="192.168.122.202"
INSTANCE_A="ubuntu"
INSTANCE_B="ubuntu1"
VM_A_USER="ubuntu"
VM_B_USER="ubuntu"
LOG_FILE="results.csv"

echo "Setting affinities"
limit_affinity $INSTANCE_A $INSTANCE_B

log "cap_a,cap_b,total_time_a,total_time_b,cpu_usage"

echo "Running with conf:CAP A=100%, CAP B=100%"
#run 100 100 $TIMES
echo "Running with conf:CAP A=100%, CAP B=50%"
#run 100 50 $TIMES
echo "Running with conf:CAP A=50%, CAP B=50%"
#run 50 50 $TIMES
echo "Running with conf:CAP A=70%, CAP B=30%"
#run 70 30 $TIMES
echo "Running with conf:CAP A=50%, CAP B=30%"
#run 50 30 $TIMES
echo "Running with conf:CAP A=80%, CAP B=60%"
#run 80 60 $TIMES
echo "Running with conf:CAP A=30%, CAP B=30%"
#run 30 30 $TIMES
echo "Running with conf:CAP A=70%, CAP B=40%"
#run 70 40 $TIMES
echo "Running with conf:CAP A=100%, CAP B=30%"
run 100 30 $TIMES

echo "Resetting affinities"
reset_affinity $INSTANCE_A $INSTANCE_B
