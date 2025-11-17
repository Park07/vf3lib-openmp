
#!/bin/bash

# --- SAFE MODE: 10s Timeout + Memory Protection ---

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

RESULTS_DIR="results/enron_10s_safe_${TIMESTAMP}"

CSV_FILE="${RESULTS_DIR}/enron_10s_openmp.csv"

ENRON_DIR=~/vf3_test_enron_NEW



mkdir -p "$RESULTS_DIR"



echo "================================================="

echo "VF3PDL OPENMP - 10s SAFE MODE Benchmark"

echo "================================================="



echo "Dataset,Type,Size,Threads,TimeLimit_s,Time_s,Count,Status,MaxMemory_KB,CPU_Percent" > "$CSV_FILE"



test_count=0

for type in sparse dense; do

    for size in 8 16 24 32; do

        query="${ENRON_DIR}/query_${type}_${size}v_1_NO_LABELS.graph"

        target="${ENRON_DIR}/enron_NO_LABELS.graph"

        

        if [ ! -f "$query" ]; then continue; fi

        

        for threads in 1 4 8 16 32 48 64; do

            ((test_count++))

            echo "[$test_count/56] $type ${size}v @ ${threads}t..."

            

            # --- MEMORY GUARD ---

            available_mem_mb=$(free -m | awk 'NR==2{print $7}')

            if [ "$available_mem_mb" -lt 5000 ]; then

                echo "  ⚠ Low Memory ($available_mem_mb MB). Waiting..."

                sleep 15

            fi

            

            TIME_FILE="${RESULTS_DIR}/time_${type}_${size}_t${threads}.txt"

            OUTPUT_FILE="${RESULTS_DIR}/output_${type}_${size}_t${threads}.log"

            

            start_time=$(date +%s.%N)

            

            /usr/bin/time -v timeout 10s ./bin/vf3p \

                "$query" "$target" -a 2 -t "$threads" -l 0 -h 3 \

                > ${OUTPUT_FILE} 2> ${TIME_FILE}

            

            exit_code=$?

            end_time=$(date +%s.%N)

            time=$(echo "$end_time - $start_time" | bc)

            

            # Parse first number only

            count=$(tail -1 ${OUTPUT_FILE} | awk '{print $1}' | grep -E '^[0-9]+$' || echo 0)

            

            max_mem=$(grep "Maximum resident set size" ${TIME_FILE} | awk '{print $NF}')

            cpu_percent=$(grep "Percent of CPU" ${TIME_FILE} | awk '{print $NF}' | tr -d '%')

            

            [ -z "$max_mem" ] && max_mem=0

            [ -z "$cpu_percent" ] && cpu_percent=0

            

            if [ $exit_code -eq 124 ]; then

                status="TIMEOUT"

            elif [ $exit_code -ne 0 ]; then

                status="ERROR"

            else

                status="OK"

            fi

            

            echo "enron,$type,$size,$threads,10,$time,$count,$status,$max_mem,$cpu_percent" >> "$CSV_FILE"

            echo "  → $count solutions, ${max_mem}KB, ${cpu_percent}% CPU"

        done

    done

done



echo ""

echo "✅ Benchmark Complete. Results in: $RESULTS_DIR"

cat "$CSV_FILE"

