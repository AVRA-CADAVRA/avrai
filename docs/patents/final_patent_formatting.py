#!/usr/bin/env python3
"""
Final Patent Document Formatting

Ensures all patent documents are properly formatted with:
- No emojis
- Well-formatted abstracts
- Professional Summary sections
- Proper spacing and formatting throughout
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def remove_emojis(text):
    """Remove all emojis"""
    emoji_chars = ['✅', '⏳', '🎯', '📋', '📁', '📊', '🔗', '⚠️', '❌', '💡', '📝', '🔍', '📄', '📍', '🎨', '🚨', '⭐']
    for emoji in emoji_chars:
        text = text.replace(emoji, '')
    text = re.sub(r'⭐+', '', text)
    return text

def fix_abstract(text):
    """Ensure abstract is properly formatted"""
    abstract_match = re.search(r'## Abstract\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    if abstract_match:
        abstract = abstract_match.group(1).strip()
        abstract = re.sub(r'^-\s*', '', abstract, flags=re.MULTILINE)
        abstract = re.sub(r'\s+', ' ', abstract)
        abstract = abstract.strip()
        if abstract and not abstract.endswith('.'):
            abstract += '.'
        
        old_section = abstract_match.group(0)
        new_section = '## Abstract\n\n' + abstract + '\n'
        text = text.replace(old_section, new_section, 1)
    return text

def fix_summary(text):
    """Fix Summary section formatting"""
    # Fix double periods
    text = re.sub(r'\.\.', '.', text)
    
    # Ensure proper paragraph breaks in Summary
    summary_match = re.search(r'## Summary\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    if summary_match:
        summary = summary_match.group(1).strip()
        # Remove double periods
        summary = re.sub(r'\.\.', '.', summary)
        # Ensure it ends with single period
        summary = re.sub(r'\.+$', '.', summary)
        
        old_section = summary_match.group(0)
        new_section = '## Summary\n\n' + summary + '\n'
        text = text.replace(old_section, new_section, 1)
    
    return text

def final_cleanup(text):
    """Final cleanup"""
    # Remove multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    # Remove trailing whitespace
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)
    # Ensure file ends with newline
    text = text.strip() + '\n'
    return text

def process_file(file_path):
    """Process a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        content = remove_emojis(content)
        content = fix_abstract(content)
        content = fix_summary(content)
        content = final_cleanup(content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error processing {file_path.name}: {e}")
        return False

def find_patent_documents():
    """Find all patent documents"""
    exclude_patterns = [
        "*_visuals.md", "*README*", "*INDEX*", "*SUMMARY*", "*STATUS*",
        "*CHECKLIST*", "*PLAN*", "*UPDATE*", "*REFERENCE*", "*CRITICAL*",
        "*EXPERIMENT*", "*MARKETING*", "*TIMEZONE*", "*SECTIONS*",
        "*DOCUMENTATION*", "*PRIOR_ART*",
    ]
    
    patent_files = []
    for category_dir in PATENTS_DIR.glob("category_*"):
        for patent_file in category_dir.rglob("*.md"):
            if any(pat.replace('*', '') in patent_file.name for pat in exclude_patterns):
                continue
            if patent_file.parent.name.startswith(("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")):
                patent_files.append(patent_file)
    
    return sorted(patent_files)

def main():
    print("Final Patent Document Formatting")
    print("=" * 50)
    
    patent_files = find_patent_documents()
    print(f"Processing {len(patent_files)} patents\n")
    
    processed = 0
    for patent_file in patent_files:
        if process_file(patent_file):
            processed += 1
    
    print(f"\nComplete! Processed {processed} patents")
    print("Ready to convert to PDF")

if __name__ == "__main__":
    main()
