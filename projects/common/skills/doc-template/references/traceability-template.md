# Traceability Template

This template defines the structure for Traceability Matrix documents.

## Purpose

The Traceability Matrix ensures complete coverage from stakeholder requirements through implementation and testing, mapping:

```
SRS (RS_*) → SAD (FS_*) → SDS (DS_*) → Tests (TC_*)
```

## Complete Traceability Matrix Template

```markdown
# Traceability Matrix

## {Component Name} ({component_id})

**Document ID**: {PREFIX}-TM-{SEQ}
**Version**: {VERSION}
**Date**: {DATE}
**Author**: {AUTHOR}
**Status**: {STATUS}

---

## 1. Revision History

| Version | Editor | Date | Note |
|---------|--------|------|------|
| 1.0 | {Author} | {YYYY-MM-DD} | Initial release |

---

## 2. Document Purpose

This document provides bidirectional traceability between:
- Stakeholder Requirements (SRS - RS_*)
- Functional Specifications (SAD - FS_*)
- Detailed Design (SDS - DS_*)
- Test Cases (TC_*)

---

## 3. ID Mapping Reference

### 3.1 Local to Jama ID Mapping

| Document | Local ID Pattern | Jama Project |
|----------|------------------|--------------|
| SRS | RS_{CAT}_{SEQ} | SW2-SHRQ-* |
| SAD | FS_{CAT}_{AREA}_{SEQ} | SW2-SWARCH-* |
| SDS | DS_{COMP}_{TYPE}_{SEQ} | SW2-SWDD-* |
| Test | TC_{COMP}_{SEQ} | SW2-VERTC-* |

---

## 4. Requirements to Specifications Traceability (RS → FS)

### 4.1 {Category} Requirements

| RS ID | Jama ID | Title | FS IDs | Coverage |
|-------|---------|-------|--------|----------|
| RS_{CAT}_001 | SW2-SHRQ-{ID} | {Title} | FS_{CAT}_{AREA}_001, FS_{CAT}_{AREA}_002 | Full |
| RS_{CAT}_002 | SW2-SHRQ-{ID} | {Title} | FS_{CAT}_{AREA}_003 | Full |
| RS_{CAT}_003 | SW2-SHRQ-{ID} | {Title} | - | Pending |

### 4.2 Coverage Summary (RS → FS)

| Category | Total RS | Covered | Pending | Coverage % |
|----------|----------|---------|---------|------------|
| {Category 1} | {N} | {M} | {P} | {%} |
| {Category 2} | {N} | {M} | {P} | {%} |
| **Total** | **{TOTAL}** | **{COVERED}** | **{PENDING}** | **{%}** |

---

## 5. Specifications to Design Traceability (FS → DS)

### 5.1 {Functional Area} Specifications

| FS ID | Jama ID | Title | DS IDs | Coverage |
|-------|---------|-------|--------|----------|
| FS_{CAT}_{AREA}_001 | SW2-SWARCH-{ID} | {Title} | DS_{COMP}_CLS_001, DS_{COMP}_SM_001 | Full |
| FS_{CAT}_{AREA}_002 | SW2-SWARCH-{ID} | {Title} | DS_{COMP}_ALG_001 | Full |

### 5.2 Coverage Summary (FS → DS)

| Category | Total FS | Covered | Pending | Coverage % |
|----------|----------|---------|---------|------------|
| {Category 1} | {N} | {M} | {P} | {%} |
| **Total** | **{TOTAL}** | **{COVERED}** | **{PENDING}** | **{%}** |

---

## 6. Design to Test Traceability (DS → TC)

### 6.1 {Component} Design Elements

| DS ID | Jama ID | Title | TC IDs | Coverage |
|-------|---------|-------|--------|----------|
| DS_{COMP}_CLS_001 | SW2-SWDD-{ID} | {Title} | TC_{COMP}_001, TC_{COMP}_002 | Full |
| DS_{COMP}_SM_001 | SW2-SWDD-{ID} | {Title} | TC_{COMP}_003 | Full |

### 6.2 Coverage Summary (DS → TC)

| Type | Total DS | Covered | Pending | Coverage % |
|------|----------|---------|---------|------------|
| Class (CLS) | {N} | {M} | {P} | {%} |
| State Machine (SM) | {N} | {M} | {P} | {%} |
| Algorithm (ALG) | {N} | {M} | {P} | {%} |
| **Total** | **{TOTAL}** | **{COVERED}** | **{PENDING}** | **{%}** |

---

## 7. End-to-End Traceability Matrix

### 7.1 Complete Trace Chain

| RS ID | RS Jama | FS ID | FS Jama | DS ID | DS Jama | TC ID | TC Jama | Status |
|-------|---------|-------|---------|-------|---------|-------|---------|--------|
| RS_{CAT}_001 | SW2-SHRQ-{ID} | FS_{CAT}_{AREA}_001 | SW2-SWARCH-{ID} | DS_{COMP}_CLS_001 | SW2-SWDD-{ID} | TC_{COMP}_001 | SW2-VERTC-{ID} | Complete |
| RS_{CAT}_002 | SW2-SHRQ-{ID} | FS_{CAT}_{AREA}_002 | SW2-SWARCH-{ID} | DS_{COMP}_SM_001 | SW2-SWDD-{ID} | TC_{COMP}_002 | SW2-VERTC-{ID} | Complete |
| RS_{CAT}_003 | SW2-SHRQ-{ID} | - | - | - | - | - | - | Pending FS |

### 7.2 Trace Chain Status Summary

| Status | Count | Percentage |
|--------|-------|------------|
| Complete (RS→FS→DS→TC) | {N} | {%} |
| Missing TC | {N} | {%} |
| Missing DS | {N} | {%} |
| Missing FS | {N} | {%} |
| **Total Requirements** | **{TOTAL}** | **100%** |

---

## 8. Reverse Traceability

### 8.1 Test to Requirement (TC → RS)

| TC ID | TC Jama | DS ID | FS ID | RS ID | RS Jama |
|-------|---------|-------|-------|-------|---------|
| TC_{COMP}_001 | SW2-VERTC-{ID} | DS_{COMP}_CLS_001 | FS_{CAT}_{AREA}_001 | RS_{CAT}_001 | SW2-SHRQ-{ID} |

### 8.2 Orphan Analysis

#### 8.2.1 Orphan Tests (TC without DS trace)
| TC ID | Description | Action Required |
|-------|-------------|-----------------|
| {TC_ID} | {Description} | Link to DS |

#### 8.2.2 Orphan Designs (DS without FS trace)
| DS ID | Description | Action Required |
|-------|-------------|-----------------|
| {DS_ID} | {Description} | Link to FS |

#### 8.2.3 Orphan Specifications (FS without RS trace)
| FS ID | Description | Action Required |
|-------|-------------|-----------------|
| {FS_ID} | {Description} | Link to RS |

---

## 9. Verification Matrix

### 9.1 Requirement Verification Status

| RS ID | Jama ID | Verification Method | TC IDs | Status |
|-------|---------|---------------------|--------|--------|
| RS_{CAT}_001 | SW2-SHRQ-{ID} | Test | TC_{COMP}_001 | Passed |
| RS_{CAT}_002 | SW2-SHRQ-{ID} | Analysis | - | Verified |
| RS_{CAT}_003 | SW2-SHRQ-{ID} | Inspection | - | Pending |

### 9.2 Verification Summary

| Method | Count | Passed | Failed | Pending |
|--------|-------|--------|--------|---------|
| Test | {N} | {P} | {F} | {W} |
| Analysis | {N} | {P} | {F} | {W} |
| Inspection | {N} | {P} | {F} | {W} |
| Demo | {N} | {P} | {F} | {W} |
| **Total** | **{TOTAL}** | **{PASSED}** | **{FAILED}** | **{PENDING}** |

---

## 10. Gap Analysis

### 10.1 Requirements without Specifications

| RS ID | Jama ID | Title | Priority | Action |
|-------|---------|-------|----------|--------|
| {RS_ID} | SW2-SHRQ-{ID} | {Title} | High | Create FS |

### 10.2 Specifications without Design

| FS ID | Jama ID | Title | Action |
|-------|---------|-------|--------|
| {FS_ID} | SW2-SWARCH-{ID} | {Title} | Create DS |

### 10.3 Design without Tests

| DS ID | Jama ID | Title | Action |
|-------|---------|-------|--------|
| {DS_ID} | SW2-SWDD-{ID} | {Title} | Create TC |

---

## 11. References

| Document | Description |
|----------|-------------|
| {PREFIX}-SRS-{SEQ} | Software Requirements Specification |
| {PREFIX}-SAD-{SEQ} | Software Architecture Document |
| {PREFIX}-SDS-{SEQ} | Software Design Specification |
| ASPICE 3.1 | Automotive SPICE Process Model |

---

**Document End**

**Related Documents**:
- {PREFIX}-SRS-{SEQ}: Software Requirements Specification
- {PREFIX}-SAD-{SEQ}: Software Architecture Document
- {PREFIX}-SDS-{SEQ}: Software Design Specification
```

