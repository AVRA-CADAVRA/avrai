#!/usr/bin/env python3
"""Extract readable strings and information from Instruments trace files"""
import re
import sys
from pathlib import Path
from collections import Counter

def extract_strings(data, min_length=4):
    """Extract readable ASCII strings from binary data"""
    strings = []
    current_string = b''
    
    for byte in data:
        if 32 <= byte <= 126:  # Printable ASCII
            current_string += bytes([byte])
        else:
            if len(current_string) >= min_length:
                strings.append(current_string.decode('utf-8'))
            current_string = b''
    
    # Don't forget the last string
    if len(current_string) >= min_length:
        strings.append(current_string.decode('utf-8'))
    
    return strings

def analyze_trace_file(file_path):
    """Analyze an Instruments trace file"""
    print(f"Analyzing: {file_path}\n")
    
    with open(file_path, 'rb') as f:
        data = f.read()
    
    print(f"File size: {len(data)} bytes\n")
    
    # Extract strings
    strings = extract_strings(data, min_length=4)
    unique_strings = list(set(strings))
    
    # Look for interesting patterns
    print("=== File Format Information ===")
    if b'streamtyped' in data:
        print("✓ NeXT/Apple typedstream format detected")
    if b'NSKeyedArchiver' in data:
        print("✓ Contains NSKeyedArchiver data")
    if b'bplist00' in data:
        print("✓ Contains binary plist data")
    if b'XRRun' in data:
        print("✓ XRRun object (Instruments run)")
    print()
    
    # Categorize strings
    print("=== Instrument Configuration ===")
    instrument_keywords = [
        'time-profile', 'target-pid', 'context-switch', 'sampling',
        'frequency', 'threads', 'kernel', 'callstack', 'life-cycle'
    ]
    
    instrument_strings = [s for s in unique_strings if any(kw in s.lower() for kw in instrument_keywords)]
    for s in sorted(instrument_strings):
        print(f"  {s}")
    print()
    
    # Object class names
    print("=== Object Classes Found ===")
    class_pattern = re.compile(r'[A-Z][A-Za-z0-9]+')
    class_like = [s for s in unique_strings if class_pattern.fullmatch(s) and len(s) > 4]
    class_like = [s for s in class_like if not any(c in s for c in '.,;:!?')]
    
    for cls in sorted(set(class_like))[:30]:
        print(f"  {cls}")
    print()
    
    # All unique strings (longer ones first)
    print("=== All Unique Strings (longest first) ===")
    unique_strings.sort(key=len, reverse=True)
    for s in unique_strings[:50]:
        if len(s) > 10:  # Only show longer strings
            print(f"  {s}")
    print(f"\n... and {len([s for s in unique_strings if len(s) <= 10])} shorter strings\n")
    
    # Statistics
    print("=== Statistics ===")
    string_lengths = [len(s) for s in strings]
    print(f"Total strings found: {len(strings)}")
    print(f"Unique strings: {len(unique_strings)}")
    print(f"Average string length: {sum(string_lengths) / len(string_lengths):.1f}" if string_lengths else "N/A")
    print(f"Longest string: {max(string_lengths)} chars" if string_lengths else "N/A")
    
    # Look for UUIDs, PIDs, timestamps
    print("\n=== Potential Identifiers ===")
    uuid_pattern = re.compile(r'[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}', re.I)
    uuids = uuid_pattern.findall(' '.join(unique_strings))
    if uuids:
        print(f"UUIDs found: {len(set(uuids))}")
        for uuid in set(uuids)[:5]:
            print(f"  {uuid}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        file_path = 'instrument_data/06D2781B-15B1-4F73-B21F-B8019752C48D/run_data/1.run_extracted/1.run'
    
    script_dir = Path(__file__).parent
    file_path = script_dir / file_path
    
    if not file_path.exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    
    analyze_trace_file(file_path)
