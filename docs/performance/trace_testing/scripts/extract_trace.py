#!/usr/bin/env python3
"""Extract data from Instruments trace .run files"""
import plistlib
import sys
import json
from pathlib import Path

def plist_to_serializable(obj, max_depth=10):
    """Convert plist objects to JSON-serializable format"""
    if max_depth <= 0:
        return "<max depth reached>"
    
    if isinstance(obj, dict):
        return {k: plist_to_serializable(v, max_depth - 1) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [plist_to_serializable(item, max_depth - 1) for item in obj]
    elif isinstance(obj, bytes):
        # Try to show if it's text
        try:
            decoded = obj.decode('utf-8', errors='ignore')
            if len(decoded) < 200:
                return f"<bytes: {decoded}>"
            else:
                return f"<bytes: {len(obj)} bytes>"
        except:
            return f"<bytes: {len(obj)} bytes>"
    elif hasattr(obj, '__dict__'):
        return f"<{type(obj).__name__}: {str(obj)[:200]}>"
    else:
        return obj

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
        print("Looking for other patterns...")
        
        # Check for NSKeyedArchiver strings
        if b'NSKeyedArchiver' in data:
            print("Found NSKeyedArchiver format (Objective-C serialization)")
            print("This format typically requires Foundation framework to decode")
        
        # Show what strings we can find
        strings = []
        current_string = b''
        for byte in data[:1000]:  # First 1KB
            if 32 <= byte <= 126:  # Printable ASCII
                current_string += bytes([byte])
            else:
                if len(current_string) > 3:
                    strings.append(current_string.decode('utf-8', errors='ignore'))
                current_string = b''
        
        if strings:
            print("\nFound readable strings:")
            for s in set(strings[:20]):  # First 20 unique
                print(f"  - {s}")
        
        return None
    
    print(f"Found binary plist at offset: {bplist_start}\n")
    
    # Extract plist - need to find the end
    # Binary plists have a trailer that tells us the size
    # For now, try to extract from start to end of file
    bplist_data = data[bplist_start:]
    
    try:
        plist = plistlib.loads(bplist_data)
        print("=== Successfully Loaded Plist Data ===\n")
        
        if isinstance(plist, dict):
            print(f"Type: Dictionary with {len(plist)} keys\n")
            print("Keys found:")
            for key in plist.keys():
                value = plist[key]
                value_type = type(value).__name__
                print(f"  - {key}")
                print(f"    Type: {value_type}")
                
                if isinstance(value, (str, int, float, bool)):
                    print(f"    Value: {value}")
                elif isinstance(value, dict):
                    print(f"    Size: {len(value)} items")
                elif isinstance(value, list):
                    print(f"    Length: {len(value)} items")
                    if value and len(value) > 0:
                        print(f"    First item type: {type(value[0]).__name__}")
                elif isinstance(value, bytes):
                    print(f"    Size: {len(value)} bytes")
                
                print()
            
            # Try to pretty print a summary
            print("\n=== Data Summary (first level) ===")
            summary = {}
            for key, value in list(plist.items())[:10]:  # First 10 keys
                if isinstance(value, (str, int, float, bool)):
                    summary[key] = value
                elif isinstance(value, (dict, list)):
                    summary[key] = f"<{type(value).__name__} with {len(value)} items>"
                elif isinstance(value, bytes):
                    summary[key] = f"<bytes: {len(value)} bytes>"
                else:
                    summary[key] = str(type(value))
            
            print(json.dumps(summary, indent=2, default=str))
            
        elif isinstance(plist, list):
            print(f"Type: List with {len(plist)} items")
            if plist:
                print(f"First item type: {type(plist[0])}")
        
        return plist
        
    except plistlib.InvalidFileException as e:
        print(f"Invalid plist format: {e}")
        print("\nNote: This file uses NSKeyedArchiver format which may require")
        print("Objective-C/Swift Foundation framework to properly decode.")
        return None
    except Exception as e:
        print(f"Error parsing plist: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == '__main__':
    # Default to the extracted run file
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        file_path = 'instrument_data/06D2781B-15B1-4F73-B21F-B8019752C48D/run_data/1.run_extracted/1.run'
    
    # Resolve relative to script location
    script_dir = Path(__file__).parent
    file_path = script_dir / file_path
    
    if not file_path.exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)
    
    extract_trace_data(file_path)
