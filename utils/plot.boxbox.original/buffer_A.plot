#reset
#clear
set title ""

set xrange [0:100000]
set yrange [0:30]

set xlabel 'time'
set ylabel 'Buffer occupation'
set key right bottom
#set term post size 5in, 2in eps enhanced color  

set term svg
set out "buffer_A.svg"

plot "buffer_A.data" using 1:3:4:5 w errorbars t '' lt 1 lc 1, \
     "buffer_A.data" using 1:7:8:9 w errorbars t '' lt 1 lc 2, \


