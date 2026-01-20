---
name: integration-optimization-checklist
description: Guides integration optimization checklist: output contracts, breaking changes, service registry updates, integration tests. Use when completing phases, starting phases, or modifying services.
---

# Integration Optimization Checklist

## Before Completing a Phase

### Output Contracts
Create output contracts document:
```markdown
# Phase X.Y Output Contracts

## Services Provided
- ServiceName: [Description]
  - Methods: [List]
  - Dependencies: [List]
  - Breaking Changes: [None/List]
```

### Breaking Changes
If applicable, create breaking changes document:
```markdown
# Phase X.Y Breaking Changes

## Service Changes
- ServiceName:
  - Removed: [Methods/Properties]
  - Changed: [Methods/Properties]
  - Migration: [Instructions]
```

### Service Registry
Update service registry with:
- New services
- Service versions
- Dependencies
- Breaking changes

### Integration Tests
Write integration tests for:
- Service integration points
- Cross-layer interactions
- End-to-end workflows

## Before Starting a Phase

### Input Requirements
Create input requirements document:
```markdown
# Phase X.Y Input Requirements

## Required Services
- ServiceName: [Version required]
  - Methods needed: [List]
  - Dependencies: [List]
```

### Dependency Verification
- [ ] All dependencies available
- [ ] Dependencies at required versions
- [ ] No circular dependencies
- [ ] All dependencies tested

### Service Registry Check
- [ ] Check for service locks
- [ ] Verify service versions
- [ ] Check breaking changes announcements

### Integration Checklist
- [ ] All dependencies satisfied
- [ ] Service registry checked
- [ ] Breaking changes reviewed
- [ ] Integration tests planned

## Before Modifying a Service

### Service Lock Check
- [ ] Check service registry for locks
- [ ] Announce breaking changes (2 weeks before)
- [ ] Lock service during modification
- [ ] Update integration tests

## Reference

- `.cursorrules_integration_optimization` - Integration optimization rules
- `docs/INTEGRATION_OPTIMIZATION_PLAN.md` - Complete guide
