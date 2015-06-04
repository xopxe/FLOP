#reset
#clear
set title ""

set xrange [0:100000]
set yrange [0:]

set xlabel 'Transmission time'
set ylabel 'Latency'
set key right bottom
#set term post size 5in, 2in eps enhanced color  

set term svg
set out "arrival.svg"

plot "arrival_node1.data" using 4:6 w points t '' pt 1 lt 1 lc 1, \
     "arrival_node2.data" using 4:6 w points t '' pt 1 lt 1 lc 2, \
     "arrival_node3.data" using 4:6 w points t '' pt 1 lt 1 lc 3

