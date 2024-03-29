1. Request a Virtual MAC from the SoYouStart control panel for your new ip address, you will need that in the command below, e.g. 06:00:00:42:9b:44


2. Update to the latest Ubuntu Cloud Images
    ```bash
    sudo uvt-simplestreams-libvirt sync arch=amd64 release=focal
    sudo uvt-simplestreams-libvirt sync --source=http://cloud-images.ubuntu.com/minimal/releases arch=amd64 release=focal
    ```

3. Run this script to create the VM:
    ```bash
    ./create-uvt-kvm.sh --hostname YOUR-GUEST-NAME --release focal --memory 4096 --disk 40 --cpu 2 --bridge virbr1 --mac 06:00:00:42:9b:44  --ip 123.123.123.123 --gateway 91.121.89.254 --dns 213.186.33.99 --dns-search evolvedbinary.com --private-bridge virbr2 --private-ip 10.0.2.123 --private-gateway 10.0.2.254 --auto-start
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
