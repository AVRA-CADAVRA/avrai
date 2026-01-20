# Trace Analysis Scripts

**Scripts for analyzing Instruments trace files.**

---

## Available Scripts

### extract_strings.py
Extract readable strings and metadata from trace files.

**Usage:**
```bash
python3 scripts/extract_strings.py [trace_file_or_directory]
```

**Output:** Lists instrument configurations, object classes, and readable strings from trace files.

---

### extract_trace.py
Extract binary plist data from trace files.

**Usage:**
```bash
python3 scripts/extract_trace.py [trace_file]
```

**Output:** Attempts to parse and display trace configuration data.

---

### analyze_all_runs.py
Analyze all instrument runs in a trace directory.

**Usage:**
```bash
python3 scripts/analyze_all_runs.py
```

**Output:** Summary of all runs, stores, and trace contents.

---

## Requirements

- Python 3.7+
- Standard library only (no external dependencies)

---

## Future Scripts

- `extract_metrics.py` - Extract key metrics to CSV/JSON
- `compare_traces.py` - Compare two traces and generate report
- `generate_report.py` - Generate formatted comparison reports
