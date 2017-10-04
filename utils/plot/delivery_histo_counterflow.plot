reset
clear
#set xrange [0:]
set yrange [0:]
set xlabel 'Delivery rate'
set ylabel 'Frequency'

set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.8

#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "delivery_histo_counterflow.png"
set key right top

#plot "delivery_histo_counterflow.data" using 1:2 w boxes t 'Gossiping', \
#     "delivery_histo_counterflow.data" using 1:4 w boxes t 'Spray&Wait', \
#     "delivery_histo_counterflow.data" using 1:3 w boxes t 'Path sampling'

plot "delivery_histo_counterflow.data" using 2 t 'Gossiping', \
     "delivery_histo_counterflow.data" using 3:xticlabels(1) t 'Path sampling'

#"delivery_histo_counterflow.data" using 4 t 'Spray&Wait', \
