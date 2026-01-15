# PDF Conversion Instructions

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
