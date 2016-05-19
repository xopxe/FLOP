reset
clear
#set title "Buffer distribution A/C, Counterflow scenario, Sector X"
#set xrange [0:50000]
set yrange [0:1]
#set xlabel 'Message'
set ylabel 'Delivery rate'
set key left bottom
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "delivery_separation.png"
#set tmargin 0
#set bmargin 0
#set lmargin 3
#set rmargin 3

set multiplot layout 2, 1 #title "Separation delivery"

set title "Flow B-A"
#unset key
plot "separation_ron/delivery_m.out" using 1:2:3:4 w errorlines  t 'Gossiping', \
     "separation_bsw/delivery_m.out" using 1:2:3:4 w errorlines  t 'Spray&Wait', \
     "separation_flop/delivery_m.out" using 1:2:3:4 w errorlines  t 'Path sampling'

set title "Flow B-C"
unset key
plot "separation_ron/delivery_m.out" using 1:5:6:7 w errorlines  t 'Gossiping', \
     "separation_bsw/delivery_m.out" using 1:5:6:7 w errorlines  t 'Spray&Wait', \
     "separation_flop/delivery_m.out" using 1:5:6:7 w errorlines  t 'Path sampling'


unset multiplot
unset output

