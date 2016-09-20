#!/bin/sh


#rm utils/plot/flopnalisis.txt

for i in `seq 1 1`;
#for i in `seq 21 30`;
do
#for proto in bsw ron flop epidemic;
for proto in flop;
do
#for scenario in separation counterflow overlay;
for scenario in separation;
do
	echo $i $scenario $proto

	rm -rf ns-3-dce-git/files-*
	sh utils/config-dce-rong-boxbox.sh $scenario $proto
	
	cd ns-3-dce-git
	./waf --run "dce-rong-boxbox 10"
	cd ..
	
	dir="${scenario}_${proto}"
	cd utils/plot
	mkdir -p $dir
	lua analisis-boxbox.lua > $dir/$i.txt

	cd $dir
	cp ../stats.lua stats.lua
	lua stats.lua
	cd ..

	cd ../..

done
done
done

