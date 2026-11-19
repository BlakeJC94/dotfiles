---
name: "jira-work-inventory"
description: "Inventory Blake Cook's active Jira work at Canva: all assigned open tickets grouped by project, with review-pending and blocker items surfaced, plus a short prioritization. Use when asked for \"what am I working on\", \"organize my Jira\", \"what's in progress\", \"what should I focus on\", or a quick inventory of open tickets."
version: 1
created: "2026-11-19"
updated: "2026-11-19"
---
## When to Use
When the user asks for a work inventory, to organize or prioritize Jira/Canva work, or what's in progress and what to focus on next. Not for a full work check-in (Slack/Zoom/Jira updates) — that is a separate workflow; pair with it when the user asks for a check-in.

## Procedure
1. Call atlassian.searchJiraIssuesUsingJql with cloudId d3a6b95b-bc47-4f92-b865-3ec7796e70f5 (canva.atlassian.net), jql 'assignee = "Blake Cook" ORDER BY updated DESC', view "compact", fields ["summary","status","priority","issuetype.name","project.key","labels","updated"], maxResults 100.
2. If isLast is false, re-run with the returned nextPageToken and append the page.
3. Drop tickets with statusCategory Done or Cancelled.
4. Bucket the rest into In Motion (statusCategory In Progress: In Development, Code Review, QA Review) and Backlog (To Do / Backlog).
5. Group by project.key; flag Epic rows separately from tasks.
6. Report per project: In Motion tickets as 'key - summary (status, priority)'. Condense Backlog to keys with short summaries. Then a short 'where to push' list: (a) every Code Review / QA Review ticket (waiting on someone else - nudge for review), (b) In Development tickets whose description mentions a blocking dependency, (c) Must have tickets in motion.
7. Only if the user asks, offer to capture the project structure into the current week's field-notes log (read ~/Workspace/field-notes/<YYYY>-wNN-MM-DD.md for the week containing today's date; never create a missing weekly note).

## Pitfalls
- 'assignee = "Blake Cook"' (display name) is the only form that works on this site; bcook, blake, blake.cook and email all return empty issue lists.
- view evidence returns 50KB+ of mostly-empty customfields per ticket and eats the output budget; stay on compact with an explicit fields list.
- Epics are also Jira issues; their subtasks are separate tickets. Do not infer subtasks from an epic row or double-count them.
- Done and Cancelled tickets still come back in the query; always filter them out before summarizing.
- JQL returns issues only; do not infer sprints, boards, or workloads from issue rows without a dedicated tool.

## Verification
1. The report covers every ticket with statusCategory In Progress or To Do; spot-check two or three keys against their Jira URLs.
2. No Done or Cancelled ticket appears in the output.
3. Every In Motion item shows status and priority, and the 'where to push' section lists every Code Review and QA Review ticket.