#!/bin/bash
cd ~/vf3lib-openmp

OPENMP_CSV=$(ls -t results/enron_final_*/enron_openmp.csv | head -1)

test_num=26
for type in dense; do
    for size in 8 16 24 32; do
        for threads in 1 8 16 32 48 64; do
            ((test_num++))
            echo "[$test_num/48] Running $type,$size with $threads threads..."
            
            # Check memory before starting
            MEM_USED=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
            if [[ $MEM_USED -gt 40 ]]; then
                echo "  ⚠ Memory high (${MEM_USED}%), waiting 10s..."
                sleep 10
            fi
            
            OUTPUT=$(timeout 30s ./bin/vf3p \
                ~/vf3_test_enron_NEW/query_${type}_${size}v_1_NO_LABELS.graph \
                ~/vf3_test_enron_NEW/enron_NO_LABELS.graph \
                -a 2 -t $threads -l 0 -h 3 2>&1)
            
            # Parse first line, first number
            COUNT=$(echo "$OUTPUT" | head -1 | awk '{print $1}')
            
            echo "$type,$size,$threads,$COUNT,30,TIMEOUT" >> "$OPENMP_CSV"
            echo "  -> $COUNT solutions"
            
            # Brief pause between tests
            sleep 2
        done
    done
done

echo ""
echo "Dense graphs complete! Final results:"
cat "$OPENMP_CSV"
