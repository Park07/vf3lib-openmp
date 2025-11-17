#!/bin/bash
cd ~/vf3lib-openmp

PREV_DIR=$(ls -td results/FINAL_OPENMP_2* | head -1)
RESULT_DIR="results/FINAL_CONTINUE_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/enron_openmp_complete.csv"

# Copy first 8 tests
head -9 "$PREV_DIR/enron_openmp_complete.csv" > "$CSV"

ENRON_DIR=~/vf3_test_enron_NEW

# Continue from test 9: sparse,16,16 (SKIP IT)
# Then sparse,16,32 onwards
tests_todo="
sparse 16 32
sparse 16 48
sparse 16 64
sparse 24 1
sparse 24 8
sparse 24 16
sparse 24 32
sparse 24 48
sparse 24 64
sparse 32 1
sparse 32 8
sparse 32 16
sparse 32 32
sparse 32 48
sparse 32 64
dense 8 1
dense 8 8
dense 8 16
dense 8 32
dense 8 48
dense 8 64
dense 16 1
dense 16 8
dense 16 16
dense 16 32
dense 16 48
dense 16 64
dense 24 1
dense 24 8
dense 24 16
dense 24 32
dense 24 48
dense 24 64
dense 32 1
dense 32 8
dense 32 16
dense 32 32
dense 32 48
dense 32 64
"

test_num=9
echo "$tests_todo" | while read type size threads; do
    [ -z "$type" ] && continue
    
    echo "[$test_num/47] $type,$size,$threads..."
    
    QUERY="${ENRON_DIR}/query_${type}_${size}v_1_NO_LABELS.graph"
    TARGET="${ENRON_DIR}/enron_NO_LABELS.graph"
    
    TIME_FILE="$RESULT_DIR/time_${type}_${size}_t${threads}.txt"
    OUTPUT_FILE="$RESULT_DIR/output_${type}_${size}_t${threads}.txt"
    
    /usr/bin/time -v timeout 15s ./bin/vf3p "$QUERY" "$TARGET" -a 2 -t $threads -l 0 -h 3 > "$OUTPUT_FILE" 2> "$TIME_FILE"
    
    COUNT=$(head -1 "$OUTPUT_FILE" | awk '{print $1}' | grep -o '^[0-9]\+')
    FIRST_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $2}')
    TOTAL_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $3}')
    MAX_MEM=$(grep "Maximum resident set size" "$TIME_FILE" | awk '{print $NF}')
    CPU_PCT=$(grep "Percent of CPU" "$TIME_FILE" | awk '{print $NF}' | tr -d '%')
    
    [ -z "$COUNT" ] && COUNT=0
    [ -z "$FIRST_TIME" ] && FIRST_TIME=0
    [ -z "$TOTAL_TIME" ] && TOTAL_TIME=15
    [ -z "$MAX_MEM" ] && MAX_MEM=0
    [ -z "$CPU_PCT" ] && CPU_PCT=0
    
    echo "$type,$size,$threads,$COUNT,$FIRST_TIME,$TOTAL_TIME,$MAX_MEM,$CPU_PCT,TIMEOUT" >> "$CSV"
    echo "  -> $COUNT"
    
    test_num=$((test_num + 1))
    sleep 1
done

echo ""
echo "COMPLETE!"
cat "$CSV"
