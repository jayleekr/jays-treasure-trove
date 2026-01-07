# PRD: Obsidian 온톨로지 지식 관리 시스템

## 개요

**프로젝트명**: jays-knowledge-vault
**목적**: 시간 + 토픽 + 사람 기반 쿼리가 가능한 Obsidian 지식 관리 시스템 구축
**관련 저장소**: jays-treasure-trove (Claude Code 설정)

---

## 목표 유스케이스

```
"Sebastian이 12월27일~1월7일 휴가였어, 이 기간동안 업데이트된 Container Manager 관련 것들을 보여줘"
```

### 필요 기능
| 요구사항 | 구현 방법 |
|---------|----------|
| 시간 범위 필터링 | `date` frontmatter + Dataview 쿼리 |
| 토픽/컴포넌트 필터링 | `component` 속성 + 태그 |
| 사람 컨텍스트 | People 노트 + 휴가 메타데이터 |
| 변경 이력 추적 | Changes 폴더 + Git 동기화 |

---

## Phase 1: 저장소 초기화

### 작업 목록

- [ ] GitHub에 `jays-knowledge-vault` 저장소 생성
- [ ] 기본 디렉토리 구조 생성
- [ ] .gitignore 설정
- [ ] README.md 작성

### 디렉토리 구조

```
jays-knowledge-vault/
├── .obsidian/                     # Obsidian 설정 (자동 생성)
├── README.md
├── .gitignore
│
├── _system/                       # 시스템 파일
│   ├── templates/                 # 노트 템플릿
│   │   ├── change.md
│   │   ├── component.md
│   │   └── person.md
│   └── queries/                   # 저장된 Dataview 쿼리
│       ├── vacation-updates.md
│       ├── component-dashboard.md
│       └── weekly-summary.md
│
├── Components/                    # 컴포넌트 온톨로지 (MOC)
│   ├── _Index.md                  # 컴포넌트 목록
│   ├── Container Manager.md
│   ├── Seccomp Profile.md
│   ├── JIRA Integration.md
│   └── Build System.md
│
├── Changes/                       # 변경 이력 (핵심)
│   ├── _Index.md                  # 변경 이력 대시보드
│   ├── 2025-01/
│   │   └── .gitkeep
│   └── 2024-12/
│       └── .gitkeep
│
├── People/                        # 팀원 정보
│   ├── _Team Dashboard.md
│   ├── Sebastian.md
│   └── Jay.md
│
├── Projects/                      # 프로젝트별 정보
│   ├── CCU_GEN2.0_SONATUS/
│   │   └── _Index.md
│   └── ccu-2.0/
│       └── _Index.md
│
└── scripts/                       # 동기화 스크립트
    ├── sync-from-git.sh           # Git 커밋 → Obsidian 노트 변환
    └── setup-vault.sh             # 초기 설정 스크립트
```

---

## Phase 2: Frontmatter 스키마 정의

### 작업 목록

- [ ] 변경 노트 템플릿 작성 (`_system/templates/change.md`)
- [ ] 컴포넌트 MOC 템플릿 작성 (`_system/templates/component.md`)
- [ ] 팀원 노트 템플릿 작성 (`_system/templates/person.md`)

### 2.1 변경 노트 스키마

```yaml
---
# === 필수 필드 ===
date: {{date}}                      # YYYY-MM-DD
component:                          # 배열 가능
  - Container Manager
type: bugfix                        # bugfix | feature | refactor | docs | update
author: Jay

# === 선택 필드 ===
jira: CCU-1234                      # JIRA 티켓 번호
pr: 456                             # PR 번호
commit: abc1234                     # 커밋 해시
related:                            # 관련 노트 링크
  - "[[Seccomp Profile]]"
  - "[[2025-01-02 Previous fix]]"
tags:                               # 추가 태그
  - container
  - security
  - urgent

# === 자동 생성 (Templater) ===
created: {{date:YYYY-MM-DD HH:mm}}
modified: {{date:YYYY-MM-DD HH:mm}}
---

# {{title}}

## 변경 내용

> 변경 사항 설명

## 영향 범위

-

## 참고 사항

-
```

### 2.2 컴포넌트 MOC 스키마

