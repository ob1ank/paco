from scapy.all import sniff, sendp
from scapy.all import Packet
from scapy.all import ShortField, IntField, LongField, BitField

import networkx as nx
import sys

class SrcRoute(Packet):
    name = "SrcRoute"
    fields_desc = [
        LongField("preamble", 0),
        IntField("num_valid", 0)
    ]

class My():
    name = "my"
    def __div__(self,other):
        print "My-class print:" + other
        return self

def main():
    nb_hosts = 0
    nb_switches = 0
    links = []
    with open("topo.txt","r") as f:
        line = f.readline()[:-1]
        w, nb_switches = line.split()
        assert(w == "switches")
        line = f.readline()[:-1]
        w, nb_hosts = line.split()
        assert(w == "hosts")
        for line in f:
	    if not f: break
            a, b = line.split()
            links.append( (a, b) )
    nb_hosts = int(nb_hosts)
    nb_switches = int(nb_switches)
    port_map = {}
    for a, b in links:
        if a not in port_map:
            port_map[a] = {}
        if b not in port_map:
            port_map[b] = {}
        assert(b not in port_map[a])
        assert(a not in port_map[b])
        port_map[a][b] = len(port_map[a]) + 1
        port_map[b][a] = len(port_map[b]) + 1
    print "port_map:"
    print port_map
    G = nx.Graph()
    for a,b in links:
        G.add_edge(a,b)
    shortest_paths = nx.shortest_path(G)
    shortest_path = shortest_paths["h1"]["h3"]
    print "\nshortest_paths:"
    print shortest_paths
    print "\nshortest_path:"
    print shortest_path
    port_list = []
    first = shortest_path[1]
    for h in shortest_path[2:]:
        port_list.append(port_map[first][h])
        first = h
    print "\nport_list:"
    print port_list
    port_str = ""
    for p in port_list:
        port_str += chr(p)
    p = SrcRoute(num_valid = 2) / "2" / "sss" 
    print "\np:"
    print p
    print " "
    t = My() / "2" / "3333"
    print "\ntype of t:"
    print t.__class__

if __name__ == '__main__':
    main()