## Traceability Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         TRACEABILITY FLOW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌────────┐ │
│  │    SRS      │ ──→ │    SAD      │ ──→ │    SDS      │ ──→ │  Test  │ │
│  │  (SWE.1)    │     │  (SWE.2)    │     │  (SWE.3)    │     │        │ │
│  ├─────────────┤     ├─────────────┤     ├─────────────┤     ├────────┤ │
│  │ RS_CM_001   │ ──→ │ FS_CM_001   │ ──→ │ DS_CM_001   │ ──→ │TC_CM_001│ │
│  │(SW2-SHRQ-*) │     │(SW2-SWARCH*)│     │(SW2-SWDD-*) │     │(VERTC-*)│ │
│  └─────────────┘     └─────────────┘     └─────────────┘     └────────┘ │
│                                                                          │
│  Forward Trace: RS → FS → DS → TC (Implementation flow)                  │
│  Reverse Trace: TC → DS → FS → RS (Verification flow)                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Coverage Metrics

### Target Coverage

| Trace Level | Target | Minimum |
|-------------|--------|---------|
| RS → FS | 100% | 100% |
| FS → DS | 100% | 95% |
| DS → TC | 100% | 90% |
| End-to-End | 100% | 85% |

### Coverage Calculation

```
Coverage % = (Items with trace / Total items) × 100
```

## Verification Methods

| Method | Description | When to Use |
|--------|-------------|-------------|
| Test | Automated or manual testing | Functional requirements |
| Analysis | Mathematical or logical analysis | Performance, timing |
| Inspection | Code/document review | Coding standards, design |
| Demo | Demonstration in target environment | Integration, UI |

## Gap Analysis Actions

| Gap Type | Priority | Action |
|----------|----------|--------|
| RS without FS | Critical | Create functional specification |
| FS without DS | High | Create detailed design |
| DS without TC | High | Create test case |
| Orphan TC | Medium | Link to design or remove |
| Orphan DS | Medium | Link to specification or remove |

## Quality Checklist

- [ ] All RS have at least one FS trace
- [ ] All FS have at least one DS trace
- [ ] All DS have at least one TC trace
- [ ] No orphan items exist
- [ ] Coverage meets minimum thresholds
- [ ] Jama IDs are correctly mapped
- [ ] Verification status is current
- [ ] Gap analysis is complete
