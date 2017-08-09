#!/usr/bin/python
i = 1 
while(i < 201):
    f = open("commands_ip/" + str(i) + ".txt", 'w')
    command = "table_add deal_ipv4 next_hop 10.0.0." + str(i) + " 10.0.0.2 => 2"
    f.write(command)
    f.close
    i = i + 1
