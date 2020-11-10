1. Update Hetzner Robot control panel for your new ip address, you should list the reverse DNS name

2. Update to the latest Ubuntu Cloud Images
    ```bash
    sudo uvt-simplestreams-libvirt sync arch=amd64 release=focal
    sudo uvt-simplestreams-libvirt sync --source=http://cloud-images.ubuntu.com/minimal/releases arch=amd64 release=focal
    ```

3. Run this script to create the VM:
    ```bash
    sudo ./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release focal --memory 4096 --disk 40 --cpu 2 --bridge br0 --ip 123.123.123.123 --gateway 91.121.89.254 --dns 213.133.100.100 --dns-search evolvedbinary.com
    ```
4. Connect to the new VM:
    ```bash
    ssh -i /root/kvm-keys/YOUR-GUEST-NAME ubuntu@123.123.123.123
    ```

6. Update the VM to the latest packages etc (inside the VM):
    ```bash
    sudo apt-get update && apt-get upgrade && apt-get dist-upgrade
    sudo apt-get autoremove --purge
    ```
