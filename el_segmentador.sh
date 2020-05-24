#!/bin/bash

PATH=$PATH:/bin:/usr/bin:xxx
export PATH

printf "
                     ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█
                     ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█
                     ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀
             ░█▀▀░█░░░░░█▀▀░█▀▀░█▀▀░█▄█░█▀▀░█▀█░▀█▀░█▀█░█▀▄░█▀█░█▀▄
             ░█▀▀░█░░░░░▀▀█░█▀▀░█░█░█░█░█▀▀░█░█░░█░░█▀█░█░█░█░█░█▀▄
             ░▀▀▀░▀▀▀░░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░░▀░▀░▀▀░░▀▀▀░▀░▀

Release v1.2, License GPL-3.0

"


init_directories()
{
	echo -en "Report the exit DIRECTORY: "
	read DIRECTORY

	mkdir -p $DIRECTORY/ping_sweep
	mkdir -p $DIRECTORY/TCP
	mkdir -p $DIRECTORY/UDP
	mkdir -p $DIRECTORY/tmp
	PING_PATH="$DIRECTORY/ping_sweep"
	TMP_PATH="$DIRECTORY/tmp"
	TCP_PATH="$DIRECTORY/TCP"
	UDP_PATH="$DIRECTORY/UDP"
}

check_interface()
{
	echo -en "Report the Network Interface: "
	read ETH

	ifconfig | grep : | cut -d: -f1 | grep -v ' ' > $TMP_PATH/eths
	isInFile=$(cat $TMP_PATH/eths | grep -Fxc "$ETH")

	while [ "$isInFile" -eq 0 ]
	do
		echo "WARNING!! Network Interface invalid!"
		echo -en "Report the Network Interface: "
		read ETH
		isInFile=$(cat $TMP_PATH/eths | grep -Fxc "$ETH")
	done
}

check_scope()
{
	echo -en "Report the network scope: "
	read SCOPE
	while [ ! -e $SCOPE ]
	do
		echo "WARNING!! Scope invalid!"
		echo -en "Report the network scope: "
		read SCOPE
	done
}

init_vars()
{
	init_directories
	check_interface
	check_scope

	rm -rf $TCP_PATH/hosts_complete_tcp.txt
	rm -rf $UDP_PATH/hosts_complete_udp.txt
	echo "TCP Hosts Scan Complete" > $TCP_PATH/hosts_complete_tcp.txt
	echo "UDP Hosts Scan Complete" > $UDP_PATH/hosts_complete_udp.txt
}

split_machines()
{
	num_hosts=$(wc $PING_PATH/alivemachines.txt -l | cut -d" " -f1)
	num_hosts_list=$(( $num_hosts > 4 ? $(($num_hosts/4)) : 1 ))

	split $PING_PATH/alivemachines.txt -d -l $num_hosts_list $TMP_PATH/list

	num_lists=$(ls $TMP_PATH/ | grep list | wc -l)
}

merge_ping_sweep()
{
	IP_REGEX="([0-9]{1,3}[\.]){3}[0-9]{1,3}"

	cat $PING_PATH/ping_sweep* | grep "report for" | grep -Eo $IP_REGEX | sort -u > $PING_PATH/alivemachines.txt

	split_machines
}

ping_sweep()
{
	echo "Executing Ping Sweep!"

	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_n.txt -sn -n --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_s.txt -sn -n -PS --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_a.txt -sn -n -PA --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_u.txt -sn -n -PU --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_y.txt -sn -n -PY --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_e.txt -sn -n -PE --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_p.txt -sn -n -PP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_m.txt -sn -n -PM --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_r.txt -sn -n -PR > /dev/null &
	wait

	merge_ping_sweep

	echo "Finished Ping Sweep"
}

tcp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
		nmap --top-ports=100 -Pn -n -sSV -A -T3 -e $ETH $ip -oA $TCP_PATH/tcp_scan_$ip > /dev/null
        echo "$ip" >> $TCP_PATH/hosts_complete_tcp.txt
        echo "TCP Scan Complete for Host $ip"
    done
}

udp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
		nmap --top-ports=10 -Pn -n -sUV -T3 -e $ETH $ip -oA $UDP_PATH/udp_scan_$ip > /dev/null
        echo "$ip" >> $UDP_PATH/hosts_complete_udp.txt
        echo "UDP Scan Complete for Host $ip"
    done
}

nmap_full_scan()
{
	echo "Executing TCP and UDP Port Scan"

	for num in `seq 0 $(($num_lists - 1))`
	do
		tcp_nmap_scan $num &
		udp_nmap_scan $num &
	done

	wait

	echo "Finished TCP and UDP Port Scan"
}

main()
{
	init_vars

	start=`date +%s`
	echo "Start Date: $(date '+%X %x')" > $DIRECTORY/time

	ping_sweep
	nmap_full_scan

	end=`date +%s`
	echo "Finished Date: $(date '+%X %x')" >> $DIRECTORY/time
	echo "AVG Total Time: $((end-start)) seconds" >> $DIRECTORY/time
	echo "AVG Total Time: $((end-start)) seconds"

	rm -rf $DIRECTORY/tmp > /dev/null
}

[[ $UID -ne 0 ]] && echo "WARNING! Need to call this script as root!" && exit 1

main

printf "
                        ░█▀▀░▀█▀░█▀█░▀█▀░█▀▀░█░█░█▀▀░█▀▄
                        ░█▀▀░░█░░█░█░░█░░▀▀█░█▀█░█▀▀░█░█
                        ░▀░░░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀░

                      ░▀█▀░█░█░░░█▀▀░█▀█░█▀▄░░░█░█░█▀▀░█▀▀
                      ░░█░░░█░░░░█▀▀░█░█░█▀▄░░░█░█░▀▀█░█▀▀
                      ░░▀░░░▀░░░░▀░░░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░▀▀▀
    ░█░█░█▀█░▀▀█░█▀▀░█▀█░█▀▄░█▀▀░▀█▀░█▀█░▀░█▀▀░░░█▀▀░█▀▀░█▀▄░▀█▀░█▀█░▀█▀░█▀▀
    ░░█░░█░█░▄▀░░█░█░█▀█░█▀▄░█░░░░█░░█▀█░░░▀▀█░░░▀▀█░█░░░█▀▄░░█░░█▀▀░░█░░▀▀█
    ░░▀░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░▀░░░▀▀▀░░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░░░░▀░░▀▀▀
"
