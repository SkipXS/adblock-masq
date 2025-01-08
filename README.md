# adblock-masq

## Dependencies
- curl : for downloading
- grep : for blocklist processing

## Installation on OpenWrt
```bash
opkg update; opkg install curl grep
wget https://raw.githubusercontent.com/SkipXS/adblock-masq/24.10/adblock-masq -O /etc/init.d/adblock-masq
chmod +x /etc/init.d/adblock-masq
service adblock-masq enable
service adblock-masq start
```

## Update blocklists daily via cron
```bash
0 5 * * * /etc/init.d/adblock-masq start
```

## Configure blocklists
- Blocklists					: /etc/config/adblock-masq
- Blacklist domains one per line: /etc/config/adblock-masq-blacklist
- Whitelist domains one per line: /etc/config/adblock-masq-whitelist

## Check blocklists
- Check if domain is blocked	: grep test.com /tmp/dnsmasq.d/adblock-masq.txt
- Check count of blocked domains: sed -n '$=' /tmp/dnsmasq.d/adblock-masq.txt
