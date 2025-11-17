#!/bin/bash
cd ~/vf3lib-openmp

mkdir -p results/simple
CSV="results/simple/openmp.csv"
echo "test,threads,solutions" > "$CSV"

# Just run sparse,8 with different threads - that's enough!
for t in 1 8 16 32; do
    echo "Running sparse,8 with $t threads..."
    result=$(timeout 10s ./bin/vf3p \
        ~/vf3_test_enron_NEW/query_sparse_8v_1_NO_LABELS.graph \
        ~/vf3_test_enron_NEW/enron_NO_LABELS.graph \
        -a 2 -t $t -l 0 -h 3 2>&1 | tail -1 | awk '{print $1}')
    echo "sparse8,$t,$result" >> "$CSV"
    echo "  -> $result solutions"
done

cat "$CSV"
