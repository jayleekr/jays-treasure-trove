# Requirements Analysis - 요구사항 추출 워크플로우

## Extraction Patterns

### From Description Field

#### Acceptance Criteria 패턴
```
Given: <context/precondition>
When: <action/trigger>
Then: <expected result>
And: <additional condition>
```

예시:
```
Given: Container Manager is running
When: A new container deployment request is received
Then: The container should start within 30 seconds
And: Health check should pass
```

#### Bullet List 패턴
```
Requirements:
- Feature A must support X
- Feature B must integrate with Y
- Performance: < 100ms response time
- Security: TLS 1.3 required
```

#### Technical Specification 패턴
```
Component: container-manager
Affected Files:
  - src/container_manager.cxx
  - config/default.json
API Changes:
  - Add new endpoint /api/v2/status
  - Deprecate /api/v1/health
```

### From Components Field

JIRA 컴포넌트를 디렉토리에 매핑:
```yaml
container-manager: container-manager/
vam: vam/
libsntxx: libsntxx/
libsntlogging: libsntlogging/
libsnt_vehicle: libsnt_vehicle/
diagnostic-manager: diagnostic-manager/
seccommon: seccommon/
dpm: dpm/
ethnm: ethnm/
soa: soa/
```

### From Labels Field

빌드/테스트 요구사항 식별:
```yaml
labels:
  cross-compile: --cross-compile --ecu CCU2 필요
  container: 컨테이너 테스트 필요
  security: 보안 리뷰 필요
  misra: MISRA 컴플라이언스 체크 필요
  performance: 성능 테스트 필요
  breaking-change: API 변경 주의
```

## Classification Logic

### Functional Requirements (FR)

Description에서 추출:
- Must/shall 문장
- User story 형식: "As a ... I want ... so that ..."
- Acceptance criteria
- Expected behavior 설명

식별 패턴:
```regex
(must|shall|should|will)\s+(be able to|support|provide|allow|enable)
As a .+ I want .+ so that
Given .+ When .+ Then
```

### Technical Requirements (TR)

Description에서 추출:
- Platform/target 명세
- Performance 요구사항
- Dependency 제약
- Security 요구사항
- API 사양

식별 패턴:
```regex
(performance|latency|throughput).*(<|>|less than|greater than)\s*\d+
(compatible with|requires|depends on)
(TLS|SSL|encryption|authentication)
(API|interface|endpoint|protocol)
```

### Test Criteria (TC)

Description에서 추출:
- Expected behaviors
- Edge cases 언급
- 연결된 테스트 티켓
- "Verify that..." 문장

식별 패턴:
```regex
(verify|validate|confirm|ensure|check)\s+that
(test|testing|tested)\s+(with|by|using)
edge case|boundary|corner case
(pass|fail)\s+when
```

## Output Format

### Structured Requirements Document

```markdown
## Requirements Summary: <TICKET_ID>

### Ticket Info
- **Title**: <Summary>
- **Status**: <Status>
- **Priority**: <Priority>
- **Assignee**: <Name>
- **Components**: <Component list>

### Functional Requirements
1. [FR-1] <Requirement description>
   - Source: Description line X
   - Priority: High/Medium/Low

2. [FR-2] <Requirement description>
   - Source: AC #2
   - Priority: High/Medium/Low

### Technical Requirements
1. [TR-1] <Technical constraint>
   - Type: Performance/Security/Compatibility

2. [TR-2] <Technical constraint>
   - Type: API/Interface

### Test Criteria
1. [TC-1] <Test case description>
   - Type: Unit/Integration/E2E
   - Expected: Pass/Fail condition

2. [TC-2] <Test case description>
   - Type: Unit/Integration/E2E

### Files Likely Affected
- `<component>/src/file1.cxx` - FR-1 구현
- `<component>/config/config.json` - TR-2 설정
- `<component>/tests/test_file.cxx` - TC-1, TC-2

### Implementation Plan
1. **Phase 1**: <First step>
   - Files: <file list>
   - Requirements: FR-1, TR-1

2. **Phase 2**: <Second step>
   - Files: <file list>
   - Requirements: FR-2, TC-1

### Estimated Effort
- Implementation: ~X hours
- Testing: ~Y hours
- Review: ~Z hours
```

## Dependency Analysis

### Linked Tickets

JIRA issuelinks에서 추출:
```json
"issuelinks": [
  {
    "type": {"name": "Blocks", "inward": "is blocked by"},
    "inwardIssue": {"key": "CCU2-12340"}
  },
  {
    "type": {"name": "Relates"},
    "outwardIssue": {"key": "CCU2-12350"}
  }
]
```

분류:
- **Blockers**: 먼저 완료되어야 하는 티켓
- **Blocked by this**: 이 티켓 완료 후 진행 가능
- **Related**: 참조용

### Code Dependencies

컴포넌트 간 의존성:
```yaml
dependency_map:
  vam:
    - libsntxx
    - libsntlogging
    - libsnt_vehicle
  container-manager:
    - libsntxx
    - libsntlogging
  diagnostic-manager:
    - libsntxx
    - libsntlogging
    - seccommon
```

빌드 순서 결정:
1. 공통 라이브러리 (libsntxx, libsntlogging)
2. 도메인 라이브러리 (libsnt_vehicle, seccommon)
3. 애플리케이션 (vam, container-manager)

## File Impact Prediction

### Keyword-to-File Mapping

Description 키워드로 파일 예측:
```yaml
keywords:
  container:
    - container-manager/src/*.cxx
    - container-manager/include/*.hxx
  policy:
    - container-manager/src/policy*.cxx
    - vam/src/policy*.cxx
  config:
    - "*/config/*.json"
    - "*/config/*.yaml"
  test:
    - "*/tests/*.cxx"
    - "*/test.py"
  api:
    - "*/include/*_api.hxx"
    - "*/src/*_service.cxx"
```

### Pattern Matching

```bash
# 컴포넌트에서 관련 파일 찾기
grep -rl "keyword" <component>/src/
grep -rl "ClassName" <component>/include/
```

## Validation Checklist

요구사항 추출 완료 전 확인:
- [ ] 모든 AC가 FR/TR/TC로 분류됨
- [ ] 각 요구사항에 소스(description 라인) 명시
- [ ] 영향받는 파일 최소 1개 이상 식별
- [ ] 의존성 티켓 확인됨
- [ ] 구현 순서 결정됨
- [ ] 테스트 전략 포함됨
