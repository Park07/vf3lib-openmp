#!/bin/bash

echo "=== ANALYZING RAW DATA ==="
echo ""

# Tests with actual metrics (memory > 0, not all zeros)
echo "Tests with valid metrics:"
awk -F',' 'NR>1 && $9 > 0' roadnet_openmp_complete.csv | wc -l

echo ""
echo "By category:"
echo "Sparse tests (all should be 0 solutions):"
awk -F',' 'NR>1 && $2=="sparse" && $9 > 0' roadnet_openmp_complete.csv | wc -l

echo "Dense tests with solutions:"
awk -F',' 'NR>1 && $2=="dense" && $6 > 0 && $9 > 0' roadnet_openmp_complete.csv | wc -l

echo "Dense tests with 0 solutions but valid metrics:"
awk -F',' 'NR>1 && $2=="dense" && $6 == 0 && $9 > 1000000' roadnet_openmp_complete.csv | wc -l

echo ""
echo "TOTAL USABLE: "
awk -F',' 'NR>1 && $9 > 0' roadnet_openmp_complete.csv | wc -l

echo ""
echo "Lines with all zeros (duplicates/failures):"
awk -F',' 'NR>1 && $9 == 0' roadnet_openmp_complete.csv | wc -l