```yaml
---
type: component
name: Container Manager
status: active                      # active | deprecated | planned
owners:                             # 담당자
  - "[[Sebastian]]"
  - "[[Jay]]"
projects:                           # 관련 프로젝트
  - "[[ccu-2.0/_Index|ccu-2.0]]"
related_components:                 # 관련 컴포넌트
  - "[[Seccomp Profile]]"
  - "[[Docker Integration]]"
tags:
  - container
  - core
---

# Container Manager

## 개요

> 컴포넌트 설명

## 최근 변경 사항

```dataview
TABLE WITHOUT ID
  file.link as "변경",
  dateformat(date, "MM-dd") as "날짜",
  type as "유형",
  author as "작성자"
FROM "Changes"
WHERE contains(component, "Container Manager")
SORT date DESC
LIMIT 10
```

## 관련 문서

-

## 담당자

```dataview
LIST
FROM "People"
WHERE contains(components, "Container Manager")
```
```

### 2.3 팀원 노트 스키마

```yaml
---
type: person
name: Sebastian
role: Senior Engineer
email: sebastian@example.com
components:                         # 담당 컴포넌트
  - Container Manager
  - Seccomp Profile
projects:
  - ccu-2.0
vacations:                          # 휴가 기록
  - start: 2024-12-27
    end: 2025-01-07
    type: holiday
    note: 연말 휴가
---

# Sebastian

## 담당 영역

```dataview
LIST
FROM "Components"
WHERE contains(owners, this.file.link)
```

## 최근 활동

```dataview
TABLE WITHOUT ID
  file.link as "변경",
  dateformat(date, "MM-dd") as "날짜",
  component as "컴포넌트"
FROM "Changes"
WHERE author = this.name
SORT date DESC
LIMIT 10
```

## 휴가 기록

| 시작 | 종료 | 유형 | 비고 |
|------|------|------|------|
| 2024-12-27 | 2025-01-07 | holiday | 연말 휴가 |
```

---

## Phase 3: Dataview 쿼리 라이브러리

### 작업 목록

- [ ] 휴가 기간 업데이트 조회 쿼리 (`_system/queries/vacation-updates.md`)
- [ ] 컴포넌트 대시보드 쿼리 (`_system/queries/component-dashboard.md`)
- [ ] 주간 요약 쿼리 (`_system/queries/weekly-summary.md`)
- [ ] 팀원별 활동 쿼리 (`_system/queries/person-activity.md`)

### 3.1 휴가 기간 업데이트 조회

```markdown
# 휴가 기간 업데이트 조회

## 사용법
아래 변수를 수정하여 사용:
- `component`: 조회할 컴포넌트명
- `startDate`: 시작일
- `endDate`: 종료일

## 쿼리

```dataview
TABLE WITHOUT ID
  file.link as "변경사항",
  dateformat(date, "MM-dd (ddd)") as "날짜",
  type as "유형",
  author as "작성자",
  jira as "JIRA"
FROM "Changes"
WHERE contains(component, "Container Manager")
  AND date >= date(2024-12-27)
  AND date <= date(2025-01-07)
SORT date DESC
```
```

### 3.2 컴포넌트별 월간 변경 현황

```markdown
# 컴포넌트 대시보드

```dataview
TABLE WITHOUT ID
  component[0] as "컴포넌트",
  length(rows) as "변경 수",
  min(rows.date) as "첫 변경",
  max(rows.date) as "마지막 변경"
FROM "Changes"
WHERE date >= date(today) - dur(30 days)
GROUP BY component
SORT length(rows) DESC
```
```

### 3.3 주간 요약

```markdown
# 주간 요약

## 이번 주 변경 사항

```dataview
TABLE WITHOUT ID
  dateformat(date, "MM-dd (ddd)") as "날짜",
  file.link as "변경",
  component as "컴포넌트",
  author as "작성자"
FROM "Changes"
WHERE date >= date(today) - dur(7 days)
SORT date DESC
```

## 작성자별 통계

```dataview
TABLE WITHOUT ID
  author as "작성자",
  length(rows) as "변경 수"
FROM "Changes"
WHERE date >= date(today) - dur(7 days)
GROUP BY author
SORT length(rows) DESC
```
```

---

## Phase 4: 자동화 스크립트

### 작업 목록

