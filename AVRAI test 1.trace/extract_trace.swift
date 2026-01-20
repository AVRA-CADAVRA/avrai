#!/usr/bin/env swift
import Foundation

let filePath = "instrument_data/06D2781B-15B1-4F73-B21F-B8019752C48D/run_data/1.run_extracted/1.run"

guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
    print("Error: Could not read file at \(filePath)")
    exit(1)
}

print("File size: \(data.count) bytes\n")

// Try to unarchive NSKeyedArchiver data
do {
    // Try unarchiving with common classes
    let classes: [AnyClass] = [
        NSDictionary.self,
        NSArray.self,
        NSString.self,
        NSNumber.self,
        NSData.self,
        NSDate.self
    ]
    
    if let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data) {
        print("✓ Successfully unarchived NSKeyedArchiver data!\n")
        
        if let dict = unarchived as? NSDictionary {
            print("Type: NSDictionary")
            print("Keys: \(dict.allKeys.count)\n")
            
            for key in dict.allKeys {
                let value = dict[key]!
                print("\(key):")
                print("  Type: \(type(of: value))")
                
                if let str = value as? String {
                    print("  Value: \(str)")
                } else if let num = value as? NSNumber {
                    print("  Value: \(num)")
                } else if let arr = value as? NSArray {
                    print("  Array length: \(arr.count)")
                    if arr.count > 0 {
                        print("  First item type: \(type(of: arr.firstObject!))")
                    }
                } else if let nestedDict = value as? NSDictionary {
                    print("  Dictionary with \(nestedDict.count) keys")
                    print("  Keys: \(nestedDict.allKeys.prefix(10))")
                } else if let data = value as? Data {
                    print("  Data: \(data.count) bytes")
                    if let str = String(data: data, encoding: .utf8), str.count < 200 {
                        print("  Text content: \(str.prefix(100))")
                    }
                } else {
                    print("  Description: \(String(describing: value).prefix(200))")
                }
                print()
            }
        } else if let arr = unarchived as? NSArray {
            print("Type: NSArray")
            print("Length: \(arr.count)")
            if arr.count > 0 {
                print("First item type: \(type(of: arr.firstObject!))")
            }
        } else {
            print("Type: \(type(of: unarchived))")
            print("Value: \(unarchived)")
        }
    } else {
        print("✗ Failed to unarchive - object is nil")
        print("\nTrying alternative decoding...")
        
        // Try as property list
        if let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            print("✓ Loaded as property list")
            print("Keys: \(plist.keys.joined(separator: ", "))")
        }
    }
} catch {
    print("✗ Error unarchiving: \(error)")
    print("\nThis file uses NeXT/Apple typedstream format (version 4)")
    print("which may require special handling.")
}
