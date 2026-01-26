# Common Template Structure

This document defines the common template elements shared across all document types (SRS, SAD, SDS), based on the Sonatus v0.2 PDF template standard.

---

## Cover Page (PDF Required)

```markdown
<!--
================================================================================
                              COVER PAGE (FOR PDF)
================================================================================
-->

                              [SONATUS LOGO]

                    Sonatus {Document Title}
                              v{VERSION}

                           {MM/DD/YYYY}

================================================================================
Please note: this document is an early draft and a work in progress. There will
be many additions, changes, and improvements as CCU2 projects continue.
================================================================================

This document or this list of mass production software is provided to you for
your information only and lists software which is owned exclusively by Sonatus, Inc.

                    Sonatus Confidential. DO NOT DISTRIBUTE.
```

---

## Page Header (PDF Required)

Each page should have a gray header bar containing:
- Left: SONATUS logo
- Right: Document title and version

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  SONATUS                     Sonatus {Document Title} v{VERSION}             │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Page Footer (PDF Required)

```
                    Sonatus Confidential. DO NOT DISTRIBUTE.           {PAGE_NUM}
```

---

## Table of Contents

```markdown
# Contents

| Section | Page |
|---------|------|
| Purpose | 4 |
| Document Description | 4 |
| Document Purpose | 4 |
| Document Scope | 4 |
| Terminology | 4 |
| Interpretation | 4 |
| Definitions, Acronyms, and Abbreviations | 4 |
| General Description | 5 |
| System Architecture | 6 |
| {Component Name} | 7 |
| {Sub-section 1} | 8 |
| {Sub-section 2} | 8 |
| ... | ... |
| References | {N} |
```

---

## Document Structure (Markdown)

### Title and Metadata

```markdown
# Sonatus {Document Title} v{VERSION}

---
```

**Note**: Unlike ASPICE-focused documents, the v0.2 style does NOT include:
- Document ID field
- ASPICE Process field
- Author field in header

These are tracked in Jama and revision history instead.

---

## Revision History Section

```markdown
# Revision History

**Table 1. Revision History**

| Version | Editor | Date | Note |
|---------|--------|------|------|
| 0.1 | {Author Name} | {M/DD/YY} | First draft |
| | | | |
| | | | |

---
```

**Key Points**:
- Use "Table N." prefix for numbered tables
- Leave empty rows for future entries
- Date format: M/DD/YY (not YYYY-MM-DD)

---

## Purpose Section

```markdown
# Purpose

{Purpose description or "TBD" for early drafts}

---
```

---

## Document Description Section

```markdown
# Document Description

## Document Purpose

{Document purpose description}

## Document Scope

{Scope description}

---
```

---

## Terminology Section

```markdown
# Terminology

This document uses the following terms, definitions, and acronyms unless otherwise stated.

## Interpretation

**Table 2. Interpretation Terms**

| Term | Definition |
|------|------------|
| Shall | Mandatory requirement |
| Should | Recommended action or suggestion (offered as advice) |
| Will | Additional or optional feature, or a declaration of intent |
| May | Allowed action, not to be considered as a requirement |

## Definitions, Acronyms, and Abbreviations

**Table 3. Acronym Definitions**

| Term | Definition |
|------|------------|
| CAN | Controller Area Network |
| CM | Container Manager |
| DB | Database |
| ECU | Electric Control Unit |
| ENMA | Ethernet Network Management Agent |
| EMT | External Monitoring Tool |
| ESU | Ethernet Switching Unit |
| HKMC | Hyundai Kia Motor Company |
| HU | Head Unit |
| ICU | Integrated Control Unit |
| IVN | In-vehicle Network |
| MCU | Microcontroller Unit |
| NM | Network Management |
| OBD | On-Board Diagnostics |
| OEM | Original Equipment Manufacturer |
| OTA | Over-the-Air update |
| AUTOSAR | AUTomotive Open System ARchitecture |
| SOME/IP | Scalable service-Oriented MiddlewarE over IP |
| CRI | Container Runtime Interface |

---
```

---

## General Description Section

```markdown
# General Description

{High-level overview of the component/system. Write in prose style, describing:
- What the component is
- Why it exists
- Key concepts and terminology
- Relationship to other systems}

---
```

---

## System Architecture Section

```markdown
# System Architecture

{Architecture description with embedded diagrams}

[ARCHITECTURE DIAGRAM - Insert image or ASCII art]

{Detailed explanation of the architecture, components, and their interactions}

---
```

---

## Technical Content Sections

Use prose-style descriptions with embedded specifications:

```markdown
# {Component/Feature Name}

{Overview description}

## {Sub-component 1}

{Description of sub-component functionality}

## {Sub-component 2}

{Description}

---
```

---

## API Documentation Format (v0.2 Style)

```markdown
# {API Category} API

This section documents the {description} APIs.

**Table N. {API Name} Function**

| Function | {FunctionName} |
|----------|----------------|
| Parameters | {Parameter description with types} |
| Return Value | {Return type and description} |
| Description | {What the function does} |

**Table N+1. {Next API Name} Function**

| Function | {FunctionName} |
|----------|----------------|
| Parameters | {Parameter description} |
| Return Value | {Return value description} |
| Description | {Description} |
```

### API Table Example

```markdown
**Table 4. CreateContainer Function**

| Function | CreateContainer |
|----------|-----------------|
| Parameters | Container configs including image name, command, working directory, environment variables, assigned resources, security context, etc. |
| Return Value | Container ID |
| Description | Create the container |

**Table 5. StartContainer Function**

| Function | StartContainer |
|----------|----------------|
| Parameters | Container ID |
| Return Value | None |
| Description | Start the container execution based on the assigned configs |
```

