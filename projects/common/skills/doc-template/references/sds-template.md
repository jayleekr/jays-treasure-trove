# SDS Template (SWE.3 - Software Design Specification)

This template defines the structure for Software Design Specification documents (Detailed Design).

## ASPICE Mapping

- **Process**: SWE.3 Software Detailed Design
- **Purpose**: Define implementation details derived from architectural specifications
- **Input**: SAD (FS_* specifications)
- **Output**: Detailed design (DS_*) with traceability to SAD and implementation

## Complete SDS Template

```markdown
# Software Design Specification

## {Component Name} ({component_id})

**Document ID**: {PREFIX}-SDS-{SEQ}
**Version**: {VERSION}
**Date**: {DATE}
**Author**: {AUTHOR}
**Status**: {STATUS}
**ASPICE Process**: SWE.3

---

## 1. Revision History

| Version | Editor | Date | Note |
|---------|--------|------|------|
| 1.0 | {Author} | {YYYY-MM-DD} | Jama-aligned restructure |
| 0.8 | {Author} | {YYYY-MM-DD} | Feature complete |
| 0.1 | {Author} | {YYYY-MM-DD} | First draft |

---

## 2. Document Description

This document serves as the detailed design specification for {component description} on CCU Gen2. It provides implementation-level details including class designs, state machines, algorithms, data structures, and interfaces that realize the functional specifications defined in the SAD.

---

## 3. Document Purpose

This document defines the software detailed design that implements the {Component Name} functional specifications. These designs serve as the blueprint for implementation and testing.

---

## 4. Document Scope

This specification covers the detailed design of:

- Class structure and relationships
- State machines and transitions
- Algorithms and data processing logic
- Data structures and schemas
- Interface specifications
- Error handling strategies
- Threading model

---

## 5. Terminology

### 5.1 Interpretation

| Term | Definition |
|------|------------|
| Shall | Mandatory requirement |
| Should | Recommended action or suggestion |
| Will | Additional or optional feature |
| May | Allowed action |

### 5.2 Definitions, Acronyms, and Abbreviations

| Term | Definition |
|------|------------|
| {ACRONYM} | {Definition} |

---

## 6. Class Design

### 6.1 Class Overview

```
+-------------------+
|   {ClassName}     |
+-------------------+
| - m_member1       |
| - m_member2       |
+-------------------+
| + method1()       |
| + method2()       |
+-------------------+
        |
        | inherits
        v
+-------------------+
|   {BaseClass}     |
+-------------------+
```

### 6.2 {ClassName} Class

**[DS_{COMP}_CLS_001]** {Class description and responsibility.}

```cpp
/**
 * @file {filename}.h
 * @brief {Brief class description}
 */

#ifndef {HEADER_GUARD}
#define {HEADER_GUARD}

#include <memory>
#include <string>

namespace {namespace} {

/**
 * @class {ClassName}
 * @brief {Detailed class description}
 *
 * @details {Extended description of class responsibilities and usage}
 */
class {ClassName} {
public:
    /**
     * @brief Constructor
     * @param config Configuration parameters
     */
    explicit {ClassName}(const Config& config);

    /**
     * @brief Destructor
     */
    ~{ClassName}();

    /**
     * @brief {Method description}
     * @param param {Parameter description}
     * @return {Return value description}
     * @throws {Exception type} {When thrown}
     */
    ReturnType methodName(ParamType param);

private:
    std::unique_ptr<Impl> m_impl;  ///< Implementation pointer (pimpl)
    MemberType m_member;           ///< {Member description}
};

}  // namespace {namespace}

#endif  // {HEADER_GUARD}
```

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Status | Draft |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 7. State Machines

### 7.1 {StateMachine} State Machine

**[DS_{COMP}_SM_001]** {State machine description and purpose.}

#### 7.1.1 State Diagram

```
                    ┌─────────────┐
                    │    INIT     │
                    └──────┬──────┘
                           │ initialize()
                           v
    ┌─────────────┐  start()  ┌─────────────┐
    │   STOPPED   │<─────────>│   RUNNING   │
    └─────────────┘  stop()   └──────┬──────┘
           ^                         │ error()
           │ reset()                 v
           │                  ┌─────────────┐
           └──────────────────│    ERROR    │
                              └─────────────┘
