#!/bin/sh

cant_nodes=13
aux=$(($cant_nodes-1))
scenario=$1
proto=$2

for i in `seq 0 $aux`; do

  mkdir ns-3-dce-git/"files-$i"

	seed=`date +%N`
  
  #n=$(($i+1))
	
	sed "s/__N__HERE__/$i/g" utils/boxbox.lua | sed "s/__SEED__HERE__/$seed/g" |  sed "s/__SCENARIO__HERE__/$scenario/g" |  sed "s/__PROTO__HERE__/$proto/g" > ns-3-dce-git/files-$i/'rong-node.lua'


  #cat utils/flopmicro.lua | tr '__N__HERE__' $i > ns-3-dce-git/files-$i/'rong-node.lua'

done
