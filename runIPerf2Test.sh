# Copyright 2016-2018 VMware, Inc.
# SPDX-License-Identifier: BSD-2

# Purpose:  Check TCP thrpughput using iperf2 across multiple pairs of sender/receiver VMs
#
# Expects 
#   1.  File "vm.list" in the script directory that contains comma seperated list of one iperf client VM and one iperf server VM per line
#   2.  iperf server VMs should already be running the iperf server "iperf -s"
#   3.  iperf executable should be in PATH
#   4.  Password less SSH login to the VMs used in the test
# 
# Tested with iperf version 2.0.5 (08 Jul 2010) pthreads on RedHat 6.0

# List of VMs that will be used in the test
VM_LIST="vm.list"
# Number of iperf threads to run
THREADS=4
# Time to run
TIME=30

# Remove older log files
rm -rf *log

# From each line in the vm.list file - get the iperf server and client IPs
for LINE in `cat $VM_LIST`
do
  # SERVER is expected to be running iperf server (iperf -s)
	SERVER=`echo $LINE | cut -f2 -d","`
  # CLIENT is where the iperf client will run
	CLIENT=`echo $LINE | cut -f1 -d","`

	# Start iperf tests in background - 
	ssh $CLIENT "iperf -c $SERVER -P $THREADS -t $TIME -f g" | tee $SERVER.log &
done


# Loop till the above tests are finished
while [ 1 ]
do
   sleep 10
   RUNNING=`ps -ef | grep -c "iperf -c"`
   if [ $RUNNING -le 1 ]; then
      break;
   fi
   echo -n "."
done

# Print individual throughput values
echo
echo "Individual Throughput in Gbits/sec"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
for LOG in `ls -1 *log`
do
	SERVER_IP=`echo $LOG | sed -e 's/.log//'`
	FLOW=`grep $SERVER_IP $VM_LIST | sed -e 's/,/ -> /g'`
	TP=`grep SUM $LOG | awk '{ print $6" "$7 }'`
	echo "$FLOW : $TP"
done

# Print total throughput
TP=`tail -n 1 *.log | grep SUM | awk '{ sum+=$6 } END { print sum }'`
echo 

echo "Total Throughput in Gbits/sec"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "IPerf Servers # : `ls -1 *.log | wc -l`, TP : $TP Gbits/sec"
