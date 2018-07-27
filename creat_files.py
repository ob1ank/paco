#!/usr/bin/python
i = 1 
while(i < 201):
    f = open("commands_new/" + str(i) + ".txt", 'w')
    command = "table_add forward_ipv4 ipv42paco 10.0.0." + str(i) + " 10.0.0.2 => 0x1040000 3"
    f.write(command)
    f.close
    i = i + 1
