#!/bin/bash

sed -i -e 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config
passwd -d manjaro

systemctl start sshd
systemctl start avahi-daemon
