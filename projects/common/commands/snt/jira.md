---
name: snt:jira
description: "Jira integration for CCU2 project. Fetch issues by ID/JQL or create new issues from git changes with proper field prompts."
---

# /snt:jira - Jira Integration

Jira API를 통해 CCU2 프로젝트 이슈 조회 및 생성.

## Usage

```bash
# 조회
/snt:jira <issue-id | jql-query>

# 생성
/snt:jira --create [options]
/snt:jira --from-changes   # git 변경사항 기반 생성
```

### Options

| Option | Description |
|--------|-------------|
| `--format <type>` | 출력 형식: summary, full, spec (default: full) |
| `--export <file>` | 결과를 파일로 저장 |
| `--to-spec` | spec 명세 형식으로 변환 |
| `--create` | 새 이슈 생성 모드 |
| `--from-changes` | git diff 분석하여 이슈 자동 생성 |
| `--type <type>` | 이슈 타입: Task, Bug, Story (default: Task) |
| `--component <name>` | 컴포넌트: kernel, systemd, container 등 |
| `--dry-run` | 생성하지 않고 미리보기만 |

## Examples

### Query Examples

```bash
# 단일 이슈 조회
/snt:jira CCU2-12345

# JQL 쿼리로 여러 이슈 검색
/snt:jira "project=CCU2 AND status='In Progress'"

# 특정 컴포넌트 이슈 검색
/snt:jira "project=CCU2 AND component=kernel"

# spec 형식으로 변환
/snt:jira CCU2-12345 --to-spec

# 파일로 저장
/snt:jira CCU2-12345 --export claudedocs/CCU2-12345-spec.yaml
```

### Creation Examples

```bash
# git 변경사항 기반으로 이슈 생성 (가장 일반적)
/snt:jira --from-changes

# 미리보기만 (실제 생성하지 않음)
/snt:jira --from-changes --dry-run

# 컴포넌트 지정하여 생성
/snt:jira --from-changes --component kernel

# 이슈 타입 지정
/snt:jira --from-changes --type Story

# 수동으로 이슈 생성 (interactive)
/snt:jira --create --component kernel --type Task
```

## Configuration

환경 변수 설정 (`~/.env`):

```bash
JIRA_BASE_URL=https://sonatus.atlassian.net/
JIRA_EMAIL=user@sonatus.com
JIRA_API_TOKEN=<api-token>
```

## API Integration

### Authentication

```bash
# Basic Auth with API Token
curl -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/{issueKey}"
```

### Single Issue Fetch

```bash
# Issue 조회 (전체 필드)
curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}rest/api/3/issue/{issueKey}?expand=changelog" \
  -H "Accept: application/json"
```

### JQL Search (New API - 2024+)

```bash
# JQL 검색 (POST 방식, 새 API 엔드포인트)
# Note: /rest/api/3/search 는 deprecated, /rest/api/3/search/jql 사용
curl -s -X POST -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}rest/api/3/search/jql" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "jql": "project=CCU2 AND status=\"In Progress\"",
    "maxResults": 50,
    "fields": ["summary", "description", "status", "assignee", "components", "labels", "comment", "attachment"]
  }'
```

### Create Issue

```bash
# 이슈 생성 (POST)
curl -s -X POST -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}rest/api/3/issue" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "CCU2" },
      "issuetype": { "name": "Task" },
      "summary": "Add cgroupv2 unified hierarchy support",
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "paragraph",
            "content": [
              { "type": "text", "text": "Enable cgroupv2 unified hierarchy for container runtime support." }
            ]
          },
          {
            "type": "heading",
            "attrs": { "level": 2 },
            "content": [{ "type": "text", "text": "Changes" }]
          },
          {
            "type": "bulletList",
            "content": [
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Kernel: Added cgroupv2.config" }]}]},
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Systemd: Enable unified hierarchy mode" }]}]}
            ]
          }
        ]
      },
      "components": [{ "name": "kernel" }, { "name": "systemd" }],
      "labels": ["cgroupv2", "container"]
    }
  }'
```

### Get Project Metadata (for valid components, issue types)

```bash
# 프로젝트 메타데이터 조회 (유효한 컴포넌트, 이슈 타입 확인)
curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}rest/api/3/project/CCU2" \
  -H "Accept: application/json"

# 이슈 생성에 필요한 필드 확인
curl -s -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}rest/api/3/issue/createmeta?projectKeys=CCU2&expand=projects.issuetypes.fields" \
  -H "Accept: application/json"
```

