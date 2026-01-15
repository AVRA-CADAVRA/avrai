#!/usr/bin/env python3
"""
Convert HTML files to PDF using Playwright

Uses headless browser to convert HTML to PDF.
"""

import subprocess
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent / "patent_package_for_lawyer"

def check_playwright():
    """Check if playwright is available"""
    try:
        import playwright
        return True
    except ImportError:
        return False

def install_playwright_browser():
    """Install playwright browser"""
    try:
        subprocess.run([sys.executable, '-m', 'playwright', 'install', 'chromium'], 
                      check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        return False

def convert_with_playwright(html_file, pdf_file):
    """Convert HTML to PDF using playwright"""
    try:
        from playwright.sync_api import sync_playwright
        
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto(f'file://{html_file.absolute()}')
            page.pdf(path=str(pdf_file), format='A4', margin={'top': '1in', 'right': '1in', 'bottom': '1in', 'left': '1in'})
            browser.close()
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("🔍 Checking for Playwright...")
    
    if not check_playwright():
        print("❌ Playwright not found. Installing...")
        try:
            subprocess.run([sys.executable, '-m', 'pip', 'install', 'playwright', '--break-system-packages'], 
                          check=True, capture_output=True)
            print("✅ Playwright installed")
        except subprocess.CalledProcessError:
            print("❌ Failed to install Playwright")
            return
    
    print("🔧 Installing browser...")
    if not install_playwright_browser():
        print("⚠️  Browser installation may have issues, but continuing...")
    
    # Find all HTML files
    html_files = list(PACKAGE_DIR.rglob("*.html"))
    print(f"\n📄 Found {len(html_files)} HTML files to convert\n")
    
    converted = 0
    failed = 0
    
    for html_file in html_files:
        pdf_file = html_file.with_suffix('.pdf')
        print(f"  Converting: {html_file.name}...", end=" ", flush=True)
        
        success = convert_with_playwright(html_file, pdf_file)
        
        if success:
            print("✅")
            converted += 1
        else:
            print("❌")
            failed += 1
    
    print(f"\n✅ Conversion complete!")
    print(f"   Converted: {converted}")
    print(f"   Failed: {failed}")

if __name__ == "__main__":
    main()
