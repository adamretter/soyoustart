1. Update Hetzner Robot control panel for your new ip address, you should list the reverse DNS name

2. Update to the latest Ubuntu Cloud Images
    ```bash
    #sudo uvt-simplestreams-libvirt sync arch=amd64 release=jammy
    sudo uvt-simplestreams-libvirt sync --source=http://cloud-images.ubuntu.com/minimal/releases arch=amd64 release=jammy
    ```

3. Run this script to create the VM:
    ```bash
    ./create-uvt-kvm.sh --arch amd64 --hostname YOUR-GUEST-NAME --release jammy --memory 4096 --disk 40 --cpu 2 --bridge virbr1 --ip 5.9.162.242 --ip6 2a01:4f8:211:ad5::4 --gateway 148.251.189.87 --gateway6 2a01:4f8:211:ad5::2 --dns 213.133.100.100 --dns-search evolvedbinary.com --private-1-bridge virbr2 --private-1-ip 10.0.2.123 --private-1-next-network 10.0.1.254/32 --private-1-gateway 10.0.2.254 --auto-start
    ```
4. Connect to the new VM:
    ```bash
    ssh -i /root/kvm-keys/YOUR-GUEST-NAME ubuntu@5.9.162.242
    ```

5. Update the VM to the latest packages etc (inside the VM):
    ```bash
    sudo apt-get update && apt-get upgrade && apt-get dist-upgrade
    sudo apt-get autoremove --purge
    ```
