#!/bin/sh

# Author: Jazz Yao-Tsung Wang <jazzwang.tw@gmail.com>
# - 2013-02-26 : First Draft
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
# Ref: http://hands.com/d-i/squeeze/start.sh

set -e

## Copy one related script to /var/lib/one
if [ -d /var/lib/one ]; then
  cp /media/cdrom/preseed/one-init /var/lib/one/.
  cp /media/cdrom/preseed/one-test /var/lib/one/.
fi

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package

## Add a new host (node) in OpenNebula pool
## -----------------------------------------
## Disable SSH client WARNING
## Setup SSH client Global variable
if [ -f /etc/ssh/ssh_config ]; then
  echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
fi
## Copy controller ssh key to localhost
## - ssh key exchange for user 'oneadmin'
if [ ! -f /var/lib/one/.ssh/authorized_keys ]; then
  cp -p /var/lib/one/.ssh/id_rsa.pub /var/lib/one/.ssh/authorized_keys
fi

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package
##
## 4.2 If the node and controller are the same server
## You need to enable 'tm_shared' in '/etc/one/oned.conf' by uncommenting:
## -------------------
## # TM_MAD = [
## #     name       = "tm_shared",
## #     executable = "one_tm",
## #     arguments  = "tm_shared/tm_shared.conf" ]
## -------------------
## Restart OpenNebula and add the node:
##   oneadmin@controller> one stop; one start
##   oneadmin@controller> onehost create localhost im_kvm vmm_kvm tm_ssh dummy

if [ -f /etc/one/oned.conf ]; then
  cat >> /etc/one/oned.conf << EOF

### Add by 'one-postinst.sh'
TM_MAD = [
    name       = "tm_shared",
    executable = "one_tm",
    arguments  = "tm_shared/tm_shared.conf" ]
### Add by 'one-postinst.sh'
EOF
fi

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package
##
## Sample setup
## -----------------------------------------
## Here is a sample setup which is adapted from
## <http://www.opennebula.org/documentation:rel3.2:vmg>
## It's based on a simple and small image of TTYLinux <http://minimalinux.org/ttylinux/>
## Download a tarball from OpenNebula project :
##   oneadmin@controller> cd
##   oneadmin@controller> mkdir one-templates
##   oneadmin@controller> cd one-templates
##   oneadmin@controller> wget http://dev.opennebula.org/attachments/download/170/ttylinux.tar.gz
##   oneadmin@controller> tar xvzf ttylinux.tar.gz

mkdir -p /var/lib/one/one-templates
if [ -f /root/ttylinux.tar.gz ]; then
  tar zxvf /root/ttylinux.tar.gz -C /var/lib/one/one-templates
fi

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package
##
## Then, create a first virtual network (using virbr0 as bridge by default) :
##   oneadmin@controller> vi small_network.net
##  -------------------
##  NAME = "Small network"
##  TYPE = FIXED
##  # virbr0 = bridge device used by libvirt /etc/libvirt/qemu/networks/default.xml
##  BRIDGE = virbr0
##  LEASES = [ IP="192.168.122.2"]
##  -------------------
##    oneadmin@controller> onevnet create small_network.net
##    oneadmin@controller> onevnet list
##    ID USER     NAME              TYPE BRIDGE P #LEASES
##     0 oneadmin Small network    Fixed virbr0 N       0

if [ ! -f /var/lib/one/small_network.net ]; then
  cat > /var/lib/one/small_network.net << EOF
NAME = "Small network"
TYPE = FIXED
BRIDGE = virbr0
LEASES = [ IP="192.168.122.2"]
EOF
fi

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package
##
## Finally, you can create the template configuration for this small VM :
## 
##   oneadmin@controller> vi ttylinux.one
## -------------------
## NAME   = ttylinux
## CPU    = 0.1
## MEMORY = 64
## DISK   = [
##   source   = "/var/lib/one/one-templates/ttylinux.img",
##   target   = "hda",
##   readonly = "no" ]
## NIC    = [ NETWORK = "Small network" ]
## -------------------
##   oneadmin@controller> onevm create ttylinux.one

if [ ! -f /var/lib/one/ttylinux.one ]; then
  cat > /var/lib/one/ttylinux.one << EOF
NAME   = ttylinux
CPU    = 0.1
MEMORY = 64
DISK   = [
  source   = "/var/lib/one/one-templates/ttylinux.img",
  target   = "hda",
  readonly = "no" ]
NIC    = [ NETWORK = "Small network" ]
EOF
fi

## Install Chinese language pack for SunStone
## Reference: http://blog.opennebula.org/?p=2771
# TODO: Check /usr/share/opennebula/sunstone/public/locale

## Enable OCCI Server 
## FIXME: there is a bug of opennebula 3.2.1-2 package
chmod a+x /usr/lib/one/ruby/cloud/occi/occi-server.rb
## -----------------------------
## Ref: https://github.com/gwdg/rOCCI-server
## -----------------------------
##

gem install bundler
wget https://github.com/gwdg/rOCCI-server/archive/0.5.3.tar.gz -O /root/rOCCI-server_0.5.3.tar.gz
