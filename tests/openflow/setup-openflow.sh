#!/bin/sh
#
# Ubuntu 10.04 LTS
#

set -e

# Trema install.
work_dir=${work_dir:?"work_dir needs to be set"}

if [ ! -d $work_dir/trema/.git ]; then
    cd $work_dir
    git clone git://github.com/rakshasa/trema
    (cd ./trema/ && ./build.rb) > /dev/null
fi

# Open vSwitch install.
ovs_build_dir=/tmp/ovs.$$/

mkdir $ovs_build_dir && cd $ovs_build_dir
git clone git://openvswitch.org/openvswitch

cd ./openvswitch
./boot.sh && ./configure --prefix=$work_dir/ovs/ --with-linux=/lib/modules/`uname -r`/build/ > /dev/null
(make && make install) > /dev/null

install --mode=0644 ./datapath/linux/*_mod.ko /lib/modules/`uname -r`/kernel/drivers/net
depmod

cat ./debian/openvswitch-switch.init | sed -e "s:/usr/:$work_dir/ovs/:g" -e "s:### END INIT INFO:### END INIT INFO\n\nBRCOMPAT=yes:" > ./ovs-switch.tmp
install --mode=0755 ./ovs-switch.tmp /etc/init.d/ovs-switch

# Initialize the Open vSwitch database.
#
# The default database path is '$PREFX/etc/openvswitch/conf.db', if a
# non-default path is used 'ovs-vswitch <db_path>' will be required
# and 'ovs-vswitch --db=<db_path>'.
cd $work_dir
./ovs/bin/ovsdb-tool create $work_dir/ovs/etc/openvswitch/conf.db $ovs_build_dir/openvswitch/vswitchd/vswitch.ovsschema
./ovs/sbin/ovsdb-server --pidfile --detach --remote=punix:$work_dir/ovs/var/run/openvswitch/db.sock $work_dir/ovs/etc/openvswitch/conf.db
./ovs/bin/ovs-vsctl --no-wait init

[ -d $ovs_build_dir ] && rm -rf $ovs_build_dir
