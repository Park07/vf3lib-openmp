#!/bin/bash
cd ~/vf3lib-openmp

RESULT_DIR="results/FINAL_OPENMP_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/enron_openmp_complete.csv"

echo "Type,Size,Threads,Solutions,FirstTime_s,TotalTime_s,MaxMemory_KB,CPU_Percent,Status" > "$CSV"

ENRON_DIR=~/vf3_test_enron_NEW

test_num=0
for type in sparse dense; do
    for size in 8 16 24 32; do
        for threads in 1 8 16 32 48 64; do
            test_num=$((test_num + 1))
            
            echo "[$test_num/48] $type,$size,$threads..."
            
            QUERY="${ENRON_DIR}/query_${type}_${size}v_1_NO_LABELS.graph"
            TARGET="${ENRON_DIR}/enron_NO_LABELS.graph"
            
            TIME_FILE="$RESULT_DIR/time_${type}_${size}_t${threads}.txt"
            OUTPUT_FILE="$RESULT_DIR/output_${type}_${size}_t${threads}.txt"
            
            /usr/bin/time -v timeout 30s ./bin/vf3p "$QUERY" "$TARGET" -a 2 -t $threads -l 0 -h 3 > "$OUTPUT_FILE" 2> "$TIME_FILE"
            
            COUNT=$(head -1 "$OUTPUT_FILE" | awk '{print $1}' | grep -o '^[0-9]\+')
            FIRST_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $2}')
            TOTAL_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $3}')
            
            MAX_MEM=$(grep "Maximum resident set size" "$TIME_FILE" | awk '{print $NF}')
            CPU_PCT=$(grep "Percent of CPU" "$TIME_FILE" | awk '{print $NF}' | tr -d '%')
            
            [ -z "$COUNT" ] && COUNT=0
            [ -z "$FIRST_TIME" ] && FIRST_TIME=0
            [ -z "$TOTAL_TIME" ] && TOTAL_TIME=30
            [ -z "$MAX_MEM" ] && MAX_MEM=0
            [ -z "$CPU_PCT" ] && CPU_PCT=0
            
            echo "$type,$size,$threads,$COUNT,$FIRST_TIME,$TOTAL_TIME,$MAX_MEM,$CPU_PCT,TIMEOUT" >> "$CSV"
            echo "  -> $COUNT solutions"
            
            sleep 1
        done
    done
done

echo ""
echo "COMPLETE! Results:"
cat "$CSV"
