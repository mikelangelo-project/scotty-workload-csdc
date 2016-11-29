BEGIN {printf "\timeDiff,trps,requests,gets,sets,hits,misses,avg_lat,90th,95th,99th,std,min,max,avgGetSize\n"}
/timeDiff/ {; getline; gsub (" ", "", $0); print}
END{printf "\n"}
