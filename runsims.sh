#!/bin/sh


rm utils/plot/flopnalisis.txt

for i in `seq 1 10`;
#for i in `seq 1 1`;
do

	rm -rf ns-3-dce-git/files-*
	sh utils/config-dce-rong-cell.sh
	
	cd ns-3-dce-git
	./waf --run dce-rong-cell
	cd ..
	
	cd utils/plot
	lua flopnalisis.lua >> flopnalisis.txt
	cd ../..

done

