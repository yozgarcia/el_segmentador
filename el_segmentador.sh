#!/bin/bash
echo "Welcome to EL Segmentador"

inicializacao()
{
	echo -en "Report the network interface: "
	read ETH
	echo -en "Report the network scope: "
	read SCOPE
	echo -en "Report the exit path: "
	read PATH
}

merge_ping_scan()
{
	rm -rf $PATH/merge_ping_scan.txt > /dev/null
	touch $PATH/merge_ping_scan.txt

	cat $PATH/ping_scan.txt | grep "report for" | cut -d" " -f5 >> $PATH/merge_ping_scan.txt
	cat $PATH/ping_scan_u.txt | grep "report for" | cut -d" " -f5 >> $PATH/merge_ping_scan.txt
	cat $PATH/ping_scan_s.txt | grep "report for" | cut -d" " -f5 >> $PATH/merge_ping_scan.txt
	cat $PATH/ping_scan_a.txt | grep "report for" | cut -d" " -f5 >> $PATH/merge_ping_scan.txt

	cat $PATH/merge_ping_scan.txt | sort -u > $PATH/alivemachines.txt
	rm -rf $PATH/merge_ping_scan.txt > /dev/null

	num_hosts=$(wc $PATH/alivemachines.txt -l | cut -d" " -f1)
	num_hosts_list=$(($num_hosts/4))

	split $PATH/alivemachines.txt -d -l $num_hosts_list $PATH/list

	num_lists=$(ls $PATH/ | grep list | wc -l)
}

ping_scan()
{
	echo "Executing MultiPingScan"

	nmap -T3 -e $ETH -iL $SCOPE -oN $PATH/ping_scan.txt --open --system-dns -sn &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PATH/ping_scan_u.txt --open --system-dns -sn -PU &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PATH/ping_scan_s.txt --open --system-dns -sn -PS &
	nmap -T3 -e $ETH -iL $SCOPE -oN $PATH/ping_scan_a.txt --open --system-dns -sn -PA &
	wait

	merge_ping_scan

	echo "MultiPingScan Finished"
}

tcp_nmap_scan()
{
    for ip in $(cat $PATH/list0$1)
    do
        nmap -p- -Pn -sV -A --script "discovery and version" -T3 -e $ETH $ip -oN $PATH/tcp/discovery_version_scan_tcp_$ip.txt --open --system-dns
        nmap -p- -Pn -sV -A --script "default and vuln" -T3 -e $ETH $ip -oN $PATH/default_vuln_scan_tcp_$ip.txt --open --system-dns
    done
    echo "TCP Scan Finished"
}

udp_nmap_scan()
{
    for ip in $(cat $PATH/list0$1)
    do
        nmap -p- -Pn -sV -A -sU --script "discovery and version" -T3 -e $ETH $ip -oN $PATH/discovery_version_scan_udp_$ip.txt --open --system-dns
        nmap -p- -Pn -sV -A -sU --script "default and vuln" -T3 -e $ETH $ip -oN $PATH/default_vuln_scan_udp_$ip.txt --open --system-dns
    done 
    echo "UDP Scan Finished"
}

nmap_full_scan()
{
	echo "Executing TCP and UDP MultiScan"

	for num in {0..$(($num_lists - 1))}
	do
		tcp_nmap_scan num &
		udp_nmap_scan num &
	done;

	wait

	echo "TCP and UDP MultiScan Finished"
}

nmap_full_scan

echo "Ty for use yozgarcia's script!"