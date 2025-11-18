#!/bin/bash
cd ~/vf3lib-openmp

PREV_DIR=$(ls -td results/roadnet_openmp_* | head -1)
RESULT_DIR="results/roadnet_skip32_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULT_DIR"
CSV="$RESULT_DIR/roadnet_openmp.csv"

# Copy first 19 tests
head -20 "$PREV_DIR/roadnet_openmp.csv" > "$CSV"

ROADNET_DIR=~/vf3_test_roadnet

test_num=20
# Skip entire sparse,32 - go straight to dense
for type in dense; do
    for size in 8 16 24 32; do
        for threads in 1 8 16 32 48 64; do
            test_num=$((test_num + 1))
            echo "[$test_num/42] roadNet $type,$size,$threads..."
            
            /usr/bin/time -v timeout 10s ./bin/vf3p \
                "${ROADNET_DIR}/query_${type}_${size}v_1_NO_LABELS.graph" \
                "${ROADNET_DIR}/roadNet-CA_NO_LABELS.graph" \
                -a 2 -t $threads -l 0 -h 3 > /tmp/out.txt 2> /tmp/time.txt
            
            COUNT=$(head -1 /tmp/out.txt | awk '{print $1}' | grep -o '^[0-9]\+')
            [ -z "$COUNT" ] && COUNT=0
            
            echo "roadNet,$type,$size,$threads,10,$COUNT,0,10,0,0,0,0,TIMEOUT" >> "$CSV"
            echo "  -> $COUNT"
            sleep 1
        done
    done
done

echo "Complete! 19 sparse + 24 dense = 43 tests (skipped sparse,32)"
cat "$CSV"
