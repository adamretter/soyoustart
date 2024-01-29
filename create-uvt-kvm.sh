#!/usr/bin/env bash

set -e
set -x

ARCH="amd64"
LABEL="minimal release"
AUTOSTART="false"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --arch)
    ARCH="$2"
    shift
    shift
    ;;
    --release)
    RELEASE="$2"
    shift
    shift
    ;;
    --label)
    LABEL="$2"
    shift
    shift
    ;;
    --hostname)
    HOSTNAME="$2"
    shift
    shift
    ;;
    --password)
    PASSWORD="$2"
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
    --ip6)
    IP6="$2"
    shift
    shift
    ;;
    --gateway)
    GATEWAY="$2"
    shift
    shift
    ;;
    --gateway6)
    GATEWAY6="$2"
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
    --private-bridge)
    PRIVATE_BRIDGE="$2"
    shift
    shift
    ;;
    --private-ip)
    PRIVATE_IP="$2"
    shift
    shift
    ;;
    --private-gateway)
    PRIVATE_GATEWAY="$2"
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
	echo "./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release focal --memory 4096 --disk 40 --cpu 2 --bridge virbr1 --ip 5.9.162.242 --ip6 2a01:4f8:211:ad5::4 --gateway 148.251.189.87 --gateway6 2a01:4f8:211:ad5::2 --dns 213.133.100.100 --dns-search evolvedbinary.com --private-bridge virbr2 --private-ip 10.0.2.123 --private-gateway 10.0.2.254"
	exit 0;
fi


SSH_KEY="/home/aretter/kvm/kvm-keys/${HOSTNAME}"
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

if [ -n "${PRIVATE_BRIDGE}" ]; then
        cat > $NETWORK_CONFIG_FILE << EOL
version: 2
ethernets:
  enp1s0:
    addresses:
      - ${IP}/32
      - ${IP6}/64
    nameservers:
      addresses:
${DNS_LINES}
      search:
${DNSSEARCH_LINES}
    routes:
      - to: 0.0.0.0/0
        via: ${GATEWAY}
        on-link: true
      - to: "::/0"
        via: "${GATEWAY6}"
        on-link: true
  enp7s0:
    addresses:
      - ${PRIVATE_IP}/24
    routes:
      - to: 10.0.1.254/32
        via: ${PRIVATE_GATEWAY}
EOL
else
	cat > $NETWORK_CONFIG_FILE << EOL
version: 2
ethernets:
  enp1s0:
    addresses:
      - ${IP}/32
      - ${IP6}/64
    nameservers:
      addresses:
${DNS_LINES}
      search:
${DNSSEARCH_LINES}
    routes:
      - to: 0.0.0.0/0
        via: ${GATEWAY}
        on-link: true
      - to: "::/0"
        via: "${GATEWAY6}"
        on-link: true
EOL
fi

ssh-keygen -b 4096 -C "ubuntu@${HOSTNAME}" -f $SSH_KEY

if [ -z ${PASSWORD+x} ]; then
	uvt-kvm create --ssh-public-key-file $SSH_KEY.pub --guest-arch $ARCH --memory $MEMORY --disk $DISK --cpu $CPU --bridge $BRIDGE --packages language-pack-en,openssh-server,mosh,git,vim,puppet,screen,ufw --meta-data $METADATA_FILE --network-config $NETWORK_CONFIG_FILE $HOSTNAME arch=$ARCH release=$RELEASE label="$LABEL"
else
	uvt-kvm create --password $PASSWORD --ssh-public-key-file $SSH_KEY.pub --guest-arch $ARCH --memory $MEMORY --disk $DISK --cpu $CPU --bridge $BRIDGE --packages language-pack-en,openssh-server,mosh,git,vim,puppet,screen,ufw --meta-data $METADATA_FILE --network-config $NETWORK_CONFIG_FILE $HOSTNAME arch=$ARCH release=$RELEASE label="$LABEL"
fi


# NOTE: uvt-kvm wait does not work with bridge as it cannot detect the IP
#uvt-kvm wait $HOSTNAME --insecure

if [ -n "${PRIVATE_BRIDGE}" ]; then
	virsh attach-interface --domain ${HOSTNAME} --type bridge --source ${PRIVATE_BRIDGE} --model virtio --config --live
fi

if [[ "${AUTOSTART}" -eq "true" ]]; then
	virsh autostart $HOSTNAME
fi

rm $METADATA_FILE
