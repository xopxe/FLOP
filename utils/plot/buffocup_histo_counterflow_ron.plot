reset
n=20 #number of intervals
max=1.0 #max value
min=0.0 #min value
width=(max-min)/n #interval width
#function used to map a value to the intervals
hist(x,width)=width*floor(x/width)+width/2.0
set term png #output terminal and file

set xrange [min:max]
set yrange [0:]
#to put an empty boundary around the
#data inside an autoscaled graph.
set offset graph 0.05,0.05,0.05,0.0
set xtics min,(max-min)/5,max
set boxwidth width*0.9
set style fill solid 0.5 #fillstyle
set tics out nomirror
set xlabel "Buffer distribution"
set ylabel "Frequency"
#count and plot

set output "buffocup_histo_counterflow_ron_X.png"
plot "counterflow_ron/buffocup.out" u (hist($2,width)):(1.0) smooth freq w boxes lc rgb"green" notitle

set output "buffocup_histo_counterflow_ron_Y.png"
plot "counterflow_ron/buffocup.out" u (hist($5,width)):(1.0) smooth freq w boxes lc rgb"green" notitle

