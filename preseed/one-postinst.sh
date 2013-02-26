#!/bin/sh

# Author: Jazz Yao-Tsung Wang <jazzwang.tw@gmail.com>
# - 2013-02-26 : First Draft
# distributed under the terms of the GNU GPL version 2 or (at your option) any later version
# see the file "COPYING" for details
# Ref: http://hands.com/d-i/squeeze/start.sh

set -e

## Ref: /usr/share/doc/opennebula/README.Debian.gz @ opennebula package

## Add a new host (node) in OpenNebula pool
## -----------------------------------------
## Disable SSH client WARNING
## Setup SSH client Global variable
echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
## Copy controller ssh key to localhost
if [ -f /var/lib/one/.ssh/id_rsa.pub ]; then
  ### ssh-copy-host for user 'oneadmin'
  cp -p /var/lib/one/.ssh/id_rsa.pub /var/lib/one/.ssh/authorized_keys
fi
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
### Add by 'preseed/run one-postinst.sh'
TM_MAD = [
    name       = "tm_shared",
    executable = "one_tm",
    arguments  = "tm_shared/tm_shared.conf" ]
EOF
su - oneadmin -c "one stop; one start; onehost create localhost im_kvm vmm_kvm tm_ssh dummy"

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
tar zxvf /cdrom/one-templates/ttylinux.tar.gz -C /var/lib/one/one-templates

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
  cat >> /var/lib/one/small_network.net << EOF
NAME = "Small network"
TYPE = FIXED
BRIDGE = virbr0
LEASES = [ IP="192.168.122.2"]
EOF
fi

su - oneadmin -c "onevnet create small_network.net"

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
  cat >> /var/lib/one/ttylinux.one << EOF
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

su - oneadmin -c "onevm create ttylinux.one"



