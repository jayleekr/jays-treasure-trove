# Sonatus PDF Template Skill

## Overview
Custom Pandoc LaTeX template for generating professional ASPICE-compliant PDF documentation (SRS, SAD, SDS) with Sonatus branding and styling.

## Purpose
Transform Container Manager documentation from plain Pandoc output to professionally branded PDFs matching the Sonatus Container Management Specification v0.2 styling standards.

## Features

### Visual Elements
- **Professional Cover Page**: Large Sonatus logo, document metadata table, draft warning box (optional)
- **Custom Headers**: Light gray background (#E8E8E8) with Sonatus logo and document title
- **Custom Footers**: "Sonatus Confidential. DO NOT DISTRIBUTE." with page numbering
- **Brand Colors**: Sonatus orange (#FF6B35), professional gray tones
- **Typography**: Clean, professional font hierarchy

### ASPICE Compliance
- Maintains SWE.1 (SRS), SWE.2 (SAD), SWE.3 (SDS) process alignment
- Document ID, version, date, ASPICE process metadata on cover
- Table of contents with 3-level depth
- Section numbering and cross-references

### Content Support
- Professional table formatting with booktabs
- Code listings with syntax highlighting
- Long tables across multiple pages
- Hyperlinked table of contents and references
- Math formulas and symbols

## File Structure

```
container-manager/
├── docs/
│   ├── templates/
│   │   └── sonatus-aspice-new.latex   # Custom Pandoc template (updated)
│   ├── assets/
│   │   ├── Sonatus Logo Stacked - Dark Logotype.png  # Cover page logo
│   │   ├── Sonatus Icon - Color.png                  # Header logo
│   │   └── fonts/
│   │       ├── NotoSans/              # Noto Sans font files
│   │       └── NotoSansMono/          # Noto Sans Mono font files
│   ├── build_docs.sh                  # Build script (updated)
│   ├── SRS/
│   │   └── SRS_Container_Manager_v1.0.md  # With YAML front matter
│   ├── SAD/
│   │   └── SAD_Container_Manager_v1.0.md  # With YAML front matter
│   └── SDS/
│       └── SDS_Container_Manager_v1.0.md  # With YAML front matter
└── .claude/skills/sonatus-pdf-template/
    └── skill.md                       # This file
```

## YAML Front Matter Schema

Each markdown document must include YAML front matter at the beginning:

```yaml
---
title: "Software Architecture Document"
subtitle: "Container Manager"
doc-id: "CM-SAD-001"
version: "1.0"
author: "Jay Lee"
aspice-process: "SWE.2"
confidential: true
draft: false  # Set to true to show draft warning box
---
```

### Required Fields
- `title`: Main document title
- `subtitle`: Document subtitle (component name only, no binary names)
- `doc-id`: Document identifier (CM-SRS-001, CM-SAD-001, CM-SDS-001)
- `version`: Document version number
- `aspice-process`: ASPICE process (SWE.1, SWE.2, SWE.3)

### Optional Fields
- `author`: Document author name
- `confidential`: Boolean, enables confidential footer (default: true)
- `draft`: Boolean, shows draft warning box on cover page (default: false)

## Usage

### Build All Documents
```bash
cd /Users/jaylee/CodeWorkspace/container-manager
./docs/build_docs.sh all
```

### Build Individual Documents
```bash
./docs/build_docs.sh srs    # Build SRS only
./docs/build_docs.sh sad    # Build SAD only
./docs/build_docs.sh sds    # Build SDS only
```

### Output Location
Generated PDFs are placed in `docs/output/`:
- `CM-SRS-001_v1.0.pdf`
- `CM-SAD-001_v1.0.pdf`
- `CM-SDS-001_v1.0.pdf`

## Logo Configuration

The template uses Sonatus logos located in `docs/assets/`:

1. **Header Logo**: `Sonatus Icon - Color.png` (small icon for page headers)
   - Height: 0.3in
   - Appears on all pages except cover page

2. **Cover Page Logo**: `Sonatus Logo Stacked - Dark Logotype.png` (full logo for title page)
   - Width: 3in
   - Centered on cover page

**Note**: Logo files are pre-configured in the template. If you need to change logo files:
- Update the file paths in `docs/templates/sonatus-aspice-new.latex`
- Header logo: Line ~152 (in fancyhead configuration)
- Cover logo: Line ~107 (in maketitle configuration)

## Customization

### Colors
Edit color definitions in the template (`docs/templates/sonatus-aspice-new.latex`):
```latex
\definecolor{sonatusOrange}{HTML}{FF6B35}
\definecolor{sonatusGray}{HTML}{E8E8E8}
\definecolor{sonatusDarkGray}{HTML}{666666}
\definecolor{warningRed}{HTML}{CC0000}
```

### Page Margins
Modify geometry settings (lines 31-35):
```latex
\usepackage[top=1in, bottom=1in, left=1in, right=1in, headheight=0.5in, headsep=0.2in]{geometry}
```

### Table Formatting
Professional table packages are pre-configured (lines 37-46):
```latex
\usepackage{booktabs}       % Professional table rules
\usepackage{tabularx}       % Auto-width columns
\usepackage{longtable}      % Multi-page tables
\usepackage{array}          % Column formatting

% Table configuration
\setlength{\tabcolsep}{6pt}         % Column padding
\renewcommand{\arraystretch}{1.3}   % Row height
\setlength{\LTleft}{0pt}            % Left-align tables
\setlength{\LTright}{0pt plus 1fill} % Stretch to page width
```

### Header/Footer Text
Edit footer text in fancyhdr configuration:
```latex
\fancyfoot[C]{%
  \small\textcolor{sonatusDarkGray}{Sonatus Confidential. DO NOT DISTRIBUTE.} \\
  \small Page \thepage
}
```

## Troubleshooting

### Build Errors

**Error: Docker not running**
```bash
# Start Docker Desktop or Docker daemon
# On macOS: open -a Docker
```

**Error: Template not found**
```bash
# Verify template exists
ls -la docs/templates/sonatus-aspice.latex
```

**Error: Missing LaTeX packages**
```bash
# The pandoc/latex:latest Docker image includes all required packages
# If using local LaTeX: install texlive-full or similar complete distribution
```

### Visual Issues

**Logo not appearing**
- Verify logo files exist in `docs/assets/`
- Check that paths in template are correct
- Ensure logo include lines are uncommented

**Header formatting issues**
- Verify YAML front matter is correctly formatted
- Check that title length fits in header width
- Adjust header width in template if needed

**Table of contents missing**
- Verify `--toc` flag is present in build_docs.sh
- Check markdown heading levels (# for top level)

**Font loading issues**
- Noto Sans fonts are downloaded to `docs/assets/fonts/` but not currently loaded
- Docker containerization prevents local font loading via relative paths
- Current workaround: Using default Computer Modern fonts
- Future options:
  1. Create custom Docker image with fonts pre-installed
  2. Use system fonts available in pandoc/latex:latest image
  3. Configure Docker volume mounting for font access

## Maintenance

### Adding New Document Types
1. Create markdown file with YAML front matter
2. Add build function to `build_docs.sh`:
   ```bash
   build_newdoc() {
       build_pdf \
           "docs/NEWDOC/NEWDOC_Container_Manager_v1.0.md" \
           "docs/output/CM-NEWDOC-001_v1.0.pdf" \
           "NEWDOC (Description)"
   }
   ```
3. Add to `build_all()` function
4. Update command usage in script

### Template Updates
- Template location: `docs/templates/sonatus-aspice.latex`
- Test changes with single document first: `./docs/build_docs.sh sad`
- Validate output visually against reference v0.2 PDF
- Document any significant changes in this file

## Reference
- **Original Template**: Container Management Specification v0.2.pdf
- **Pandoc Documentation**: https://pandoc.org/MANUAL.html#templates
- **ASPICE Guidelines**: SWE.1 (Requirements), SWE.2 (Architecture), SWE.3 (Design)

## Version History
- **1.1** (2026-01-07): Template refinements and fixes
  - ✅ Removed binary name "(snt_cm)" from subtitle
  - ✅ Removed date field from YAML front matter and title page
  - ✅ Fixed header gray background overlay (single centered header design)
  - ✅ Fixed duplicate section numbering (removed manual numbers, Pandoc auto-numbering)
  - ✅ Added table formatting packages (booktabs, tabularx, longtable, array)
  - ✅ Configured tables for left-alignment and full page width
  - ⏳ Font configuration deferred (Noto Sans downloaded but Docker loading issue)
  - Template renamed to `sonatus-aspice-new.latex`

- **1.0** (2026-01-07): Initial template implementation with Sonatus branding
  - Custom LaTeX template with cover page, headers, footers
  - YAML front matter support
  - ASPICE-compliant metadata
  - Sonatus logo integration
