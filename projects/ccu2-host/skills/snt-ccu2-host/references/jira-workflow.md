# JIRA Workflow - 티켓 조회 및 파싱 패턴

## Authentication Setup

### API Token 방식 (권장)

`.env` 파일에서 인증 정보 로드:
```bash
# .env 파일 내용
JIRA_BASE_URL=https://sonatus.atlassian.net/
JIRA_EMAIL=your.email@sonatus.com
JIRA_API_TOKEN=your_api_token_here
```

### API 호출 패턴

```bash
# .env에서 변수 로드
source <(grep -E '^JIRA_' .env | sed 's/^/export /')

# Basic Auth 생성
AUTH=$(echo -n "${JIRA_EMAIL}:${JIRA_API_TOKEN}" | base64)

# REST API 호출
curl -s -L \
    -H "Authorization: Basic ${AUTH}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "${JIRA_BASE_URL}rest/api/2/issue/${TICKET_ID}"
```

### Python 패턴

```python
import os
import base64
import requests

# .env 로드 (python-dotenv 사용시)
# from dotenv import load_dotenv
# load_dotenv()

JIRA_BASE_URL = os.getenv("JIRA_BASE_URL")
JIRA_EMAIL = os.getenv("JIRA_EMAIL")
JIRA_API_TOKEN = os.getenv("JIRA_API_TOKEN")

def get_jira_ticket(ticket_id: str) -> dict:
    auth_string = f"{JIRA_EMAIL}:{JIRA_API_TOKEN}"
    auth_bytes = base64.b64encode(auth_string.encode()).decode()

    headers = {
        "Authorization": f"Basic {auth_bytes}",
        "Accept": "application/json"
    }

    url = f"{JIRA_BASE_URL}rest/api/2/issue/{ticket_id}"
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()
```

## API Endpoints

### Single Ticket
```
GET /rest/api/2/issue/{TICKET_ID}
```

### With Fields Filter
```
GET /rest/api/2/issue/{TICKET_ID}?fields=summary,description,status,priority,components,assignee
```

### Search (JQL)
```
GET /rest/api/2/search?jql=project=CCU2+AND+status="In Progress"
```

## Response Structure

### Key Fields
```json
{
  "key": "CCU2-12345",
  "fields": {
    "summary": "Ticket title",
    "description": "Detailed description text",
    "status": {
      "name": "In Progress",
      "id": "3"
    },
    "priority": {
      "name": "High",
      "id": "2"
    },
    "assignee": {
      "displayName": "Developer Name",
      "emailAddress": "dev@sonatus.com"
    },
    "reporter": {
      "displayName": "Reporter Name"
    },
    "created": "2025-01-15T10:00:00.000+0000",
    "updated": "2025-01-20T14:30:00.000+0000",
    "components": [
      {"name": "container-manager"},
      {"name": "vam"}
    ],
    "labels": ["critical", "security"],
    "issuelinks": [
      {
        "type": {"name": "Blocks"},
        "outwardIssue": {"key": "CCU2-12346"}
      }
    ]
  }
}
```

## Parsing Logic

### jq 명령어 패턴
```bash
# Summary 추출
jq -r '.fields.summary' ticket.json

# Description (null 처리)
jq -r '.fields.description // "No description"' ticket.json

# Status
jq -r '.fields.status.name' ticket.json

# Components (배열)
jq -r '.fields.components[].name' ticket.json

# Assignee
jq -r '.fields.assignee.displayName // "Unassigned"' ticket.json

# Labels (배열을 쉼표로 연결)
jq -r '.fields.labels | join(", ")' ticket.json

# Linked issues
jq -r '.fields.issuelinks[].outwardIssue.key // empty' ticket.json
```

### Acceptance Criteria 추출

Jira description에서 AC 패턴 찾기:
```bash
# Given/When/Then 패턴
grep -E "^(Given|When|Then|And):" description.txt

# Bullet points
grep -E "^\s*[-*]" description.txt

# Numbered list
grep -E "^\s*[0-9]+\." description.txt
```

## Error Handling

### Authentication Failure

**증상**: HTML 로그인 페이지 반환
```html
<!DOCTYPE html>
<html lang="en">
<head><title>Log in
```

**복구**:
1. `.env` 파일 존재 확인
2. API Token 유효성 확인
3. Email 형식 확인
4. Token 재생성 안내

### Rate Limiting

**증상**: HTTP 429 + Retry-After 헤더

**복구**:
```bash
# Retry-After 헤더 값만큼 대기
sleep $RETRY_AFTER
# 재시도
```

### Ticket Not Found

**증상**: HTTP 404 또는 에러 JSON
```json
{"errorMessages":["Issue Does Not Exist"],"errors":{}}
```

**복구**:
1. 티켓 ID 형식 확인 (CCU2-*, SEB-*, CRM-*)
2. 프로젝트 접근 권한 확인
3. 티켓 존재 여부 확인

## Ticket ID Validation

```bash
# 유효한 형식
CCU2-12345
SEB-1234
CRM-567

# 정규식 패턴
^(CCU2|SEB|CRM)-[0-9]+$
```

```python
import re

def validate_ticket_id(ticket_id: str) -> bool:
    pattern = r'^(CCU2|SEB|CRM)-\d+$'
    return bool(re.match(pattern, ticket_id))
```

## Caching Strategy

로컬에 티켓 정보 캐싱:
```bash
# 캐시 디렉토리
CACHE_DIR=".claude/jira-cache"
CACHE_FILE="${CACHE_DIR}/${TICKET_ID}.json"

# 캐시 확인 (1시간 이내)
if [[ -f "$CACHE_FILE" ]] && [[ $(find "$CACHE_FILE" -mmin -60) ]]; then
    cat "$CACHE_FILE"
else
    # API 호출 후 캐싱
    curl ... > "$CACHE_FILE"
    cat "$CACHE_FILE"
fi
```

## Component Mapping

JIRA 컴포넌트를 CCU-2.0 디렉토리에 매핑:
```yaml
component_map:
  container-manager: container-manager/
  vam: vam/
  libsntxx: libsntxx/
  libsntlogging: libsntlogging/
  diagnostic-manager: diagnostic-manager/
  seccommon: seccommon/
  dpm: dpm/
  ethnm: ethnm/
  soa: soa/
```
