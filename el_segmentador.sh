#!/bin/bash

PATH=$PATH:/bin:/usr/bin:xxx
export PATH

echo "Welcome to EL Segmentador"

check_interface()
{
	echo -en "Report the Network Interface: "
	read ETH	

	ifconfig | grep : | cut -d: -f1 | grep -v ' ' > /tmp/eths
	isInFile=$(cat /tmp/eths | grep -Fxc "$ETH")

	while [ "$isInFile" -eq 0 ]
	do
		echo "WARMING!! Network Interface invalid!"
		echo -en "Report the Network Interface: "
		read ETH
		isInFile=$(cat /tmp/eths | grep -Fxc "$ETH")
	done
}

check_scope()
{
	echo -en "Report the network scope: "
	read SCOPE
	while [ ! -e $SCOPE ]
	do
		echo "WARMING!! Scope invalid!"
		echo -en "Report the network scope: "
		read SCOPE
	done
}

init_directories()
{
	echo -en "Report the exit DIRECTORY: "
	read DIRECTORY

	mkdir -p $DIRECTORY/ping_scan
	mkdir -p $DIRECTORY/TCP
	mkdir -p $DIRECTORY/UDP
	mkdir -p $DIRECTORY/tmp
	PING_PATH="$DIRECTORY/ping_scan"
	TMP_PATH="$DIRECTORY/tmp"
	TCP_PATH="$DIRECTORY/TCP"
	UDP_PATH="$DIRECTORY/UDP"
}

init_vars()
{
	check_interface
	check_scope
	init_directories

	rm -rf $TCP_PATH/hosts_complete_tcp.txt
	rm -rf $UDP_PATH/hosts_complete_udp.txt
	echo "TCP Hosts Complete Scan" > $TCP_PATH/hosts_complete_tcp.txt
	echo "UDP Hosts Complete Scan" > $UDP_PATH/hosts_complete_udp.txt
}

split_machines()
{
	num_hosts=$(wc $PING_PATH/alivemachines.txt -l | cut -d" " -f1)
	num_hosts_list=$(( $num_hosts > 4 ? $(($num_hosts/4)) : 1 ))

	split $PING_PATH/alivemachines.txt -d -l $num_hosts_list $TMP_PATH/list

	num_lists=$(ls $TMP_PATH/ | grep list | wc -l)
}

merge_ping_scan()
{
	IP_REGEX="([0-9]{1,3}[\.]){3}[0-9]{1,3}"

	cat $PING_PATH/ping_scan* | grep "report for" | grep -Eo $IP_REGEX | sort -u > $PING_PATH/alivemachines.txt

	split_machines
}

ping_scan()
{
	echo "Executing MultiPingScan"

	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan.txt --open -system-dns -sn > /dev/null & 
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_u.txt --open --system-dns -sn -PU > /dev/null & 
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_s.txt --open --system-dns -sn -PS > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_a.txt --open --system-dns -sn -PA > /dev/null &
	wait

	merge_ping_scan

	echo "MultiPingScan Finished"
}

tcp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
        nmap -p- -Pn -sV -A --script "discovery and version" -T3 -e $ETH $ip -oN $TCP_PATH/discovery_version_scan_tcp_$ip.txt --open --system-dns
        nmap -p- -Pn -sV -A --script "default and vuln" -T3 -e $ETH $ip -oN $TCP_PATH/default_vuln_scan_tcp_$ip.txt --open --system-dns
        echo "$ip" >> $TCP_PATH/hosts_complete_tcp.txt
    done
    echo "TCP Scan Finished"
}

udp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
        nmap -p- -Pn -sV -A -sU --script "discovery and version" -T3 -e $ETH $ip -oN $UDP_PATH/discovery_version_scan_udp_$ip.txt --open --system-dns
        nmap -p- -Pn -sV -A -sU --script "default and vuln" -T3 -e $ETH $ip -oN $UDP_PATH/default_vuln_scan_udp_$ip.txt --open --system-dns
        echo "$ip" >> $UDP_PATH/hosts_complete_udp.txt
    done 
    echo "UDP Scan Finished"
}

nmap_full_scan()
{
	echo "Executing TCP and UDP MultiScan"

	for num in `seq 0 $(($num_lists - 1))`
	do
		tcp_nmap_scan $num &
		udp_nmap_scan $num &
	done;

	wait

	echo "TCP and UDP MultiScan Finished"
}

main()
{
	init_vars
	ping_scan
	nmap_full_scan

	echo "Ty for use yozgarcia's script!"
	rm -rf $DIRECTORY/tmp > /dev/null
}

main

