#!/usr/bin/python
from scapy.all import sniff, sendp
from scapy.all import Packet
from scapy.all import ShortField, IntField, LongField, BitField
from scapy.all import Ether, IP, ICMP

import time
import networkx as nx

import sys

def main():
    i = 0
    while(i < 200):
        #time.sleep(1)
        #raw =  raw_input("What do you want to send: ")
        #if raw=="q":
        #    exit()
        now = time.time()
        msg = "send_time: " + "%.6f" % float(now) + " msg: "
        #msg = str(now) + " " + raw

        p = Ether() / IP(src="10.0.0." + str(i+1), dst="10.0.0.2") / ICMP() / msg
        sendp(p, iface = "eth0")
        i = i + 1
        # print msg

if __name__ == '__main__':
    main()
