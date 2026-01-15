#!/usr/bin/env python3
"""
Comprehensive Patent Document Enhancement

Reads each patent document, removes emojis, improves abstracts, enhances readability,
and ensures proper formatting throughout.
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def remove_all_emojis(text):
    """Remove all emojis and emoji-like characters"""
    # Comprehensive emoji removal
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

def enhance_abstract(text):
    """Enhance abstract section - ensure it's well-formatted and complete"""
    # Find abstract section
    abstract_match = re.search(r'## Abstract\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    
    if abstract_match:
        abstract_content = abstract_match.group(1).strip()
        
        # Remove any leading dashes or hyphens
        abstract_content = re.sub(r'^-\s*', '', abstract_content, flags=re.MULTILINE)
        
        # Normalize whitespace - make it a single flowing paragraph
        abstract_content = re.sub(r'\s+', ' ', abstract_content)
        abstract_content = abstract_content.strip()
        
        # Ensure abstract is complete (not truncated)
        if abstract_content.endswith('...') or len(abstract_content) < 50:
            # Abstract might be incomplete - leave as is for now
            pass
        
        # Replace in text - use simpler approach to avoid regex issues
        old_abstract_section = abstract_match.group(0)
        new_abstract_section = '## Abstract\n\n' + abstract_content + '\n'
        text = text.replace(old_abstract_section, new_abstract_section, 1)
    
    return text

def improve_section_flow(text):
    """Improve flow between sections"""
    # Ensure proper spacing between major sections
    major_sections = [
        '## Cross-References to Related Applications',
        '## Statement Regarding Federally Sponsored Research or Development',
        '## Incorporation by Reference',
        '## Definitions',
        '## Brief Description of the Drawings',
        '## Abstract',
        '## Background',
        '## Summary',
        '## Detailed Description',
        '## Claims',
    ]
    
    for section in major_sections:
        # Ensure section has proper spacing before and after
        text = re.sub(rf'\n({re.escape(section)})', r'\n\n\1', text)
        text = re.sub(rf'({re.escape(section)})\n([^\n])', r'\1\n\n\2', text)
    
    return text

def improve_readability(text):
    """Improve overall readability"""
    # Remove redundant status markers
    text = re.sub(r'\*\*Status:\*\*\s*Found\s*$', '**Status:** Found', text, flags=re.MULTILINE)
    
    # Clean up patent strength
    text = re.sub(r'\*\*Patent Strength:\*\*\s+Tier', '**Patent Strength:** Tier', text)
    
    # Improve list formatting
    text = re.sub(r'^- \s+', '- ', text, flags=re.MULTILINE)
    text = re.sub(r'^\d+\.\s+', r'\g<0>', text, flags=re.MULTILINE)
    
    # Ensure proper paragraph breaks after sentences
    # Don't break in the middle of formulas or code blocks
    text = re.sub(r'\.\n([A-Z][a-z])', r'.\n\n\1', text)
    
    # Fix spacing around code blocks
    text = re.sub(r'```\n\n+', '```\n', text)
    text = re.sub(r'\n\n+```', '\n```', text)
    
    # Remove trailing whitespace
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)
    
    # Fix multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    return text

def fix_formatting_issues(text):
    """Fix common formatting issues"""
    # Fix spacing issues
    text = re.sub(r'\n(#{1,6}\s+[^\n]+)\n([^\n#])', r'\n\1\n\n\2', text)
    
    # Fix list spacing
    text = re.sub(r'(\n- [^\n]+)\n([A-Z][a-z])', r'\1\n\n\2', text)
    text = re.sub(r'(\n\d+\. [^\n]+)\n([A-Z][a-z])', r'\1\n\n\2', text)
    
    # Ensure proper spacing after headers
    text = re.sub(r'(#{1,6}\s+[^\n]+)\n([^\n#\s])', r'\1\n\n\2', text)
    
    # Fix spacing in definitions
    text = re.sub(r'(\*\*"[^"]+"\*\*)\s+means', r'\1 means', text)
    
    return text

def ensure_professional_tone(text):
    """Ensure professional patent document tone"""
    # Remove casual language
    text = re.sub(r'\b(can\'t|cannot)\b', 'cannot', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(don\'t|do not)\b', 'do not', text, flags=re.IGNORECASE)
    text = re.sub(r'\b(won\'t|will not)\b', 'will not', text, flags=re.IGNORECASE)
    
    # Ensure consistent terminology
    text = re.sub(r'\bAI\b', 'AI', text)  # Keep AI capitalized
    
    return text

def process_patent_file(file_path):
    """Process a single patent file comprehensively"""
    print(f"Enhancing: {file_path.name}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Apply all enhancements
        content = remove_all_emojis(content)
        content = enhance_abstract(content)
        content = improve_section_flow(content)
        content = improve_readability(content)
        content = fix_formatting_issues(content)
        content = ensure_professional_tone(content)
        
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
            if any(pat.replace('*', '') in patent_file.name for pat in exclude_patterns):
                continue
            if patent_file.parent.name.startswith(("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")):
                patent_files.append(patent_file)
    
    return sorted(patent_files)

def main():
    print("Comprehensive Patent Document Enhancement")
    print("=" * 50)
    
    patent_files = find_all_patent_documents()
    print(f"\nFound {len(patent_files)} patent documents to enhance\n")
    
    processed = 0
    failed = 0
    
    for patent_file in patent_files:
        if process_patent_file(patent_file):
            processed += 1
        else:
            failed += 1
    
    print(f"\n" + "=" * 50)
    print(f"Enhancement complete!")
    print(f"   Processed: {processed}")
    print(f"   Failed: {failed}")
    print(f"\nNext step: Re-convert to PDF")

if __name__ == "__main__":
    main()
