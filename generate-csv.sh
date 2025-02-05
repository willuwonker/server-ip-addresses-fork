#!/usr/bin/env bash

set -euo pipefail

CIDR_REGEX='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'
IP_ADDRESS_REGEX='([0-9]{1,3}[\.]){3}[0-9]{1,3}'

mkdir -p /data
cd /data

cidrs_aws=$(wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "AWS CIDRs: "
echo "$cidrs_aws" | wc -l

cidrs_cloudflare=$(wget -qO- https://www.cloudflare.com/ips-v4 | sort -V)
echo -n "CloudFlare CIDRs: "
echo "$cidrs_cloudflare" | wc -l

cidrs_gcp=$(wget -qO- https://www.gstatic.com/ipranges/cloud.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "GCP CIDRs: "
echo "$cidrs_gcp" | wc -l

cidrs_azure=$(wget -qO- $(wget -qO- -U Mozilla https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519 | grep -Eo 'https://download.microsoft.com/download/\S+?\.json' | head -n 1) | grep -o "$CIDR_REGEX" | sort -V )
echo -n "Azure CIDRs: "
echo "$cidrs_azure" | wc -l

cidrs_linode=$(wget -qO- https://geoip.linode.com/ | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Linode CIDRs: "
echo "$cidrs_linode" | wc -l

cidrs_digitalocean=$(wget -qO- https://digitalocean.com/geo/google.csv | grep -o "$CIDR_REGEX" | sort -V)
echo -n "DigitalOcean CIDRs: "
echo "$cidrs_digitalocean" | wc -l

echo -e "$cidrs_aws\n$cidrs_cloudflare\n$cidrs_gcp\n$cidrs_azure\n$cidrs_linode\n$cidrs_digitalocean\n" | uniq > datacenters.txt

get_csv_of_low_and_high_ip_from_cidr_list()
{
    cidrs=$1
    vendor=$2
    echo "$cidrs" | while read cidr;
    do
        hostmin=$(ipcalc -n $cidr |cut -f2 -d=)
        hostmax=$(ipcalc -b $cidr |cut -f2 -d=)
        echo "\"$cidr\",\"$hostmin\",\"$hostmax\",\"$vendor\""
    done
}
echo '"cidr","hostmin","hostmax","vendor"' > datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_aws" "AWS" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_cloudflare" "CloudFlare" | uniq  >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_gcp" "GCP" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_azure" "Azure" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_linode" "Linode" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_digitalocean" "DigitalOcean" | uniq >> datacenters.csv

mkdir -p /data_country
cd /data_country

wget -nv https://ftp.apnic.net/stats/apnic/delegated-apnic-latest -O delegated-apnic-latest.txt
wget -nv https://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest -O delegated-arin-extended-latest.txt
wget -nv https://ftp.ripe.net/ripe/stats/delegated-ripencc-latest -O delegated-ripencc-latest.txt
wget -nv https://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest -O delegated-afrinic-latest.txt
wget -nv https://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest -O delegated-lacnic-latest.txt

awk -F '|' '{ print $2 }' delegated-*-latest.txt | sort | uniq | grep -E '[A-Z]{2}' > country_code.txt

while read cc; do
    grep "$cc|ipv4|" delegated-*-latest.txt | awk -F '|' '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > ${cc}_IPv4.txt
    grep "$cc|ipv6|" delegated-*-latest.txt | awk -F '|' '{ printf("%s/%d\n", $4, $5) }' > ${cc}_IPv6.txt
done < country_code.txt

echo "Success!"
