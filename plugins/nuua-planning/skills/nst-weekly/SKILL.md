---
name: nst-weekly
description: 서비스기획팀 주간 취합 초안. 매주 화요일 15시까지 쓰는 "N월 N주" 페이지의 '담당자 별 상세 진행 사항' 내 칸, 또는 주간 회의 '1분 브리핑'을 지난 한 주 Jira·Confluence 활동으로 초안을 만든다. "주간 써줘", "이번 주 내 진행 사항", "1분 브리핑", "위클리 정리".
---

# NST 주간 취합 초안

먼저 `nuua-context` 스킬을 따른다. **"N월 N주" 페이지는 팀 전체가 같이 쓰는 페이지라 API로 고치지 않는다.** 붙여 넣을 글만 만든다.

## 1. 모으기 (지난 화요일 15시 ~ 지금)
1. 지난주 내 칸: CQL `space = NST AND title ~ "월" AND title ~ "주" ORDER BY created DESC` → 최근 "N월 N주" 1건을 `markdown`으로 읽고, `담당자 별 상세 진행 사항` 표에서 사용자 이름 행만 뽑는다. (이름을 모르면 `atlassianUserInfo`로 확인)
2. Jira: `assignee = currentUser() AND updated >= -7d ORDER BY updated DESC`, `fields: ["summary","status","updated","project"]`, `maxResults: 50`. 담당이 아니어도 내가 만든 건 `reporter = currentUser() AND created >= -7d`.
3. Confluence: `space = NST AND contributor = currentUser() AND lastmodified >= now("-7d")` — 내가 쓴 회의록·기획 문서 제목.

## 2. 초안 형식 (팀 표의 한 칸 모양)
```
**프로젝트명** (NDB 프로젝트 / OBT VIP / OBT UA / 오피스 고도화 …)
- 진행한 일 — 상태 (리뷰 진행(10/2), 작성 완료, stg QA 대응 …) [OBT-2231]
    - 세부 1줄
- 다음 주 예정: …
- 이슈: …        ← 막힌 것·결정이 필요한 것만
```
- 지난주 칸에 있던 항목은 이어서 쓰고, 이번 주 Jira 상태로 바꾼다(완료면 "완료(날짜)").
- 근거 없는 진행률·날짜를 만들지 않는다. 모르면 "(확인 필요)".
- 1분 브리핑을 달라고 하면 같은 재료로 1~2줄만.

## 3. 전달
초안을 보여 주고, 빠진 일이 있는지 물어 고친 뒤 최종 글을 한 덩어리로 준다(복사해서 표 칸에 붙여 넣기).
