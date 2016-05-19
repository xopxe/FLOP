reset
clear
#set title "Buffer distribution A/C, Counterflow scenario, Sector X"
set xrange [0:4000]
set yrange [0:1]
set xlabel 'Time (sec)'
set ylabel 'Buffer use by flow to A'
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "buffocup_counterflow_X.png"
set key left top

plot "counterflow_ron/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Gossiping', \
     "counterflow_bsw/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Spray&Wait', \
     "counterflow_flop/buffocup.out" using ($1-1262304004-500):2:3:4 w errorlines t 'Path sampling'


#set title "Buffer distribution A/C, Counterflow scenario, Sector Y"
set out "buffocup_counterflow_Y.png"
set key left bottom

plot "counterflow_ron/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Gossiping', \
     "counterflow_bsw/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Spray&Wait', \
     "counterflow_flop/buffocup.out" using ($1-1262304004-500):5:6:7 w errorlines t 'Path sampling'

unset output

