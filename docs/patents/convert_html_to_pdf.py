#!/usr/bin/env python3
"""
Convert HTML files to PDF

Converts all HTML files in patent_package_for_lawyer to PDF format.
"""

import subprocess
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent / "patent_package_for_lawyer"

def check_wkhtmltopdf():
    """Check if wkhtmltopdf is available"""
    try:
        result = subprocess.run(['wkhtmltopdf', '--version'], 
                              capture_output=True, text=True)
        return result.returncode == 0
    except FileNotFoundError:
        return False

def check_weasyprint():
    """Check if weasyprint is available"""
    try:
        import weasyprint
        return True
    except ImportError:
        return False

def convert_with_wkhtmltopdf(html_file, pdf_file):
    """Convert HTML to PDF using wkhtmltopdf"""
    cmd = ['wkhtmltopdf', str(html_file), str(pdf_file)]
    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=60)
        return True
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        return False

def convert_with_weasyprint(html_file, pdf_file):
    """Convert HTML to PDF using weasyprint"""
    try:
        from weasyprint import HTML
        HTML(str(html_file)).write_pdf(str(pdf_file))
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("🔍 Checking for PDF conversion tools...")
    
    has_wkhtmltopdf = check_wkhtmltopdf()
    has_weasyprint = check_weasyprint()
    
    if not has_wkhtmltopdf and not has_weasyprint:
        print("\n❌ No PDF conversion tool found!")
        print("\n📋 Please install one of the following:")
        print("   1. wkhtmltopdf: brew install wkhtmltopdf")
        print("   2. weasyprint: pip install weasyprint")
        print("\n💡 Alternative: Use browser print (Cmd+P > Save as PDF)")
        print("   See CONVERT_HTML_TO_PDF.md for instructions")
        return
    
    print(f"✅ Found: {'wkhtmltopdf' if has_wkhtmltopdf else 'weasyprint'}")
    
    # Find all HTML files
    html_files = list(PACKAGE_DIR.rglob("*.html"))
    print(f"\n📄 Found {len(html_files)} HTML files to convert\n")
    
    converted = 0
    failed = 0
    
    for html_file in html_files:
        pdf_file = html_file.with_suffix('.pdf')
        print(f"  Converting: {html_file.name}...", end=" ")
        
        if has_wkhtmltopdf:
            success = convert_with_wkhtmltopdf(html_file, pdf_file)
        else:
            success = convert_with_weasyprint(html_file, pdf_file)
        
        if success:
            print("✅")
            converted += 1
        else:
            print("❌")
            failed += 1
    
    print(f"\n✅ Conversion complete!")
    print(f"   Converted: {converted}")
    print(f"   Failed: {failed}")
    
    if failed > 0:
        print(f"\n💡 For failed conversions, use browser print method")
        print(f"   See CONVERT_HTML_TO_PDF.md for instructions")

if __name__ == "__main__":
    main()
