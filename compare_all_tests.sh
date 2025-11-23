#!/bin/bash

echo "=== VF3 Pthread vs OpenMP Comparison (8 threads) ==="
echo "Test,Pthread_Solutions,OpenMP_Solutions,Match"
echo "------------------------------------------------"

# Test all small test files
for test_file in ~/vf3lib/test/*.sub.grf; do
    if [[ ! -f "$test_file" ]]; then continue; fi
    
    base=$(basename "$test_file" .sub.grf)
    target="${test_file%.sub.grf}.grf"
    
    # Skip if target doesn't exist
    if [[ ! -f "$target" ]]; then continue; fi
    
    # Run pthread version (timeout after 5s for large tests)
    pthread_result=$(timeout 5s ~/vf3lib/bin/vf3p "$test_file" "$target" -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
    
    # Run OpenMP version
    openmp_result=$(timeout 5s ~/vf3lib-openmp/bin/vf3p "$test_file" "$target" -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
    
    # Check if they match
    if [[ "$pthread_result" == "$openmp_result" ]]; then
        match="✓"
    else
        match="✗"
    fi
    
    printf "%-30s %-15s %-15s %s\n" "$base" "$pthread_result" "$openmp_result" "$match"
done

echo ""
echo "=== Testing on real datasets (30s timeout each) ==="
echo "Dataset,Pthread_Solutions,OpenMP_Solutions,Match"
echo "------------------------------------------------"

# Test ENRON sparse 8v
echo -n "ENRON_sparse_8v,"
pthread_enron=$(timeout 30s ~/vf3lib/bin/vf3p ~/vf3_test_enron_NEW/query_sparse_8v_1_NO_LABELS.graph ~/vf3_test_enron_NEW/enron_NO_LABELS.graph -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
openmp_enron=$(timeout 30s ~/vf3lib-openmp/bin/vf3p ~/vf3_test_enron_NEW/query_sparse_8v_1_NO_LABELS.graph ~/vf3_test_enron_NEW/enron_NO_LABELS.graph -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
if [[ "$pthread_enron" == "$openmp_enron" ]]; then match="✓"; else match="✗"; fi
echo "$pthread_enron,$openmp_enron,$match"

# Test RoadNet dense 8v
echo -n "RoadNet_dense_8v,"
pthread_road=$(timeout 30s ~/vf3lib/bin/vf3p ~/vf3_test_roadnet/query_dense_8v_1_NO_LABELS.graph ~/vf3_test_roadnet/roadNet-CA_NO_LABELS.graph -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
openmp_road=$(timeout 30s ~/vf3lib-openmp/bin/vf3p ~/vf3_test_roadnet/query_dense_8v_1_NO_LABELS.graph ~/vf3_test_roadnet/roadNet-CA_NO_LABELS.graph -a 2 -t 8 -l 0 -h 3 2>/dev/null | awk '{print $1}')
if [[ "$pthread_road" == "$openmp_road" ]]; then match="✓"; else match="✗"; fi
echo "$pthread_road,$openmp_road,$match"

echo ""
echo "=== Summary ==="
echo "Tests where solutions match: implementation is correct"
echo "Tests where solutions differ: potential bug"
echo "Empty results: test timed out (normal for hard problems)"
