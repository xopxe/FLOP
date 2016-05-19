reset
clear
#set title "Buffer distribution B/C, Overlay scenario, Sector X"
#set xrange [0:50000]
set yrange [0:1]
set xlabel 'Time (sec)'
set ylabel 'Buffer use by flow to B'
set key left bottom
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "buffocup_overlay_X.png"

plot "overlay_ron/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Gossiping', \
     "overlay_bsw/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Spray&Wait', \
     "overlay_flop/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Path sampling'


#set title "Buffer distribution B/C, Overlay scenario, Sector Y"
set key left bottom
set out "buffocup_overlay_Y.png"

plot "overlay_ron/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Gossiping', \
     "overlay_bsw/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Spray&Wait', \
     "overlay_flop/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Path sampling'


unset output

