##
# Puppet script for installing KVM on SoYouStart Ubuntu Server
##

package { "ntp":
        ensure => installed
}

service { "ntpd":
    name => "ntp",
    ensure => running,
    enable => true,
    pattern => 'ntpd',
    subscribe => Package["ntp"]
}

package { "cpu-checker":
	ensure => installed
}

exec { "kvm-ok":
	command => "/usr/sbin/kvm-ok",
	subscribe => Package["cpu-checker"]
}

$kvmPackages = [ "qemu-kvm", "libvirt-bin", "ubuntu-vm-builder", "bridge-utils" ]
package { $kvmPackages:
	ensure => installed,
	require => Exec["kvm-ok"]
}

augeas { "interfaces":
        context => "/files/etc/network/interfaces",
        changes => [
		"set auto[2]/1 br0",
		"set iface[2] br0",
		"set iface[2]/bridge_ports eth0",
		"set iface[2]/bridge_stp off",
		"set iface[2]/bridge_fd 0",
		"set iface[2]/bridge_maxwait 0",
		"set iface[3] br0",
		'set iface[3]/post-up[1] "/sbin/ip -family inet6 route add 2001:41D0:1:8Eff:ff:ff:ff:ff dev br0"',
		'set iface[3]/pre-down[2] "/sbin/ip -family inet6 route del 2001:41D0:1:8Eff:ff:ff:ff:ff dev br0"',
		"set auto[3]/1 eth0",
		"set iface[4] eth0",
		"set iface[4]/family inet",
		"set iface[4]/method manual"
        ],
        require => Package["bridge-utils"]
}

exec { "eth0-down":
	command => "/sbin/ifdown eth0",
	subscribe => Augeas["interfaces"]
}

exec { "eth0-up":
        command => "/sbin/ifup eth0",
        subscribe => Exec["eth0-down"]
}

exec { "br0-up":
        command => "/sbin/ifup br0",
        subscribe => Exec["eth0-up"]
}

file { "/etc/vmbuild.cfg":
	require => Package["ubuntu-vm-builder"],
	content => "[DEFAULT]
arch   = amd64
domain = evolvedbinary.com
mask   = 255.255.255.255
net    = 5.196.205.132
bcast  = 5.196.205.132
gw     = 91.121.89.254
dns    = 213.186.33.99
user   = aretter
name   = Adam Retter
pass   = changeme

[kvm]
libvirt     = qemu:///system
bridge      = br0
virtio_net  = true
mem         = 4096
cpus        = 2

[ubuntu]
suite         = vivid
flavour       = virtual
components    = main,universe
addpkg        = openssh-server, git, vim, puppet"
}

