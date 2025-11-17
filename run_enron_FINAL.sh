#!/bin/bash
cd ~/vf3lib-openmp

RESULT_DIR="results/enron_final_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/enron_openmp.csv"

echo "Type,Size,Threads,Solutions,Time_s,Status" > "$CSV"

for type in sparse dense; do
    for size in 8 16 24 32; do
        for threads in 1 8 16 32 48 64; do
            echo "Running $type,$size with $threads threads..."
            
            OUTPUT=$(timeout 30s ./bin/vf3p \
                ~/vf3_test_enron_NEW/query_${type}_${size}v_1_NO_LABELS.graph \
                ~/vf3_test_enron_NEW/enron_NO_LABELS.graph \
                -a 2 -t $threads -l 0 -h 3 2>&1)
            
            # Parse first line, first number
            COUNT=$(echo "$OUTPUT" | head -1 | awk '{print $1}')
            
            echo "$type,$size,$threads,$COUNT,30,TIMEOUT" >> "$CSV"
            echo "  -> $COUNT solutions"
        done
    done
done

echo ""
echo "Complete! Results:"
cat "$CSV"
