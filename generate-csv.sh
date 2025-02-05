#!/usr/bin/env bash

set -euo pipefail

CIDR_REGEX='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'
IP_ADDRESS_REGEX='([0-9]{1,3}[\.]){3}[0-9]{1,3}'

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

cidrs_oracle=$(wget -qO- https://docs.cloud.oracle.com/en-us/iaas/tools/public_ip_ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Oracle Cloud CIDRs: "
echo "$cidrs_oracle" | wc -l

cidrs_ibm=$(wget -qO- https://raw.githubusercontent.com/IBM-Cloud/ip-ranges/master/ip-ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "IBM Cloud CIDRs: "
echo "$cidrs_ibm" | wc -l

cidrs_alibaba=$(wget -qO- https://raw.githubusercontent.com/alibaba-cloud/ip-ranges/master/ip-ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Alibaba Cloud CIDRs: "
echo "$cidrs_alibaba" | wc -l


echo -e "$cidrs_aws\n$cidrs_cloudflare\n$cidrs_gcp\n$cidrs_azure\n$cidrs_linode\n$cidrs_digitalocean\n$cidrs_oracle\n$cidrs_ibm\n$cidrs_alibaba\n" | uniq > datacenters.txt

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

# Generate CSV
echo '"cidr","hostmin","hostmax","vendor"' > datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_aws" "AWS" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_cloudflare" "CloudFlare" | uniq  >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_gcp" "GCP" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_azure" "Azure" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_linode" "Linode" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_digitalocean" "DigitalOcean" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_oracle" "Oracle Cloud" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_ibm" "IBM Cloud" | uniq >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_alibaba" "Alibaba Cloud" | uniq >> datacenters.csv

echo "Success!"
