##
# Puppet script for setting up base for SoYouStart Ubuntu Server
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

package { "screen":
	ensure => installed
}

package { "git":
	ensure => installed
}

exec { "git-user":
	environment => [ 'HOME=/root' ],
	command => '/usr/bin/git config --global user.name "Adam Retter"',
	subscribe => Package["git"]
}

exec { "git-email":
	environment => [ 'HOME=/root' ],
	command => '/usr/bin/git config --global user.email "adam.retter@googlemail.com"',
	subscribe => Package["git"]
}

# install java 8

exec { "webupd8-java-repo":
	command => "/usr/bin/add-apt-repository ppa:webupd8team/java",
}

exec { "apt-update":
	command => "/usr/bin/apt-get update",
	require => Exec["webupd8-java-repo"]
}

exec { "accept-oracle-license":
        command => '/bin/echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections',
	require => Exec["webupd8-java-repo"]
}

package { "oracle-java8-installer":
	ensure => installed,
	require => Exec["accept-oracle-license"]
}

package { "oracle-java8-set-default":
	ensure => installed,
	subscribe => Package["oracle-java8-installer"]
}

user { "aretter":
	ensure => present,
	groups => [ "sudo" ],
	comment => "Adam Retter",
	managehome => true,
	password => '$1$Oxem9OpZ$W8CaoSzWSlU5kQq6JV3N./'
}

ssh_authorized_key { "aretter@hollowcore.local":
	user => "aretter",
	type => "ssh-rsa",
	key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDHvJ21M2Jfw75K82bEdZIhL9t7N8kUuXOPxKWFs7o6Z+42UGH47lmQrk95OJdhLxlp2paGFng++mMLV1Xf7uLjTUE8lJHJv/TSzC81Q5NSfFXQTn4kpr5BRKgTnXPNYTHcsueeUr6auZDThVG3mU62AvieFeI5MJOE7FlAS4++u2pVG7+H4l48snlKiUDH5oXRLdJtZbED2v6byluSkj6uNThEYoHzHRxvF8Lo12NgQEMBVrHyvBWtHPpZIhCzzzsTEf9+249VqsO3NqTl7vswMhf8z2NYgGjf0w+5A3bJDIpvDRWQ+40uB1bdwqUDuiY8nGSSKwpVOby0cYZjfhjZ"
}

exec { "git-user-aretter":
        environment => [ 'HOME=/home/aretter' ],
        command => '/usr/bin/git config --global user.name "Adam Retter"',
        require => Package["git"],
	subscribe => User['aretter']
}

exec { "git-email-aretter":
        environment => [ 'HOME=/home/aretter' ],
        command => '/usr/bin/git config --global user.email "adam.retter@googlemail.com"',
        require => Package["git"],
	subscribe => User['aretter']
}


augeas { "sshd_config":
	context => "/files/etc/ssh/sshd_config",
	changes => [
		"set PermitRootLogin no"
	],
	require => User["aretter"]
}

