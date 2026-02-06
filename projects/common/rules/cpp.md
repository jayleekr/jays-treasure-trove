---
paths:
  - "**/*.cpp"
  - "**/*.cxx"
  - "**/*.cc"
  - "**/*.hpp"
  - "**/*.h"
  - "**/CMakeLists.txt"
---

# C++ Development Rules (CCU2)

## C++ Standard
- **C++17** 사용 (modern features 적극 활용)
- `-std=c++17` 컴파일러 플래그

## AUTOSAR 네이밍 규칙

| 타입 | 패턴 | 예시 |
|------|------|------|
| Class | PascalCase | `ContainerManager` |
| Method | camelCase | `startContainer()` |
| Variable | camelCase | `containerName` |
| Constant | SCREAMING_SNAKE | `MAX_CONTAINERS` |
| Namespace | lowercase | `sonatus::cm` |

## 헤더 가드

```cpp
// 선호: #pragma once
#pragma once

// 또는 전통적 가드
#ifndef CONTAINER_MANAGER_H
#define CONTAINER_MANAGER_H
// ...
#endif
```

## Include 순서

```cpp
// 1. 해당 헤더 (cpp 파일의 경우)
#include "container_manager.hpp"

// 2. 프로젝트 헤더
#include "snt/logging.hpp"
#include "snt/vehicle/interface.hpp"

// 3. 외부 라이브러리
#include <boost/asio.hpp>
#include <vsomeip/vsomeip.hpp>

// 4. 표준 라이브러리
#include <string>
#include <vector>
#include <memory>
```

## 스마트 포인터 사용

```cpp
// ✅ 선호
std::unique_ptr<Container> container = std::make_unique<Container>();
std::shared_ptr<Logger> logger = std::make_shared<Logger>();

// ❌ 지양
Container* container = new Container();  // raw pointer
```

## MISRA-C 2023 준수

Coverity 억제 패턴:
```cpp
// coverity[misra_cpp_2023_rule_X_Y_Z_violation:SUPPRESS] 사유 설명
violating_code();
```

자주 사용하는 억제:
- `rule_0_1_1`: Unused variable (테스트용)
- `rule_11_3_1`: Pointer cast (하드웨어 레지스터)
- `rule_18_4_1`: Dynamic memory (container 필수)

## 에러 처리

```cpp
// ara::core::Result 패턴 (AUTOSAR)
ara::core::Result<ContainerInfo> GetContainerInfo(const std::string& id) {
    if (id.empty()) {
        return ara::core::Result<ContainerInfo>::FromError(
            ErrorCode::kInvalidArgument);
    }
    return ContainerInfo{...};
}
```

## 로깅 (DLT)

```cpp
#include <snt/logging.hpp>

// 로거 선언
SNT_DECLARE_LOGGER(CM, "CM", "Container Manager");

// 사용
SNT_LOG_INFO(CM) << "Container started: " << container_id;
SNT_LOG_ERROR(CM) << "Failed to start: " << error.message();
```

## CMake 패턴

```cmake
add_library(${PROJECT_NAME} SHARED
    src/container_manager.cpp
    src/docker_client.cpp
)

target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_link_libraries(${PROJECT_NAME}
    PUBLIC
        snt::logging
        snt::vehicle
    PRIVATE
        Boost::system
)
```
