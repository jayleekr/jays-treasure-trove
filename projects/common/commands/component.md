---
description: Navigate and analyze CCU-2.0 components with structure overview
---

# Component Analysis Command

Analyze a specific CCU-2.0 component's structure, dependencies, and recent changes.

## Task

Given component name (or current directory if in component), provide:

1. **Component Overview**
   - Purpose and description
   - Key dependencies (from CMakeLists.txt)
   - Build targets

2. **Structure Analysis**
   - Directory layout
   - Source files organization
   - Test structure
   - Configuration files

3. **Recent Activity**
   - Last 10 commits affecting this component
   - Active branches
   - Recent changes summary

4. **Dependencies**
   - Internal dependencies (other ccu-2.0 components)
   - External libraries
   - AUTOSAR interfaces (if applicable)

5. **Test Information**
   - Test files location
   - Test framework used
   - Recent test modifications

## Usage

```
/component [component-name]
/component container-manager
/component vam
/component               # Use current directory
```

## Output Format

Provide structured markdown with:
- 🔍 Component overview
- 📁 Directory structure
- 🔗 Dependencies graph
- 📝 Recent changes (last 10 commits)
- 🧪 Test information
- 💡 Quick actions (build, test commands)
