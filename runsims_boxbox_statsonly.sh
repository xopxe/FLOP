#!/bin/sh


#rm utils/plot/flopnalisis.txt

for proto in bsw ron flop;
do
for scenario in separation counterflow overlay;
do
	echo $i $scenario $proto
	dir="${scenario}_${proto}"
	cd utils/plot
	cp stats.lua $dir/	
        cd $dir
	rm invdump*.out
	lua stats.lua
	cd ..
	cd ../..
done
done

