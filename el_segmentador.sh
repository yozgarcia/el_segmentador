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

	SCTP="7,9,20-22,80,179,443,1021,1022,1167,1720,1812,1813,2049,2225,2427,2904,2905,2944,2945,3097,3565,3863-3868,4195,4333,4502,4711,4739,4740,5060,5061,5090,5091,5215,5445,5060,5672,5675,5868,5910-5912,5913,6701-6706,6970,7626,7701,7728,8282,8471,9082,9084,9899-9902,11997-11999,14001,20049,25471,29118,29168,29169,30100,36412,36422-36424,36443,36444,36462,38412,38422,38462,38472"
	TCP="7,9,13,21-23,25-26,37,53,79-81,88,106,110-111,113,119,135,139,143-144,179,199,389,427,443-445,465,513-515,543-544,548,554,587,631,646,873,990,993,995,1025-1029,1110,1433,1720,1723,1755,1900,2000-2001,2049,2121,2717,3000,3128,3306,3389,3986,4899,5000,5009,5051,5060,5101,5190,5357,5432,5631,5666,5800,5900,6000-6001,6646,7070,8000,8008-8009,8080-8081,8443,8888,9100,9999-10000,32768,49152-49157"
	UDP="53,67,123,135,137-138,161,445,631,1434"

	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_n.txt -sn -n --packet-trace --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_s.txt -sn -n --packet-trace -PS$TCP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_a.txt -sn -n --packet-trace -PA$TCP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_u.txt -sn -n --packet-trace -PU$UDP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_y.txt -sn -n --packet-trace -PY$SCTP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_e.txt -sn -n --packet-trace -PE --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_p.txt -sn -n --packet-trace -PP --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_m.txt -sn -n --packet-trace -PM --disable-arp-ping > /dev/null &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PING_PATH/ping_sweep_o.txt -sn -n --packet-trace -PO2 --disable-arp-ping> /dev/null &
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