- [ ] Git 커밋 → Obsidian 노트 변환 스크립트 (`scripts/sync-from-git.sh`)
- [ ] Vault 초기 설정 스크립트 (`scripts/setup-vault.sh`)
- [ ] jays-treasure-trove 연동 (선택사항)

### 4.1 Git 동기화 스크립트

```bash
#!/bin/bash
# scripts/sync-from-git.sh
# Git 커밋을 Obsidian 노트로 변환

set -e

# === 설정 ===
VAULT_PATH="${VAULT_PATH:-$HOME/jays-knowledge-vault}"
CHANGES_PATH="$VAULT_PATH/Changes"
DEFAULT_AUTHOR="${DEFAULT_AUTHOR:-Unknown}"

# === 함수 ===
usage() {
    echo "Usage: $0 <repo-path> [--since=<date>] [--until=<date>] [--component=<name>]"
    echo ""
    echo "Examples:"
    echo "  $0 ~/ccu-2.0 --since=2024-12-27 --until=2025-01-07"
    echo "  $0 ~/ccu-2.0 --since='1 week ago' --component='Container Manager'"
    exit 1
}

create_note() {
    local date="$1"
    local author="$2"
    local subject="$3"
    local body="$4"
    local commit="$5"
    local component="${6:-General}"

    # 날짜 형식 변환 (YYYY-MM-DD)
    local formatted_date=$(date -d "$date" +%Y-%m-%d 2>/dev/null || echo "$date")
    local month=$(date -d "$date" +%Y-%m 2>/dev/null || echo "unknown")

    # 파일명 생성 (특수문자 제거)
    local safe_subject=$(echo "$subject" | tr -cd '[:alnum:] ' | tr ' ' '-' | cut -c1-50)
    local filename="${formatted_date}-${safe_subject}.md"
    local filepath="$CHANGES_PATH/$month/$filename"

    # 디렉토리 생성
    mkdir -p "$CHANGES_PATH/$month"

    # 타입 추론
    local type="update"
    if echo "$subject" | grep -qi "fix\|bug"; then
        type="bugfix"
    elif echo "$subject" | grep -qi "feat\|add"; then
        type="feature"
    elif echo "$subject" | grep -qi "refactor"; then
        type="refactor"
    elif echo "$subject" | grep -qi "doc"; then
        type="docs"
    fi

    # JIRA 티켓 추출
    local jira=$(echo "$subject" | grep -oE '[A-Z]+-[0-9]+' | head -1)

    # 노트 작성
    cat > "$filepath" << EOF
---
date: $formatted_date
component:
  - $component
type: $type
author: $author
commit: $commit
${jira:+jira: $jira}
created: $(date +%Y-%m-%d\ %H:%M)
---

# $subject

## 변경 내용

$body

## 커밋 정보

- **Commit**: \`$commit\`
- **Author**: $author
- **Date**: $formatted_date
EOF

    echo "Created: $filepath"
}

# === 메인 ===
REPO_PATH="$1"
shift || usage

if [ ! -d "$REPO_PATH/.git" ]; then
    echo "Error: $REPO_PATH is not a git repository"
    exit 1
fi

# 옵션 파싱
SINCE=""
UNTIL=""
COMPONENT=""

for arg in "$@"; do
    case $arg in
        --since=*)
            SINCE="${arg#*=}"
            ;;
        --until=*)
            UNTIL="${arg#*=}"
            ;;
        --component=*)
            COMPONENT="${arg#*=}"
            ;;
    esac
done

# Git log 명령 구성
GIT_CMD="git -C $REPO_PATH log --pretty=format:'%H|%ad|%an|%s|%b' --date=short"
[ -n "$SINCE" ] && GIT_CMD="$GIT_CMD --since='$SINCE'"
[ -n "$UNTIL" ] && GIT_CMD="$GIT_CMD --until='$UNTIL'"

echo "Syncing commits from $REPO_PATH..."
echo "Command: $GIT_CMD"
echo ""

# 커밋 처리
eval "$GIT_CMD" | while IFS='|' read -r commit date author subject body; do
    [ -z "$commit" ] && continue
    create_note "$date" "$author" "$subject" "$body" "${commit:0:7}" "$COMPONENT"
done

echo ""
echo "Sync complete!"
```

