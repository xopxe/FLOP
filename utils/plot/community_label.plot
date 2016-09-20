reset
clear
#set title "Label frequency, Sector X"
#set xrange [0:2000]
#set yrange [0:1]
set xlabel 'Time (sec)'
set ylabel 'Label frecuency'
#set term post size 5in, 2in eps enhanced color  
set term png size 700,400

set out "community_label_X.png"


plot "separation_flop/community.out" using ($1-1262304004):($3/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($6/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($9/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($12/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($15/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($18/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($21/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($24/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($27/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($30/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($33/5) w l t ''

#set title "Label frequency, Sector Y"
set out "community_label_Y.png"

plot "separation_flop/community.out" using ($1-1262304004):($4/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($7/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($10/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($13/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($16/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($19/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($22/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($25/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($28/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($31/5) w l t '', \
     "separation_flop/community.out" using ($1-1262304004):($34/5) w l t ''

unset output

