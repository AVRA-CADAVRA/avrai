#!/usr/bin/env python3
"""
Improve Summary Sections in Patent Documents

Makes Summary sections more concise, well-structured, and professional.
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"

def improve_summary(text):
    """Improve Summary section - make it concise and well-structured"""
    summary_match = re.search(r'## Summary\s*\n\s*\n(.+?)(?=\n---|\n##)', text, re.DOTALL)
    
    if summary_match:
        summary = summary_match.group(1).strip()
        
        # Remove excessive bold
        summary = re.sub(r'\*\*([^*]+)\*\*', r'\1', summary)
        
        # Break into logical paragraphs if too long
        # Split on sentences, but keep related ideas together
        sentences = re.split(r'\.\s+', summary)
        
        # Reconstruct into 2-3 well-structured paragraphs
        if len(sentences) > 5:
            # First paragraph: Core innovation
            first_para = '. '.join(sentences[:3]) + '.'
            if not first_para.endswith('.'):
                first_para += '.'
            
            # Second paragraph: Key features
            if len(sentences) > 6:
                second_para = '. '.join(sentences[3:6]) + '.'
                if not second_para.endswith('.'):
                    second_para += '.'
                
                # Third paragraph: Additional details (if needed)
                if len(sentences) > 6:
                    third_para = '. '.join(sentences[6:]) + '.'
                    if not third_para.endswith('.'):
                        third_para += '.'
                    summary = first_para + '\n\n' + second_para + '\n\n' + third_para
                else:
                    summary = first_para + '\n\n' + second_para
            else:
                second_para = '. '.join(sentences[3:]) + '.'
                if not second_para.endswith('.'):
                    second_para += '.'
                summary = first_para + '\n\n' + second_para
        else:
            # Short summary - keep as single paragraph but ensure proper formatting
            summary = '. '.join(sentences) + '.'
            if not summary.endswith('.'):
                summary += '.'
        
        # Replace in text
        old_section = summary_match.group(0)
        new_section = '## Summary\n\n' + summary + '\n'
        text = text.replace(old_section, new_section, 1)
    
    return text

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

def process_patent_file(file_path):
    """Process a single patent file"""
    print(f"Improving Summary: {file_path.name}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        content = improve_summary(content)
        
        # Final cleanup
        content = re.sub(r'\n{3,}', '\n\n', content)
        content = content.strip() + '\n'
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    patent_files = find_all_patent_documents()
    print(f"Improving Summary sections in {len(patent_files)} patents\n")
    
    processed = 0
    for patent_file in patent_files:
        if process_patent_file(patent_file):
            processed += 1
    
    print(f"\nComplete! Processed {processed} patents")

if __name__ == "__main__":
    main()
