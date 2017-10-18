# Use network installation
url --url="http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/os/"
repo --name="Updates - Security" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7/x86_64/updates/security/
repo --name="Updates - Fastbugs" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7/x86_64/updates/fastbugs/
repo --name="SL7 Extras" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7x/external_products/extras/x86_64/

# Use graphical install
graphical
# Firewall configuration
firewall --disabled
firstboot --disabled
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Reboot after installation
reboot

# Root password
rootpw --iscrypted --lock locked
user --name=none

# System services
services --disabled="chronyd"
# System timezone
timezone UTC --isUtc --nontp

# System bootloader configuration
bootloader --disabled
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="xfs" --size=4096

%packages --excludedocs --nobase --nocore --instLangs=en
bash
bind-utils
bzip2
file
findutils
sl-release
passwd
rootfiles
shadow-utils
systemd
tar
vim-minimal
which
yum
yum-conf-repos
yum-plugin-ovl
# don't need these
-*-firmware
-kernel
-firewalld
-firewalld-filesystem
-iptables
-ip6tables
-libteam
-qemu-guest-agent
-teamd

%end

%addon com_redhat_kdump --disable
%end

%post

# remove the user anaconda forces us to make
userdel -r none

# these packages are not required, kernel has complex deps
rpm -e --nodeps kernel
yum -y remove bind-libs bind-libs-lite bind-utils dhcp* dracut-network e2fsprogs e2fsprogs-libs ethtool GeoIP iptables libnetfilter_conntrack libnfnetlink libmnl libss qemu-guest-agent sl-logos snappy sysvinit-tools redhat-logos xfsprogs

# Set the language rpm nodocs transaction flag persistently in the
# image yum.conf and rpm macros
LANG="en_US"
echo "%_install_langs $LANG" > /etc/rpm/macros.image-language-conf
awk '(NF==0&&!done){print "override_install_langs='$LANG'\ntsflags=nodocs";done=1}{print}' < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
mkdir -p /etc/yum.repos.d/

# setup at least some locales
rm -f /usr/lib/locale/locale-archive
localedef -v -c -i ${LANG} -f UTF-8 ${LANG}.UTF-8
localedef -v -c -i en_US -f UTF-8 C.UTF-8


find / -type f -name \*.rpmsave -exec rm {} \;
find / -type f -name \*.rpmnew -exec rm {} \;

# A few identical files in /usr could be linked to save space
hardlink -c -v /usr

# systemd wrongly expects "unpopulated /etc" when /etc/machine-id does not exist
# so make it, but be empty
touch --reference=/etc/redhat-release /etc/machine-id

# content of /run can not be prepared if /run is tmpfs (disappears on reboot)
umount /run
systemd-tmpfiles --create --boot
rm -f /var/run/nologin

# These are not useful in a container
rm /usr/lib/rpm/rpm.daily
rm /etc/yum/version-groups.conf
rm -f /usr/sbin/{glibc_post_upgrade.x86_64,sln}
rm -rfv /etc/logrotate.d/*
rm -rfv /usr/lib64/nss/unsupported-tools/
rm -rfv /usr/share/gcc*/python
rm -rfv /var/lib/yum/*
rm -rfv /etc/yum/protected.d
rm -rfv /usr/lib/udev/*
rm -rfv /usr/share/icons/*
rm -rfv /etc/dbus-1/* /usr/share/dbus-1/*

# No real hardware for this to make sense
rm -f /etc/udev/hwdb.bin
rm -f /etc/udev/rules.d/*
rm -f /etc/dhcp/dhclient*
rm -rfv /usr/lib/udev/hwdb.d/*
rm -rfv /boot/*

# These utils are old and not that useful
rm -f /var/db/Makefile
rm -f /usr/bin/oldfind
rm -f /usr/bin/pinky
rm -f /usr/bin/script

# Licences are stored in rpmdb, doc can be found elsewhere
rm -rf /usr/share/licenses/*
rm -rf /usr/share/doc/*

# leave systemd mostly intact in the container, must still mount /sys/fs/cgroup if you care
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -fv $i; done)
rm -rfv /lib/systemd/system/multi-user.target.wants/*
rm -rfv /lib/systemd/system/local-fs.target.wants/*
rm -rfv /lib/systemd/system/sockets.target.wants/*udev*
rm -rfv /lib/systemd/system/sockets.target.wants/*initctl*
rm -rfv /lib/systemd/system/basic.target.wants/*
rm -rfv /lib/systemd/system/anaconda.target.wants/*
rm -rfv /etc/systemd/system/*.wants/*

# UTC is a good default timezone, you can bind mount in others as needed
rm -f /etc/localtime
mv /usr/share/zoneinfo/UTC /etc/localtime
# leave zoneinfo in container by request
#rm -rf  /usr/share/zoneinfo

# no point in packaging up these
rm -rfv /var/log/yum.log
rm -rfv /var/cache/yum/*
rm -rfv /etc/firewalld/*
rm -f /etc/nsswitch.conf.bak
rm -f /etc/sysconfig/network-scripts/ifcfg-*
find /var/cache/ -type f -exec rm -fv {} \;

# set blank defaults
echo > /etc/hosts.allow
echo > /etc/hosts.deny

# cleanup broken symlinks in /etc
find /etc -type l ! -exec test -e {} \; -print | xargs -i /bin/rm -fv {} \;

# cleanup unused triggers
mv /usr/libexec/sl-release/set-slrelease.sh /tmp
rm -f /usr/libexec/sl-release/*
mv /tmp/set-slrelease.sh /usr/libexec/sl-release/

# populate possible needed slreleasever
mkdir -p /etc/yum/vars
echo 7 > /etc/yum/vars/slreleasever

# Import the SL keys
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-sl
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-sl7

# Optimize rpmdb indexes
rm -f /var/lib/rpm/__db.*
rpm --rebuilddb
rpm -qa > /dev/null

%end
