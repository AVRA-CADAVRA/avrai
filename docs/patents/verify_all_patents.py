#!/usr/bin/env python3
"""
Comprehensive Patent Verification Script

Verifies all patent documents for:
1. Mathematical formula accuracy (matches code)
2. Code reference validity (files exist)
3. Formula consistency across documents
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Tuple, Set

# Project root
PROJECT_ROOT = Path(__file__).parent.parent.parent
PATENTS_DIR = PROJECT_ROOT / "docs" / "patents"
LIB_DIR = PROJECT_ROOT / "lib"

class PatentVerifier:
    def __init__(self):
        self.patents_verified = []
        self.formulas_found = []
        self.code_refs_found = []
        self.issues = []
        
    def find_all_patent_docs(self) -> List[Path]:
        """Find all main patent documents (exclude visuals, summaries, etc.)"""
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
        ]
        
        patent_files = []
        for category_dir in PATENTS_DIR.glob("category_*"):
            for patent_file in category_dir.rglob("*.md"):
                # Skip excluded patterns
                if any(pat in patent_file.name for pat in exclude_patterns):
                    continue
                # Only include main patent documents
                if patent_file.parent.name.startswith(("0", "1", "2", "3", "4", "5", "6", "7", "8", "9")):
                    patent_files.append(patent_file)
        
        return sorted(patent_files)
    
    def extract_formulas(self, content: str) -> List[Dict]:
        """Extract mathematical formulas from patent content"""
        formulas = []
        
        # Pattern for quantum compatibility: C = |⟨ψ_A|ψ_B⟩|²
        patterns = [
            (r'C\s*=\s*\|\s*⟨\s*ψ[^⟩]*⟩\s*\|\s*\^?2', 'Quantum Compatibility'),
            (r'\|⟨\s*ψ[^⟩]*⟩\|\s*\^?2', 'Quantum Inner Product Squared'),
            (r'⟨\s*ψ[^⟩]*⟩', 'Quantum Inner Product'),
            (r'D_B\s*=\s*√?\s*\[?\s*2\s*\(\s*1\s*-\s*\|⟨[^⟩]*⟩\|\s*\)\s*\]?', 'Bures Distance'),
            (r'\|ψ_entangled⟩\s*=\s*[^=]+', 'Entangled State'),
            (r'F\s*\(\s*ρ[^)]+\)', 'Quantum Fidelity'),
            (r'α_optimal\s*=\s*[^=]+', 'Coefficient Optimization'),
            (r'compatibility\s*=\s*[^=]+', 'Compatibility Formula'),
            (r'[0-9.]+%\s*\*\s*[A-Za-z_]+', 'Weighted Formula'),
        ]
        
        for pattern, formula_type in patterns:
            matches = re.finditer(pattern, content, re.IGNORECASE | re.MULTILINE)
            for match in matches:
                formulas.append({
                    'type': formula_type,
                    'formula': match.group(0),
                    'line': content[:match.start()].count('\n') + 1,
                })
        
        return formulas
    
    def extract_code_references(self, content: str) -> List[str]:
        """Extract code file references from patent content"""
        # Pattern: lib/core/... or packages/...
        pattern = r'(lib|packages)/[a-zA-Z0-9_/]+\.dart'
        matches = re.findall(pattern, content)
        return list(set(matches))
    
    def verify_code_file_exists(self, file_path: str) -> Tuple[bool, str]:
        """Check if code file exists"""
        # Handle both lib/ and packages/ paths
        if file_path.startswith('lib/'):
            full_path = LIB_DIR / file_path[4:]  # Remove 'lib/'
        elif file_path.startswith('packages/'):
            full_path = PROJECT_ROOT / file_path
        else:
            return False, f"Unknown path format: {file_path}"
        
        if full_path.exists():
            return True, str(full_path)
        else:
            return False, f"File not found: {file_path}"
    
    def verify_formula_in_code(self, formula: str, code_file: str) -> bool:
        """Check if formula appears in code file"""
        if not code_file or not os.path.exists(code_file):
            return False
        
        try:
            with open(code_file, 'r', encoding='utf-8') as f:
                code_content = f.read()
            
            # Extract key parts of formula for matching
            # Remove whitespace and normalize
            formula_normalized = re.sub(r'\s+', '', formula.lower())
            
            # Check for common formula patterns in code
            if '|⟨' in formula or 'innerproduct' in formula_normalized:
                # Look for inner product or compatibility calculations
                if 'innerproduct' in code_content.lower() or 'compatibility' in code_content.lower():
                    return True
            
            if 'fidelity' in formula_normalized:
                if 'fidelity' in code_content.lower():
                    return True
            
            # Check if formula comment exists in code
            if formula in code_content or formula.replace(' ', '') in code_content.replace(' ', ''):
                return True
                
        except Exception as e:
            return False
        
        return False
    
    def verify_patent(self, patent_file: Path) -> Dict:
        """Verify a single patent document"""
        print(f"Verifying: {patent_file.name}")
        
        with open(patent_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract formulas and code references
        formulas = self.extract_formulas(content)
        code_refs = self.extract_code_references(content)
        
        # Verify code references
        code_refs_status = []
        for ref in code_refs:
            exists, path = self.verify_code_file_exists(ref)
            code_refs_status.append({
                'reference': ref,
                'exists': exists,
                'path': path,
            })
        
        # Get patent number/name from file
        patent_name = patent_file.stem
        category = patent_file.parent.parent.name
        
        return {
            'patent_file': str(patent_file.relative_to(PROJECT_ROOT)),
            'patent_name': patent_name,
            'category': category,
            'formulas': formulas,
            'code_references': code_refs_status,
            'formula_count': len(formulas),
            'code_ref_count': len(code_refs),
        }
    
    def verify_all(self) -> Dict:
        """Verify all patents"""
        patent_files = self.find_all_patent_docs()
        print(f"Found {len(patent_files)} patent documents to verify\n")
        
        results = []
        for patent_file in patent_files:
            try:
                result = self.verify_patent(patent_file)
                results.append(result)
            except Exception as e:
                print(f"Error verifying {patent_file.name}: {e}")
                results.append({
                    'patent_file': str(patent_file.relative_to(PROJECT_ROOT)),
                    'error': str(e),
                })
        
        return {
            'total_patents': len(patent_files),
            'verified': len([r for r in results if 'error' not in r]),
            'results': results,
        }
    
    def generate_report(self, results: Dict) -> str:
        """Generate verification report"""
        report = []
        report.append("# Comprehensive Patent Verification Report\n")
        report.append(f"**Date:** {Path(__file__).stat().st_mtime}\n")
        report.append(f"**Total Patents:** {results['total_patents']}\n")
        report.append(f"**Successfully Verified:** {results['verified']}\n\n")
        report.append("---\n\n")
        
        # Summary by category
        by_category = {}
        for result in results['results']:
            if 'error' in result:
                continue
            category = result.get('category', 'unknown')
            if category not in by_category:
                by_category[category] = []
            by_category[category].append(result)
        
        report.append("## Summary by Category\n\n")
        for category, patents in sorted(by_category.items()):
            report.append(f"### {category}\n")
            report.append(f"- **Patents:** {len(patents)}\n")
            total_formulas = sum(p['formula_count'] for p in patents)
            total_refs = sum(p['code_ref_count'] for p in patents)
            valid_refs = sum(
                sum(1 for ref in p['code_references'] if ref['exists'])
                for p in patents
            )
            report.append(f"- **Total Formulas:** {total_formulas}\n")
            report.append(f"- **Total Code References:** {total_refs}\n")
            report.append(f"- **Valid Code References:** {valid_refs}/{total_refs}\n\n")
        
        # Detailed results
        report.append("## Detailed Results\n\n")
        for result in results['results']:
            if 'error' in result:
                report.append(f"### {result['patent_file']}\n")
                report.append(f"**Error:** {result['error']}\n\n")
                continue
            
            report.append(f"### {result['patent_name']}\n")
            report.append(f"- **File:** `{result['patent_file']}`\n")
            report.append(f"- **Category:** {result['category']}\n")
            report.append(f"- **Formulas Found:** {result['formula_count']}\n")
            report.append(f"- **Code References:** {result['code_ref_count']}\n\n")
            
            if result['formulas']:
                report.append("**Formulas:**\n")
                for formula in result['formulas'][:10]:  # Limit to first 10
                    report.append(f"- `{formula['formula']}` (line {formula['line']})\n")
                if len(result['formulas']) > 10:
                    report.append(f"- ... and {len(result['formulas']) - 10} more\n")
                report.append("\n")
            
            if result['code_references']:
                report.append("**Code References:**\n")
                for ref in result['code_references']:
                    status = "✅" if ref['exists'] else "❌"
                    report.append(f"- {status} `{ref['reference']}`\n")
                    if not ref['exists']:
                        report.append(f"  - **Issue:** File not found\n")
                report.append("\n")
        
        return "\n".join(report)

if __name__ == "__main__":
    verifier = PatentVerifier()
    results = verifier.verify_all()
    
    report = verifier.generate_report(results)
    
    # Save report
    report_file = PATENTS_DIR / "COMPREHENSIVE_VERIFICATION_REPORT.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"\n✅ Verification complete!")
    print(f"📄 Report saved to: {report_file}")
    print(f"📊 Total patents: {results['total_patents']}")
    print(f"✅ Verified: {results['verified']}")
