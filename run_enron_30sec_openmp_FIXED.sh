
#!/bin/bash



RESULT_DIR=~/vf3lib-openmp/results/enron_30sec/run_FIXED_$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULT_DIR"

cd "$RESULT_DIR"



VF3P=~/vf3lib-openmp/bin/vf3p

ENRON_DIR=~/vf3_test_enron_NEW

CSV_FILE="enron_30sec_openmp.csv"



echo "Type,Size,Threads,Solutions,FirstTime_s,TotalTime_s,Status" > "$CSV_FILE"



run_test() {

    local type=$1

    local size=$2

    local threads=$3

    

    QUERY="${ENRON_DIR}/query_${type}_${size}v_1_NO_LABELS.graph"

    TARGET="${ENRON_DIR}/enron_NO_LABELS.graph"

    

    echo "Running: $type ${size}v with $threads threads..."

    

    OUTPUT=$(timeout 30s "$VF3P" "$QUERY" "$TARGET" -a 2 -t "$threads" -l 0 -h 3 2>&1)

    EXIT_CODE=$?

    

    # Parse FIRST occurrence of each number from last line

    LAST_LINE=$(echo "$OUTPUT" | tail -1)

    SOLUTIONS=$(echo "$LAST_LINE" | awk '{print $1}')

    FIRST_TIME=$(echo "$LAST_LINE" | awk '{print $2}')

    TOTAL_TIME=$(echo "$LAST_LINE" | awk '{print $3}')

    

    if [[ $EXIT_CODE -eq 124 ]]; then

        STATUS="TIMEOUT"

    elif [[ $EXIT_CODE -eq 0 ]]; then

        STATUS="OK"

    else

        STATUS="ERROR"

    fi

    

    echo "$type,$size,$threads,$SOLUTIONS,$FIRST_TIME,$TOTAL_TIME,$STATUS" >> "$CSV_FILE"

}



for TYPE in sparse dense; do

    for SIZE in 8 16 24 32; do

        for THREADS in 1 8 16 32 48 64; do

            run_test "$TYPE" "$SIZE" "$THREADS"

        done

    done

done



echo ""

echo "ENRON OpenMP complete!"

cat "$CSV_FILE"

