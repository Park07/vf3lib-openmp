# Makefile for OpenMP debugging tools

CXX = g++
CXXFLAGS = -std=c++11 -fopenmp -g -O0 -Wall -Wextra
LDFLAGS = -fopenmp

# Enable debugging output
DEBUG_FLAGS = -DDEBUG -DVERBOSE

# Sanitizer options for detecting memory issues
SANITIZER_FLAGS = -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer

# Targets
all: test_stack test_stack_sanitized

# Basic stack test
test_stack: test_openmp_stack.cpp
	$(CXX) $(CXXFLAGS) $(DEBUG_FLAGS) -o $@ $< $(LDFLAGS)
	@echo "Built test_stack - Run with: ./test_stack [num_threads]"

# Stack test with sanitizers
test_stack_sanitized: test_openmp_stack.cpp
	$(CXX) $(CXXFLAGS) $(SANITIZER_FLAGS) $(DEBUG_FLAGS) -o $@ $< $(LDFLAGS) -lasan -lubsan
	@echo "Built test_stack_sanitized - Run with: ./test_stack_sanitized [num_threads]"

# Run tests
run_test: test_stack
	@echo "Running basic stack test..."
	./test_stack 8

run_sanitized: test_stack_sanitized
	@echo "Running stack test with sanitizers..."
	ASAN_OPTIONS=detect_leaks=1:halt_on_error=0 ./test_stack_sanitized 8

# Valgrind test (if available)
valgrind_test: test_stack
	@echo "Running with valgrind..."
	valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./test_stack 4

# GDB debugging
debug: test_stack
	@echo "Starting GDB session..."
	gdb ./test_stack

# Clean up
clean:
	rm -f test_stack test_stack_sanitized
	rm -f core* *.o
	rm -rf debug_*
	rm -f /tmp/openmp_debug_*.log

# Compile your actual ParallelMatchingEngine with debug version
compile_debug_engine:
	@echo "To compile your VF3 library with the debug version:"
	@echo "1. Copy ParallelMatchingEngine_debug.hpp to your include directory"
	@echo "2. Rebuild your VF3 library with -DDEBUG flag"
	@echo "Example:"
	@echo "  cp ParallelMatchingEngine_debug.hpp ~/vf3lib-openmp/include/parallel/"
	@echo "  cd ~/vf3lib-openmp && make clean && make CXXFLAGS='-DDEBUG -g -O0'"

.PHONY: all clean run_test run_sanitized valgrind_test debug compile_debug_engine