```

#### 7.1.2 State Transition Table

| Current State | Event | Next State | Action | Guard |
|---------------|-------|------------|--------|-------|
| INIT | initialize() | STOPPED | setupResources() | - |
| STOPPED | start() | RUNNING | beginOperation() | isReady() |
| RUNNING | stop() | STOPPED | cleanup() | - |
| RUNNING | error() | ERROR | logError() | - |
| ERROR | reset() | STOPPED | resetState() | - |

#### 7.1.3 State Descriptions

| State | Description | Entry Action | Exit Action |
|-------|-------------|--------------|-------------|
| INIT | Initial state after construction | None | None |
| STOPPED | Ready but not processing | Release resources | None |
| RUNNING | Actively processing | Acquire resources | Release resources |
| ERROR | Error condition detected | Log error | None |

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 8. Algorithms

### 8.1 {Algorithm Name}

**[DS_{COMP}_ALG_001]** {Algorithm description and purpose.}

#### 8.1.1 Algorithm Description

{Detailed description of what the algorithm does and why.}

#### 8.1.2 Pseudo-code

```
ALGORITHM {AlgorithmName}
INPUT: {input parameters}
OUTPUT: {output parameters}

BEGIN
    1. {Step 1 description}
    2. {Step 2 description}
    3. FOR each item IN collection DO
        3.1 {Sub-step description}
        3.2 IF condition THEN
            3.2.1 {Action}
        END IF
    END FOR
    4. RETURN result
END
```

#### 8.1.3 Complexity Analysis

| Aspect | Complexity | Notes |
|--------|------------|-------|
| Time | O({complexity}) | {Explanation} |
| Space | O({complexity}) | {Explanation} |

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 9. Data Structures

### 9.1 C++ Structures

**[DS_{COMP}_DS_001]** {Data structure description.}

```cpp
/**
 * @struct {StructName}
 * @brief {Structure description}
 */
struct {StructName} {
    std::string name;           ///< {Field description}
    uint32_t id;                ///< {Field description}
    std::vector<Item> items;    ///< {Field description}

    /**
     * @brief Validate structure contents
     * @return true if valid, false otherwise
     */
    bool isValid() const;
};
```

### 9.2 JSON Schemas

**[DS_{COMP}_DS_002]** {JSON schema description.}

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "{Schema Title}",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "{Field description}"
    },
    "settings": {
      "type": "object",
      "properties": {
        "key": {
          "type": "string"
        }
      },
      "required": ["key"]
    }
  },
  "required": ["name", "settings"]
}
```

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001, FS_CP_001 |

---

## 10. Interface Design

### 10.1 External API

**[DS_{COMP}_IF_001]** {Interface description.}

| Function | Parameters | Return | Description |
|----------|------------|--------|-------------|
| `create()` | `Config config` | `std::unique_ptr<T>` | Create instance |
| `start()` | `void` | `Result` | Start operation |
| `stop()` | `void` | `Result` | Stop operation |
| `getStatus()` | `void` | `Status` | Get current status |

### 10.2 AUTOSAR Interfaces

**[DS_{COMP}_IF_002]** AUTOSAR service interface specifications.

| Interface | Type | Port | Description |
|-----------|------|------|-------------|
| {ServiceInterface} | Provided | {PortName} | {Description} |
| {ClientInterface} | Required | {PortName} | {Description} |

### 10.3 Internal Component Interfaces

**[DS_{COMP}_IF_003]** Internal interface specifications.

```cpp
/**
 * @interface I{InterfaceName}
 * @brief {Interface description}
 */
class I{InterfaceName} {
public:
    virtual ~I{InterfaceName}() = default;

    /**
     * @brief {Method description}
     */
    virtual ReturnType method() = 0;
};
```

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 11. Error Handling

### 11.1 Error Codes

**[DS_{COMP}_ERR_001]** Error code definitions.

| Code | Name | Description | Recovery |
|------|------|-------------|----------|
| 0x0000 | SUCCESS | Operation successful | N/A |
| 0x0001 | E_INIT_FAILED | Initialization failed | Retry or restart |
| 0x0002 | E_INVALID_PARAM | Invalid parameter | Check inputs |
| 0x0003 | E_TIMEOUT | Operation timed out | Retry |
| 0x0004 | E_RESOURCE | Resource unavailable | Wait and retry |

### 11.2 Exception Hierarchy

```cpp
class {Component}Exception : public std::runtime_error {
public:
    explicit {Component}Exception(const std::string& msg, ErrorCode code);
    ErrorCode getCode() const;
};

class InitializationException : public {Component}Exception { };
class ConfigurationException : public {Component}Exception { };
class RuntimeException : public {Component}Exception { };
```

