# Complete Skills Catalog

This document lists all 56 skills for the AVRAI project, with creation instructions for remaining skills.

## Skills Created (56/56) ✅ COMPLETE

### ✅ Top 10 Critical Skills (1-10)
1. ✅ `spots-philosophy-integration`
2. ✅ `logging-standards-enforcement`
3. ✅ `dependency-injection-getit`
4. ✅ `bloc-state-management`
5. ✅ `master-plan-notation`
6. ✅ `test-quality-enforcement`
7. ✅ `design-tokens-enforcement`
8. ✅ `error-handling-patterns`
9. ✅ `context-gathering-protocol`
10. ✅ `clean-architecture-implementation`

### ✅ Architecture & Patterns (11-15)
11. ✅ `service-pattern-standardization`
12. ✅ `async-await-patterns`
13. ✅ `file-organization-standards`
14. ✅ `controller-pattern`
15. ✅ `workflow-controller-pattern`

### ✅ Code Standards (16-25)
16. ✅ `import-organization`
17. ✅ `code-documentation-standards`
18. ✅ `deprecated-api-detection`
19. ✅ `linter-error-prevention`
20-25. *(Additional code standards skills can be added here)*

### ✅ Domain-Specific SPOTS (26-30)
26. ✅ `doors-philosophy-validation`
27. ✅ `meaningful-connections-check`
28. ✅ `spots-journey-flow`
29. ✅ `real-world-enhancement-check`
30. ✅ `master-plan-integration-validation`

### ✅ AI2AI & Networking (31-36)
31. ✅ `ai2ai-protocol-implementation`
32. ✅ `signal-protocol-integration`
33. ✅ `ble-implementation-patterns`
34. ✅ `device-discovery-service`
35. ✅ `connection-orchestrator-patterns`
36. ✅ `ai2ai-learning-service`

### ✅ Testing (45-50)
45. ✅ `test-template-generation`
46. ✅ `integration-test-patterns`
47. ✅ `widget-test-patterns`
48. ✅ `test-coverage-requirements`
49. ✅ `experiment-testing-standards`
50. ✅ `test-implementation-requirements`

### ✅ Performance & Security (61-66)
61. ✅ `offline-first-patterns`
62. ✅ `performance-optimization-guide`
63. ✅ `battery-adaptive-scheduling`
64. ✅ `privacy-protection-patterns`
65. ✅ `security-validation-checklist`
66. ✅ `ai2ai-privacy-validation`

### ✅ Feature-Specific (37-44)
37. ✅ `quantum-matching-algorithms`
38. ✅ `expertise-system-implementation`
39. ✅ `reservation-system-patterns`
40. ✅ `payment-service-integration`
41. ✅ `hybrid-search-implementation`
42. ✅ `geographic-services-patterns`
43. ✅ `business-partnership-patterns`
44. ✅ `event-system-implementation`

### ✅ Documentation & Workflow (55-60)
55. ✅ `master-plan-integration-workflow`
56. ✅ `documentation-refactoring-protocol`
57. ✅ `integration-optimization-checklist`
58. ✅ `status-query-handling`
59. ✅ `plan-discovery-workflow`
60. ✅ `completion-report-generation`

## ✅ ALL SKILLS COMPLETE

All 56 skills have been created and are available in `.cursor/skills/`.

### Domain-Specific SPOTS (28-30)
28. `master-plan-integration-validation` - Validates Master Plan integration workflow
29. `spots-journey-flow` - Ensures features support Spots → Community → Life journey
30. `real-world-enhancement-check` - Validates technology enhances real world, doesn't replace it

### AI2AI & Networking (34-36)
34. `device-discovery-service` - Guides device discovery implementation patterns
35. `connection-orchestrator-patterns` - Guides connection orchestration patterns
36. `ai2ai-learning-service` - Guides AI2AI learning service implementation

### Feature-Specific (37-44)
37. `quantum-matching-algorithms` - Guides quantum matching implementation
38. `expertise-system-implementation` - Guides expertise system implementation
39. `reservation-system-patterns` - Guides reservation system patterns
40. `payment-service-integration` - Guides payment service integration
41. `hybrid-search-implementation` - Guides hybrid search implementation
42. `geographic-services-patterns` - Guides geographic services patterns
43. `business-partnership-patterns` - Guides business partnership implementation
44. `event-system-implementation` - Guides event system implementation

