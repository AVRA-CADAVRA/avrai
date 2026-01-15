#!/usr/bin/env python3
"""
Convert Patent Documents to PDF

Converts all patent markdown documents to PDF format for lawyer meeting.
Uses markdown-pdf or pandoc if available, otherwise provides instructions.
"""

import os
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"
OUTPUT_DIR = PROJECT_ROOT / "docs" / "patents" / "patent_package_for_lawyer"

def check_pandoc():
    """Check if pandoc is available"""
    try:
        result = subprocess.run(['pandoc', '--version'], 
                              capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def check_markdown_pdf():
    """Check if markdown-pdf is available"""
    try:
        result = subprocess.run(['markdown-pdf', '--version'], 
                              capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def convert_with_pandoc(md_file, pdf_file):
    """Convert markdown to PDF using pandoc"""
    # Try HTML first, then convert to PDF
    html_file = pdf_file.with_suffix('.html')
    
    # Convert markdown to HTML
    cmd_html = [
        'pandoc',
        str(md_file),
        '-o', str(html_file),
        '--standalone',
        '--css=https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.min.css',
        '--metadata', 'title=' + md_file.stem,
    ]
    
    try:
        subprocess.run(cmd_html, check=True, capture_output=True)
        
        # Try to convert HTML to PDF using wkhtmltopdf if available
        try:
            cmd_pdf = ['wkhtmltopdf', str(html_file), str(pdf_file)]
            subprocess.run(cmd_pdf, check=True, capture_output=True, timeout=60)
            html_file.unlink()  # Remove HTML file if PDF created
            return True
        except (FileNotFoundError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
            # If wkhtmltopdf not available, keep HTML file
            # User can print HTML to PDF from browser
            print(f"(HTML created - print to PDF from browser)", end="")
            return True
            
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr.decode() if e.stderr else str(e)}", end="")
        return False

def convert_with_markdown_pdf(md_file, pdf_file):
    """Convert markdown to PDF using markdown-pdf"""
    cmd = [
        'markdown-pdf',
        str(md_file),
        '-o', str(pdf_file),
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error converting {md_file.name}: {e}")
        return False

def find_patent_documents():
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
    
    # Also include overview document
    overview_file = PATENTS_DIR / "LAWYER_MEETING_OVERVIEW.md"
    if overview_file.exists():
        patent_files.insert(0, overview_file)
    
    return sorted(patent_files)

def create_output_structure():
    """Create output directory structure"""
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # Create category directories
    for category_dir in PATENTS_DIR.glob("category_*"):
        category_name = category_dir.name
        (OUTPUT_DIR / category_name).mkdir(exist_ok=True)
    
    # Create root for overview
    return OUTPUT_DIR

def main():
    print("🔍 Checking for PDF conversion tools...")
    
    has_pandoc = check_pandoc()
    has_markdown_pdf = check_markdown_pdf()
    
    if not has_pandoc and not has_markdown_pdf:
        print("\n❌ No PDF conversion tool found!")
        print("\n📋 Please install one of the following:")
        print("   1. Pandoc: brew install pandoc (macOS) or apt-get install pandoc (Linux)")
        print("   2. markdown-pdf: npm install -g markdown-pdf")
        print("\n💡 Alternative: Use online converters or markdown editors with PDF export")
        print("\n📝 Creating conversion instructions file...")
        
        # Create instructions file
        instructions = OUTPUT_DIR / "CONVERSION_INSTRUCTIONS.md"
        instructions.parent.mkdir(exist_ok=True)
        with open(instructions, 'w') as f:
            f.write("""# PDF Conversion Instructions

Since no PDF conversion tool is installed, please use one of these methods:

## Option 1: Install Pandoc (Recommended)

**macOS:**
```bash
brew install pandoc
brew install basictex  # For PDF support
```

**Linux:**
```bash
sudo apt-get install pandoc texlive-latex-base
```

**Windows:**
Download from: https://pandoc.org/installing.html

Then run this script again.

## Option 2: Use Online Converter

1. Visit: https://www.markdowntopdf.com/
2. Upload each .md file
3. Download PDF
4. Save to appropriate category folder

## Option 3: Use Markdown Editor

1. Open .md file in:
   - Typora (File > Export > PDF)
   - Marked 2 (File > Export > PDF)
   - VS Code with Markdown PDF extension
2. Export to PDF
3. Save to appropriate category folder

## Option 4: Use Command Line (if you install pandoc)

```bash
cd docs/patents
pandoc LAWYER_MEETING_OVERVIEW.md -o patent_package_for_lawyer/00_OVERVIEW.pdf
# Repeat for each patent document
```
""")
        print(f"✅ Instructions saved to: {instructions}")
        return
    
    print(f"✅ Found: {'Pandoc' if has_pandoc else 'markdown-pdf'}")
    
    # Create output structure
    print("\n📁 Creating output directory structure...")
    output_dir = create_output_structure()
    
    # Find all patent documents
    print("\n🔍 Finding patent documents...")
    patent_files = find_patent_documents()
    print(f"✅ Found {len(patent_files)} documents to convert")
    
    # Convert each document
    print("\n📄 Converting documents to PDF...")
    converted = 0
    failed = 0
    
    for md_file in patent_files:
        # Determine output path
        if md_file.name == "LAWYER_MEETING_OVERVIEW.md":
            pdf_file = output_dir / "00_OVERVIEW.pdf"
        else:
            category_name = md_file.parent.parent.name
            pdf_name = md_file.stem + ".pdf"
            pdf_file = output_dir / category_name / pdf_name
        
        print(f"  Converting: {md_file.name}...", end=" ")
        
        # Convert
        if has_pandoc:
            success = convert_with_pandoc(md_file, pdf_file)
        else:
            success = convert_with_markdown_pdf(md_file, pdf_file)
        
        if success:
            print(f"✅")
            converted += 1
        else:
            print(f"❌")
            failed += 1
    
    print(f"\n✅ Conversion complete!")
    print(f"   Converted: {converted}")
    print(f"   Failed: {failed}")
    print(f"\n📁 PDFs saved to: {output_dir}")
    print(f"\n📋 Next steps:")
    print(f"   1. Review PDFs in: {output_dir}")
    print(f"   2. Verify all documents converted correctly")
    print(f"   3. Package for lawyer meeting")

if __name__ == "__main__":
    main()
