#!/usr/bin/env python3
"""Analyze all three instrument runs and create a summary"""
import zlib
from pathlib import Path

def decompress_store(store_path):
    """Decompress a zlib-compressed store file"""
    try:
        with open(store_path, 'rb') as f:
            compressed = f.read()
        decompressed = zlib.decompress(compressed)
        return decompressed
    except Exception as e:
        return None

def analyze_all():
    """Analyze all runs and stores"""
    base_path = Path(__file__).parent
    
    print("=" * 70)
    print("INSTRUMENTS TRACE ANALYSIS SUMMARY")
    print("=" * 70)
    print()
    
    # Analyze all three runs
    runs = [
        ("06D2781B-15B1-4F73-B21F-B8019752C48D", "Time Profiler"),
        ("D65AC803-3D60-4741-8101-BA188E9A10E7", "Context Switch Profiler"),
        ("D6E96833-D4F5-4AD3-9E4D-09E7153D9AF9", "Dynamic Library Loader"),
    ]
    
    print("=== INSTRUMENT RUNS ===")
    for uuid, name in runs:
        run_file = base_path / "instrument_data" / uuid / "run_data" / "1.run_extracted" / "1.run"
        if not run_file.exists():
            # Try alternative extraction paths
            alt_paths = [
                base_path / "instrument_data" / uuid / "run_data" / "1.run_extracted_2" / "1.run",
                base_path / "instrument_data" / uuid / "run_data" / "1.run_extracted_3" / "1.run",
            ]
            run_file = next((p for p in alt_paths if p.exists()), None)
        
        if run_file and run_file.exists():
            size = run_file.stat().st_size
            print(f"\n{name} ({uuid[:8]}...)")
            print(f"  File: {run_file.name}")
            print(f"  Size: {size:,} bytes ({size/1024:.1f} KB)")
        else:
            print(f"\n{name} ({uuid[:8]}...)")
            print("  Status: Not extracted")
    print()
    
    # Analyze corespace stores
    print("=== CORESPACE STORES (Profiling Data) ===")
    stores_path = base_path / "corespace" / "currentRun" / "core" / "stores"
    
    total_size = 0
    compressed_stores = 0
    
    for i in range(37):  # 0-36 stores
        store_file = stores_path / f"indexed-store-{i}" / "bulkstore"
        if store_file.exists():
            size = store_file.stat().st_size
            total_size += size
            
            # Try to decompress
            decompressed = decompress_store(store_file)
            if decompressed:
                compressed_stores += 1
                ratio = (1 - size/len(decompressed)) * 100 if len(decompressed) > 0 else 0
                print(f"  Store {i:2d}: {size:6d} bytes (compressed) → {len(decompressed):8d} bytes ({ratio:.1f}% compression)")
            else:
                print(f"  Store {i:2d}: {size:6d} bytes (uncompressed or error)")
    
    print(f"\n  Total stores: 37")
    print(f"  Total size: {total_size:,} bytes ({total_size/1024:.1f} KB)")
    print(f"  Compressed stores: {compressed_stores}")
    print()
    
    # Summary of what we found
    print("=== WHAT THE TRACE CONTAINS ===")
    print()
    print("1. TIME PROFILER")
    print("   - CPU usage sampling")
    print("   - High-frequency sampling enabled")
    print("   - Kernel call stacks recorded")
    print("   - Context switch tracking")
    print()
    print("2. CONTEXT SWITCH PROFILER")
    print("   - Thread switching analysis")
    print("   - Thread states (running, waiting, etc.)")
    print("   - Thread residency calculations")
    print()
    print("3. DYNAMIC LIBRARY LOADER")
    print("   - dyld activity tracking")
    print("   - Static initializer calls")
    print("   - Library open/close events")
    print()
    print("=== DATA LOCATIONS ===")
    print()
    print("Configuration & UI Specs:")
    print("  - instrument_data/*/run_data/1.run (metadata)")
    print()
    print("Actual Profiling Samples:")
    print("  - corespace/currentRun/core/stores/ (indexed stores)")
    print("  - Each store contains compressed profiling data")
    print()
    print("Symbol Information:")
    print("  - symbols/stores/*.symbolsarchive (170 symbol archives)")
    print()

if __name__ == '__main__':
    analyze_all()
