#!/bin/bash

CLI_PATH=/home/snail/apps/behavioral-model/targets/simple_switch/sswitch_CLI
for i in 1 2 3 4 5 6 7
do
    command_file="commands/commands_s"$i".txt"
    port=`expr 22222 + $i - 1`
    $CLI_PATH openflow.json  $port   < $command_file
done
