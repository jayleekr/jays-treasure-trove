# Document Template Skill

Generate consistent SAD, SDS, SRS documents following Sonatus template standards with Jama ID integration.

## Activation Triggers

- Keywords: "document", "SRS", "SAD", "SDS", "specification", "requirements", "architecture", "design"
- Commands: `/doc-template`
- Document generation or reformatting requests

## Template Styles

This skill supports **two document styles**:

| Style | Use Case | Characteristics |
|-------|----------|-----------------|
| **v0.2 (Prose)** | External delivery, early drafts | Prose-based, numbered tables, embedded specs |
| **ASPICE (ID-based)** | Internal audit, Jama sync | RS_*/FS_* IDs, explicit traceability |

### Style Comparison

| Element | v0.2 Style | ASPICE Style |
|---------|------------|--------------|
| Header | Title + Version only | Document ID, Author, ASPICE Process |
| Tables | Numbered (Table 1, 2...) | Unnumbered |
| Content | Prose-based | ID-based requirements |
| Date Format | M/DD/YY | YYYY-MM-DD |
| Requirements | Embedded in prose | Separate RS_* entries |
| Traceability | Hidden/Jama-managed | Explicit in document |

## Capabilities

### Document Types

| Type | ASPICE | Description | ID Prefix |
|------|--------|-------------|-----------|
| **SRS** | SWE.1 | Software Requirements Specification | RS_{PREFIX}_{SEQ} |
| **SAD** | SWE.2 | Software Architecture Document | FS_{PREFIX}_{SEQ} |
| **SDS** | SWE.3 | Software Design Specification | DS_{PREFIX}_{SEQ} |
| **TM** | - | Traceability Matrix | - |

### ID System (Dual Mapping)

**Local IDs** (for internal reference):
```
RS_CM_001  → Stakeholder Requirement
FS_CM_001  → Functional Specification
DS_CM_001  → Design Specification
TC_CM_001  → Test Case
```

**Jama Project IDs** (for external traceability):
```
SW2-SHRQ-*   → Stakeholder Requirements (SRS)
SW2-SWARCH-* → Software Architecture (SAD)
SW2-SWDD-*   → Software Detailed Design (SDS)
SW2-VERTC-*  → Verification Test Cases
```

**Mapping Format**:
```markdown
#### RS_CM_001: Requirement Title

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SHRQ-968 |
| Status | Accepted |
| Source | Customer |
| External ID | RS_CM_001 |
| Priority | High |

**Description**: ...
**Rationale**: ...
**Traces To**: FS_CM_001, FS_CM_002
```

## Usage

### Generate New Document
```bash
/doc-template --type srs --component "Feature Name" --prefix FN
/doc-template --type sad --component "Container Manager" --prefix CM
/doc-template --type sds --component "Security Module" --prefix SM
```

### Apply Template to Existing Document
```bash
/doc-template --apply existing_doc.md --type srs
```

### Generate Full Document Set
```bash
/doc-template --type all --component "Component Name" --prefix CN
```

## Template Structure

### Common Sections (All Documents)

1. **Document Header**
   - Document ID: `{PREFIX}-{TYPE}-{SEQ}` (e.g., CM-SRS-001)
   - Version, Date, Author, Status
   - ASPICE Process mapping

2. **Revision History**
   | Version | Editor | Date | Note |
   |---------|--------|------|------|

3. **Document Description/Purpose/Scope**

4. **Terminology**
   - Interpretation table (Shall/Should/Will/May)
   - Definitions, Acronyms, Abbreviations table

5. **General Description**

6. **[Document-Specific Content]**

7. **Summary/Traceability**

8. **References**

### SRS-Specific (SWE.1)
- Stakeholder Requirements organized by category
- Each requirement: ID, Jama Project ID, Status, Description, Rationale, Traces To
- Requirements Summary table

### SAD-Specific (SWE.2)
- System Architecture diagram
- Functional Specifications with FS_* IDs
- Component descriptions
- Traceability to SRS (RS → FS mapping)

### SDS-Specific (SWE.3)
- Class Design with code blocks
- State Machines (diagrams + transition tables)
- Algorithms (pseudo-code)
- Data Structures (C++ structs, JSON schemas)
- Interface Design (API tables)
- Error Handling
- Threading Model
- Traceability to SAD (FS → Implementation)

## Document ID Convention

```
{PREFIX}-{TYPE}-{SEQ}_v{MAJOR}.{MINOR}

Examples:
- CM-SRS-001_v1.0  (Container Manager SRS)
- VAM-SAD-001_v0.5 (Vehicle App Manager SAD)
- DPM-SDS-002_v1.1 (Data Path Manager SDS)
```

## Traceability Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    SRS      │ ──→ │    SAD      │ ──→ │    SDS      │ ──→ │   Tests     │
│  (SWE.1)    │     │  (SWE.2)    │     │  (SWE.3)    │     │ (Verify)    │
├─────────────┤     ├─────────────┤     ├─────────────┤     ├─────────────┤
│ RS_CM_001   │ ──→ │ FS_CM_001   │ ──→ │ DS_CM_001   │ ──→ │ TC_CM_001   │
│ (SW2-SHRQ-*)│     │(SW2-SWARCH*)│     │ (SW2-SWDD-*)│     │(SW2-VERTC-*)│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

## Output Format

- **Primary**: Markdown (.md) - Git-friendly, reviewable
- **Secondary**: PDF-ready format with Sonatus styling cues

### Sonatus Template Elements
- Header: "Sonatus {Document Title} v{Version}"
- Footer: "Sonatus Confidential. DO NOT DISTRIBUTE."
- Consistent table formatting
- Section numbering for PDF generation

## References

- Template files in `references/` directory
- Existing documents in `container-manager/docs/`
- Jama project: SW2-* ID space

## Related Skills

- `jira-commit` - Commit with JIRA integration
- `jira-pr` - PR creation with JIRA
- `isir` - MISRA/CERT-CPP compliance
