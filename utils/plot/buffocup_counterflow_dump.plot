reset
clear
#set title "Buffer distribution A/C, Counterflow scenario, Sector X"
#set xrange [0:50000]
set yrange [0:1]
set xlabel 'Time (sec)'
set ylabel 'Buffer use by flow to A'
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "buffocup_counterflow_dump_X.png"
set key left top

plot "counterflow_ron/invdump_node1_X.out" using ($1-1262304004-500):2 w points t 'Gossiping', \
     "counterflow_bsw/invdump_node1_X.out" using ($1-1262304004-500):2 w points t 'Spray&Wait', \
     "counterflow_flop/invdump_node1_X.out" using ($1-1262304004-500):2 w points t 'Path sampling'


#set title "Buffer distribution A/C, Counterflow scenario, Sector Y"
set out "buffocup_counterflow_dump_Y.png"
set key left bottom

plot "counterflow_ron/invdump_node1_Y.out" using ($1-1262304004-500):2 w points t 'Gossiping', \
     "counterflow_bsw/invdump_node1_Y.out" using ($1-1262304004-500):2 w points t 'Spray&Wait', \
     "counterflow_flop/invdump_node1_Y.out" using ($1-1262304004-500):2 w points t 'Path sampling'

unset output

