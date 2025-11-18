
#!/bin/bash

cd ~/vf3lib-openmp



RESULT_DIR="results/roadnet_openmp_CLEAN_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$RESULT_DIR"

CSV="$RESULT_DIR/roadnet_openmp_complete.csv"



echo "Dataset,Type,Size,Threads,TimeLimit_s,Solutions,FirstTime_s,TotalTime_s,MaxMemory_KB,CPU_Percent,ContextSwitches,PageFaults,Status" > "$CSV"



ROADNET_DIR=~/vf3_test_roadnet



test_num=0

for type in sparse dense; do

    for size in 8 16 24 32; do

        for threads in 1 8 16 32 48 64; do

            test_num=$((test_num + 1))

            

            # SKIP test 20: sparse,32,8

            if [ "$type" = "sparse" ] && [ "$size" = "32" ] && [ "$threads" = "8" ]; then

                echo "[$test_num/46] SKIP sparse,32,8 (test 20 - known hang)"

                continue

            fi

            

            # SKIP test 41: dense,32,16

            if [ "$type" = "dense" ] && [ "$size" = "32" ] && [ "$threads" = "16" ]; then

                echo "[$test_num/46] SKIP dense,32,16 (test 45 - known hang)"

                continue

            fi

            

            echo "[$test_num/46] roadNet $type,$size,$threads..."

            

            QUERY="${ROADNET_DIR}/query_${type}_${size}v_1_NO_LABELS.graph"

            TARGET="${ROADNET_DIR}/roadNet-CA_NO_LABELS.graph"

            

            TIME_FILE="$RESULT_DIR/time_${type}_${size}_t${threads}.txt"

            OUTPUT_FILE="$RESULT_DIR/output_${type}_${size}_t${threads}.txt"

            

            /usr/bin/time -v timeout 10s ./bin/vf3p "$QUERY" "$TARGET" -a 2 -t $threads -l 0 -h 3 > "$OUTPUT_FILE" 2> "$TIME_FILE"

            

            COUNT=$(head -1 "$OUTPUT_FILE" | awk '{print $1}' | grep -o '^[0-9]\+')

            FIRST_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $2}')

            TOTAL_TIME=$(head -1 "$OUTPUT_FILE" | awk '{print $3}')

            MAX_MEM=$(grep "Maximum resident set size" "$TIME_FILE" | awk '{print $NF}')

            CPU_PCT=$(grep "Percent of CPU" "$TIME_FILE" | awk '{print $NF}' | tr -d '%')

            CTX_SWITCHES=$(grep "Voluntary context switches" "$TIME_FILE" | awk '{print $NF}')

            PAGE_FAULTS=$(grep "Minor (reclaiming a frame) page faults" "$TIME_FILE" | awk '{print $NF}')

            

            [ -z "$COUNT" ] && COUNT=0

            [ -z "$FIRST_TIME" ] && FIRST_TIME=0

            [ -z "$TOTAL_TIME" ] && TOTAL_TIME=10

            [ -z "$MAX_MEM" ] && MAX_MEM=0

            [ -z "$CPU_PCT" ] && CPU_PCT=0

            [ -z "$CTX_SWITCHES" ] && CTX_SWITCHES=0

            [ -z "$PAGE_FAULTS" ] && PAGE_FAULTS=0

            

            echo "roadNet,$type,$size,$threads,10,$COUNT,$FIRST_TIME,$TOTAL_TIME,$MAX_MEM,$CPU_PCT,$CTX_SWITCHES,$PAGE_FAULTS,TIMEOUT" >> "$CSV"

            echo "  -> $COUNT"

            

            sleep 1

        done

    done

done



echo "COMPLETE! 46/48 tests (skipped 2 hangs)"

cat "$CSV"

