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

Release v1.02, License GPL-3.0

"


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

check_interface()
{
	echo -en "Report the Network Interface: "
	read ETH	

	ifconfig | grep : | cut -d: -f1 | grep -v ' ' > $TMP_PATH/eths
	isInFile=$(cat $TMP_PATH/eths | grep -Fxc "$ETH")

	while [ "$isInFile" -eq 0 ]
	do
		echo "WARMING!! Network Interface invalid!"
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
		echo "WARMING!! Scope invalid!"
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

	echo "Ping Scan" > $TMP_PATH/atual_ping_scan.txt
	echo "Ping Scan SYN" > $TMP_PATH/atual_ping_scan_s.txt
	echo "Ping Scan ACK" > $TMP_PATH/atual_ping_scan_a.txt
	echo "Ping Scan UDP" > $TMP_PATH/atual_ping_scan_u.txt
	echo "Ping Scan SCTP INIT" > $TMP_PATH/atual_ping_scan_y.txt
	echo "Ping Scan ICMP" > $TMP_PATH/atual_ping_scan_e.txt
	echo "Ping Scan IP" > $TMP_PATH/atual_ping_scan_o.txt
	echo "Ping Scan ARP" > $TMP_PATH/atual_ping_scan_r.txt

	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan.txt --open -system-dns -sn >> $TMP_PATH/atual_ping_scan.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_s.txt --open --system-dns -sn -PS >> $TMP_PATH/atual_ping_scan_s.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_a.txt --open --system-dns -sn -PA >> $TMP_PATH/atual_ping_scan_a.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_u.txt --open --system-dns -sn -PU >> $TMP_PATH/atual_ping_scan_u.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_y.txt --open --system-dns -sn -PY >> $TMP_PATH/atual_ping_scan_y.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_e.txt --open --system-dns -sn -PE >> $TMP_PATH/atual_ping_scan_e.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_o.txt --open --system-dns -sn -PO >> $TMP_PATH/atual_ping_scan_o.txt &
	nmap -T2 -v -e $ETH -iL $SCOPE -oN $PING_PATH/ping_scan_r.txt --open --system-dns -sn -PR >> $TMP_PATH/atual_ping_scan_r.txt &
	wait

	rm -rf $TMP_PATH/atual_ping_scan.txt
	rm -rf $TMP_PATH/atual_ping_scan_s.txt
	rm -rf $TMP_PATH/atual_ping_scan_a.txt
	rm -rf $TMP_PATH/atual_ping_scan_u.txt
	rm -rf $TMP_PATH/atual_ping_scan_y.txt
	rm -rf $TMP_PATH/atual_ping_scan_e.txt
	rm -rf $TMP_PATH/atual_ping_scan_o.txt
	rm -rf $TMP_PATH/atual_ping_scan_r.txt

	merge_ping_scan

	echo "MultiPingScan Finished"
}

tcp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
    	echo "TCP Scan $ip" > $TCP_PATH/atual_tcp_scan_$ip.txt
        nmap -p- -Pn -sV -A --script "discovery and version" -T4 -v -e $ETH $ip -oN $TCP_PATH/discovery_version_scan_tcp_$ip.txt --open --system-dns >> $TCP_PATH/atual_tcp_scan_$ip.txt
        nmap -p- -Pn -sV -A --script "default and vuln" -T4 -v -e $ETH $ip -oN $TCP_PATH/default_vuln_scan_tcp_$ip.txt --open --system-dns >> $TCP_PATH/atual_tcp_scan_$ip.txt
        echo "$ip" >> $TCP_PATH/hosts_complete_tcp.txt
        echo "TCP Scan Complete for Host $ip"
        rm -rf $TCP_PATH/atual_tcp_scan_$ip.txt
    done
}

udp_nmap_scan()
{
    for ip in $(cat $TMP_PATH/list0$1)
    do
    	echo "TCP Scan $ip" > $UDP_PATH/atual_tcp_scan_$ip.txt
        nmap -p- -Pn -sV -A -sU --script "discovery and version" -T4 -e $ETH $ip -oN $UDP_PATH/discovery_version_scan_udp_$ip.txt --open --system-dns >> $UDP_PATH/atual_udp_scan_$ip.txt
        nmap -p- -Pn -sV -A -sU --script "default and vuln" -T4 -e $ETH $ip -oN $UDP_PATH/default_vuln_scan_udp_$ip.txt --open --system-dns >> $UDP_PATH/atual_udp_scan_$ip.txt
        echo "$ip" >> $UDP_PATH/hosts_complete_udp.txt
        echo "UDP Scan Complete for Host $ip"
        rm -rf $UDP_PATH/atual_udp_scan_$ip.txt
    done 
}

nmap_full_scan()
{
	echo "Executing TCP and UDP MultiScan"

	for num in `seq 0 $(($num_lists - 1))`
	do
		tcp_nmap_scan $num &
		udp_nmap_scan $num &
	done

	wait

	echo "TCP and UDP MultiScan Finished"
}

main()
{
	init_vars

	start=`date +%s`
	echo "Start Date: $(date '+%X %x')" > $DIRECTORY/time

	ping_scan	
	nmap_full_scan

	end=`date +%s`	
	echo "Finished Date: $(date '+%X %x')" >> $DIRECTORY/time
	echo "AVG Total Time: $((end-start)) seconds" >> $DIRECTORY/time
	echo "AVG Total Time: $((end-start)) seconds"

	rm -rf $DIRECTORY/tmp > /dev/null
}

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