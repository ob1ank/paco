#!/usr/bin/python
from scapy.all import sniff, sendp, hexdump, DADict, IP, ICMP
from scapy.all import Packet, Ether
from scapy.all import XByteField, DestMACField, SourceMACField, XShortEnumField, XShortField, XIntField, LongField, BitField, MACField
from mininet.cli import CLI
import subprocess
import sys
import struct

finish = []

ETHER_TYPES = DADict(_name="/etc/ethertypes")
ETHER_TYPES['paco'] = 0x0037
ETHER_TYPES['IP'] = 0x0800

class Cpu(Packet):
    name = "cpu"
    fields_desc = [
        XByteField("device_id",1)
    ]

class MyEther(Packet):
    name = "MyEther"
    fields_desc = [
        DestMACField("dst"),
        SourceMACField("src"),
        XShortEnumField("ethertype", 0x0800, ETHER_TYPES)
    ]

class Paco(Packet):
    name = "paco"
    fields_desc = [
        XIntField("ids",0x0),
        XShortField("ori_ethertype",0x0800)
    ]

def str2mac(s):
    return ("%02x:"*6)[:-1] % tuple(map(ord, s))

def install_table(device_id):
    mid = [2, 4, 5, 7, 8, 9]
    tail = [3, 6, 10]
    if device_id in tail:
        command_file = "commands_tail.txt"
    elif device_id in mid:
        command_file = "commands_mid.txt"
    elif device_id == 11:
        command_file = "commands_egress.txt"
    else:
        command_file = "commands_ingress.txt"
    bm_cli = "/home/snail/apps/behavioral-model/tools/runtime_CLI.py"
    json = "paco.json"
    cmd = [bm_cli, "--json", json,
           "--thrift-port", str(22222 + device_id - 1)]
    with open(command_file, "r") as f:
        try:
            output = subprocess.check_output(cmd, stdin = f)
            print output
        except subprocess.CalledProcessError as e:
            print e
            print e.output

def deal_ip(pkt):
    if 1 in finish:
        return
    pkt_str = str(pkt)

    # MyEther
    myether = MyEther(pkt_str[1:])
    mac_dst = myether.sprintf("%MyEther.dst%")
    mac_src = myether.sprintf("%MyEther.src%")
    ethertype = myether.sprintf("%MyEther.ethertype%")
    if ethertype != "IP":
        return   

    # IP
    ip = IP(pkt_str[15:])
    ip_dst = ip.sprintf("%IP.dst%")
    ip_src = ip.sprintf("%IP.src%")
    raw = ip.sprintf("%Raw.load%")[1:-1]
    if ip_src != '10.0.0.1' or ip_dst != '10.0.0.2':
        return

    print "s1 receive."
    install_table(1)
    # send
    interface = "s1-eth3"
    sendp(MyEther(dst=mac_dst,src=mac_src,ethertype=ETHER_TYPES[ethertype]) / IP(dst=ip_dst,src=ip_src) / ICMP() / raw, iface=interface)
    
    finish.append(1)

def deal_paco(pkt, device_id):
    if device_id in finish:
        return
    pkt_str = str(pkt)

    # MyEther
    myether = MyEther(pkt_str[1:])
    mac_dst = myether.sprintf("%MyEther.dst%")
    mac_src = myether.sprintf("%MyEther.src%")
    ethertype = myether.sprintf("%MyEther.ethertype%")
    if ethertype != 'paco':
        return
    
    # Paco
    paco = Paco(pkt_str[15:])
    ids = paco.sprintf("%Paco.ids%")
    ori_ethertype = paco.sprintf("%Paco.ori_ethertype%")
    
    # IP
    ip = IP(pkt_str[21:])
    ip_dst = ip.sprintf("%IP.dst%")
    ip_src = ip.sprintf("%IP.src%")
    raw = ip.sprintf("%Raw.load%")[1:-1]
    if ip_src != '10.0.0.1' or ip_dst != '10.0.0.2':
        return
    
    print 's' + '%d' %device_id + ' receive.'
    install_table(device_id)
    # send
    interface = "s"+ '%d' %(device_id) + "-eth3"
    sendp(MyEther(dst=mac_dst,src=mac_src,ethertype=ETHER_TYPES[ethertype]) / Paco(ids=eval(ids),ori_ethertype=eval(ori_ethertype)) / IP(dst=ip_dst,src=ip_src) / ICMP() / raw, iface=interface)
    
    finish.append(device_id)

def handle_pkt(pkt):
    #print "Receive 1 package, msg: " + pkt.sprintf("%Raw.load%")
    pkt_str = str(pkt)
    if pkt_str[0] > '\x0b' or pkt_str[0] < '\x01':
        return
    device_id = struct.unpack("b",pkt_str[0])[0]
    #_dst = str2mac(pkt_str[1:7])
    #_src = str2mac(pkt_str[7:13])
    #ethertype = pkt_str[13:15]
    #if ethertype == '\x08\x00':
    #    _ethertype = 0x0800
    #elif ethertype == '\x00\x37':
    #    _ethertype = 0x0037
    #else:
    #    return
    if device_id == 1:
        deal_ip(pkt)
    elif device_id > 1 and device_id < 12 :
        deal_paco(pkt, device_id)
    else:
        return

def main():
    #sniff(filter="icmp", prn = lambda x: handle_pkt(x))
    sniff(iface=["s1-eth3","s2-eth3","s3-eth3","s4-eth3","s5-eth3","s6-eth3","s7-eth3","s8-eth3","s9-eth3","s10-eth3","s11-eth3"],prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
