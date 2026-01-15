#!/usr/bin/env python3
"""
Final Comprehensive Patent Document Enhancement

Reads each patent document one at a time, removes all emojis, improves abstracts,
enhances readability, and ensures proper professional formatting.
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def remove_all_emojis(text):
    """Remove all emojis"""
    emoji_chars = ['✅', '⏳', '🎯', '📋', '📁', '📊', '🔗', '⚠️', '❌', '💡', '📝', '🔍', '📄', '📍', '🎨', '🚨', '⭐']
    for emoji in emoji_chars:
        text = text.replace(emoji, '')
    # Remove star patterns
    text = re.sub(r'⭐+', '', text)
    return text

def fix_abstract_section(text):
    """Fix abstract section formatting"""
    # Ensure proper spacing before Abstract
    text = re.sub(r'(\n## Brief Description of the Drawings[^\n]*\n[^\n]*\n)', r'\1\n', text)
    
    # Fix abstract header spacing
    text = re.sub(r'(\n## Abstract)\s*\n\s*\n?', r'\1\n\n', text)
    
    # Find and clean abstract content
    abstract_match = re.search(r'## Abstract\n\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    if abstract_match:
        abstract = abstract_match.group(1).strip()
        # Remove leading dashes
        abstract = re.sub(r'^-\s*', '', abstract, flags=re.MULTILINE)
        # Normalize whitespace to single paragraph
        abstract = re.sub(r'\s+', ' ', abstract)
        abstract = abstract.strip()
        
        # Replace abstract
        text = text[:abstract_match.start(1)] + abstract + '\n' + text[abstract_match.end(1):]
    
    return text

def improve_readability(text):
    """Improve overall readability and flow"""
    # Remove redundant status markers
    text = re.sub(r'\*\*Status:\*\*\s*Found\s*$', '**Status:** Found', text, flags=re.MULTILINE)
    text = re.sub(r'- \*\*Status:\*\*\s*Found', '- **Status:** Found', text)
    
    # Clean up patent strength
    text = re.sub(r'\*\*Patent Strength:\*\*\s+Tier', '**Patent Strength:** Tier', text)
    
    # Improve list formatting
    text = re.sub(r'^- \s+', '- ', text, flags=re.MULTILINE)
    
    # Ensure proper paragraph breaks
    text = re.sub(r'\.\n([A-Z][a-z])', r'.\n\n\1', text)
    
    # Fix spacing around code blocks
    text = re.sub(r'```\n\n+', '```\n', text)
    text = re.sub(r'\n\n+```', '\n```', text)
    
    # Remove trailing whitespace
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)
    
    # Fix multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    return text

def ensure_proper_structure(text):
    """Ensure proper patent document structure"""
    # Ensure Abstract comes after Brief Description of Drawings
    if '## Brief Description of the Drawings' in text and '## Abstract' in text:
        brief_pos = text.find('## Brief Description of the Drawings')
        abstract_pos = text.find('## Abstract')
        if abstract_pos < brief_pos:
            # Abstract is before Brief - this is wrong, but we'll leave it for now
            pass
    
    # Ensure proper section spacing
    sections = [
        '## Cross-References to Related Applications',
        '## Statement Regarding Federally Sponsored Research or Development',
        '## Incorporation by Reference',
        '## Definitions',
        '## Brief Description of the Drawings',
        '## Abstract',
        '## Background',
        '## Summary',
        '## Detailed Description',
    ]
    
    for section in sections:
        # Ensure section has proper spacing
        text = re.sub(rf'\n({re.escape(section)})', r'\n\n\1', text)
        text = re.sub(rf'({re.escape(section)})\n([^\n#\s])', r'\1\n\n\2', text)
    
    return text

def process_patent_file(file_path):
    """Process a single patent file comprehensively"""
    print(f"Processing: {file_path.name}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Apply all enhancements
        content = remove_all_emojis(content)
        content = fix_abstract_section(content)
        content = improve_readability(content)
        content = ensure_proper_structure(content)
        
        # Final cleanup
        content = re.sub(r'\n{3,}', '\n\n', content)
        content = content.strip() + '\n'
        
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def find_all_patent_documents():
    """Find all main patent documents"""
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
    print("Final Comprehensive Patent Document Enhancement")
    print("=" * 60)
    
    patent_files = find_all_patent_documents()
    print(f"\nFound {len(patent_files)} patent documents\n")
    
    processed = 0
    failed = 0
    
    for patent_file in patent_files:
        if process_patent_file(patent_file):
            processed += 1
        else:
            failed += 1
    
    print(f"\n" + "=" * 60)
    print(f"Enhancement complete!")
    print(f"   Processed: {processed}")
    print(f"   Failed: {failed}")

if __name__ == "__main__":
    main()
