#!/bin/sh /etc/rc.common
# 0 5 * * * /etc/init.d/adblock-masq start
# Author: SkipXS
# Thanks to: @Lynx, @Wizballs, @Stangri (OpenWrt forum)

START=99
STOP=4

EXTRA_COMMANDS="check"

start() 
{
	# Waiting for WAN to come up after reboot
	# sleep 60
	
	get_config
		
	download_blocklists
	
	generate_blocklist
	
	# Move generated blocklist and restart dnsmasq
	mv /tmp/adblock-masq.txt /tmp/dnsmasq.d/adblock-masq.txt 
	/etc/init.d/dnsmasq restart >/dev/null 
}

stop(){
	# Remove generated blocklist and restart dnsmasq
	rm /tmp/dnsmasq.d/adblock-masq.txt 
	/etc/init.d/dnsmasq restart >/dev/null 
}

restart()
{
	stop
	start
}

check() {
	grep "$1" /tmp/dnsmasq.d/adblock-masq.txt
}

get_config()
{
	# Generate config, blacklist, whitelist, /tmp/dnsmasq.d-folder and cron entry if not existant
	if [ ! -f "/etc/config/adblock-masq" ]
		then cat > "/etc/config/adblock-masq" <<-EOT
	# adblock-masq: configuration
	# One or more dnsmasq blocklist urls separated by spaces
	blocklist_urls="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/multi.txt"
	EOT
	fi
	
	if [ ! -f "/etc/config/adblock-masq-blacklist" ]
	 then cat > "/etc/config/adblock-masq-blacklist" <<-EOT
	EOT
	fi
	
	if [ ! -f "/etc/config/adblock-masq-whitelist" ]
	 then cat > "/etc/config/adblock-masq-whitelist" <<-EOT
	EOT
	fi
	
	mkdir -p /tmp/dnsmasq.d
		
	. "/etc/config/adblock-masq"
}

download_blocklists()
{
	# Download blocklist(s), if more than one append
	for blocklist_url in ${blocklist_urls}
	do
		if [ ! -f "/tmp/adblock-masq.txt" ]
			then wget "${blocklist_url}" -O /tmp/adblock-masq.txt
		else
			wget "${blocklist_url}" -O ->> /tmp/adblock-masq.txt
		fi
	done
}

generate_blocklist()
{
	# Only take the entries between /.../ 
	awk '{split($0, a, /\//); print a[2]}' /tmp/adblock-masq.txt > /tmp/tmp.txt && mv /tmp/tmp.txt /tmp/adblock-masq.txt
	
	# Add blacklisted
	cat /etc/config/adblock-masq-blacklist >> /tmp/adblock-masq.txt
	
	# Remove non domain entries
	sed -i -E '\~^[[:alnum:]][[:alnum:].-]*$~!d' /tmp/adblock-masq.txt
	
	# Remove duplicates
	awk '!seen[$0]++' /tmp/adblock-masq.txt > /tmp/tmp.txt && mv /tmp/tmp.txt /tmp/adblock-masq.txt
	
	# Remove whitelisted
	grep -Fvxf /etc/config/adblock-masq-whitelist /tmp/adblock-masq.txt > /tmp/tmp.txt && mv /tmp/tmp.txt /tmp/adblock-masq.txt

	# Generate actual filterlist using 0.0.0.0
	# NXDOMAIN would be (awk '{print "local=/" $1  "/"}')
	awk '{print "address=/" $1  "/#"}' /tmp/adblock-masq.txt > /tmp/tmp.txt && mv /tmp/tmp.txt /tmp/adblock-masq.txt
}