### 4.2 Vault 초기 설정 스크립트

```bash
#!/bin/bash
# scripts/setup-vault.sh
# Obsidian Vault 초기 설정

set -e

VAULT_PATH="${1:-$HOME/jays-knowledge-vault}"

echo "Setting up Obsidian Vault at: $VAULT_PATH"

# 디렉토리 생성
mkdir -p "$VAULT_PATH"/{_system/templates,_system/queries}
mkdir -p "$VAULT_PATH"/Components
mkdir -p "$VAULT_PATH"/Changes/{2024-12,2025-01}
mkdir -p "$VAULT_PATH"/People
mkdir -p "$VAULT_PATH"/Projects/{CCU_GEN2.0_SONATUS,ccu-2.0}
mkdir -p "$VAULT_PATH"/scripts

# .gitignore 생성
cat > "$VAULT_PATH/.gitignore" << 'EOF'
# Obsidian
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/plugins/*/data.json
.trash/

# System
.DS_Store
Thumbs.db

# Temporary
*.tmp
*.bak
EOF

# README 생성
cat > "$VAULT_PATH/README.md" << 'EOF'
# Jay's Knowledge Vault

Obsidian 기반 온톨로지 지식 관리 시스템

## 구조

- `_system/` - 템플릿 및 쿼리
- `Components/` - 컴포넌트 온톨로지 (MOC)
- `Changes/` - 변경 이력
- `People/` - 팀원 정보
- `Projects/` - 프로젝트별 정보
- `scripts/` - 자동화 스크립트

## 필수 플러그인

- Dataview
- Templater
- Calendar (권장)

## 사용법

```bash
# Git 커밋을 노트로 변환
./scripts/sync-from-git.sh ~/ccu-2.0 --since="1 week ago"
```
EOF

echo "Vault setup complete!"
echo ""
echo "Next steps:"
echo "1. Open $VAULT_PATH in Obsidian"
echo "2. Install Dataview and Templater plugins"
echo "3. Copy templates from _system/templates/"
```

---

## Phase 5: 필수 플러그인 설정

### 작업 목록

- [ ] Dataview 플러그인 설치 및 설정
- [ ] Templater 플러그인 설치 및 설정
- [ ] Calendar 플러그인 설치 (선택)
- [ ] Git 플러그인 설치 (선택)

### Dataview 설정

```json
{
  "enableDataviewJs": true,
  "enableInlineDataviewJs": true,
  "prettyRenderInlineFields": true,
  "tableIdColumnName": "File",
  "tableGroupColumnName": "Group"
}
```

### Templater 설정

```json
{
  "templates_folder": "_system/templates",
  "trigger_on_file_creation": true,
  "enable_system_commands": true
}
```

---

## Phase 6: 샘플 데이터 및 테스트

### 작업 목록

- [ ] 샘플 컴포넌트 노트 5개 생성
- [ ] 샘플 변경 노트 10개 생성
- [ ] 샘플 팀원 노트 3개 생성
- [ ] 휴가 기간 쿼리 테스트
- [ ] 컴포넌트 대시보드 쿼리 테스트

---

## 체크리스트 요약

### Phase 1: 저장소 초기화
- [ ] GitHub 저장소 생성
- [ ] 디렉토리 구조 생성
- [ ] .gitignore 설정
- [ ] README.md 작성

### Phase 2: 템플릿 작성
- [ ] change.md 템플릿
- [ ] component.md 템플릿
- [ ] person.md 템플릿

### Phase 3: 쿼리 라이브러리
- [ ] vacation-updates.md
- [ ] component-dashboard.md
- [ ] weekly-summary.md
- [ ] person-activity.md

### Phase 4: 자동화
- [ ] sync-from-git.sh
- [ ] setup-vault.sh

### Phase 5: 플러그인
- [ ] Dataview 설치/설정
- [ ] Templater 설치/설정

### Phase 6: 테스트
- [ ] 샘플 데이터 생성
- [ ] 쿼리 테스트
- [ ] 워크플로우 검증

---

## 참고 자료

- [Dataview 문서](https://blacksmithgu.github.io/obsidian-dataview/)
- [Templater 문서](https://silentvoid13.github.io/Templater/)
- [Obsidian 공식 문서](https://help.obsidian.md/)
