#!/usr/bin/env python3
"""
Comprehensive Patent Document Cleanup and Enhancement

Processes each patent document to:
1. Remove all emojis
2. Improve abstracts (ensure they're complete and well-formatted)
3. Improve Summary sections (remove excessive bold, improve flow)
4. Enhance overall readability
5. Ensure professional patent document formatting
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def remove_all_emojis(text):
    """Remove all emojis and emoji-like characters"""
    emoji_chars = ['✅', '⏳', '🎯', '📋', '📁', '📊', '🔗', '⚠️', '❌', '💡', '📝', '🔍', '📄', '📍', '🎨', '🚨', '⭐']
    for emoji in emoji_chars:
        text = text.replace(emoji, '')
    text = re.sub(r'⭐+', '', text)
    return text

def enhance_abstract(text):
    """Enhance abstract - ensure it's complete, well-formatted, and professional"""
    # Find abstract section
    abstract_match = re.search(r'## Abstract\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    
    if abstract_match:
        abstract = abstract_match.group(1).strip()
        
        # Remove leading dashes or hyphens
        abstract = re.sub(r'^-\s*', '', abstract, flags=re.MULTILINE)
        
        # Normalize to single paragraph (remove excessive line breaks)
        abstract = re.sub(r'\n+', ' ', abstract)
        abstract = re.sub(r'\s+', ' ', abstract)
        abstract = abstract.strip()
        
        # Ensure it ends with a period
        if abstract and not abstract.endswith('.'):
            abstract += '.'
        
        # Replace in text
        old_section = abstract_match.group(0)
        new_section = '## Abstract\n\n' + abstract + '\n'
        text = text.replace(old_section, new_section, 1)
    
    return text

def improve_summary_section(text):
    """Improve Summary section - remove excessive bold, improve flow"""
    # Find Summary section
    summary_match = re.search(r'## Summary\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    
    if summary_match:
        summary = summary_match.group(1).strip()
        
        # Remove excessive bold formatting (keep only for technical terms if needed)
        # Remove bold from entire sentences/paragraphs
        summary = re.sub(r'\*\*([^*]+)\*\*', r'\1', summary)
        
        # Remove "Key Innovation:" bold headers - make it flow naturally
        summary = re.sub(r'\*\*Key Innovation:\*\*\s*', '', summary)
        
        # Normalize whitespace
        summary = re.sub(r'\n+', ' ', summary)
        summary = re.sub(r'\s+', ' ', summary)
        
        # Break into paragraphs if too long (but keep as flowing text)
        # For now, keep as single paragraph for patent style
        
        # Replace in text
        old_section = summary_match.group(0)
        new_section = '## Summary\n\n' + summary.strip() + '\n'
        text = text.replace(old_section, new_section, 1)
    
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
    
    # Ensure proper paragraph breaks after sentences
    text = re.sub(r'\.\n([A-Z][a-z])', r'.\n\n\1', text)
    
    # Fix spacing around code blocks
    text = re.sub(r'```\n\n+', '```\n', text)
    text = re.sub(r'\n\n+```', '\n```', text)
    
    # Remove trailing whitespace
    text = re.sub(r'[ \t]+$', '', text, flags=re.MULTILINE)
    
    # Fix multiple blank lines
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    return text

def ensure_professional_formatting(text):
    """Ensure professional patent document formatting"""
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
        # Ensure section has proper spacing
        text = re.sub(rf'\n({re.escape(section)})', r'\n\n\1', text)
        text = re.sub(rf'({re.escape(section)})\n([^\n#\s])', r'\1\n\n\2', text)
    
    # Ensure Abstract has proper spacing before it
    text = re.sub(r'(\n## Brief Description of the Drawings[^\n]*\n[^\n]*\n)', r'\1\n', text)
    text = re.sub(r'(\n## Abstract)', r'\1', text)
    
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
        content = improve_summary_section(content)
        content = improve_readability(content)
        content = ensure_professional_formatting(content)
        
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
    print("Comprehensive Patent Document Cleanup and Enhancement")
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
    print(f"\nNext: Re-convert to PDF")

if __name__ == "__main__":
    main()
