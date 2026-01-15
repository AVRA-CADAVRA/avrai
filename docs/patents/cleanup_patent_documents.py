#!/usr/bin/env python3
"""
Cleanup and Improve Patent Documents

Removes emojis, improves formatting, enhances abstracts, and improves readability.
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

# Emoji patterns to remove
EMOJI_PATTERNS = [
    r'[✅⏳🎯📋📁📊🔗⚠️❌💡📝🔍📄📍🎨🚨⭐]',
    r'✅',
    r'⏳',
    r'🎯',
    r'📋',
    r'📁',
    r'📊',
    r'🔗',
    r'⚠️',
    r'❌',
    r'💡',
    r'📝',
    r'🔍',
    r'📄',
    r'📍',
    r'🎨',
    r'🚨',
    r'⭐+',
]

def remove_emojis(text):
    """Remove all emojis from text"""
    for pattern in EMOJI_PATTERNS:
        text = re.sub(pattern, '', text)
    return text

def improve_formatting(text):
    """Improve formatting and readability"""
    # Remove multiple consecutive blank lines (more than 2)
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    # Ensure proper spacing around headers
    text = re.sub(r'\n(#{1,6}\s+[^\n]+)\n([^\n#])', r'\n\1\n\n\2', text)
    
    # Fix spacing around code blocks
    text = re.sub(r'```\n\n', '```\n', text)
    text = re.sub(r'\n\n```', '\n```', text)
    
    # Ensure proper spacing after lists
    text = re.sub(r'(\n- [^\n]+)\n([A-Z])', r'\1\n\n\2', text)
    
    return text

def ensure_abstract_format(text):
    """Ensure abstract is properly formatted"""
    # Check if abstract exists and is well-formatted
    abstract_match = re.search(r'## Abstract\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    
    if abstract_match:
        abstract = abstract_match.group(1).strip()
        # Ensure abstract is a single paragraph or well-formatted
        abstract = re.sub(r'\n{2,}', ' ', abstract)  # Replace multiple newlines with space
        abstract = re.sub(r'\s+', ' ', abstract)  # Normalize whitespace
        abstract = abstract.strip()
        
        # Replace abstract in text using simpler approach
        old_abstract = abstract_match.group(1)
        text = text.replace(
            '## Abstract\n\n' + old_abstract,
            '## Abstract\n\n' + abstract + '\n'
        )
    
    return text

def improve_readability(text):
    """Improve overall readability"""
    # Remove status indicators that are redundant
    text = re.sub(r'\*\*Status:\*\*\s*✅\s*', '**Status:** ', text)
    text = re.sub(r'\*\*Status:\*\*\s*⏳\s*', '**Status:** ', text)
    
    # Clean up "Status: ✅ Found" patterns
    text = re.sub(r'- \*\*Status:\*\*\s*✅\s*Found', '- **Status:** Found', text)
    
    # Remove emoji-only lines
    text = re.sub(r'^\s*[✅⏳🎯📋📁📊🔗⚠️❌💡📝🔍📄📍🎨🚨⭐]+\s*$', '', text, flags=re.MULTILINE)
    
    # Clean up patent strength line
    text = re.sub(r'\*\*Patent Strength:\*\*\s*⭐+\s*', '**Patent Strength:** ', text)
    
    # Improve bullet point formatting
    text = re.sub(r'^- ✅\s+', '- ', text, flags=re.MULTILINE)
    text = re.sub(r'^- ⏳\s+', '- ', text, flags=re.MULTILINE)
    text = re.sub(r'^- ❌\s+', '- ', text, flags=re.MULTILINE)
    
    # Clean up conclusion sections
    text = re.sub(r'\*\*Conclusion:\*\*\s*✅\s+', '**Conclusion:** ', text)
    
    return text

def process_patent_file(file_path):
    """Process a single patent file"""
    print(f"Processing: {file_path.name}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Apply all transformations
        content = remove_emojis(content)
        content = improve_formatting(content)
        content = ensure_abstract_format(content)
        content = improve_readability(content)
        
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error processing {file_path.name}: {e}")
        return False

def find_all_patent_documents():
    """Find all main patent documents"""
    exclude_patterns = [
        "*_visuals.md",
        "*README*",
        "*INDEX*",
        "*SUMMARY*",
        "*STATUS*",
        "*CHECKLIST*",
        "*PLAN*",
        "*UPDATE*",
        "*REFERENCE*",
        "*CRITICAL*",
        "*EXPERIMENT*",
        "*MARKETING*",
        "*TIMEZONE*",
        "*SECTIONS*",
        "*DOCUMENTATION*",
        "*PRIOR_ART*",
    ]
    
    patent_files = []
    for category_dir in PATENTS_DIR.glob("category_*"):
        for patent_file in category_dir.rglob("*.md"):
            # Skip excluded patterns
            if any(pat.replace('*', '') in patent_file.name for pat in exclude_patterns):
                continue
            # Only include main patent documents
            if patent_file.parent.name.startswith(("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")):
                patent_files.append(patent_file)
    
    return sorted(patent_files)

def main():
    print("🔍 Finding patent documents...")
    patent_files = find_all_patent_documents()
    print(f"Found {len(patent_files)} patent documents\n")
    
    processed = 0
    failed = 0
    
    for patent_file in patent_files:
        if process_patent_file(patent_file):
            processed += 1
        else:
            failed += 1
    
    print(f"\n✅ Processing complete!")
    print(f"   Processed: {processed}")
    print(f"   Failed: {failed}")
    print(f"\n📋 Next: Re-convert to PDF using convert_to_pdf.py")

if __name__ == "__main__":
    main()