---

## Policy/Configuration Sections

```markdown
# {Policy Name} Policy

{Policy description and purpose}

**Table N. {Policy Name} Attributes**

| Attribute | Description |
|-----------|-------------|
| {attr1} | {Description of attribute 1} |
| {attr2} | {Description of attribute 2} |
| {attr3} | {Description of attribute 3} |

---
```

### Policy Table Example

```markdown
# Execution Policy

**Table 8. Execution Policy Attributes**

| Attribute | Description |
|-----------|-------------|
| runtime | Docker, balena, systemd-nspawn, lxc |
| launchAtStart | Whether the container shall be launched when AP boots up. Default to Yes. |
| cpus | How many CPU cores can be used |
| memory | How much memory can be used |
| oomKillDisable | Favor to kill host process in case of OOM |
```

---

## References Section

```markdown
# References

{List of reference documents - can be empty for early drafts}

---
```

---

## Numbered Table Convention

All tables MUST be numbered sequentially:

| Table Number | Typical Content |
|--------------|-----------------|
| Table 1 | Revision History |
| Table 2 | Interpretation Terms |
| Table 3 | Acronym Definitions |
| Table 4+ | Content-specific tables |

Format: `**Table N. {Table Title}**`

---

## Diagram Standards

### Architecture Diagrams (Embedded Images Preferred)

For Markdown, use ASCII art or reference images:

```
+------------------------------------------------------------------+
|                        Container Manager                          |
+------------------------------------------------------------------+
|                        Policy Manager                             |
|  +------------+  +------------+  +------------+  +-------------+  |
|  | Execution  |  | Security   |  | Update     |  | Image       |  |
|  | Manager    |  | Manager    |  | Manager    |  | Repo        |  |
|  +------------+  +------------+  +------------+  +-------------+  |
|  +------------+  +------------+  +------------+  +-------------+  |
|  | Network    |  | Storage    |  | Stats      |  | Policy      |  |
|  | Manager    |  | Manager    |  | Collector  |  | Repo        |  |
|  +------------+  +------------+  +------------+  +-------------+  |
|                   Container Runtime Interface                      |
+------------------------------------------------------------------+
        |                    |                    |
        v                    v                    v
+----------------+  +----------------+  +----------------+
| Container A    |  | Container B    |  | Container C    |
| run by Docker  |  | run by         |  | run by Balena  |
|                |  | Containerd     |  |                |
+----------------+  +----------------+  +----------------+
```

### Sequence Diagrams

```
+----------------+    +----------------+    +----------------+
|   Component A  |    |   Component B  |    |   Component C  |
+-------+--------+    +-------+--------+    +-------+--------+
        |                     |                     |
        | request             |                     |
        |-------------------->|                     |
        |                     | forward             |
        |                     |-------------------->|
        |                     |                     |
        |                     |     response        |
        |                     |<--------------------|
        |      response       |                     |
        |<--------------------|                     |
        |                     |                     |
```

---

## Writing Style Guidelines

### v0.2 Style Characteristics

1. **Prose-based**: Write flowing descriptions, not bullet-point requirements
2. **Technical but readable**: Explain concepts clearly
3. **Embedded specifications**: Weave requirements into prose using shall/should
4. **Diagram-rich**: Include architecture and sequence diagrams
5. **Table-heavy**: Use numbered tables for structured data

### Example Prose Style

**Good (v0.2 style)**:
```markdown
Container Manager comprises three main functions: orchestrating the container
execution of all containers, updating and storing the container artifacts
including images and policies, and monitoring the container execution statistics.

The container runtime shall be fully managed by Container Manager, an Adaptive
application running on the host Adaptive AutoSAR. Yet Container Manager shall
possess no knowledge about what runs inside the container, hence it shall not
directly control the execution of the 3rd-party applications.
```

**Avoid (ID-focused style)**:
```markdown
#### RS_CM_001: Container Manager Process Management

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SHRQ-973 |
...
```

---

## Jama ID Integration (Internal Reference)

While v0.2 style is prose-based, maintain internal ID tracking:

```markdown
<!-- Jama Trace: SW2-SHRQ-973 -->
Container Manager should manage the S/W Process of Container and satisfy
all the specifications that Adaptive AUTOSAR App requires.
```

Or use footnotes:
```markdown
Container Manager should manage the S/W Process of Container[^1].

[^1]: Jama ID: SW2-SHRQ-973
```

---

## Version Comparison

| Element | v0.2 Style | ASPICE Style |
|---------|------------|--------------|
| Header | Title + Version only | Document ID, Author, ASPICE Process |
| Tables | Numbered (Table 1, 2...) | Unnumbered |
| Content | Prose-based | ID-based requirements |
| Date Format | M/DD/YY | YYYY-MM-DD |
| Requirements | Embedded in prose | Separate RS_* entries |
| Traceability | Hidden/Jama-managed | Explicit in document |

---

## Template Selection Guide

| Use Case | Recommended Style |
|----------|-------------------|
| External customer delivery | v0.2 (prose) |
| Internal ASPICE audit | ASPICE (ID-based) |
| Jama synchronization | ASPICE (ID-based) |
| Early concept documents | v0.2 (prose) |
| Formal specification | Both (hybrid) |

---

## Confidentiality Notice

**Required on every page footer for PDF**:
```
Sonatus Confidential. DO NOT DISTRIBUTE.
```
