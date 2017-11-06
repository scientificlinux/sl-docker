# Use network installation
install
url --url="http://ftp.scientificlinux.org/linux/scientific/6x/x86_64/os/"
repo --name="Updates - Security" --baseurl=http://ftp.scientificlinux.org/linux/scientific/6x/x86_64/updates/security/
repo --name="Updates - Fastbugs" --baseurl=http://ftp.scientificlinux.org/linux/scientific/6x/x86_64/updates/fastbugs/

# Use graphical install
graphical
# Firewall configuration
firewall --disabled
firstboot --disabled
# Keyboard layouts
keyboard us
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

# System timezone
timezone UTC --isUtc

# System bootloader configuration
bootloader --location=none
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all
# Disk partitioning information
part / --fstype="ext4" --size=4096

%packages --excludedocs --nobase --nocore --instLangs=en
bash
bind-utils
bzip2
file
hardlink
iputils
iproute
sl-release
passwd
rootfiles
shadow-utils
tar
vim-minimal
which
yum
yum-conf-sl-other
yum-plugin-ovl
# don't need these
-*-firmware
-kernel
-dhcp*

%end

%post

# remove the user anaconda forces us to make
userdel -r none

# these packages are not required, kernel has complex deps
rpm -e --nodeps kernel
yum -y remove e2fsprogs e2fsprogs-libs dash dbus-glib dracut-kernel dracut grubby grub hwdata kbd-misc kbd kernel-firmware libpciaccess libss sl-logos sysvinit-tools redhat-logos upstart xfsprogs

find / -type f -name \*.rpmsave -exec rm {} \;
find / -type f -name \*.rpmnew -exec rm {} \;

# Support for subscription-manager secrets from host
ln -s /run/secrets/etc-pki-entitlement /etc/pki/entitlement-host
ln -s /run/secrets/rhsm /etc/rhsm-host

# Set the language rpm nodocs transaction flag persistently in the
# image yum.conf and rpm macros
LANG="en_US"
echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf
awk '(NF==0&&!done){print "tsflags=nodocs";done=1}{print}' < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf

# turn on fastbugs repo
awk '!x{x=sub("enabled=0","enabled=1")}7' /etc/yum.repos.d/sl-other.repo > /etc/yum.repos.d/out.repo
mv -f /etc/yum.repos.d/out.repo /etc/yum.repos.d/sl-other.repo

# setup at least some locale
rm -f /usr/lib/locale/locale-archive
localedef -v -c -i ${LANG} -f UTF-8 ${LANG}.UTF-8

# cleanup lang files
rm /usr/share/gnupg/help*.txt -f
for dir in locale i18n; do
    find /usr/share/${dir} -mindepth  1 -maxdepth 1 -type d -not \( -name "${LANG}" -o -name POSIX \) -exec rm -rf {} +
done

# A few identical files in /usr could be linked to save space
hardlink -c -v /usr

# Turn off all services, not really running init
for serv in `/sbin/chkconfig|cut -f1`; do /sbin/chkconfig "$serv" off; done;

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
rm -rfv /usr/share/licenses/*
rm -rfv /usr/share/doc/*

# UTC is a good default timezone, you can bind mount in others as needed
rm -f /etc/localtime
mv /usr/share/zoneinfo/UTC /etc/localtime
rm -rfv  /usr/share/zoneinfo

# no point in packaging up these
rm -rfv /var/cache/yum/*
rm -f /etc/nsswitch.conf.bak
rm -f /etc/sysconfig/network-scripts/ifcfg-*
find /var/cache/ -type f -exec rm -f {} \;

# set blank defaults
echo > /etc/hosts.allow
echo > /etc/hosts.deny

# cleanup broken symlinks in /etc
find /etc -type l ! -exec test -e {} \; -print | xargs -i /bin/rm {} \;

# Import the SL keys
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-sl
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-sl6

# Optimize rpmdb indexes
rm -f /var/lib/rpm/__db.*
rpm --rebuilddb
rpm -qa > /dev/null

%end
