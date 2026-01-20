---
name: master-plan-integration-validation
description: Validates Master Plan integration workflow completion: plan created, tracker updated, dependencies analyzed, execution sequence updated. Use when validating Master Plan integration or reviewing plan integration completeness.
---

# Master Plan Integration Validation

## Validation Checklist

### Plan Document
- [ ] Comprehensive plan document created
- [ ] Plan folder structure created
- [ ] Supporting docs initialized (progress.md, status.md, blockers.md)
- [ ] Doors questions answered
- [ ] Methodology compliance verified

### Master Plan Tracker
- [ ] Added to Master Plan Tracker
- [ ] All required fields included (Date, Status, Priority, Timeline, File Path)
- [ ] Dependencies listed
- [ ] Dependents listed

### Master Plan Integration
- [ ] Dependencies analyzed
- [ ] Tier determined
- [ ] Inserted into Master Plan execution index
- [ ] Position respects dependency order

### Status Tracker
- [ ] Status tracker updated
- [ ] Phase status set correctly
- [ ] Progress tracking initialized

### Notation Compliance
- [ ] Phase.Section.Subsection (X.Y.Z) format used
- [ ] No "Week" or "Day" terminology
- [ ] Consistent notation throughout

## Validation Pattern

```markdown
## Master Plan Integration Validation

### Plan Document ✅
- Plan created: ✅
- Folder structure: ✅
- Supporting docs: ✅
- Doors questions: ✅

### Master Plan Tracker ✅
- Added to tracker: ✅
- Required fields: ✅
- Dependencies: ✅

### Master Plan Integration ✅
- Dependencies analyzed: ✅
- Tier determined: ✅
- Inserted into index: ✅

### Status Tracker ✅
- Updated: ✅
- Status correct: ✅
```

## Reference

- `docs/MASTER_PLAN.md` - Master Plan
- `docs/MASTER_PLAN_TRACKER.md` - Master Plan Tracker
- `.cursorrules_master_plan` - Master Plan rules
