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
