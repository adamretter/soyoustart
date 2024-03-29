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
    --mac)
    MAC="$2"
    shift
    shift
    ;;
    --ip)
    IP="$2"
    shift
    shift
    ;;
    --network)
    NETWORK="$2"
    shift
    shift
    ;;
    --mask)
    MASK="$2"
    shift
    shift
    ;;
    --broadcast)
    BROADCAST="$2"
    shift
    shift
    ;;
    --gateway)
    GATEWAY="$2"
    shift
    shift
    ;;
    --dns)
    DNS="$2"
    shift
    shift
    ;;
    --dns-search)
    DNSSEARCH="$2"
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
	echo "./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release bionic --memory 4096 --disk 40 --cpu 2 --bridge virbr1 --mac 02:00:00:42:9b:84  --ip 54.36.67.139 --network 54.36.67.139 --mask 255.255.255.255 --broadcast 5.196.205.132 --gateway 91.121.89.254 --dns 213.186.33.99 --dns-search evolvedbinary.com --private-bridge virbr2 --private-ip 10.0.2.123 --private-gateway 10.0.2.254"
	exit 0;
fi


SSH_KEY="/home/${USER}/kvm/kvm-keys/${HOSTNAME}"
ID=$(uuidgen)
METADATA_FILE="/tmp/${ID}-meta-data"
NETWORK_CONFIG_FILE="/tmp/${ID}-network-config"

if [ -e $SSH_KEY ]
then
	echo "SSH key for guest: ${SSH_KEY} already exists!"
	exit 1
fi


#cat > $METADATA_FILE <<EOL
#instance-id: ${ID}
#local-hostname: ${HOSTNAME}
#network-interfaces: |
#  iface ens3 inet static
#  hwaddress ether ${MAC}
#  address ${IP}
#  network ${NETWORK}
#  netmask ${MASK}
#  broadcast ${BROADCAST}
#  gateway ${GATEWAY}
#  dns-nameservers ${DNS}
#  dns-search ${DNSSEARCH}
#EOL

cat > $METADATA_FILE <<EOL
instance-id: ${ID}
local-hostname: ${HOSTNAME}
EOL

if [ -n "${PRIVATE_BRIDGE}" ]; then
        cat > $NETWORK_CONFIG_FILE << EOL
version: 2
ethernets:
    ens3:
        addresses:
        - ${IP}/32
        gateway4: ${GATEWAY}
        match:
            macaddress: ${MAC}
        nameservers:
            addresses:
            - ${DNS}
            search:
            - ${DNSSEARCH}
        set-name: ens3
        routes:
        - to: ${GATEWAY}/32
          via: 0.0.0.0
          scope: link
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
    ens3:
        addresses:
        - ${IP}/32
        gateway4: ${GATEWAY}
        match:
            macaddress: ${MAC}
        nameservers:
            addresses:
            - ${DNS}
            search:
            - ${DNSSEARCH}
        set-name: ens3
        routes:
        - to: ${GATEWAY}/32
          via: 0.0.0.0
          scope: link
EOL
fi

ssh-keygen -b 4096 -C "ubuntu@${HOSTNAME}" -f $SSH_KEY

if [ -z ${PASSWORD+x} ]; then
	uvt-kvm create --ssh-public-key-file $SSH_KEY.pub --memory $MEMORY --disk $DISK --cpu $CPU --bridge $BRIDGE --mac $MAC --packages language-pack-en,openssh-server,mosh,git,vim,puppet,screen,ufw --meta-data $METADATA_FILE --network-config $NETWORK_CONFIG_FILE $HOSTNAME arch="amd64" release=$RELEASE label="minimal release"
else
	uvt-kvm create --password $PASSWORD --ssh-public-key-file $SSH_KEY.pub --memory $MEMORY --disk $DISK --cpu $CPU --bridge $BRIDGE --mac $MAC --packages language-pack-en,openssh-server,mosh,git,vim,puppet,screen,ufw --meta-data $METADATA_FILE --network-config $NETWORK_CONFIG_FILE $HOSTNAME arch="amd64" release=$RELEASE label="minimal release"
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
