# SAD Template (SWE.2 - Software Architecture Document)

This template defines the structure for Software Architecture Documents (Functional Specifications).

## ASPICE Mapping

- **Process**: SWE.2 Software Architectural Design
- **Purpose**: Define functional specifications derived from stakeholder requirements
- **Input**: SRS (RS_* requirements)
- **Output**: Functional specifications (FS_*) with traceability to SRS and SDS

## Complete SAD Template

```markdown
# Software Architecture Document

## {Component Name} ({component_id})

**Document ID**: {PREFIX}-SAD-{SEQ}
**Version**: {VERSION}
**Date**: {DATE}
**Author**: {AUTHOR}
**Status**: {STATUS}
**ASPICE Process**: SWE.2

---

## 1. Revision History (4.2.1.1)

| Version | Editor | Date | Note |
|---------|--------|------|------|
| 1.0 | {Author} | {YYYY-MM-DD} | Jama-aligned restructure |
| 0.8 | {Author} | {YYYY-MM-DD} | Feature complete |
| 0.1 | {Author} | {YYYY-MM-DD} | First draft |

---

## 2. Document Description (4.2.1.2)

This document serves as the functional specification for {component description} on CCU Gen2. It defines the functional specifications (FS_*) that trace from stakeholder requirements (RS_*) and guide the detailed design (SDS).

---

## 3. Document Purpose (4.2.1.3)

This document defines the software architecture and functional specifications that the {Component Name} component shall implement. These specifications serve as the bridge between stakeholder requirements and detailed design.

---

## 4. Document Scope (4.2.1.4)

This specification applies to {scope description}.

---

## 5. Terminology (4.2.1.5)

### 5.1 Interpretation (4.2.1.5.1)

| Term | Definition |
|------|------------|
| Shall | Mandatory requirement |
| Should | Recommended action or suggestion (offered as advice) |
| Will | Additional or optional feature, or a declaration of intent |
| May | Allowed action, not to be considered as a requirement |

### 5.2 Definitions, Acronyms, and Abbreviations (4.2.1.5.2)

| Term | Definition |
|------|------------|
| {ACRONYM} | {Definition} |

---

## 6. General Description (4.2.1.6)

{High-level description of the component/system, its purpose, and architectural context.}

---

## 7. Requirements Specification (4.2.1.7)

This section contains the functional specifications, organized by requirement category.

### 7.1 {Feature Area} (4.2.1.7.1)

**[FS_{CAT}_{AREA}_001]** {Functional specification description using shall/should language.}

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWARCH-{JAMA_ID} |
| Heading | 4.2.1.7.1 |
| Status | Draft |
| Verification | Test |
| Traces From | RS_{CAT}_001 |

---

### 7.2 {Next Feature Area} (4.2.1.7.2)

{Continue pattern for each functional area...}

---

## 8. System Architecture (4.2.1.8)

{Description of the overall system architecture.}

```
+------------------------------------------------------------------+
|                        System Architecture                         |
+------------------------------------------------------------------+
|                                                                    |
|  +------------------+    +------------------+    +----------------+ |
|  | Component A      |    | Component B      |    | Component C    | |
|  +------------------+    +------------------+    +----------------+ |
|           |                      |                       |         |
|           v                      v                       v         |
|  +------------------+    +------------------+    +----------------+ |
|  | Layer 1          |    | Layer 2          |    | Layer 3        | |
|  +------------------+    +------------------+    +----------------+ |
|                                                                    |
+------------------------------------------------------------------+
```

---

## 9. Specification of {Component} (4.2.1.9)

{Detailed component specifications organized by submodule/function.}

### 9.1 {Submodule 1} (4.2.1.9.1)

**[FS_{COMP}_{SUB}_001]** {Specification description.}

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWARCH-{ID} |
| Heading | 4.2.1.9.1 |
| Status | Draft |
| Verification | Test |
| Traces From | RS_{CAT}_001 |

---

### 9.2 {Submodule 2} (4.2.1.9.2)

{Continue pattern...}

---

## 10. {Configuration/Policy} (4.2.1.10)

**[FS_{CONF}_001]** {Configuration specification.}

**Sample Configuration:**
```json
{
  "metadata": {
    "name": "{Config name}",
    "version": "1.0"
  },
  "settings": {
    "key": "value"
  }
}
```

**Configuration Attributes:**

| Attribute | Description | Related FS |
|-----------|-------------|------------|
| {attr} | {Description} | FS_{CAT}_001 |

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWARCH-{ID} |
| Heading | 4.2.1.10 |
| Status | Draft |
| Verification | Test |
| Traces From | RS_{CAT}_001 |

---

## 11. {Additional Component} (4.2.1.11)

{Continue pattern for additional architectural components...}

---

## 12. References (4.2.1.12)

| Document | Description |
|----------|-------------|
| {PREFIX}-SRS-{SEQ} | Software Requirements Specification (Stakeholder Requirements) |
| {PREFIX}-SDS-{SEQ} | Software Design Specification (Detailed Design) |
| {PREFIX}-TM-{SEQ} | Traceability Matrix |
| ISO/IEC/IEEE 42010:2011 | Architecture description standard |
| ASPICE 3.1 | Automotive SPICE SWE.2 |

---

## 13. Appendix (4.2.1.13)

### A.1 {Appendix Topic}

{Additional reference material, diagrams, or supporting information.}

---

## 14. Functional Specifications Summary

### 14.1 {Category} Specifications (FS_{CAT}_*)

| ID | Title | RS Trace |
|----|-------|----------|
| FS_{CAT}_{AREA}_001 | {Title} | RS_{CAT}_001 |
| FS_{CAT}_{AREA}_002 | {Title} | RS_{CAT}_001 |

### 14.2 {Next Category} Specifications (FS_{CAT2}_*)

| ID | Title | RS Trace |
|----|-------|----------|
| FS_{CAT2}_{AREA}_001 | {Title} | RS_{CAT2}_001 |

---

**Document End**

**Related Documents**:
- {PREFIX}-SRS-{SEQ}: Software Requirements Specification
- {PREFIX}-SDS-{SEQ}: Software Design Specification
- {PREFIX}-TM-{SEQ}: Traceability Matrix
```

