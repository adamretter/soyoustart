1. Request a Virtual MAC from the SoYouStart control panel for your new ip address, you will need that in the command below, e.g. 06:00:00:42:9b:44


2. Update to the latest Ubuntu Cloud Images
    ```bash
    sudo uvt-simplestreams-libvirt sync arch=amd64 release=focal
    sudo uvt-simplestreams-libvirt sync --source=http://cloud-images.ubuntu.com/minimal/releases arch=amd64 release=focal
    ```

3. Run this script to create the VM:
    ```bash
    ./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release bionic --memory 4096 --disk 40 --cpu 2 --bridge br0 --mac 06:00:00:42:9b:44  --ip 123.123.123.123 --network 54.36.67.139 --mask 255.255.255.255 --broadcast 5.196.205.132 --gateway 91.121.89.254 --dns 213.186.33.99 --dns-search evolvedbinary.com --auto-start
    ```
4. Connect to the new VM:
    ```bash
    ssh -i /root/kvm-keys/YOUR-GUEST-NAME ubuntu@123.123.123.123
    ```

5. Update the VM to the latest packages etc (inside the VM):
    ```bash
    sudo apt-get update && apt-get upgrade && apt-get dist-upgrade
    sudo apt-get autoremove --purge
    ```