## Output Format

### Summary Format (`--format summary`)

```
Issue: CCU2-12345
Title: Add cgroupv2 support for container runtime
Status: In Progress
Assignee: jay.lee@sonatus.com
Components: kernel, systemd
Labels: feature, container
```

### Full Format (`--format full`, default)

```yaml
issue:
  key: CCU2-12345
  summary: "Add cgroupv2 support for container runtime"
  description: |
    ## Background
    현재 시스템은 cgroupv1을 사용하고 있으나, Podman 5.0+ 는 cgroupv2를 권장함.

    ## Requirements
    1. 커널에서 cgroupv2 지원 활성화
    2. systemd unified hierarchy 모드 설정
    3. Podman/containerd 호환성 확인

    ## Acceptance Criteria
    - [ ] cgroupv2 파일시스템 마운트 확인
    - [ ] 컨테이너 정상 실행 확인

  status: "In Progress"
  priority: "High"
  assignee:
    name: "Jay Lee"
    email: "jay.lee@sonatus.com"

  components:
    - kernel
    - systemd
    - container

  labels:
    - feature
    - container
    - cgroupv2

  links:
    - type: "blocks"
      outward: CCU2-12346
    - type: "relates to"
      outward: CCU2-12340

  comments:
    - author: "John Doe"
      created: "2025-01-03T10:00:00Z"
      body: "커널 config fragment 추가 필요"

  attachments:
    - filename: "cgroupv2-design.pdf"
      url: "https://..."

  custom_fields:
    target_version: "2.5.0"
    affected_modules: "linux-s32, systemd"
```

### Spec Format (`--to-spec`)

Jira 이슈를 spec 형식으로 자동 변환:

```yaml
spec:
  name: "CCU2-12345-cgroupv2-support"
  source:
    jira_issue: "CCU2-12345"
    jira_url: "https://sonatus.atlassian.net/browse/CCU2-12345"

  description: |
    Add cgroupv2 support for container runtime
    (from Jira issue CCU2-12345)

  requirements:
    - "커널에서 cgroupv2 지원 활성화"
    - "systemd unified hierarchy 모드 설정"
    - "Podman/containerd 호환성 확인"

  acceptance_criteria:
    - "cgroupv2 파일시스템 마운트 확인"
    - "컨테이너 정상 실행 확인"

  affected_components:
    - kernel
    - systemd
    - container

  # 아래 필드는 분석 후 채워짐
  recipe_changes: []
  kernel_configs: []
  code_changes: []
  config_changes: []
  documentation: []
```

## Common JQL Queries

### By Status

```bash
# 진행 중인 이슈
/snt:jira "project=CCU2 AND status='In Progress'"

# 리뷰 대기 중
/snt:jira "project=CCU2 AND status='In Review'"

# 이번 스프린트
/snt:jira "project=CCU2 AND sprint in openSprints()"
```

### By Component

```bash
# 커널 관련
/snt:jira "project=CCU2 AND component=kernel"

# 컨테이너 관련
/snt:jira "project=CCU2 AND component in (podman, docker, containerd)"
```

### By Assignee

```bash
# 나에게 할당된 이슈
/snt:jira "project=CCU2 AND assignee=currentUser()"

# 특정 담당자
/snt:jira "project=CCU2 AND assignee='jay.lee@sonatus.com'"
```

### By Label/Version

```bash
# 특정 라벨
/snt:jira "project=CCU2 AND labels=cgroupv2"

# 특정 버전
/snt:jira "project=CCU2 AND fixVersion='2.5.0'"
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | 인증 실패 | ~/.env API 토큰 확인 |
| 404 Not Found | 이슈 없음 | Issue Key 확인 |
| 400 Bad Request | JQL 문법 오류 | JQL 쿼리 확인 |
| Connection Error | 네트워크 문제 | VPN/프록시 확인 |

## Boundaries

**Will:**
- Jira API를 통한 이슈 조회
- Issue ID 및 JQL 쿼리 지원
- 전체 필드 (comments, attachments, links) 조회
- spec 형식으로 자동 변환
- git 변경사항 분석하여 이슈 자동 생성
- 새 이슈 생성 (Task, Bug, Story 등)

**Will Not:**
- 이슈 삭제
- 첨부파일 업로드/다운로드
- Jira 웹훅 설정
- Jira 프로젝트/보드 설정 변경

## Issue Creation from Git Changes

### Change Analysis Flow

```
git diff / git status
├── 파일 분류
│   ├── Kernel config (.config) → component: kernel
│   ├── Recipe (.bb, .bbappend) → 영향 모듈 파악
│   ├── Source code → 기능 분석
│   └── Config files → 설정 변경 분석
├── 요약 생성
│   ├── Summary: 변경 목적 (자동 추론 또는 입력)
│   ├── Description: 변경 내용 상세
│   └── Components: 영향받는 컴포넌트
└── Jira 이슈 생성
    └── 생성된 이슈 KEY 반환