### 11.3 Error Handling Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| Return Code | Performance-critical paths | `Result doOperation()` |
| Exception | Exceptional conditions | `throw ConfigException()` |
| Optional | May-fail operations | `std::optional<T> tryGet()` |
| Expected | Error with value | `expected<T, Error> parse()` |

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 12. Threading Model

### 12.1 Thread Architecture

**[DS_{COMP}_THR_001]** Threading model description.

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Thread                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Init/Setup  │  │   Control   │  │  Shutdown   │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
          │                │                │
          v                v                v
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Worker Thread  │ │  Worker Thread  │ │  Worker Thread  │
│     Pool        │ │     Pool        │ │     Pool        │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### 12.2 Synchronization

| Resource | Protection | Lock Type | Scope |
|----------|------------|-----------|-------|
| {Resource1} | Mutex | std::mutex | Class |
| {Resource2} | RW Lock | std::shared_mutex | Module |
| {Resource3} | Atomic | std::atomic | Variable |

### 12.3 Thread Safety Guarantees

| Class/Function | Thread Safety | Notes |
|----------------|---------------|-------|
| {ClassName} | Thread-safe | All public methods |
| {Function} | Not thread-safe | Caller must synchronize |
| {Singleton} | Thread-safe init | Double-checked locking |

| Attribute | Value |
|-----------|-------|
| Project ID | SW2-SWDD-{ID} |
| Traces From | FS_{COMP}_{AREA}_001 |

---

## 13. Traceability

### 13.1 Design to Specification Mapping

| DS ID | FS ID (SAD) | RS ID (SRS) | Test ID |
|-------|-------------|-------------|---------|
| DS_{COMP}_CLS_001 | FS_{COMP}_{AREA}_001 | RS_{CAT}_001 | TC_{COMP}_001 |
| DS_{COMP}_SM_001 | FS_{COMP}_{AREA}_002 | RS_{CAT}_002 | TC_{COMP}_002 |

---

## 14. References

| Document | Description |
|----------|-------------|
| {PREFIX}-SRS-{SEQ} | Software Requirements Specification |
| {PREFIX}-SAD-{SEQ} | Software Architecture Document |
| {PREFIX}-TM-{SEQ} | Traceability Matrix |
| ASPICE 3.1 | Automotive SPICE SWE.3 |
| C++ Core Guidelines | Coding standards reference |

---

## 15. Design Specifications Summary

| ID | Title | Type | FS Trace |
|----|-------|------|----------|
| DS_{COMP}_CLS_001 | {Class Title} | Class | FS_{COMP}_001 |
| DS_{COMP}_SM_001 | {State Machine Title} | State Machine | FS_{COMP}_002 |
| DS_{COMP}_ALG_001 | {Algorithm Title} | Algorithm | FS_{COMP}_003 |
| DS_{COMP}_DS_001 | {Data Structure Title} | Data Structure | FS_{COMP}_004 |
| DS_{COMP}_IF_001 | {Interface Title} | Interface | FS_{COMP}_005 |
| DS_{COMP}_ERR_001 | {Error Handling Title} | Error | FS_{COMP}_006 |
| DS_{COMP}_THR_001 | {Threading Title} | Threading | FS_{COMP}_007 |

---

**Document End**

**Related Documents**:
- {PREFIX}-SRS-{SEQ}: Software Requirements Specification
- {PREFIX}-SAD-{SEQ}: Software Architecture Document
- {PREFIX}-TM-{SEQ}: Traceability Matrix
```

## Design Specification ID Convention

### Format
```
DS_{COMPONENT}_{TYPE}_{SEQUENCE}
```

### Type Codes

| Type | Code | Description |
|------|------|-------------|
| Class | CLS | Class design |
| State Machine | SM | State machine design |
| Algorithm | ALG | Algorithm design |
| Data Structure | DS | Data structure design |
| Interface | IF | Interface design |
| Error | ERR | Error handling |
| Threading | THR | Threading model |

### Jama Project Mapping

| Local ID Pattern | Jama Project |
|------------------|--------------|
| DS_* | SW2-SWDD-* |

## Quality Checklist

- [ ] All classes have proper documentation
- [ ] State machines have complete transition tables
- [ ] Algorithms include complexity analysis
- [ ] Data structures match JSON schemas
- [ ] Interfaces are fully specified
- [ ] Error handling is comprehensive
- [ ] Threading model is documented
- [ ] All designs trace to FS specifications
