
#!/bin/bash

cd ~/vf3lib-openmp



PREV_DIR=$(ls -td results/roadnet_openmp_CLEAN_* | head -1)

CSV="$PREV_DIR/roadnet_openmp_complete.csv"



ROADNET_DIR=~/vf3_test_roadnet



# Continue from test 27: dense,8,16 onwards

tests_to_run="

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

dense 32 32

dense 32 48

dense 32 64

"



test_num=26

echo "$tests_to_run" | while read type size threads; do

    [ -z "$type" ] && continue

    test_num=$((test_num + 1))

    

    # Skip dense,32,16 (test 41 - known hang)

    if [ "$type" = "dense" ] && [ "$size" = "32" ] && [ "$threads" = "16" ]; then

        echo "[$test_num/46] SKIP dense,32,16 (known hang)"

        continue

    fi

    

    echo "[$test_num/46] roadNet $type,$size,$threads..."

    

    TIME_FILE="$PREV_DIR/time_${type}_${size}_t${threads}.txt"

    OUTPUT_FILE="$PREV_DIR/output_${type}_${size}_t${threads}.txt"

    

    /usr/bin/time -v timeout 10s ./bin/vf3p \

        "${ROADNET_DIR}/query_${type}_${size}v_1_NO_LABELS.graph" \

        "${ROADNET_DIR}/roadNet-CA_NO_LABELS.graph" \

        -a 2 -t $threads -l 0 -h 3 > "$OUTPUT_FILE" 2> "$TIME_FILE"

    

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



echo "DONE! Check results:"

wc -l "$CSV"

