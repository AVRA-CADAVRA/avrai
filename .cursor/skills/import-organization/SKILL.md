---
name: import-organization
description: Enforces import grouping (Dart SDK → Flutter → packages → relative), alphabetical order, unused import removal. Use when writing or reviewing code to ensure consistent import organization.
---

# Import Organization

## Mandatory Order

**Group imports in this exact order:**

1. Dart SDK imports (`dart:...`)
2. Flutter imports (`package:flutter/...`)
3. Package imports (`package:...`)
4. Relative imports (`../...`)

**Use alphabetical ordering within each group**
**Separate groups with blank line**

## Pattern

```dart
// ✅ GOOD
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:avrai/core/models/user.dart';
import 'package:avrai/core/services/auth_service.dart';
import 'package:avrai/core/theme/colors.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
```

## Grouping Rules

### Group 1: Dart SDK
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
```

### Group 2: Flutter
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
```

### Group 3: Packages (Alphabetical)
```dart
import 'package:avrai/core/models/user.dart';
import 'package:avrai/core/services/auth_service.dart';
import 'package:avrai/presentation/pages/home_page.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
```

### Group 4: Relative (Alphabetical)
```dart
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../../core/models/spot.dart';
```

## Alphabetical Ordering

Within each group, sort alphabetically:

```dart
// ✅ GOOD: Alphabetical
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

// ❌ BAD: Not alphabetical
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
```

## Blank Line Separation

Separate groups with blank line:

```dart
// ✅ GOOD: Blank lines between groups
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avrai/core/models/user.dart';

import '../widgets/button.dart';

// ❌ BAD: No blank lines
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:avrai/core/models/user.dart';
```

## Import Aliases

Use aliases when needed:

```dart
import 'dart:developer' as developer;
import 'package:avrai/core/theme/colors.dart' as theme;
```

## Remove Unused Imports

**Always remove unused imports** (automatically handled by cleanup philosophy):

```dart
// ❌ BAD: Unused import
import 'package:unused_package/unused.dart'; // Remove this

class MyClass {
  // Doesn't use unused_package
}
```

## Exceptions

### Show/Hide Imports
When using `show` or `hide`, keep with the main import:

```dart
import 'package:avrai/core/services/storage_service.dart'
    show StorageService, StorageError;
```

### Conditional Imports
Keep conditional imports together:

```dart
import 'package:avrai/core/platform/file_stub.dart'
    if (dart.library.io) 'package:avrai/core/platform/file_io.dart'
    if (dart.library.html) 'package:avrai/core/platform/file_web.dart';
```

## Tools

- **Dart formatter** - Automatically organizes imports
- **IDE** - Most IDEs can organize imports automatically
- **Pre-commit hooks** - Can enforce import organization

## Checklist

Before committing:
- [ ] Imports grouped correctly (Dart → Flutter → Packages → Relative)
- [ ] Imports alphabetically ordered within groups
- [ ] Blank lines between groups
- [ ] No unused imports
- [ ] Import aliases used when needed