## Functional Specification ID Convention

### Format
```
FS_{CATEGORY}_{AREA}_{SEQUENCE}
```

### Standard Categories and Areas

| Category | Area Examples | Full ID Example |
|----------|---------------|-----------------|
| CTN (Container) | GEN, ISO, CTL, CTR, NET, UPD, ITG | FS_CTN_GEN_001 |
| CM (Container Manager) | GEN, Orch, EXE, CTL, ISO, UPD, NET, MON | FS_CM_GEN_001 |
| CP (Container Policy) | - | FS_CP_001 |
| CSP (Container SW Package) | - | FS_CSP_001 |

### Area Definitions

| Area | Description |
|------|-------------|
| GEN | General/Core functionality |
| ISO | Isolation |
| CTL | Control/Resource management |
| CTR | Container runtime specific |
| NET | Networking |
| UPD | Update/OTA |
| ITG | Integrity |
| EXE | Execution management |
| Orch | Orchestration |
| MON | Monitoring |

### Jama Project Mapping

| Local ID Pattern | Jama Project |
|------------------|--------------|
| FS_* | SW2-SWARCH-* |

## Functional Specification Attribute Definitions

| Attribute | Values | Description |
|-----------|--------|-------------|
| Project ID | SW2-SWARCH-{N} | Jama project identifier |
| Heading | 4.2.1.X.X | Jama document heading reference |
| Status | Draft, Accepted | Approval status |
| Verification | Test, Analysis, Inspection, Demo | Verification method |
| Traces From | RS_{CAT}_{SEQ} | Source requirement(s) |

## Example Functional Specification

```markdown
### 9.1 Full Control of Container Runtime (4.2.1.9.1)

**[FS_CM_GEN_001]** The Container Runtime shall be fully managed by Container Manager, an Adaptive application running on the host Adaptive AutoSAR.

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWARCH-1486 |
| Heading | 4.2.1.9.1 |
| Status | Draft |
| Verification | Test |
| Traces From | RS_CM_001 |

---

### 9.2 Delegation of Control (4.2.1.9.2)

**[FS_CM_GEN_002]** Container Manager shall possess no knowledge about what runs inside the container, hence it shall not directly control the execution of the 3rd-party applications, middlewares and container Adaptive AutoSAR running inside the container. It can, however, terminate the container runtime hosting all the container processes and hence also stop all third-party applications in consequence.

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWARCH-1487 |
| Heading | 4.2.1.9.2 |
| Status | Draft |
| Verification | Test |
| Traces From | RS_CM_001 |
```

## Architecture Diagram Standards

### System Block Diagram
```
+------------------------------------------------------------------+
|                        Vehicle System                             |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------+            |
|  |              Container Manager (snt_cm)          |            |
|  |                                                  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Container  |  | Container  |  | Container  |  |            |
|  |  | App A      |  | App B      |  | App C      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|           |              |                  |                     |
|           v              v                  v                     |
|  +------------------+  +------------------+  +------------------+ |
|  | Docker Engine    |  | AUTOSAR Services |  | Linux Kernel     | |
|  +------------------+  +------------------+  +------------------+ |
|                                                                  |
+------------------------------------------------------------------+
```

### Component Interaction Diagram
```
+----------------+      +----------------+      +----------------+
|   Component A  |----->|   Component B  |----->|   Component C  |
+----------------+      +----------------+      +----------------+
        |                       |                       |
        v                       v                       v
+----------------+      +----------------+      +----------------+
| External I/F A |      | External I/F B |      | External I/F C |
+----------------+      +----------------+      +----------------+
```

## Traceability Requirements

Every functional specification MUST:
1. Have a unique Local ID (FS_*)
2. Have a Jama Project ID (SW2-SWARCH-*)
3. Reference source requirements (RS_*)
4. Include verification method
5. Be listed in the summary table

## Quality Checklist

- [ ] All specifications use shall/should/will/may correctly
- [ ] Each specification has a unique ID
- [ ] Jama IDs and headings are correctly mapped
- [ ] All specifications trace back to RS in SRS
- [ ] Architecture diagrams are included
- [ ] Summary tables match actual specifications
- [ ] Configuration/policy sections include examples
