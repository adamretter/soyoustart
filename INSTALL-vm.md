Request a Virtual MAC from the SoYouStart control panel for your new ip address, you will need that in the command below, e.g. 02:00:00:12:51:ce

Run -

```bash
$ vmbuilder --verbose kvm ubuntu --suite xenial --mirror http://213.32.5.7/ubuntu/ubuntu --dest /vm/your-guest-name --rootsize 40960 --mac 02:00:00:89:26:be --hostname your-guest-name --ip 54.36.67.136 --mask 255.255.255.255 --dns 213.186.33.99 --bridge br0 --addpkg linux-image-generic --addpkg acpid --addpkg openssh-server --libvirt qemu:///system
```

```bash
virsh autostart your-guest
```

1) Then you need to add serial tty to the guest to allow access via `virsh console`. Do this by connecting via vnc+ssh or editing the image file directly. See:

```bash
virsh edit your-guest
```

Add the line in the `devices` section:

```xml
<console type='pty'>
  <target port='0'/>
</console>
```

```bash
virsh start your-guest
```


```bash
virsh vncdisplay your-guest
```

Note the VNC Port number, you should use it as part of the port number in the ssh forwarding below. e.g. if the VNC port number is `3` you should forward the port `5903`.

From the remote client:
ssh -L 5901:localhost:5901 this-physical-server
Connect via vncviewer to the guest

default login is aretter/changeme

Create the file /etc/init/ttyS0.conf:

```
# ttyS0 - getty
#
# This service maintains a getty on ttyS0 from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L 115200 ttyS0 xterm
```

You will need to restart for the above to take effect.


https://help.ubuntu.com/community/KVM/Access
http://serverfault.com/questions/338770/kvm-on-ubuntu-console-connection-displays-nothing

2) Make sure the default gateway is specified in the guest's /etc/network/interfaces using post-up and pre-down and NOT `gateway`, i.e. these lines should be present on eth0:

```
        post-up /sbin/route add 91.121.89.254 dev eth0
        post-up /sbin/route add default gw 91.121.89.254
        pre-down /sbin/route del 91.121.89.254 dev eth0
        pre-down /sbin/route del default gw 91.121.89.254
```

So the config should look like:

```
auto ens3
iface ens3 inet static
        address 5.196.205.132
        netmask 255.255.255.255 
        broadcast 5.196.205.132
        # gateway 91.121.89.254  # gateway must be specified using post-up for OVH config
        post-up /sbin/route add 91.121.89.254 dev ens3
        post-up /sbin/route add default gw 91.121.89.254
        pre-down /sbin/route del 91.121.89.254 dev ens3
        pre-down /sbin/route del default gw 91.121.89.254
        dns-search evolvedbinary.com
        dns-nameservers 213.186.33.99
```


```bash
sudo service networking restart
```

TODO - consider using -- Puppet master and puppet agent to setup the serial port and routes by using a on firstboot script with kvm which calls puppet, e.g. http://pebblecode.com/blog/building-armies-of-servers-with-kvm-and-puppet/


If routing is not configured in the guest, e.g. no output from `route -p` run `sudo  ip r add default via 91.121.89.254 dev eth0 onlink`


3) Update to the latest packages etc

```bash
sudo apt-get update && apt-get upgrade && apt-get dist-upgrade 
```

4) Update to latest ubuntu dist

```bash
sudo apt-get install update-manager-core
```

Change `lts` to `normal` in /etc/update-manager/release-upgrades

```bash
sudo do-release-upgrade -d
```

You will need to run the above command a number of times to get you to the latest version of ubuntu. i.e. trusty -> utopic -> vivid

NOTE - after upgrading to vivid, you will need to reenable the serial console via VNC as vivid uses `systemd` and not `upstart` for managing such things. To do that run the following in the guest

```bash
	systemctl enable serial-getty@ttyS0.service
	systemctl start serial-getty@ttyS0.service
	rm /etc/init/ttyS0.conf
```
