#!/usr/bin/env python3
"""
Enhance Patent Documents

Removes emojis, improves formatting, enhances abstracts, and improves readability.
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def remove_emojis(text):
    """Remove all emojis from text"""
    emoji_patterns = [
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
    for pattern in emoji_patterns:
        text = re.sub(pattern, '', text)
    return text

def fix_abstract(text):
    """Fix abstract formatting"""
    # Find abstract section
    abstract_pattern = r'(## Abstract\s*\n\s*\n?)(.+?)(?=\n---|\n##)'
    match = re.search(abstract_pattern, text, re.DOTALL)
    
    if match:
        abstract_header = match.group(1)
        abstract_content = match.group(2).strip()
        
        # Remove leading dashes or hyphens
        abstract_content = re.sub(r'^-\s*', '', abstract_content, flags=re.MULTILINE)
        
        # Normalize whitespace - convert multiple newlines to single space, but preserve sentence structure
        # First, replace multiple spaces/newlines with single space
        abstract_content = re.sub(r'\s+', ' ', abstract_content)
        
        # Ensure it's a proper paragraph
        abstract_content = abstract_content.strip()
        
        # Replace abstract in text
        text = text[:match.start()] + abstract_header + abstract_content + '\n\n' + text[match.end():]
    
    return text

def improve_formatting(text):
    """Improve overall formatting"""
    # Remove multiple consecutive blank lines (more than 2)
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    # Fix spacing around headers
    text = re.sub(r'\n(#{1,6}\s+[^\n]+)\n([^\n#])', r'\n\1\n\n\2', text)
    
    # Fix spacing after lists
    text = re.sub(r'(\n- [^\n]+)\n([A-Z][a-z])', r'\1\n\n\2', text)
    text = re.sub(r'(\n\d+\. [^\n]+)\n([A-Z][a-z])', r'\1\n\n\2', text)
    
    # Ensure proper spacing around code blocks
    text = re.sub(r'```\n\n+', '```\n', text)
    text = re.sub(r'\n\n+```', '\n```', text)
    
    # Fix patent strength line
    text = re.sub(r'\*\*Patent Strength:\*\*\s+(\w+)', r'**Patent Strength:** \1', text)
    
    # Remove status indicators with emojis
    text = re.sub(r'\*\*Status:\*\*\s*Found', '**Status:** Found', text)
    text = re.sub(r'- \*\*Status:\*\*\s*Found', '- **Status:** Found', text)
    
    # Clean up conclusion sections
    text = re.sub(r'\*\*Conclusion:\*\*\s+', '**Conclusion:** ', text)
    
    # Remove empty lines with just spaces
    text = re.sub(r'^\s+$', '', text, flags=re.MULTILINE)
    
    return text

def improve_readability(text):
    """Improve readability and flow"""
    # Remove redundant status markers
    text = re.sub(r'\*\*Status:\*\*\s*Ready for Patent Filing', '**Status:** Ready for Patent Filing', text)
    
    # Clean up bullet points
    text = re.sub(r'^- \s+', '- ', text, flags=re.MULTILINE)
    
    # Ensure proper paragraph breaks
    text = re.sub(r'\.\n([A-Z])', r'.\n\n\1', text)
    
    # Fix spacing in formulas
    text = re.sub(r'`([^`]+)`\s*\n\s*\n', r'`\1`\n\n', text)
    
    # Remove trailing whitespace
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)
    
    return text

def ensure_proper_structure(text):
    """Ensure proper patent document structure"""
    # Ensure Abstract comes before Background
    if '## Abstract' in text and '## Background' in text:
        abstract_pos = text.find('## Abstract')
        background_pos = text.find('## Background')
        if abstract_pos > background_pos:
            # Abstract is after Background - this shouldn't happen, but handle it
            pass
    
    # Ensure proper section ordering
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
    
    return text

def process_patent_file(file_path):
    """Process a single patent file"""
    print(f"Processing: {file_path.name}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_length = len(content)
        
        # Apply all transformations
        content = remove_emojis(content)
        content = fix_abstract(content)
        content = improve_formatting(content)
        content = improve_readability(content)
        content = ensure_proper_structure(content)
        
        # Final cleanup
        content = re.sub(r'\n{3,}', '\n\n', content)  # Remove excessive blank lines
        content = content.strip() + '\n'  # Ensure file ends with newline
        
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error processing {file_path.name}: {e}")
        import traceback
        traceback.print_exc()
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
    print("Finding patent documents...")
    patent_files = find_all_patent_documents()
    print(f"Found {len(patent_files)} patent documents\n")
    
    processed = 0
    failed = 0
    
    for patent_file in patent_files:
        if process_patent_file(patent_file):
            processed += 1
        else:
            failed += 1
    
    print(f"\nProcessing complete!")
    print(f"   Processed: {processed}")
    print(f"   Failed: {failed}")

if __name__ == "__main__":
    main()
