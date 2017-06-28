#!/usr/bin/python
from scapy.all import sniff, sendp
from scapy.all import Packet
from scapy.all import ShortField, IntField, LongField, BitField
from scapy.all import Ether, IP, ICMP

import time
import networkx as nx

import sys

def main():
    while(1):
<<<<<<< HEAD
        time.sleep(4)
=======
        time.sleep(3)
>>>>>>> 72d349f90407c0440020dfb8e54fe8b0ad87b7a7
        #raw =  raw_input("What do you want to send: ")
        #if raw=="q":
        #    exit()
        now = time.time()
        msg = "send_time: " + "%.6f" % float(now) + " msg: "
        #msg = str(now) + " " + raw

<<<<<<< HEAD
        p = Ether() / IP(src="10.0.0.1", dst="10.0.0.2") / ICMP() / msg
=======
        p = Ether() / IP(src="10.0.0.1", dst="10.0.0.2") / ICMP() / "msg"
>>>>>>> 72d349f90407c0440020dfb8e54fe8b0ad87b7a7
        sendp(p, iface = "eth0")
        # print msg

if __name__ == '__main__':
    main()
