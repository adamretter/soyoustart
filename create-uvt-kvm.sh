#!/usr/bin/env bash

set -e
set -x

AUTOSTART="false"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --release)
    RELEASE="$2"
    shift
    shift
    ;;
    --hostname)
    HOSTNAME="$2"
    shift
    shift
    ;;
    --memory)
    MEMORY="$2"
    shift
    shift
    ;;
    --disk)
    DISK="$2"
    shift
    shift
    ;;
    --cpu)
    CPU="$2"
    shift
    shift
    ;;
    --bridge)
    BRIDGE="$2"
    shift
    shift
    ;;
    --ip)
    IP="$2"
    shift
    shift
    ;;
    --gateway)
    GATEWAY="$2"
    shift
    shift
    ;;
    --dns)
    DNS+=("$2")
    shift
    shift
    ;;
    --dns-search)
    DNSSEARCH+=("$2")
    shift
    shift
    ;;
    --auto-start)
    AUTOSTART="true"
    shift
    ;;
    -h|--help)
    HELP="YES"
    shift
    ;;
    *)
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -n "${HELP}" ]
then
	echo "./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release focal --memory 4096 --disk 40 --cpu 2 --bridge br0 --ip 5.9.162.241 --broadcast 5.9.162.255 --gateway 148.251.189.87 --dns 213.133.100.100 --dns-search evolvedbinary.com"
	exit 0;
fi


SSH_KEY="/home/aretter/kvm-keys/${HOSTNAME}"
ID=$(uuidgen)
METADATA_FILE="/tmp/${ID}-meta-data"
NETWORK_CONFIG_FILE="/tmp/${ID}-network-config"

if [ -e $SSH_KEY ]
then
	echo "SSH key for guest: ${SSH_KEY} already exists!"
	exit 1
fi


cat > $METADATA_FILE <<EOL
instance-id: ${ID}
local-hostname: ${HOSTNAME}
EOL

# convert DNS array to YAML lines
for i in ${!DNS[@]}; do
	DNS_LINES="${DNS_LINES}        - ${DNS[$i]}"
	if [[ $(($i + 1)) -ne ${#DNS[@]} ]]; then
		DNS_LINES+=$'\n'
	fi
done

# convert DNSSEARCH array to YAML lines
for i in ${!DNSSEARCH[@]}; do
        DNSSEARCH_LINES="${DNSSEARCH_LINES}        - ${DNSSEARCH[$i]}"
        if [[ $(($i + 1)) -ne ${#DNSSEARCH[@]} ]]; then
                DNSSEARCH_LINES+=$'\n'
        fi
done

cat > $NETWORK_CONFIG_FILE << EOL
version: 2
ethernets:
  ens3:
    addresses:
      - ${IP}/28
    gateway4: ${GATEWAY}
    nameservers:
      addresses:
${DNS_LINES}
      search:
${DNSSEARCH_LINES}
    routes:
      - to: ${GATEWAY}/32
        via: 0.0.0.0
        scope: link
EOL


ssh-keygen -b 4096 -C "ubuntu@${HOSTNAME}" -f $SSH_KEY

uvt-kvm create --ssh-public-key-file $SSH_KEY.pub --memory $MEMORY --disk $DISK --cpu $CPU --bridge $BRIDGE --packages language-pack-en,openssh-server,mosh,git,vim,puppet,screen,ufw --meta-data $METADATA_FILE --network-config $NETWORK_CONFIG_FILE $HOSTNAME arch="amd64" release=$RELEASE label="minimal release"

# NOTE: uvt-kvm wait does not work with bridge as it cannot detect the IP
#uvt-kvm wait $HOSTNAME --insecure

if [[ "${AUTOSTART}" -eq "true" ]]; then
	virsh autostart $HOSTNAME
fi

rm $METADATA_FILE
