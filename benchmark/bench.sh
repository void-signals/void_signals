#!/bin/bash

# Navigate to benchmark directory
cd "$(dirname "$0")"

# Initialize frameworks array
frameworks=()

# Get list of framework directories
for dir in frameworks/*/; do
  framework=$(basename "$dir")
  frameworks+=("$framework")
done

if [ ${#frameworks[@]} -eq 0 ]; then
  echo "Error: No framework directories found in frameworks directory."
  exit 1
fi

# Create output directories
mkdir -p bench
mkdir -p build

echo "==================== Compiling all frameworks ===================="

# Phase 1: Compile all frameworks
for framework in "${frameworks[@]}"
do
  echo "[Compile] $framework..."
  cd "frameworks/$framework"
  
  # Install deps
  dart pub get > /dev/null 2>&1
  
  # Compile to native
  if dart compile exe "main.dart" -o "../../build/$framework" 2>/dev/null; then
    echo "[Compile] $framework ✓"
  else
    echo "[Compile] $framework ✗ (compilation failed)"
  fi
  
  cd ../..
done

echo ""
echo "==================== Running all benchmarks ===================="

# Phase 2: Run all benchmarks
for framework in "${frameworks[@]}"
do
  if [ -f "build/$framework" ]; then
    echo ""
    echo "[Benchmark] $framework"
    echo "$(date)"
    
    # Run benchmark and save results
    ./build/$framework > "bench/$framework.md" 2>&1
    
    if [ $? -eq 0 ]; then
      echo "[Benchmark] $framework ✓"
    else
      echo "[Benchmark] $framework ✗ (execution failed)"
    fi
  fi
done

echo ""
echo "==================== Generating combined report ===================="

# Phase 3: Generate combined report
dart run gen_report.dart

echo ""
echo "==================== Syncing to README files ===================="

# Phase 4: Sync results to all README files
dart run sync_readme.dart

echo ""
echo "==================== Complete ===================="
echo "Individual results saved in bench/ directory"
echo "Combined report: bench/BENCHMARK_REPORT.md"
echo "README files updated with latest results"

# Cleanup
rm -rf build
