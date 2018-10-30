# Copyright 2016-2018 VMware, Inc.
# SPDX-License-Identifier: BSD-2

# The BSD-2 license (the "License") set forth below applies to all parts of the NSX - Performance Testing Scripts project.  You may not use this file except in compliance with the License.

# BSD-2 License 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
