#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR=~/vf3lib/results/roadnet_10sec/run_${TIMESTAMP}
CSV_FILE="${RESULTS_DIR}/roadnet_10sec.csv"

mkdir -p "$RESULTS_DIR"

echo "VF3PDL roadNet-CA - 10s timeout | Threads: 1,8,16,32,48,64 | 48 tests"

# Initialize CSV
echo "Type,Size,Threads,Solutions,FirstTime_s,TotalTime_s,MaxMemory_KB,CPU_Percent,Status" > "$CSV_FILE"

test_count=0
for type in sparse dense; do
    for size in 8 16 24 32; do
        query=~/vf3_test_roadnet/query_${type}_${size}v_1_NO_LABELS.graph

        if [ ! -f "$query" ]; then
            echo "ERROR: Query file not found: $query"
            continue
        fi

        for threads in 1 8 16 32 48 64; do
            ((test_count++))

            OUTPUT_FILE="${RESULTS_DIR}/vf3p_${test_count}.txt"
            TIME_FILE="${RESULTS_DIR}/time_${test_count}.txt"

            /usr/bin/time -v -o "$TIME_FILE" \
                timeout 10s ~/vf3lib/bin/vf3p \
                  "$query" \
                  ~/vf3_test_roadnet/roadNet-CA_NO_LABELS.graph \
                  -a 2 -t $threads -l 0 -h 3 \
                  > "$OUTPUT_FILE" 2>&1
            EXIT_CODE=$?

            SOLUTIONS=$(grep -E "^[0-9]+ [0-9\.]+ [0-9\.]+" "$OUTPUT_FILE" | awk '{print $1}' | tail -1 || echo "0")
            FIRST_TIME=$(grep -E "^[0-9]+ [0-9\.]+ [0-9\.]+" "$OUTPUT_FILE" | awk '{print $2}' | tail -1 || echo "0")
            TOTAL_TIME=$(grep -E "^[0-9]+ [0-9\.]+ [0-9\.]+" "$OUTPUT_FILE" | awk '{print $3}' | tail -1 || echo "0")

            MAX_MEM=$(grep 'Maximum resident set size' "$TIME_FILE" | grep -oP '\d+' || echo "0")
            CPU_PCT=$(grep 'Percent of CPU' "$TIME_FILE" | grep -oP '\d+' || echo "0")

            if [[ $EXIT_CODE -eq 124 ]]; then
                STATUS="TIMEOUT"
            elif [[ $EXIT_CODE -eq 137 ]]; then
                STATUS="KILLED"
            elif [[ $EXIT_CODE -ne 0 ]]; then
                STATUS="ERROR"
            else
                STATUS="OK"
            fi

            echo "$type,$size,$threads,$SOLUTIONS,$FIRST_TIME,$TOTAL_TIME,$MAX_MEM,$CPU_PCT,$STATUS" >> "$CSV_FILE"
        done
    done
done

echo "COMPLETE! Results: $CSV_FILE"