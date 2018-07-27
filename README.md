# Paco

> This repository is the code that simulates the paco protocol and compares the paco protocol with the openflow protocol. The p4<sub>14</sub> code that implements the paco protocol can be seen in [paco.p4](https://github.com/an15m/paco/blob/master/p4src/paco.p4).
> 
> It toal include 3 experiments.
> - [paco simulate experiment](#paco-simulate-experiment)
> - [paco time delay experiment](#paco-time-delay-experiment)
> - [paco compares with openflow experiment](#paco-compares-with-openflow-experiment)
>
> To run the experiments, you need first install the [Requirements](#requirements)

## Requirements
>  The experimental environment was built on ubuntu14.04

1. download and install bmv2
```
git clone https://github.com/p4lang/behavioral-model.git
cd behavioral-model
git checkout 1.2.0
./install_deps.sh
./autogen.sh
./configure
make
[sudo] make install
```

2. download and install p4c-bm
```
git clone https://github.com/p4lang/p4c-bm.git
cd p4c-bm
git checkout 1.2.0
sudo pip install -r requirements.txt
sudo python setup.py install
```

3. download and install mininet
```
git clone https://github.com/mininet/mininet.git
cd mininet
git checkout 2.2.1
./util/install.sh
```

4. download and install OpenVswitch
```
# get the source code
wget http://openvswitch.org/releases/openvswitch-2.4.0.tar.gz
tar -zxvf openvswitch-2.4.0.tar.gz
cd openvswitch-2.4.0

# Check the existing version and delete it, note that everyone's version may be different
lsmod | grep openvswitch
rmmod openvswitch
find / -name openvswitch.ko –print
rm /lib/modules/*-generic/extra/openvswitch.ko

# build and install ovs
sh boot.sh
./configure --with-linux=/lib/modules/`uname -r`/build
make
make install
make modules_install
/sbin/modprobe openvswitch
mkdir -p /usr/local/etc/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema  2>/dev/null
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                --private-key=db:Open_vSwitch,SSL,private_key \
                --certificate=db:Open_vSwitch,SSL,certificate \
                --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                --pidfile --detach
ovs-vsctl --no-wait init
ovs-vswitchd --pidfile --detach

# note: every time you want to run ovs you should run the last three commands again. 
# For your convenience, you'd better put them in ovs_start.sh
```

## paco simulate experiment

The first experiment is to simulates the paco protocol. The code is on the *master* branch.

1. Preparations
  ls
  ds

## paco time delay experiment

sss


## paco compares with openflow experiment

sss
