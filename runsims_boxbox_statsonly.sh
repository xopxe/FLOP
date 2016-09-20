#!/bin/sh


#rm utils/plot/flopnalisis.txt

#for proto in bsw ron flop epidemic;
for proto in flop;
do
#for scenario in separation counterflow overlay;
for scenario in separation;
do

	echo $i $scenario $proto
	dir="${scenario}_${proto}"
	cd utils/plot
	cp stats.lua $dir/	
        cd $dir
	rm invdump*.out
	rm deliveryall*.out
	lua stats.lua
	cd ..
	cd ../..
done
done

