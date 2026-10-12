---
name: jira-request
description: 요청·문의·회의 다음 액션을 Jira 이슈 초안으로 정리하고, 비슷한 이슈가 있는지 먼저 찾고, 어느 프로젝트·담당 영역인지 제안한다. 확인받은 뒤에만 만든다. "지라 올려줘", "티켓 만들어줘", "이거 요청 정리해줘", "TRQ 등록".
---

# Jira 요청 정리

먼저 `nuua-context` 스킬을 따른다.

## 1. 프로젝트 고르기
| 내용 | 프로젝트 |
|---|---|
| 누아오피스 화면·기능 | `OFF` |
| OBT(UA·VIP·WON트래블 포함) | `OBT` (WON트래블 고유 건은 `WON`) |
| NDB·채팅·Intelligence | `INT` |
| 여러 제품 공통 | `COM` |
| 다른 팀에 맡기는 요청 | `TRQ` |
| 항공사 문의 | `QNA` |
1차 담당 영역은 서비스기획팀 **"업무 컨택 포인트"** 페이지(id `390365188`)를 읽어 정한다(Office / OBT / New Chat 별 1차 담당). 담당자는 제안만 하고 사용자가 정한다.

## 2. 중복 확인
`project = <키> AND text ~ "<핵심어 2~3개>" AND created >= -180d ORDER BY updated DESC`, `fields: ["summary","status","assignee","updated"]`, `maxResults: 10`. 비슷한 게 있으면 새로 만들지 말지 먼저 묻는다(댓글로 붙이기 제안).

## 3. 초안
```
프로젝트: OBT   유형: 작업/버그/스토리(프로젝트에 있는 것만 — getJiraProjectIssueTypesMetadata로 확인)
제목: [영역] 무엇을 — 한 줄 (예: [OBT UA] 메인 배너 2단 롤링으로 변경)
설명:
  배경: 누가·왜 요청했는지 (출처 회의록·메일 링크)
  요청 내용: 번호 목록
  완료 기준: 확인할 수 있는 문장
  참고: 관련 이슈 키, 화면 캡처 위치
상위 에픽: 있으면 키
```

## 4. 만들기
초안을 보여 주고 "이대로 만들까요?" → 승인되면 `createJiraIssue`, 만든 키와 링크(`https://nuuainc.atlassian.net/browse/<키>`)를 알려 준다. 여러 건이면 표로 한 번에 보여 주고 한 번에 승인받는다.
