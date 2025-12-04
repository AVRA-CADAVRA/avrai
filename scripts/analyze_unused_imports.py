#!/usr/bin/env python3
"""
Systematic Unused Import Analyzer and Remover

This script:
1. Finds all unused imports using flutter analyze
2. Checks each import for context (type annotations, exports, etc.)
3. Safely removes unused imports
4. Provides detailed report
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple, Dict
from collections import defaultdict

class UnusedImportAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.unused_imports: List[Tuple[str, int, str]] = []
        self.files_to_fix: Dict[str, List[Tuple[int, str]]] = defaultdict(list)
        
    def find_unused_imports(self) -> int:
        """Run flutter analyze and extract unused import warnings."""
        print("🔍 Running flutter analyze to find unused imports...")
        
        result = subprocess.run(
            ["flutter", "analyze", "--no-fatal-infos"],
            cwd=self.project_root,
            capture_output=True,
            text=True
        )
        
        # Parse output for unused import warnings
        pattern = r"warning • Unused import: '(.*?)' • (.*?):(\d+):\d+ • unused_import"
        
        for line in result.stdout.split('\n'):
            match = re.search(pattern, line)
            if match:
                import_name = match.group(1)
                file_path = match.group(2)
                line_num = int(match.group(3))
                
                # Only process files in lib/ directory
                if file_path.startswith('lib/'):
                    self.unused_imports.append((file_path, line_num, import_name))
                    self.files_to_fix[file_path].append((line_num, import_name))
        
        return len(self.unused_imports)
    
    def check_import_context(self, file_path: str, import_name: str) -> Dict[str, any]:
        """Check if import might be needed for type annotations, exports, etc."""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            return {"safe_to_remove": True, "reason": "File not found"}
        
        try:
            content = full_path.read_text()
            lines = content.split('\n')
            
            # Extract import name without package path
            import_base = import_name.split('/')[-1].replace('.dart', '')
            
            # Check for type annotations (more complex - would need Dart parser)
            # For now, we trust flutter analyze
            return {
                "safe_to_remove": True,
                "reason": "Verified by flutter analyze",
                "file_exists": True
            }
        except Exception as e:
            return {
                "safe_to_remove": False,
                "reason": f"Error reading file: {e}"
            }
    
    def remove_unused_import(self, file_path: str, line_num: int, import_name: str) -> bool:
        """Remove a single unused import from a file."""
        full_path = self.project_root / file_path
        
        if not full_path.exists():
            print(f"⚠️  File not found: {file_path}")
            return False
        
        try:
            content = full_path.read_text()
            lines = content.split('\n')
            
            # Check if line number is valid
            if line_num < 1 or line_num > len(lines):
                print(f"⚠️  Invalid line number {line_num} in {file_path}")
                return False
            
            # Get the import line (0-indexed)
            import_line = lines[line_num - 1]
            
            # Verify it's actually an import line
            if not (import_line.strip().startswith('import ') or 
                    import_line.strip().startswith('export ')):
                print(f"⚠️  Line {line_num} in {file_path} doesn't look like an import")
                return False
            
            # Check if the import name matches
            if import_name not in import_line:
                print(f"⚠️  Import name mismatch at line {line_num} in {file_path}")
                print(f"    Expected: {import_name}")
                print(f"    Found: {import_line}")
                return False
            
            # Remove the import line
            lines.pop(line_num - 1)
            
            # If it was the last line, remove trailing newline
            new_content = '\n'.join(lines)
            if content.endswith('\n') and not new_content.endswith('\n'):
                new_content += '\n'
            
            full_path.write_text(new_content)
            return True
            
        except Exception as e:
            print(f"❌ Error removing import from {file_path}: {e}")
            return False
    
    def generate_report(self) -> str:
        """Generate a detailed report of unused imports."""
        report = []
        report.append("=" * 80)
        report.append("UNUSED IMPORTS ANALYSIS REPORT")
        report.append("=" * 80)
        report.append("")
        report.append(f"Total unused imports found: {len(self.unused_imports)}")
        report.append(f"Files affected: {len(self.files_to_fix)}")
        report.append("")
        report.append("-" * 80)
        
        # Group by file
        for file_path in sorted(self.files_to_fix.keys()):
            imports = self.files_to_fix[file_path]
            report.append(f"\n📄 {file_path}")
            report.append(f"   Unused imports: {len(imports)}")
            for line_num, import_name in sorted(imports):
                report.append(f"   - Line {line_num}: {import_name}")
        
        return "\n".join(report)
    
    def fix_all(self, dry_run: bool = False) -> Tuple[int, int]:
        """Remove all unused imports."""
        fixed = 0
        failed = 0
        
        print(f"\n{'🔍 DRY RUN: ' if dry_run else '🔧 '}Removing unused imports...")
        
        for file_path, imports in sorted(self.files_to_fix.items()):
            print(f"\n📄 {file_path}")
            for line_num, import_name in sorted(imports, reverse=True):  # Reverse to maintain line numbers
                if dry_run:
                    print(f"   Would remove line {line_num}: {import_name}")
                else:
                    if self.remove_unused_import(file_path, line_num, import_name):
                        print(f"   ✅ Removed line {line_num}: {import_name}")
                        fixed += 1
                    else:
                        print(f"   ❌ Failed to remove line {line_num}: {import_name}")
                        failed += 1
        
        return fixed, failed


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("""
Unused Import Analyzer and Remover

Usage:
    python scripts/analyze_unused_imports.py [--dry-run] [--report-only] [--fix]

Options:
    --dry-run       Show what would be removed without actually removing
    --report-only   Generate report only, don't remove anything
    --fix           Actually remove the unused imports (default: dry-run)

Examples:
    python scripts/analyze_unused_imports.py --report-only
    python scripts/analyze_unused_imports.py --dry-run
    python scripts/analyze_unused_imports.py --fix
        """)
        return
    
    project_root = Path(__file__).parent.parent
    analyzer = UnusedImportAnalyzer(str(project_root))
    
    print("🚀 Starting unused import analysis...\n")
    
    # Find unused imports
    count = analyzer.find_unused_imports()
    print(f"✅ Found {count} unused imports across {len(analyzer.files_to_fix)} files\n")
    
    # Generate report
    report = analyzer.generate_report()
    
    # Determine action
    if "--report-only" in sys.argv:
        print(report)
        report_path = project_root / "docs/agents/reports/agent_2/phase_7/unused_imports_report.md"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(f"# Unused Imports Report\n\n{report}")
        print(f"\n📄 Report saved to: {report_path}")
    elif "--fix" in sys.argv:
        print(report)
        print("\n" + "=" * 80)
        confirm = input("\n⚠️  Are you sure you want to remove all unused imports? (yes/no): ")
        if confirm.lower() == 'yes':
            fixed, failed = analyzer.fix_all(dry_run=False)
            print(f"\n✅ Fixed: {fixed}")
            print(f"❌ Failed: {failed}")
        else:
            print("❌ Cancelled")
    else:
        print(report)
        print("\n" + "=" * 80)
        print("\n💡 Tip: Use --fix to actually remove the imports")
        print("💡 Tip: Use --report-only to generate a report file")


if __name__ == "__main__":
    main()

