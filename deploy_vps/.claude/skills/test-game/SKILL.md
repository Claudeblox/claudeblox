---
name: test-game
description: Runs code review and structural testing. Finds bugs before they ship.
user-invocable: true
context: fork
---

# /test-game

Runs the full test pipeline using MCP read tools.

## Pipeline

### Step 1: Code Review
Call the **luau-reviewer** subagent:
- Gets all scripts via `get_project_structure(scriptsOnly=true)`
- Reads each script via `get_script_source`
- Searches for deprecated patterns via `search_files`
- Reviews security, memory leaks, performance, race conditions, logic bugs
- Returns list of issues with exact line numbers and fixes

### Step 2: Structure Test
Call the **roblox-playtester** subagent:
- Checks game structure (all services have content)
- Verifies scripts have source code
- Checks RemoteEvents match architecture
- Verifies world content and organization
- Checks UI structure
- Verifies tagged objects and attributes
- Counts parts for performance

### Step 3: Report
Combine results:

```
TEST RESULTS

Code Review:
- Scripts reviewed: X
- Critical issues: Y
- Serious issues: Z
- Moderate issues: W
[issue list with fixes]

Structure Test:
- Test 1 (Game Structure):  PASS/FAIL
- Test 2 (Scripts Source):   PASS/FAIL
- Test 3 (RemoteEvents):    PASS/FAIL
- Test 4 (World Content):   PASS/FAIL
- Test 5 (UI Structure):    PASS/FAIL
- Test 6 (Tagged Objects):  PASS/FAIL
- Test 7 (Performance):     PASS/FAIL

VERDICT: READY / NEEDS FIXES
```

If NEEDS FIXES — list every fix needed. The main agent or luau-scripter should fix issues and re-run /test-game.