### Testing (46-50)
46. `integration-test-patterns` - Guides integration test patterns
47. `widget-test-patterns` - Guides widget test patterns
48. `test-coverage-requirements` - Enforces test coverage requirements
49. `experiment-testing-standards` - Enforces experiment testing standards (real implementation)
50. `test-implementation-requirements` - Enforces test implementation requirements (no mocks/stubs)

### Native Code (51-54)
51. `rust-ffi-bindings` - Guides Rust FFI bindings implementation
52. `swift-integration-patterns` - Guides Swift integration patterns
53. `kotlin-java-android-patterns` - Guides Kotlin/Java Android integration
54. `native-code-error-handling` - Guides native code error handling patterns

### Documentation & Workflow (55-60)
55. `master-plan-integration-workflow` - Guides Master Plan integration workflow
56. `documentation-refactoring-protocol` - Enforces documentation refactoring protocol
57. `integration-optimization-checklist` - Guides integration optimization checklist
58. `status-query-handling` - Guides status query handling protocol
59. `plan-discovery-workflow` - Guides plan discovery workflow
60. `completion-report-generation` - Guides completion report generation

### Performance & Security (61-66)
61. `offline-first-patterns` - Enforces offline-first architecture patterns
62. `performance-optimization-guide` - Guides performance optimization
63. `battery-adaptive-scheduling` - Guides battery-adaptive BLE scheduling
64. `privacy-protection-patterns` - Enforces privacy protection patterns
65. `security-validation-checklist` - Guides security validation checklist
66. `ai2ai-privacy-validation` - Enforces AI2AI privacy validation

## Skill Creation Instructions

### Skill Structure

Each skill must have:
1. Directory: `.cursor/skills/[skill-name]/`
2. File: `SKILL.md` with YAML frontmatter

### SKILL.md Template

```markdown
---
name: skill-name
description: Brief description of what this skill does and when to use it. Use when [trigger scenarios].
---

# Skill Name

## Core Principle/Pattern

[Main guidance]

## Implementation Pattern

```dart
// Code examples
```

## Checklist

- [ ] Item 1
- [ ] Item 2

## Reference

- File paths
- Documentation links
```

### Description Guidelines

- **Write in third person** (the description is injected into system prompt)
- **Be specific** - Include trigger terms
- **Include both WHAT and WHEN**
- **Max 1024 characters**

### Example Description

```yaml
description: Guides Signal protocol integration: encryption/decryption, key management, session management, FFI bindings, security best practices. Use when implementing encryption, secure communication, or Signal protocol features.
```

## Creating Remaining Skills

### Quick Creation Script

For each remaining skill:

1. Create directory: `.cursor/skills/[skill-name]/`
2. Create file: `SKILL.md`
3. Use template above
4. Reference existing skills for patterns
5. Include code examples from codebase
6. Reference relevant documentation

### Skill Creation Checklist

- [ ] Directory created: `.cursor/skills/[skill-name]/`
- [ ] SKILL.md created with frontmatter
- [ ] Description is specific and includes trigger terms
- [ ] Description is in third person
- [ ] Includes implementation patterns
- [ ] Includes code examples
- [ ] Includes checklist (if applicable)
- [ ] References relevant files/docs
- [ ] Under 500 lines (use progressive disclosure)

## Priority Order for Remaining Skills

Create remaining skills in this priority order:

### ✅ High Priority (Completed)
1. ✅ `integration-test-patterns` - Frequently used
2. ✅ `offline-first-patterns` - Core architecture
3. ✅ `privacy-protection-patterns` - Critical requirement
4. ✅ `quantum-matching-algorithms` - Domain-specific
5. ✅ `master-plan-integration-workflow` - Frequently used

### Medium Priority (Next Batch)

### Medium Priority (Next Batch)
1. `device-discovery-service`
2. `connection-orchestrator-patterns`
3. `reservation-system-patterns`
4. `expertise-system-implementation`
5. `hybrid-search-implementation`

### Lower Priority (Can create on-demand)
- Remaining feature-specific skills
- Native code skills (when needed)
- Performance optimization skills (when needed)

## Notes

- All skills are project-level (`.cursor/skills/`) - shared with repository
- Skills auto-discoverable by Cursor AI
- Skills guide AI behavior when trigger terms detected
- Update this catalog as new skills are created
