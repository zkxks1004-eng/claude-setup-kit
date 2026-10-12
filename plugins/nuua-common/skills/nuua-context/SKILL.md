---
name: nuua-context
description: 누아(nuua) 사내 Confluence·Jira를 읽거나 쓸 때 먼저 읽는다 — 사이트·스페이스 키·Jira 프로젝트 키, 페이지 제목 규칙, 쓰기 안전 규칙, 조회를 가볍게 하는 법. 회의록·주간보고·이슈 검색·페이지 작성 요청이면 해당.
---

# 누아 사내 맥락

## 사이트
- Atlassian `cloudId`: `nuuainc.atlassian.net` (Confluence·Jira 공통). 찾느라 `getAccessibleAtlassianResources`를 부르지 않는다.

## Confluence 스페이스 (활발한 곳)
| 키 | 이름 | 주로 있는 것 |
|---|---|---|
| `NST` | 서비스기획팀 | 회의록, 주간 회의, 본부 Weekly 취합("N월 N주"), 리더 회의 공유 |
| `BD` | 사업개발팀 | 회의록(Action Item 표), 주간보고("YYMMDD 주간보고") |
| `OBT` | OBT/WON트래블, Hotel Agg | 명세 |
| `AA` | AI Agent, Air Agg | 명세 |
| `AggOffice` | Air Office | 명세 |
| `CORETECH` | 기반기술팀 | |

- 페이지 ID를 모르면 CQL로 찾는다: `space = NST AND title ~ "주간 회의" ORDER BY created DESC`.
- 방금 만든 페이지는 CQL 색인에 늦게 잡힌다. 같은 이름 페이지를 또 만들지 말고, 부모 페이지의 하위 목록(`getConfluencePageDescendants`)으로 확인한다.

## Jira 프로젝트
| 키 | 이름 | 비고 |
|---|---|---|
| `OFF` | Office | 누아오피스 |
| `OBT` | OBT | |
| `INT` | Intelligence | NDB 등 |
| `AGG` | Air Aggregator | |
| `HAG` | Hotel Aggregator | |
| `COM` | Common | 공통 |
| `TRQ` | Team Request | 팀 간 요청 |
| `QNA` | 항공사 Q&A | |
| `QA`·`QATE` | QA·QA 자동화 테스트 | |
| `BD` | 사업개발 | |
| `TST` | Direct Booking | |
| `WON` | WONtravel | |

## 쓰기 규칙 (꼭 지킨다)
1. **저장 전에 보여 주고 확인받는다.** 페이지 생성·수정, 이슈 생성·전환·댓글 모두.
2. **다른 사람이 쓰는 페이지(주간보고, 팀 회의 페이지 등)는 API로 고치지 않는다.** 붙여 넣을 글로 만들어 준다. `updateConfluencePage`는 그 사이 남이 고친 내용을 확인하지 않고 통째로 덮어쓴다.
3. 내 페이지를 고칠 때도 **저장 직전에 다시 읽고** 그 본문에 덧붙인다. 저장 결과 버전이 읽은 버전+1이 아니면 사이에 누가 고친 것이니 사용자에게 알린다.
4. 이사님·팀장님의 제안을 "결정"으로 쓰지 않는다. 회의록에 결정이라고 적힌 것만 결정이다.

## 가볍게 조회하기 (느려지고 잘리는 것 방지)
- Jira 검색은 `fields`를 꼭 좁힌다: `["summary","status","assignee","updated","priority"]`, `maxResults` 20~50. 설명·댓글은 필요한 이슈만 따로 연다. (기본값으로 50건을 받으면 6만 자가 넘어 잘린다.)
- Confluence 본문은 요약이면 `markdown`, 고쳐 쓸 거면 `html`로 읽는다.
- 여러 스페이스를 넓게 훑어야 하면 서브에이전트에게 맡기고 결론만 받는다.
- 단정하기 전에 실제 페이지·이슈를 확인한다. 못 찾았으면 "못 찾았다"고 말한다.
