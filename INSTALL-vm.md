Request a Virtual MAC from the SoYouStart control panel for your new ip address, you will need that in the command below, e.g. 02:00:00:12:51:ce

Run -

vmbuilder kvm ubuntu --suite trusty --mirror http://91.121.125.139/ftp.ubuntu.com/ubuntu --dest /vm/artifacts --rootsize 20480 --mac 02:00:00:12:51:ce --hostname artifacts --ip 5.196.205.132 --mask 255.255.255.255 --dns 213.186.33.99 --bridge br0 --addpkg linux-image-generic --addpkg acpid --addpkg openssh-server --libvirt qemu:///system

1) Then you need to add serial tty to the guest to allow access via `virsh console`. Do this by connecting via vnc+ssh or editing the image file directly. See:

virsh edit your-guest
Add the line in the `devices` section:

<console type='pty'>
  <target port='0'/>
</console>


virsh vncdisplay your-guest
ssh -L 5901:localhost:5901 this-physical-server
Connect via vncviewer to the guest
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
auto eth0
iface eth0 inet static
        address 5.196.205.132
        netmask 255.255.255.255 
        broadcast 5.196.205.132
        # gateway 91.121.89.254  # gateway must be specified using post-up for OVH config
        post-up /sbin/route add 91.121.89.254 dev eth0
        post-up /sbin/route add default gw 91.121.89.254
        pre-down /sbin/route del 91.121.89.254 dev eth0
        pre-down /sbin/route del default gw 91.121.89.254
        dns-search evolvedbinary.com
        dns-nameservers 213.186.33.99
```


TODO - consider using -- Puppet master and puppet agent to setup the serial port and routes by using a on firstboot script with kvm which calls puppet, e.g. http://pebblecode.com/blog/building-armies-of-servers-with-kvm-and-puppet/


If routing is not configured in the guest, e.g. no output from `route -p` run `sudo  ip r add default via 91.121.89.254 dev eth0 onlink`


3) Update to the latest packages etc

apt-get update && apt-get upgrade && apt-get dist-upgrade 

4) Update to latest ubuntu dist

apt-get install update-manager-core

Change `lts` to `normal` in /etc/update-manager/release-upgrades

sudo do-release-upgrade -d

You will need to run the above command a number of times to get you to the latest version of ubuntu. i.e. trusty -> utopic -> vivid

NOTE - after upgrading to vivid, you will need to reenable the serial console via VNC as vivid uses `systemd` and not `upstart` for managing such things. To do that run the following in the guest

	systemctl enable serial-getty@ttyS0.service
	systemctl start serial-getty@ttyS0.service
	rm /etc/init/ttyS0.conf
