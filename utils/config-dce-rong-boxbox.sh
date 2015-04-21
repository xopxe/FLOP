#!/bin/sh

# must be run as follows:
# /RonSimu$ rm -rf ns-3-dce-git/files-*; sh utils/config-dce-rong-boxbox.sh 30


cant_nodes=$1
cant_tokens=$2

aux=$(($cant_nodes-1))

for i in `seq 0 $aux`; do

  mkdir ns-3-dce-git/"files-$i"
  
  #n=$(($i+1))
	
	sed "s/__N__HERE__/$i/g" utils/boxbox.lua > ns-3-dce-git/files-$i/'rong-node.lua'
  #cat utils/boxbox.lua | tr '__N__HERE__' $i > ns-3-dce-git/files-$i/'rong-node.lua'

done
