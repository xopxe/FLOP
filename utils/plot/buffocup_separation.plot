reset
clear
#set title "Buffer distribution A/C, Separation scenario, Sector X"
#set xrange [0:50000]
set yrange [0:1]
set xlabel 'Time (sec)'
set ylabel 'Buffer use by flow to A'
set key right bottom
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "buffocup_separation_X.png"

plot "separation_ron/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Gossiping', \
     "separation_bsw/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Spray&Wait', \
     "separation_flop/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Path sampling'


#set title "Buffer distribution A/C, Separation scenario, Sector Y"
set key right top
set out "buffocup_separation_Y.png"

plot "separation_ron/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Gossiping', \
     "separation_bsw/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Spray&Wait', \
     "separation_flop/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Path sampling'

unset output
