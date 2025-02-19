#!/bin/bash

# Usage: index-timer.sh index query db_file csv_file
#
# Arguments:
#     index:    column or column,column,... or none
#     query:    SQL query to run
#     db_file:  database file
#     csv_file: CSV file to create or append to

if [ $# -ne 4 ]; then
    echo "Usage: index-timer.sh index query db_file csv_file"
    exit 1
fi

index=$1
query=$2
db_file=$3
csv_file=$4

if [ ! -f $csv_file ]; then
    echo "index,average_time,num_distinct_values" > $csv_file
fi

if [ $index != none ]; then
    echo "Creating index on $index"
    sqlite3 $db_file "CREATE INDEX bni ON Bird_nests ($index)" >& /dev/null
fi

num_reps=1
while true; do
    echo -n "$num_reps repetitions"
    start=$SECONDS
    for i in $(seq $num_reps); do
        echo -n .
        sqlite3 $db_file "$query" >& /dev/null
    done
    end=$SECONDS
    echo
    if [ $((end - start)) -gt 3 ]; then
        break
    fi
    echo "Too fast!"
    num_reps=$((num_reps * 10))
done

if [ $index != none ]; then
    nd_query="SELECT COUNT(*) FROM (SELECT DISTINCT $index FROM Bird_nests)"
    num_distinct=$(sqlite3 -csv $db_file "$nd_query" 2> /dev/null)
else
    num_distinct=
fi

if [ $index != none ]; then
    echo "Dropping index"
    sqlite3 $db_file "DROP INDEX bni" >& /dev/null
fi

time=$(echo "scale = 7; ($end-$start)/$num_reps" | bc)
echo "Average time: $time"

echo "\"$index\",$time,$num_distinct" >> $csv_file
