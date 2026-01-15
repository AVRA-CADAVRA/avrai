# CodeQL Setup and Maintenance Scripts

Scripts for managing CodeQL databases for security and code quality analysis.

## Scripts Overview

### 1. `codeql_cleanup.sh` - Clean Corrupted Databases
Removes CodeQL databases that contain ambiguous datasets (multiple languages mixed together).

**Usage:**
```bash
./scripts/codeql_cleanup.sh
```

**What it does:**
- Finds all CodeQL databases in Cursor workspace storage
- Identifies databases with multiple language datasets (causes "ambiguous datasets" error)
- Prompts for confirmation before deletion
- Removes corrupted databases so CodeQL extension can recreate them

**When to use:**
- When you see "contains ambiguous datasets" error in CodeQL extension
- After switching between different CodeQL database configurations
- When CodeQL extension is having trouble resolving databases

---

### 2. `codeql_setup_rust.sh` - Setup Rust Analysis Database
Creates a CodeQL database specifically for Rust code analysis.

**Usage:**
```bash
./scripts/codeql_setup_rust.sh
```

**What it does:**
- Checks for CodeQL CLI availability
- Finds Rust projects (Cargo.toml files) in `native/` directory
- Creates a CodeQL database for Rust code
- Outputs database to `.codeql-databases/rust/`

**Requirements:**
- CodeQL CLI installed (usually comes with CodeQL extension)
- Rust source code in `native/` directory

**Database Location:**
- `.codeql-databases/rust/` (in project root)

**Note:** The database creation may take several minutes depending on codebase size.

---

### 3. `codeql_setup_complete.sh` - Complete Setup
Runs both cleanup and Rust setup in sequence.

**Usage:**
```bash
./scripts/codeql_setup_complete.sh
```

**What it does:**
1. Cleans up corrupted databases
2. Sets up Rust analysis database
3. Provides guidance for Dart database (auto-created by extension)

**Recommended for:**
- First-time setup
- After cleaning up corrupted databases
- When setting up both Dart and Rust analysis

---

## Quick Start

### First Time Setup

```bash
# Run complete setup (recommended)
./scripts/codeql_setup_complete.sh
```

This will:
1. ✅ Clean any corrupted databases
2. ✅ Create Rust analysis database
3. ✅ Guide you on Dart database (auto-created by extension)

### Individual Operations

```bash
# Just clean corrupted databases
./scripts/codeql_cleanup.sh

# Just setup Rust database
./scripts/codeql_setup_rust.sh
```

---

## Database Locations

### Dart Database (Auto-created)
- **Location:** Cursor workspace storage (managed by extension)
- **Creation:** Automatic when using CodeQL extension
- **Language:** Dart (primary language - 1,206 files)

### Rust Database (Manual setup)
- **Location:** `.codeql-databases/rust/` (in project root)
- **Creation:** Manual via `codeql_setup_rust.sh`
- **Language:** Rust (native code - 157 files)
- **Source:** `native/` directory

---

## Using CodeQL Databases

### In Cursor/VS Code

1. **Open Database:**
   - Command Palette (Cmd+Shift+P)
   - Run: `CodeQL: Choose Database`
   - Select your database

2. **Run Queries:**
   - Command Palette → `CodeQL: Run Query`
   - Select a query file or use built-in queries

3. **View Results:**
   - Results appear in CodeQL extension panel
   - Click results to navigate to code

### Command Line

```bash
# Run a query
codeql query run <query.ql> --database=.codeql-databases/rust

# List available queries
codeql resolve queries --format=json
```

---

## Troubleshooting

### "CodeQL CLI not found"
- CodeQL CLI should come with the CodeQL extension
- Check: `~/Library/Application Support/Cursor/User/globalStorage/github.vscode-codeql/distribution*/codeql`
- Or install manually: https://github.com/github/codeql-cli-binaries/releases

### "Ambiguous datasets" error
- Run cleanup script: `./scripts/codeql_cleanup.sh`
- Reload CodeQL extension
- Restart Cursor if needed

### Rust database creation fails
- Ensure Rust code is buildable: `cd native && cargo build`
- Check CodeQL Rust support: `codeql resolve languages`
- Try manual creation: `codeql database create .codeql-databases/rust --language=rust --source-root=native`

### Dart database not auto-creating
- Open a Dart file in your project
- Use Command Palette → `CodeQL: Create Database`
- Select language: Dart, source root: project root

---

## Language Support

### Supported Languages
- ✅ **Dart** - Primary language (auto-created by extension)
- ✅ **Rust** - Native code (manual setup via script)
- ⚠️ **Python** - Scripts (not recommended for CodeQL, use other tools)
- ⚠️ **TypeScript** - Supabase functions (small codebase, optional)

### Not Recommended
- ❌ **Java/Kotlin** - Mostly in submodules (not your code)
- ❌ **Swift** - Minimal code, mostly in submodules

---

## Project Language Breakdown

- **Dart:** 1,206 files (primary - Flutter app)
- **Rust:** 157 files (native libraries)
- **Python:** 132 files (scripts/experiments)
- **TypeScript/JavaScript:** 52 files (Supabase functions)
- **Java/Kotlin/Swift:** Minimal (mostly submodules)

---

## Maintenance

### Regular Cleanup
Run cleanup periodically if you see database issues:
```bash
./scripts/codeql_cleanup.sh
```

### Recreate Rust Database
If Rust code changes significantly:
```bash
rm -rf .codeql-databases/rust
./scripts/codeql_setup_rust.sh
```

### Update Databases
CodeQL databases should be recreated when:
- Major code changes
- After large refactorings
- When security analysis is needed
- After updating CodeQL CLI

---

## Additional Resources

- [CodeQL Documentation](https://codeql.github.com/docs/)
- [CodeQL Queries](https://github.com/github/codeql)
- [CodeQL CLI Reference](https://codeql.github.com/docs/codeql-cli/)

---

**Last Updated:** January 2026
