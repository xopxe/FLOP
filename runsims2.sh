#!/bin/sh


rm utils/plot/flopnalisis2.txt

for i in `seq 1 10`;
#for i in `seq 1 1`;
do

	rm -rf ns-3-dce-git/files-*
	sh utils/config-dce-rong-cell2.sh
	
	cd ns-3-dce-git
	./waf --run dce-rong-cell
	cd ..
	
	cd utils/plot
	lua flopnalisis2.lua >> flopnalisis2.txt
	cd ../..

done

