#reset
#clear
set title ""

set xrange [0:100000]
set yrange [0:1]

set xlabel 'time'
set ylabel 'sub quality'
set key right bottom
#set term post size 5in, 2in eps enhanced color  

set term svg
set out "p_B.svg"

plot "p_B_node1.data" using 1:2 t 'node A' lt 1 lc 1, \
     "p_B_node2.data" using 1:2 t 'node O' lt 1 lc 2, \
     "p_B_node3.data" using 1:2 t 'node B' lt 1 lc 3, \
     

