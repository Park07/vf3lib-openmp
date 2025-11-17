#!/bin/bash
cd ~/vf3lib-openmp

RESULT_DIR="results/dense_only_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/dense_openmp.csv"

echo "Type,Size,Threads,Solutions,Time_s,Status" > "$CSV"

test_num=0
for size in 8 16 24 32; do
    for threads in 1 8 16 32 48 64; do
        ((test_num++))
        echo "[$test_num/24] dense,$size with $threads threads..."
        
        # Run and capture to temp file
        timeout 30s ./bin/vf3p \
            ~/vf3_test_enron_NEW/query_dense_${size}v_1_NO_LABELS.graph \
            ~/vf3_test_enron_NEW/enron_NO_LABELS.graph \
            -a 2 -t $threads -l 0 -h 3 > /tmp/vf3p_out.txt 2>&1
        
        # FIXED PARSING: Take ONLY first line, ONLY first number, validate it's a number
        COUNT=$(head -1 /tmp/vf3p_out.txt | awk '{print $1}' | grep -o '^[0-9]*' | head -c 20)
        
        # If empty or invalid, mark as ERROR
        if [[ -z "$COUNT" ]] || ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
            COUNT="PARSE_ERROR"
        fi
        
        echo "dense,$size,$threads,$COUNT,30,TIMEOUT" >> "$CSV"
        echo "  -> $COUNT solutions"
        
        sleep 1
    done
done

echo ""
echo "Dense complete! Results:"
cat "$CSV"
