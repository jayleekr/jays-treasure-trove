# SRS Template (SWE.1 - Software Requirements Specification)

This template defines the structure for Software Requirements Specification documents.

## ASPICE Mapping

- **Process**: SWE.1 Software Requirements Analysis
- **Purpose**: Define stakeholder requirements that drive functional specifications
- **Output**: Stakeholder requirements with traceability to SAD

## Complete SRS Template

```markdown
# Software Requirements Specification

## {Component Name} ({component_id})

**Document ID**: {PREFIX}-SRS-{SEQ}
**Version**: {VERSION}
**Date**: {DATE}
**Author**: {AUTHOR}
**Status**: {STATUS}
**ASPICE Process**: SWE.1

---

## 1. Revision History

| Version | Editor | Date | Note |
|---------|--------|------|------|
| 1.0 | {Author} | {YYYY-MM-DD} | Jama-aligned restructure |
| 0.8 | {Author} | {YYYY-MM-DD} | Feature complete |
| 0.1 | {Author} | {YYYY-MM-DD} | First draft |

---

## 2. Document Description

This document serves as the stakeholder requirements specification for {component description} on CCU Gen2. It captures high-level customer and business requirements that drive the functional specifications defined in the Software Architecture Document (SAD).

---

## 3. Document Purpose

This document defines the stakeholder requirements that the {Component Name} component must satisfy. These requirements serve as the foundation for deriving functional specifications and architectural decisions.

---

## 4. Document Scope

This specification applies to {scope description}. It encompasses:

- {Scope item 1}
- {Scope item 2}
- {Scope item 3}
- {Scope item 4}

---

## 5. Terminology

### 5.1 Interpretation

| Term | Definition |
|------|------------|
| Shall | Mandatory requirement |
| Should | Recommended action or suggestion (offered as advice) |
| Will | Additional or optional feature, or a declaration of intent |
| May | Allowed action, not to be considered as a requirement |

### 5.2 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|------|------------|
| {ACRONYM} | {Definition} |

---

## 6. General Description

{High-level description of the component/system and its context.}

---

## 7. Stakeholder Requirements

This section defines the stakeholder requirements organized by functional area. Each requirement traces forward to functional specifications in the SAD document.

### 7.1 {Category Name} Requirements (RS_{CAT})

{Category description explaining the scope of these requirements.}

---

#### RS_{CAT}_001: {Requirement Title}

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SHRQ-{JAMA_ID} |
| Status | {Accepted|Draft|Rejected} |
| Source | {Customer|Internal|Unassigned} |
| External ID | RS_{CAT}_001 |
| Priority | {High|Medium|Low} |

**Description**: {Detailed requirement description using shall/should/will/may language.}

**Rationale**: {Business or technical justification for this requirement.}

**Traces To (Functional Specifications)**:
- FS_{CAT}_{AREA}_001: {FS Title}
- FS_{CAT}_{AREA}_002: {FS Title}

---

### 7.2 {Next Category} Requirements (RS_{CAT2})

{Repeat pattern for each requirement category...}

---

## 8. Requirements Summary

### 8.1 Requirements by Category

| Category | Count | IDs |
|----------|-------|-----|
| {Category 1} (RS_{CAT1}) | {N} | RS_{CAT1}_001 - RS_{CAT1}_{N} |
| {Category 2} (RS_{CAT2}) | {M} | RS_{CAT2}_001 - RS_{CAT2}_{M} |
| **Total** | **{TOTAL}** | |

### 8.2 Traceability Summary

| RS ID | Jama ID | FS IDs (SAD) |
|-------|---------|--------------|
| RS_{CAT}_001 | SW2-SHRQ-{ID} | FS_{CAT}_{AREA}_001, FS_{CAT}_{AREA}_002 |

---

## 9. References

| Document | Description |
|----------|-------------|
| {PREFIX}-SAD-{SEQ} | Software Architecture Document (Functional Specifications) |
| {PREFIX}-SDS-{SEQ} | Software Design Specification (Detailed Design) |
| {PREFIX}-TM-{SEQ} | Traceability Matrix |
| ISO 26262 | Functional Safety Standard |
| ASPICE 3.1 | Automotive SPICE Process Reference Model |

---

**Document End**

**Related Documents**:
- {PREFIX}-SAD-{SEQ}: Software Architecture Document
- {PREFIX}-SDS-{SEQ}: Software Design Specification
- {PREFIX}-TM-{SEQ}: Traceability Matrix
```

## Requirement ID Convention

### Format
```
RS_{CATEGORY}_{SEQUENCE}
```

### Standard Categories

| Category | Prefix | Description |
|----------|--------|-------------|
| Container | RS_CTN | Container isolation, control, update, integrity |
| Container Manager | RS_CM | CM orchestration, update, monitoring, security |
| Container Policy | RS_CP | Policy structure and configuration |
| Container SW Package | RS_CSP | Packaging and deployment standards |
| Network | RS_NET | Network configuration and communication |
| Security | RS_SEC | Security policies and enforcement |
| Storage | RS_STG | Data persistence and isolation |

### Jama Project Mapping

| Local ID Pattern | Jama Project |
|------------------|--------------|
| RS_* | SW2-SHRQ-* |

## Requirement Attribute Definitions

| Attribute | Values | Description |
|-----------|--------|-------------|
| Project ID | SW2-SHRQ-{N} | Jama project identifier |
| Status | Accepted, Draft, Rejected | Approval status |
| Source | Customer, Internal, Unassigned | Requirement origin |
| External ID | RS_{CAT}_{SEQ} | Local tracking ID |
| Priority | High, Medium, Low | Implementation priority |

## Example Requirement

```markdown
#### RS_CM_001: Container Manager S/W Process Management

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SHRQ-973 |
| Status | Accepted |
| Source | Customer |
| External ID | RS_CM_001 |
| Priority | High |

**Description**: Container Manager should manage the S/W Process of Container and satisfy all the specifications that Adaptive AUTOSAR App requires.

**Rationale**: Ensures Container Manager operates as a compliant AUTOSAR Adaptive application.

**Traces To (Functional Specifications)**:
- FS_CM_GEN_001: Full Control of Container Runtime
- FS_CM_GEN_002: Delegation of Control
```

## Requirements Grouping Strategy

1. **Functional Area Grouping**: Group by component/subsystem
2. **Lifecycle Grouping**: Group by development phase
3. **Stakeholder Grouping**: Group by requirement source

### Recommended Structure

```
7. Stakeholder Requirements
├── 7.1 Core Functionality (RS_{CORE})
├── 7.2 Resource Management (RS_{RES})
├── 7.3 Security (RS_{SEC})
├── 7.4 Communication (RS_{COM})
├── 7.5 Update/OTA (RS_{UPD})
└── 7.6 Monitoring (RS_{MON})
```

## Traceability Requirements

Every requirement MUST:
1. Have a unique Local ID (RS_*)
2. Have a Jama Project ID (SW2-SHRQ-*)
3. Trace to at least one Functional Specification (FS_*)
4. Include status, source, and priority

## Quality Checklist

- [ ] All requirements use shall/should/will/may correctly
- [ ] Each requirement has a unique ID
- [ ] Jama IDs are correctly mapped
- [ ] All requirements trace to FS in SAD
- [ ] Requirements summary matches actual count
- [ ] Terminology includes all acronyms used