```

### Example: --from-changes Execution

```
## Analyzed Changes

**Modified Files:**
- recipes-tiers/mobis/recipes-kernel/linux/linux-s32_5.10.bbappend

**New Files:**
- recipes-core/systemd/systemd_%.bbappend
- recipes-tiers/mobis/recipes-kernel/linux/linux-ccu2/cgroupv2.config

## Detected Changes

| Category | Change |
|----------|--------|
| Kernel | Added cgroupv2.config with CONFIG_CGROUP_V2, CONFIG_PSI |
| Systemd | Enable cgroupv2 unified hierarchy mode |

## Generated Issue Preview

**Summary:** Add cgroupv2 unified hierarchy support
**Type:** Task
**Components:** Container
**Labels:** cgroupv2, container, kernel

---
Proceed with creation? [y/N]
```

## Required Fields (User Prompts)

이슈 생성 시 Claude가 사용자에게 물어봐야 하는 필드:

### General Tab Fields

| Field | API Field | Default | Options |
|-------|-----------|---------|---------|
| **H/W Type** | customfield_10478 | BCU Mobis | BCU Mobis, BCU LGE, etc. |
| **Components** | components | Container | Container, kernel, systemd, etc. |
| **Fix Version** | fixVersions | future | future, CCU2_DEV_SNT_*, CCU2_MP_* |
| **Category** | customfield_10158 | Maintenance | Maintenance, New Feature |

### CCU2 Release-Notes Tab Fields

| Field | API Field | Default | Description |
|-------|-----------|---------|-------------|
| **Notify Customer** | customfield_10129 | NO | 고객에게 알림 여부 |
| **Affected Vehicle Types** | customfield_10127 | None | 영향받는 차량 타입 |
| **Feature Description** | customfield_10128 | (from changes) | 기능 설명 |
| **Manual Test** | customfield_10060 | None | 수동 테스트 방법 |
| **Automated Test** | customfield_10224 | None | 자동화 테스트 |
| **Customer Ticket Links** | customfield_10248 | None | 고객 티켓 링크 |
| **RN Components** | customfield_10577 | (ask user) | CM-Security, CM-Container, etc. |

### User Prompt Flow

이슈 생성 시 사용자에게 다음을 확인:

```
## Issue Creation - Field Confirmation

### General Tab
1. **Category**: [Maintenance / New Feature]
   → Default: Maintenance

2. **Fix Version**:
   → future (default)
   → 특정 버전 선택

### CCU2 Release-Notes Tab
3. **Notify Customer**: [YES / NO]
   → Default: NO

4. **Feature Description**:
   → (변경 내용에서 자동 생성)
   → 수정이 필요하면 입력

5. **RN Components**: [선택]
   - CM-Security: 보안 관련 변경
   - CM-Container: 컨테이너/Podman 관련
   - CM-Monitoring: 모니터링 관련
   - CM-System: 시스템 레벨 변경

6. **Manual Test** (optional):
   → 테스트 방법 입력

생성을 진행할까요? [y/N]
```

### API Field IDs Reference

```yaml
# General Tab
customfield_10478:  # H/W Type
  default: { "id": "10843" }  # BCU Mobis

customfield_10158:  # Category
  options:
    - { "id": "10416", "value": "Maintenance" }

components:
  - { "id": "10126", "name": "Container" }

fixVersions:
  - { "id": "10072", "name": "future" }

# CCU2 Release-Notes Tab
customfield_10129:  # Notify Customer
  options:
    - { "id": "10384", "value": "NO" }
    - { "id": "10383", "value": "YES" }

customfield_10127:  # Affected Vehicle Types
  type: text

customfield_10128:  # Feature Description
  type: doc (ADF format)

customfield_10060:  # Manual Test
  type: doc (ADF format)

customfield_10224:  # Automated Test
  type: doc (ADF format)

customfield_10248:  # Customer Ticket Links
  type: text

customfield_10577:  # RN Components
  type: multi-select
  # Note: Options must be fetched from Jira or set manually in UI
```
