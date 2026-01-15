# Convert HTML Files to PDF

All patent documents have been converted to HTML format. To create PDFs for your lawyer meeting, use one of these methods:

## Method 1: Browser Print (Easiest - Recommended)

**macOS:**
1. Open each HTML file in Safari or Chrome
2. Press `Cmd+P` (Print)
3. Click "Save as PDF"
4. Save to the same location (replace .html with .pdf)

**Batch Conversion Script (macOS):**
```bash
cd /Users/reisgordon/AVRAI/docs/patents/patent_package_for_lawyer
find . -name "*.html" -exec sh -c 'open -a Safari "$1" && sleep 2 && osascript -e "tell application \"Safari\" to activate" -e "tell application \"System Events\" to keystroke \"p\" using command down" -e "delay 1" -e "tell application \"System Events\" to keystroke \"s\" using command down" -e "delay 1" -e "tell application \"System Events\" to keystroke \"$(basename \"$1\" .html).pdf\"" -e "tell application \"System Events\" to keystroke return' _ {} \;
```

## Method 2: Online Converter

1. Visit: https://www.ilovepdf.com/html-to-pdf
2. Upload HTML files in batches
3. Download PDFs
4. Save to appropriate category folders

## Method 3: Command Line (if tools installed)

**Using wkhtmltopdf:**
```bash
brew install wkhtmltopdf
cd /Users/reisgordon/AVRAI/docs/patents/patent_package_for_lawyer
find . -name "*.html" -exec sh -c 'wkhtmltopdf "$1" "${1%.html}.pdf"' _ {} \;
```

**Using weasyprint (Python):**
```bash
pip install weasyprint
cd /Users/reisgordon/AVRAI/docs/patents/patent_package_for_lawyer
python3 -c "
from pathlib import Path
from weasyprint import HTML
for html_file in Path('.').rglob('*.html'):
    pdf_file = html_file.with_suffix('.pdf')
    HTML(str(html_file)).write_pdf(str(pdf_file))
    print(f'Converted: {html_file.name}')
"
```

## Method 4: Manual (One-by-One)

1. Open HTML file in browser
2. File > Print > Save as PDF
3. Repeat for each file

---

## Quick Conversion Script

I've created a helper script. Run:

```bash
cd /Users/reisgordon/AVRAI/docs/patents
python3 convert_html_to_pdf.py
```

This will attempt automatic conversion using available tools.
