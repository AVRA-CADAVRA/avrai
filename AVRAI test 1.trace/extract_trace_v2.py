#!/usr/bin/env python3
"""Extract data from Instruments trace .run files - improved version"""
import plistlib
import sys
import struct
from pathlib import Path

def find_bplist_end(data, start_pos):
    """Find the end of a binary plist by reading its trailer"""
    if start_pos + 32 > len(data):
        return len(data)
    
    # Binary plist trailer is last 32 bytes
    # Format: 6 unused bytes, offset table size (1 byte), offset int size (1 byte),
    # object ref size (1 byte), num objects (8 bytes), root object (8 bytes),
    # offset table offset (8 bytes)
    
    # Start from end and work backwards
    pos = len(data) - 32
    
    # Read trailer
    try:
        trailer = data[pos:pos + 32]
        if len(trailer) < 32:
            return len(data)
        
        # Get offset table offset (last 8 bytes as big-endian uint64)
        offset_table_offset = struct.unpack('>Q', trailer[24:32])[0]
        offset_table_size = trailer[5]  # 6th byte (0-indexed: 5)
        offset_int_size = trailer[6]
        
        # The plist data ends where the offset table starts
        # (offset table is after the object data)
        # Actually, the plist ends at len(data), but the object data ends before offset table
        # Let's try a different approach - binary plists are self-contained
        
        # For now, just return the full length
        # The plistlib should handle incomplete data gracefully
        return len(data)
    except:
        return len(data)

def extract_trace_data(file_path):
    """Extract data from an Instruments trace .run file"""
    print(f"Reading: {file_path}")
    
    with open(file_path, 'rb') as f:
        data = f.read()
    
    print(f"File size: {len(data)} bytes\n")
    
    # Find binary plist start
    bplist_start = data.find(b'bplist00')
    if bplist_start == -1:
        print("No binary plist found in file")
        return None
    
    print(f"Found 'bplist00' at offset: {bplist_start}\n")
    
    # Try to extract just the plist portion
    # Look for the end - binary plist should have trailer at the end
    # Or try extracting different sizes
    bplist_end = find_bplist_end(data, bplist_start)
    
    # Actually, let's try a different approach:
    # The NSKeyedArchiver format has the plist embedded
    # Let's try to extract a chunk that looks complete
    # Binary plists end with a trailer that's 32 bytes from the end
    
    # Try multiple strategies:
    # 1. From bplist00 to end of file
    # 2. From bplist00 to end - 32 (assuming trailer is at end)
    # 3. Try to find another marker
    
    strategies = [
        ("Full remaining data", data[bplist_start:]),
        ("Up to last 32 bytes (trailer)", data[bplist_start:-32] if len(data) > bplist_start + 32 else data[bplist_start:]),
    ]
    
    # Also try to find where NSData objects might end
    # Look for patterns that might indicate structure boundaries
    
    for strategy_name, bplist_data in strategies:
        print(f"\n=== Trying strategy: {strategy_name} ===")
        print(f"Plist data size: {len(bplist_data)} bytes")
        
        try:
            # Try to parse as binary plist
            plist = plistlib.loads(bplist_data)
            print("✓ Successfully parsed binary plist!\n")
            
            print(f"Root type: {type(plist).__name__}")
            
            if isinstance(plist, dict):
                print(f"Dictionary with {len(plist)} keys:\n")
                for key in list(plist.keys())[:20]:  # First 20 keys
                    value = plist[key]
                    print(f"  {key}:")
                    print(f"    Type: {type(value).__name__}")
                    if isinstance(value, (str, int, float, bool)):
                        print(f"    Value: {value}")
                    elif isinstance(value, (dict, list)):
                        print(f"    Items: {len(value)}")
                    elif isinstance(value, bytes):
                        print(f"    Bytes: {len(value)}")
                        # Try to show if it's text
                        try:
                            text = value.decode('utf-8', errors='ignore')
                            if len(text) < 100 and text.isprintable():
                                print(f"    Text: {text[:50]}")
                        except:
                            pass
                    print()
            
            return plist
            
        except plistlib.InvalidFileException as e:
            print(f"✗ Invalid plist: {str(e)[:100]}")
            continue
        except Exception as e:
            print(f"✗ Error: {type(e).__name__}: {str(e)[:100]}")
            continue
    
    # If all strategies fail, show hex dump of plist start
    print("\n=== Plist header (first 200 bytes) ===")
    plist_header = data[bplist_start:bplist_start + 200]
    for i in range(0, len(plist_header), 16):
        hex_part = ' '.join(f'{b:02x}' for b in plist_header[i:i+16])
        ascii_part = ''.join(chr(b) if 32 <= b < 127 else '.' for b in plist_header[i:i+16])
        print(f"{bplist_start + i:08x}: {hex_part:<48} {ascii_part}")
    
    print("\n=== Note ===")
    print("The plist appears to be embedded in NSKeyedArchiver format.")
    print("To fully decode this, you may need:")
    print("  1. macOS with Foundation framework (Swift/Objective-C)")
    print("  2. Python biplist library with NSKeyedArchiver support")
    print("  3. Or inspect the raw hex/strings for relevant data")
    
    return None

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
    
    extract_trace_data(file_path)
