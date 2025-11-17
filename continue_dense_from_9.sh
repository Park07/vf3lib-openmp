#!/bin/bash
cd ~/vf3lib-openmp

RESULT_DIR=$(ls -td results/dense_metrics_10s_* | head -1)
CSV="$RESULT_DIR/dense_openmp_full.csv"

# Tests 9-24 (skip dense,16,16 if it keeps hanging, or try it last)
tests=(
    "16 16"
    "16 32"
    "16 48"
    "16 64"
    "24 1"
    "24 8"
    "24 16"
    "24 32"
    "24 48"
    "24 64"
    "32 1"
    "32 8"
    "32 16"
    "32 32"
    "32 48"
    "32 64"
)

test_num=8
for test in "${tests[@]}"; do
    read size threads <<< "$test"
    ((test_num++))
    
    echo "[$test_num/24] dense,$size with $threads threads..."
    
    TIME_FILE="$RESULT_DIR/time_${size}_t${threads}.txt"
    OUTPUT_FILE="$RESULT_DIR/output_${size}_t${threads}.txt"
    
    /usr/bin/time -v timeout 10s ./bin/vf3p \
        ~/vf3_test_enron_NEW/query_dense_${size}v_1_NO_LABELS.graph \
        ~/vf3_test_enron_NEW/enron_NO_LABELS.graph \
        -a 2 -t $threads -l 0 -h 3 \
        > "$OUTPUT_FILE" 2> "$TIME_FILE"
    
    COUNT=$(head -1 "$OUTPUT_FILE" | awk '{print $1}' | grep -o '^[0-9]*')
    FIRST_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $2}')
    TOTAL_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $3}')
    MAX_MEM=$(grep "Maximum resident set size" "$TIME_FILE" | awk '{print $NF}')
    CPU_PCT=$(grep "Percent of CPU" "$TIME_FILE" | awk '{print $NF}' | tr -d '%')
    
    [[ -z "$COUNT" ]] || ! [[ "$COUNT" =~ ^[0-9]+$ ]] && COUNT=0
    [[ -z "$MAX_MEM" ]] && MAX_MEM=0
    [[ -z "$CPU_PCT" ]] && CPU_PCT=0
    
    echo "dense,$size,$threads,$COUNT,$FIRST_TIME,10,$MAX_MEM,$CPU_PCT,TIMEOUT" >> "$CSV"
    echo "  -> $COUNT, ${MAX_MEM}KB"
    
    sleep 2
done

echo "Complete!"
cat "$CSV"
