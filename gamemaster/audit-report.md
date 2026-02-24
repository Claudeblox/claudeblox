# ClaudeBlox Agent System Audit Report

---

## Executive Summary

The agent system is architecturally sound but suffers from a specific, pervasive problem: **operational scripting disguised as best practices.** The luau-scripter, world-builder, and story-teller prompts all contain hundreds of lines of literal Lua code blocks that the model treats as copy-paste templates rather than principles to reason from. This is the single most impactful issue -- it inflates prompt size (luau-scripter is 2500+ lines), burns context window, and produces mechanically identical outputs regardless of game genre or task. The roblox-architect, by contrast, is remarkably well-designed with genuine principle-based thinking -- its "templating" is actually adaptive structure, not rigidity. The CLAUDE.md/ai-developer overlap is LOW severity -- they serve clearly different roles with minimal conflict. Priority action: de-script luau-scripter and world-builder by replacing literal code blocks with principles and reference patterns.

**MISSION 2 UPDATE:** Complete rewritten prompts for both roblox-architect and story-teller have been delivered and saved to their respective files. See the "Rewrites Delivered" section below for what changed and why.

**DE-SCRIPTING UPDATE:** Complete rewrites of world-builder and luau-scripter have been delivered. World-builder reduced from ~1698 to 437 lines (74% reduction). Luau-scripter reduced from ~2539 to 553 lines (78% reduction). All game-specific code blocks removed, all embedded Lua replaced with principle-based guidance and reference file pointers. See Priority Action items 1-3 below for detailed change tables.

---

## Mission 1: Scripting Diagnosis (luau-scripter, luau-reviewer, world-builder)

### luau-scripter -- Scripting Diagnosis

**Scripting severity:** CRITICAL

The luau-scripter prompt is 2539 lines. Roughly 40% of that content is literal Lua code blocks that the model will reproduce verbatim or with trivial modifications. This is the most heavily scripted agent in the system.

**Hardcoded code blocks found:**

1. **GameStateBridge** (lines 477-623): A complete 146-line server script embedded verbatim in the prompt. This is the most egregious example. The model will reproduce this character-for-character every time, regardless of game genre. A tycoon game gets the same GameStateBridge as a horror game. The `getNearbyObjects`, `getCurrentRoom`, `getFlashlightStatus`, `countCollectibles`, `countDoors` functions are all hardcoded with specific tag names ("Collectible", "InteractiveDoor"), specific attribute names ("Collected", "Opened", "IsOpen"), and specific search patterns (`obj.Name:find("Door")`). These patterns leak into the model's general output -- when the model sees "bridge" or "state tracking," it gravitates toward this exact implementation.

2. **Flashlight** (lines 631-682): A complete flashlight Tool + LocalScript embedded verbatim. Every horror game gets identical flashlight dimensions (0.5, 0.5, 2), identical light properties (Brightness=8, Range=80, Angle=50), identical toggle logic. The model cannot adapt this to, say, a lantern mechanic or a UV flashlight that reveals hidden messages -- it will reproduce this template because the prompt presents it as THE implementation, not A possible implementation.

3. **Creating Scripts patterns** (lines 214-265): Three separate complete code blocks showing how to create Script, LocalScript, and ModuleScript. These are reproduced verbatim in every build. The ModuleScript example even hardcodes the folder creation pattern with a specific name "Modules".

4. **Folder/RemoteEvent creation** (lines 270-323): Four more complete code blocks for creating folders, RemoteEvent batches, reading scripts, and writing scripts. The RemoteEvent batch example hardcodes specific event names ("PlayerAction", "UpdateUI", "GameStateChanged") that bleed into actual output.

5. **Project structure check** (lines 329-353): A complete getStructure function that gets reproduced identically every verification pass.

6. **Connection safety pattern** (lines 720-743): A complete connection tracking pattern with specific variable names (`characterConnections`), specific table types, specific cleanup logic. This is a GOOD pattern but should be a principle, not a template.

7. **R6 NPC Creation** (lines 1594-1784): Over 190 lines of verbatim R6 rig creation code, including exact CFrame values for all 6 Motor6D joints, exact Size vectors for all 7 body parts. While these values ARE correct R6 standards, embedding them as verbatim code means the model cannot reason about alternative rig configurations (R15, custom proportions, stylized characters).

8. **PathfindingService patterns** (lines 1807-1885): Complete pathfinding code including CreatePath, ComputeAsync, MoveToFinished waypoint following, Blocked event handling. These are reference-quality patterns but embedded as code-to-copy rather than principles-to-apply.

9. **AI State Machine** (lines 1900-1976): Complete state machine architecture with literal code for state handlers, detection raycast, and spawning. Over 75 lines of template code.

10. **Surgical edit workflow** (lines 169-197): Complete run_code examples for string.find + string.sub editing. This is useful operational knowledge but presented as copy-paste templates.

11. **Verification patterns** (lines 774-793, 969-1010): Multiple complete verification scripts that get reproduced identically regardless of what was actually built.

**What the agent copies vs. what it should reason about:**

- COPIES: "Create a Script named GameManager in ServerScriptService with `--!strict`" using the exact Instance.new pattern from lines 214-229.
- SHOULD REASON: "This game needs a central controller. Given the architecture specifies [X services], I need a Script in ServerScriptService that initializes and coordinates them. Let me determine the appropriate structure for this specific game."

- COPIES: The GameStateBridge verbatim, including functions that may be irrelevant (getFlashlightStatus for a tycoon game).
- SHOULD REASON: "The computer-player needs to understand game state. What information is relevant for THIS game? A tycoon needs currency/upgrades/building state. A horror needs position/health/inventory/nearby-threats."

**Template locks found:**

- **Mandatory Infrastructure Checklist** (lines 396-445): Forces GameStateBridge, AgentControl, and Flashlight into every build regardless of relevance. The checklist structure ("STOP. READ THIS. This is not optional.") is so aggressive that the model will never skip these even when inappropriate.

- **Submission format** (lines 2373-2518): Five separate rigid output formats for Mode A/B/C/D/E. While pipeline compatibility requires markers (SCRIPTS CREATED:, READY FOR REVIEW), the internal structure is overly rigid and produces identical-looking reports regardless of what was built.

**Hardcoded values found:**

- Flashlight dimensions: `Vector3.new(0.5, 0.5, 2)` (line 639)
- SpotLight Brightness=8, Range=80, Angle=50 (lines 647-649)
- GameStateBridge URL: `http://localhost:8585` (line 489)
- Nearby objects radius: 30 studs (line 607)
- State update interval: 1 second (line 619)
- NPC WalkSpeed: 14 (line 1727)
- Detection range: 40 studs (line 1735)
- AI tick rate: 0.2 seconds (line 1928)

---

### luau-reviewer -- Scripting Diagnosis

**Scripting severity:** LOW

The luau-reviewer is one of the best-designed agents in the system. I read the full file (persisted output). Key observations:

The reviewer prompt is principle-driven, not template-driven. It describes WHAT to look for (security vulnerabilities, memory leaks, deprecated APIs, performance issues) through explanation of WHY these are problems, not through literal code examples of what bad code looks like.

**Minor hardcoded patterns found:**

- The reviewer does contain some specific code patterns for what "correct" looks like (e.g., the connection tracking pattern, the pcall retry pattern), but these are presented as "this is what the fix should look like" in the context of reviewing, not as templates to reproduce. This is appropriate -- a reviewer needs to know what correct code looks like to judge incorrect code.

- The output format (VERDICT: PASS/NEEDS FIXES) is intentionally rigid because Game Master parses it. This is pipeline compatibility, not over-scripting.

**What works well:**

- The role section is excellent -- "senior security engineer who has seen hundreds of hacked games" activates the right paranoia level without scripting specific behaviors.
- The review categories (Security, Memory, Performance, Logic, Structure) are principle-based with explained reasoning.
- The severity system (Critical, Serious, Moderate) is well-defined with clear criteria.

**Verdict:** The reviewer needs no de-scripting. It is operating as intended.

---

### world-builder -- Scripting Diagnosis

**Scripting severity:** HIGH

The world-builder prompt is approximately 1698 lines, with roughly 50% being literal Lua code blocks.

**Hardcoded code blocks found:**

1. **Lighting setup** (lines 220-253): A complete lighting configuration script that destroys Atmosphere, Sky, BloomEffect, ColorCorrectionEffect, SunRaysEffect, DepthOfFieldEffect and sets specific values (ClockTime=14, Brightness=2, Ambient=RGB(138,138,138)). This runs identically every time regardless of genre. A bright outdoor obby gets the same lighting setup as a dark horror game.

2. **Room folder creation** (lines 357-369): Verbatim pattern for creating Map folder and room subfolder.

3. **Part creation pattern** (lines 374-398): Complete floor + wall creation with specific material (Slate), specific color (RGB 42,42,42), specific positions. These specific values bleed into every build.

4. **Wall construction with doorway gaps** (lines 408-454): A complete 46-line example with hardcoded positions, sizes, materials, and colors from a specific game ("CortexChamber", "EastWall_A", "EastWall_B", SmoothPlastic, RGB(74,42,58)). This is THE most harmful code block in the world-builder -- every wall construction will echo these specific dimensions and color values.

5. **Door creation pattern** (lines 458-483): Complete door creation with specific name ("F2_HubToBoiler"), specific attributes, specific PathfindingModifier. Hardcoded tag name "InteractiveDoor" and attribute name "DoorId".

6. **Key creation pattern** (lines 489-517): Complete key creation with specific game-specific values ("Key_Tongue", "Tongue" KeyType, specific RGB colors for a body-horror themed game).

7. **Fragment/Collectible creation** (lines 523-557): Complete fragment creation with a specific lore text from a specific game ("I drew the throat first. The esophagus followed naturally.").

8. **Passable entrance pattern** (lines 563-582): Complete entrance creation with specific room names from a previous game.

9. **Crawl passage pattern** (lines 594-622): Complete passage creation with specific room names.

10. **Special structure placement** (lines 624-657): Incinerator example with game-specific values.

11. **Decorative elements** (lines 663-683): Neon vein creation with game-specific tag ("F3Vein").

12. **Prop/furniture creation** (lines 698-744): Complete drafting table creation with multiple parts, specific to one game.

13. **Invisible trigger pattern** (lines 748-775): Multiple trigger types from a specific game ("SeverancePoint", "BrainstemCorridor").

14. **ContractionWall, PeristalsisPipe patterns** (lines 777-824): Game-specific patterns that will confuse the model when building a tycoon or obby.

15. **Lighting pattern** (lines 828-875): Complete lighting creation with specific positions from one game.

16. **CameraPoint pattern** (lines 878-914): Complete CameraPoint creation with specific room names.

17. **SpawnLocation pattern** (lines 924-936): Complete SpawnLocation creation with specific coordinates.

18. **Standard verification** (lines 944-1041): Nearly 100 lines of verification Lua code with game-specific tag names hardcoded into the check list (lines 991-994: "ContractionWall", "PeristalsisPipe", "FloodGate", "BrainstemTile", "BrainstemDebris", "BrainstemGate", "SeverancePoint", "F3Light", "F3Vein").

19. **Floor-wide verification** (lines 1174-1298): Over 120 lines of verification code with the same game-specific tags hardcoded again.

**What the agent copies vs. what it should reason about:**

- COPIES: Lighting setup that destroys all post-processing effects and sets ClockTime=14. Every game starts with identical lighting regardless of genre.
- SHOULD REASON: "This is a [genre] game. The architecture specifies [lighting mood]. I need to configure lighting to support that mood. For horror: low ClockTime, dark Ambient. For obby: bright ClockTime, high Ambient."

- COPIES: Wall construction with specific materials (SmoothPlastic) and colors (RGB 74,42,58) from the body-horror game "The Gullet."
- SHOULD REASON: "The architecture specifies [material] and [color] for this room's walls. Let me use those values."

- COPIES: Verification scripts that check for "BrainstemTile", "PeristalsisPipe", "F3Vein" -- tags from one specific game.
- SHOULD REASON: "I need to verify all tagged objects exist. Let me check for the tags specified in THIS game's architecture."

**Hardcoded values found:**

- Lighting: ClockTime=14, Brightness=2, Ambient=RGB(138,138,138), ExposureCompensation=0.2
- Wall color: RGB(74,42,58) (a flesh-pink specific to The Gullet)
- Wall material: SmoothPlastic (organic theme from The Gullet)
- Door size: 5x7x0.5 studs
- Key size: 1.2x1.2x1.2 studs, Ball shape
- Light brightness: 0.5, Range: 18
- Light color: RGB(128,96,64) -- warm amber
- Neon vein size: 0.3x0.3x14 studs
- CameraPoint FOV: 90 (general) or 65 (small rooms)

**Template locks found:**

- **Delivery format** (lines 1629-1697): Two rigid templates (Floor Build and Addition/Detail Build) that force the same sections regardless of what was built. The TAGGED OBJECTS section will always reference tags even when the game has no tag system.

- **Verification tag lists** (lines 991-994, 1196-1201): Hardcoded lists of tags to check that include game-specific tags from The Gullet. A new game with different tags will pass verification even if its actual tags are missing, because the check list doesn't know about them.

---

### general-purpose-luau-notes.md -- Scripting Diagnosis

**Scripting severity:** MEDIUM (but different in nature)

This file is 557 lines and is fundamentally different from the agent prompts -- it is a knowledge base document, not an agent prompt. It exists to compensate for the lack of the dedicated luau-scripter prompt when a general-purpose agent handles scripting tasks.

**What works well:**

- The "Known Failure Patterns" section (lines 22-262) is genuinely useful diagnostic knowledge, organized by root cause rather than by symptom. Each pattern explains WHY the failure happens, not just WHAT to do.
- The "Root Causes" summary table (lines 536-551) correctly identifies all problems as TYPE 2 (context/information).
- The three-phase approach for integration features (Read, Plan, Build) is principle-based and well-reasoned.

**What is over-scripted:**

- The "Effective Task Prompt Template" (lines 267-332) is a literal template to copy-paste into task prompts. This is appropriate for a knowledge document (it is literally instructions for Game Master on how to construct prompts), but the template itself contains hardcoded patterns that will be reproduced verbatim.

- The UI creation examples (lines 428-458) include specific values (DisplayOrder=15, BackgroundColor3=RGB(20,20,20), CornerRadius=6) that will bleed through to actual output.

**Verdict:** This file serves its purpose as a knowledge document. It is not an agent prompt and should not be judged by the same criteria. The literal examples are appropriate here because this file is instructions for Game Master, not instructions for the model to embody. Minor cleanup could remove the most specific hardcoded values, but the file is fundamentally well-designed.

---

## Mission 2: De-Template Diagnosis and Rewrites (roblox-architect, story-teller)

### roblox-architect -- Template Diagnosis

**Template severity:** LOW

After reading the complete architect prompt (~1388 lines), my diagnosis: **the roblox-architect is NOT significantly over-templated.** What might look like rigid structure is actually well-designed adaptive architecture.

**Rigid structures found -- that are actually justified:**

1. **Task type identification (TYPE A/B/C)**: Not rigidity -- a legitimate decision tree that routes the agent into fundamentally different workflows.

2. **TYPE C sub-flavors (SPATIAL/SYSTEMIC/HYBRID)**: One of the BEST parts of the prompt. Prevents the #1 failure mode of feature additions.

3. **"Thinking before work" sections**: Extensive but NOT templated. Lists of QUESTIONS to consider, not answers to reproduce.

4. **Self-review checklists**: Perspective-shift exercises, not rigid checklists.

**Actual template concerns addressed in rewrite (all minor):**

1. **Genre descriptions**: "how to make unique" examples replaced with open-ended uniqueness questions that force genuine creative exploration rather than anchoring on provided ideas.

2. **Service Architecture Patterns**: Disclaimer strengthened from "baseline" to explicit guidance that every game's architecture should emerge from its specific needs, with the pattern presented as "typical" rather than "standard."

3. **Priority #2 (Systemic precision)**: Specific difficulty-system example values removed. The priority now teaches the LEVEL of precision needed through principle rather than through a specific example that could become an anchor.

### roblox-architect -- REWRITE DELIVERED

**File:** `C:\claudeblox-git\.claude\agents\roblox-architect.md`

**What changed and why:**

| Section | Change | Why |
|---------|--------|-----|
| Genres section header | "UNDERSTANDING, NOT LIMITATION" -> "CREATIVE FUEL, NOT FORMULAS" | Stronger framing that these are starting points for exploration |
| Genre descriptions | Replaced "how to make unique: [specific ideas]" with "the uniqueness question: [open-ended prompt]" | Prevents anchoring on provided twist ideas. Forces the architect to discover novel angles rather than selecting from a menu |
| Service Architecture intro | Added explicit paragraph about architecture emerging from game needs, not from template reproduction | Mitigates the risk of every game getting identical script organization |
| Service Architecture header | "Standard structure" -> "Typical structure (adapt freely)" | Subtle but important: "standard" implies "always use this," "typical" implies "this is common but not required" |
| Priority #2 | Removed inline difficulty-system code example. Replaced with principle statement about matching precision level | The example was pedagogically excellent but risked becoming an anchor. The principle communicates the same standard without providing copyable field names |
| Priority #3 | Removed inline Config example. Replaced with principle statement | Same reasoning as Priority #2 |
| Priority #6 | Removed specific room/data examples. Kept the core principle | The paired examples were good illustrations but the principle is clear without them |
| Constraints | "Never leave vague descriptions" simplified | Removed specific room/data examples from the constraint, keeping the principle |
| Thinking section (TYPE A) | Removed material-meaning parenthetical "(Concrete = neglect, SmoothPlastic = clinical, CorrodedMetal = decay)" | These specific meanings bleed into every game. The architect should determine what each material means for THIS game |
| em-dash cleanup | Replaced all "---" with "--" throughout | Consistency with the prompt's existing style |

**What was preserved (everything else):**

The entire structure, all 18 priorities, the complete TYPE A/B/C system, all thinking questions, all self-review perspectives, all output format templates, all constraints, all delivery criteria. The rewrite is deliberately conservative -- this agent was already the strongest in the system.

---

### story-teller -- Template Diagnosis

**Template severity:** MEDIUM

The prompt has genuine template problems in its technical implementation code, but the narrative craft sections are well-designed principles.

**What was templated (problems):**

1. **GUI creation code**: 54 lines of verbatim Lua with hardcoded visual values (DisplayOrder=20, BackgroundColor3=RGB(8,8,10), Font=Gotham, TextSize=18)
2. **NarrativeEngine script**: 160+ lines of verbatim Lua across two MCP calls, reproduced character-for-character every time
3. **Configuration constants**: CHAR_DELAY=0.05, HOLD_TIME=3.5, FADE_IN_TIME=0.4, etc. -- identical regardless of genre
4. **Narrative voice list**: 10 closed options presented as a menu, anchoring the model away from novel voices
5. **World audit script**: 65 lines of verbatim Lua reproduced identically

**What was correctly consistent (preserved):**

1. Technical architecture (NarrativeTrigger tag, magnitude polling, MaxVisibleGraphemes) -- pipeline compatibility
2. Brevity constraints (120 characters, 4 sentences) -- craft principles
3. Trigger placement strategy -- principles, not prescriptions
4. Output format markers -- Game Master parsing compatibility

### story-teller -- REWRITE DELIVERED

**File:** `C:\claudeblox-git\.claude\agents\story-teller.md`

**What changed and why:**

| Section | Change | Why |
|---------|--------|-----|
| WHO YOU ARE, paragraph 6 | Removed hardcoded "0.05 seconds per character" timing. Replaced with principle that timing is a creative decision per genre | Prevents locking every game into identical typewriter speed |
| WHO YOU ARE, paragraph 7 | Removed specific "DisplayOrder=20, positioned bottom-center" and "0.1 seconds" poll interval from the role description | These are implementation details, not identity. Moved to work cycle where they belong |
| Narrative voice section | Replaced closed list of 10 voices with open framework | The closed list anchored the model to these 10 options. Open framework encourages discovering a voice native to the game's world |
| GUI creation (Step 3) | Replaced 54-line verbatim Lua code block with principle-based guidance | The code block was reproduced character-for-character. New version explains the structure (ScreenGui > Frame > TextLabel) and teaches genre-adaptive styling rather than prescribing exact RGB values |
| Trigger creation (Step 4) | Replaced 38-line verbatim Lua code block with principle-based description | Same reasoning. The trigger creation pattern is simple enough to describe without literal code |
| NarrativeEngine (Step 5) | Replaced 160+ lines of verbatim Lua across two code blocks with structured description of what each part must contain | This is the most significant change. The new version describes the required components (NARRATIVES table, configuration constants, state tracking, display functions, proximity detection, polling loop) without providing copyable code. Critically, it introduces genre-adaptive timing ranges instead of fixed constants |
| Configuration constants | Replaced fixed values with genre-based ranges | CHAR_DELAY was locked at 0.05. Now: horror 0.06-0.08, adventure 0.04-0.06, action 0.03-0.04. Same for hold time and fade times |
| World audit (Step 1) | Replaced 65-line verbatim Lua code block with description of what the audit needs to discover | The audit script was reproduced identically. New version explains what data to gather without prescribing the exact Lua |
| Verification scripts (Steps 3-6) | Replaced verbatim verification Lua with descriptions of what to verify | Same pattern: describe the checks, let the model write the Lua |
| Brevity section | Removed "At 0.05s per character, 60 characters = 3 seconds" arithmetic | This arithmetic hardcoded the timing. With adaptive timing, the arithmetic changes per genre |

**What was preserved (critical elements):**

- The entire role section (paragraphs 1-5) -- excellent worldview that drives quality
- Pipeline-compatible output format markers (NARRATIVE DESIGNED:, TRIGGER ZONES:, READY FOR REVIEW)
- All hard constraints (120 chars, 4 sentences, no server code, no Touched events, etc.)
- All 9 priorities with full explanations
- The 7-step work cycle structure
- MCP reliability section (split script creation, verify-as-you-go)
- Trigger position calculation from audit data
- Self-critique and iteration step
- Pacing principles (density, silence as narrative choice)
- Composition principles (implication over explanation, specificity, no exposition, narrative arc)

**Prompt size change:** ~927 lines -> ~420 lines (55% reduction). The reduction comes entirely from removing verbatim Lua code. No craft principles, pipeline markers, or quality requirements were cut.

---

## Mission 3: CLAUDE.md vs ai-developer.md -- Duplication Report

### CLAUDE.md vs ai-developer.md -- Duplication Report

**Overlap severity:** LOW

After reading both files completely, the relationship is clear: **CLAUDE.md is the Game Master's operating system. ai-developer.md is a specialist agent's prompt.** They serve fundamentally different purposes with minimal overlap.

**Duplicated responsibilities:**

1. **ClaudeBlox system architecture diagram**
   - Found in CLAUDE.md (lines in "YOUR TEAM" and "REFERENCE" sections): Full pipeline description with all 18 agents, their roles, when to call them, what to verify.
   - Found in ai-developer.md (lines 427-455): A simplified pipeline diagram with only 8 agents listed.
   - **Assessment:** The ai-developer's version is OUTDATED and INCOMPLETE. It lists only 8 agents while CLAUDE.md lists 18. This is not a duplication problem -- it is an ai-developer maintenance problem. The ai-developer's architecture section should be updated OR replaced with a reference: "Read the full pipeline in CLAUDE.md."

2. **Agent design philosophy**
   - CLAUDE.md contains NO agent design philosophy. It describes WHAT each agent does and HOW to call them, not how to design their prompts.
   - ai-developer.md contains the complete agent design methodology (worlds, discourse, core/fine-tuning/constraints framework, TYPE 1/2/3 diagnosis).
   - **Assessment:** NO duplication. These are complementary, not overlapping.

3. **The "territory ownership" principle**
   - CLAUDE.md: Implicitly enforced through the team descriptions ("What it does:", "When to call:"). Each agent has a clear domain.
   - ai-developer.md: Explicitly stated as a design principle ("each subagent is the only one responsible for their domain").
   - **Assessment:** CLAUDE.md demonstrates it; ai-developer.md teaches it. This is not duplication -- it is the same principle operating at two different levels.

**Conflicting instructions:**

1. **Pipeline diagram**
   - CLAUDE.md shows: `architect -> scripter + builder (parallel) -> interior-designer -> detail-architect -> set-dresser -> sound-designer -> vfx-designer -> lighting-director -> art-director -> enemy-designer -> story-teller -> reviewer -> ui-designer -> playtester -> computer-player`
   - ai-developer.md shows: `architect -> scripter + builder (parallel) -> reviewer -> playtester -> computer-player`
   - **Conflict:** ai-developer's diagram is stale. It was never updated when the 10 new agents (interior-designer, detail-architect, set-dresser, sound-designer, vfx-designer, lighting-director, art-director, enemy-designer, story-teller, ui-designer) were added.
   - **Resolution:** Update ai-developer.md's architecture section to match CLAUDE.md, or remove it entirely and reference CLAUDE.md.

2. **Audience description**
   - CLAUDE.md: "audience: Roblox gamers" (line 455 of ai-developer section)
   - ai-developer.md: "Roblox audience (kids 7-15, 60% on mobile)" (line 101)
   - **Conflict:** Minor. ai-developer has more specificity. Neither is wrong.

**Unclear ownership:**

1. **Who decides agent prompts need updating?**
   - CLAUDE.md says ai-developer should "run in parallel (background) every time any other subagent is called" and be passed "the agent name, file path, what the agent just did, and any problems it had."
   - ai-developer.md says it receives tasks from Game Master in two forms (creating new, fixing existing).
   - **Assessment:** Ownership is clear: ai-developer owns prompt design. Game Master triggers it. No conflict.

2. **Pipeline verification after agent changes**
   - Neither file clearly specifies how to verify that a prompt change didn't break the pipeline. ai-developer says "check point by point" but doesn't describe end-to-end testing.
   - **Recommendation:** Add to ai-developer.md a note about pipeline compatibility verification: "After modifying an agent prompt, verify the agent's delivery format still contains the markers Game Master parses (VERDICT:, SCRIPTS CREATED:, WORLD BUILT:, etc.)."

**Recommendation:**

- **Keep in CLAUDE.md:** Everything. It is the Game Master's complete operating system and should remain self-contained.
- **Keep in ai-developer.md:** The entire agent design methodology (worlds, discourse, core design, TYPE 1/2/3 diagnosis, fine-tuning principles). This is specialist knowledge that does not belong in Game Master.
- **Update in ai-developer.md:** The pipeline architecture diagram (lines 427-455) is stale. Either update it to list all 18 agents or replace with: "See the full pipeline in CLAUDE.md. The current system has 18+ specialist agents."
- **Remove from ai-developer.md:** Nothing. The file is well-scoped and not over-long.

**Specific edits needed:**

1. ai-developer.md line 430-438: Update the architecture tree to include all agents, or add a note: "Note: this diagram shows the core pipeline. The full system includes additional specialist agents (interior-designer, detail-architect, set-dresser, sound-designer, vfx-designer, lighting-director, art-director, enemy-designer, story-teller, ui-designer) -- see CLAUDE.md for the complete pipeline."

2. ai-developer.md line 443-444: Update the pipeline order to match CLAUDE.md's full sequence.

---

## Priority Action List

Ordered by impact (highest first):

1. **DONE -- DE-SCRIPT world-builder: Remove game-specific code blocks.** Complete rewrite delivered. All 18+ literal Lua code blocks from "The Gullet" removed. Prompt reduced from ~1698 to 437 lines (74% reduction). File: `C:\claudeblox-git\.claude\agents\world-builder.md`

   | Section | Change | Why |
   |---------|--------|-----|
   | Lighting setup (lines 220-253) | Removed complete lighting script with hardcoded ClockTime=14, Brightness=2, Ambient=RGB(138,138,138). Replaced with principle: "Configure Lighting to values the architecture specifies (or genre-appropriate defaults)" | Every game got identical lighting regardless of genre |
   | Room folder creation (lines 357-369) | Removed verbatim pattern. Replaced with structural description of Map > RoomName > Walls/Floor/Ceiling hierarchy | Pattern is simple enough to describe without code |
   | Part creation patterns (lines 374-398) | Removed complete floor+wall code with specific Slate material and RGB(42,42,42). Replaced with principle-based build order | Specific material/color values bled into every build |
   | Wall construction with doorway gaps (lines 408-454) | Removed 46-line example with CortexChamber, SmoothPlastic, RGB(74,42,58). Preserved the CONCEPT of gap-based doorways as a principle with position math formulas | Most harmful code block -- flesh-pink colors appeared in every game |
   | Door creation (lines 458-483) | Removed complete door code with "F2_HubToBoiler" and hardcoded tags. Replaced with principle: "Create door BasePart with tags/attributes from architecture" | Game-specific names and tags anchored output |
   | Key/Fragment/Entrance/Passage patterns (lines 489-622) | Removed all 5 game-specific creation patterns ("Key_Tongue", specific lore text, specific room names). Replaced with generic principle for tagged interactive objects | All values from "The Gullet" body-horror theme |
   | Special structures (lines 624-657) | Removed incinerator example with game-specific values | Game-specific |
   | Decorative elements (lines 663-683) | Removed neon vein creation with "F3Vein" tag | Game-specific tag |
   | Prop/furniture (lines 698-744) | Removed complete drafting table multi-part creation | Game-specific prop |
   | Invisible triggers (lines 748-824) | Removed "SeverancePoint", "BrainstemCorridor", ContractionWall, PeristalsisPipe patterns | Game-specific mechanics from The Gullet |
   | Lighting placement (lines 828-875) | Removed complete lighting with specific positions | Hardcoded coordinates |
   | CameraPoint/SpawnLocation (lines 878-936) | Removed with specific room names and coordinates. Kept as principles | Game-specific positions |
   | Standard verification (lines 944-1041) | Removed 100-line script with hardcoded tag lists (BrainstemTile, F3Vein, etc.). Replaced with: "Verify all tags listed in THIS game's architecture" | Checked for irrelevant tags, missed actual game tags |
   | Floor-wide verification (lines 1174-1298) | Removed 120-line verification with same hardcoded tags | Same problem as standard verification |
   | Detail/Addition verification scripts | Removed scripts with hardcoded room names (DraftingChamber, StorageRoom, IncubationTank, PrayerCloset) | Game-specific room names |

   **What was preserved:**
   - Entire role section (all paragraphs, unchanged)
   - CanCollide discipline section (principle-based, not code-based)
   - MCP reliability section (batching, silent failures, timeout prevention, verify-after-every-room)
   - Task type identification (Floor/Addition/Detail)
   - Build order planning (10-step floor build sequence)
   - Wall construction math reference (position formulas for gaps)
   - Material behavior notes and cylinder orientation notes
   - Multi-floor guidance
   - All 9 priorities, all 11 constraints
   - Delivery format templates (Floor Build and Addition/Detail Build)

2. **DONE -- DE-SCRIPT luau-scripter: Replace verbatim code with reference patterns.** Complete rewrite delivered. All embedded Lua code blocks removed. Infrastructure scripts now point to reference files at `C:/claudeblox/scripts/`. Prompt reduced from ~2539 to 553 lines (78% reduction). File: `C:\claudeblox-git\.claude\agents\luau-scripter.md`

   | Section | Change | Why |
   |---------|--------|-----|
   | GameStateBridge (lines 477-623) | Removed embedded 146-line script. Replaced with: "Read from `C:/claudeblox/scripts/GameStateBridge.lua`" | Embedded version was STALE -- actual reference file is 513 lines with direction calculation, level info, death tracking, enemy detection, agent command relay that the embedded version lacked |
   | Flashlight (lines 631-682) | Removed 52-line embedded script. Replaced with principle description of what a flashlight needs (Tool with Handle, SpotLight, toggle LocalScript) | Identical flashlight in every game regardless of mechanic design |
   | Creating Scripts patterns (lines 214-265) | Removed 3 verbatim code blocks for Instance.new(Script/LocalScript/ModuleScript). Kept as principle | MCP operations are simple enough to describe |
   | Folder/RemoteEvent creation (lines 270-323) | Removed 4 code blocks including batch RemoteEvent with hardcoded names ("PlayerAction", "UpdateUI", "GameStateChanged") | Hardcoded event names bled into output |
   | Project structure check (lines 329-353) | Removed getStructure function. Kept as principle | Reproduced identically every time |
   | Connection safety (lines 720-743) | Removed complete code block with specific variable names. Kept as principle with reasoning | Good pattern but should be reasoned about, not copied |
   | R6 NPC Creation (lines 1594-1784) | Removed 190 lines of rig code with CFrame values. Replaced with: "Enemy NPC rigs and AI are now enemy-designer's territory" | Territory overlap -- enemy-designer owns this domain |
   | PathfindingService patterns (lines 1807-1885) | Removed 78 lines of pathfinding code | Enemy-designer's territory |
   | AI State Machine (lines 1900-1976) | Removed 76 lines of state machine code | Enemy-designer's territory |
   | Surgical edit workflow (lines 169-197) | Removed verbatim run_code examples. Kept surgical vs. full rewrite decision framework as principle | Templates not needed for simple string operations |
   | RemoteEvent validation (lines 2150-2171) | Removed code block. Kept as principle in domain instructions | The principle is clear; the code anchors specific patterns |
   | Type checking examples (lines 2183-2201) | Removed code blocks. Kept rules | Rules are sufficient |
   | Memory management (lines 2212-2251) | Removed playerData/playerConnections pattern. Kept as principle | Anchors specific variable names |
   | DataStore (lines 2258-2281) | Removed saveWithRetry pattern. Kept as principle | Anchors specific retry implementation |
   | Cross-script communication (lines 2310-2325) | Removed code blocks. Kept principles | Simple enough to describe |
   | Duplicate reporting formats | Consolidated Modes B, D, E from appearing twice each (once in mode description, once in submission format) to single instances | Pure redundancy |
   | Verification code blocks (lines 774-793, 969-1010) | Removed complete verification scripts | Reproduced identically regardless of what was built |

   **What was preserved:**
   - Entire role section (philosophy, prevention mindset, code-as-documentation, --!strict, extending code, cross-cutting features)
   - Work context (pipeline position, territory boundaries, enemy-designer exception, 5 task types)
   - MCP tools section (run_code, insert_model)
   - MCP reliability section (truncation detection, chunked writes, silent failures, timeout, reading long scripts, string replacement)
   - Surgical vs. full rewrite decision framework
   - All 5 modes (A/B/C/D/E) with step structures
   - --!strict compatibility rules
   - All 10 priorities
   - All domain instructions (client-server security, memory management, DataStore, mobile input, cross-script communication) -- as principles
   - All limitations
   - All 5 submission format templates (with pipeline markers)
   - REMEMBER section

   **Key infrastructure change:** GameStateBridge, AgentControl, EditorLighting, FirstPersonCamera now all point to reference files at `C:/claudeblox/scripts/` instead of embedding code. This means the scripter will always use the current, maintained version of these files rather than a stale embedded copy.

3. **DONE -- DE-SCRIPT luau-scripter: Make GameStateBridge adaptive.** Addressed as part of the item 2 rewrite. The embedded 146-line GameStateBridge (which was horror-game-specific with flashlight status, collectibles, doors) has been removed. The prompt now instructs the scripter to: "Read the reference implementation at `C:/claudeblox/scripts/GameStateBridge.lua`. Use it as the canonical base. Adapt the data it sends to match what THIS game needs the computer-player to know about." The actual reference file at `C:\claudeblox-git\scripts\GameStateBridge.lua` (513 lines) is more comprehensive but still somewhat horror-oriented -- further adaptation of the reference file itself is a separate concern (the reference file is not part of the agent prompt system).

4. **DONE -- DE-SCRIPT story-teller.** Complete rewrite delivered. Replaced 160+ lines of verbatim Lua with principle-based descriptions. Made configuration genre-adaptive. Replaced closed voice list with open framework. Prompt reduced from ~927 to ~420 lines (55% reduction). File: `C:\claudeblox-git\.claude\agents\story-teller.md`

5. **DONE -- DE-TEMPLATE roblox-architect.** Complete rewrite delivered. Conservative changes to an already-strong agent: replaced hardcoded genre twist examples with open-ended uniqueness questions, strengthened service architecture flexibility, removed specific data-structure examples from priorities that risked becoming anchors. File: `C:\claudeblox-git\.claude\agents\roblox-architect.md`

6. **DONE (absorbed into item 1) -- UPDATE world-builder verification scripts.** The hardcoded tag lists (BrainstemTile, F3Vein, ContractionWall, etc.) were removed as part of the world-builder rewrite. Verification now instructs: "Check for every tag listed in the architecture's tagged objects section" -- dynamic rather than hardcoded.

7. **UPDATE ai-developer.md pipeline diagram.** Replace the outdated 8-agent diagram with the full 18-agent pipeline from CLAUDE.md. **Impact: LOW.** The ai-developer is rarely called and the stale diagram has minimal practical impact, but it represents technical debt.

8. **DONE (absorbed into item 2) -- EXTRACT hardcoded Lua patterns from luau-scripter to reference files.** The luau-scripter rewrite addresses this by pointing to existing reference files at `C:\claudeblox-git\scripts\` (GameStateBridge.lua, AgentControl.lua, EditorLighting.lua, FirstPersonCamera.lua) instead of embedding code. No new reference files needed to be created -- they already existed.

9. **KEEP luau-reviewer unchanged.** It is principle-based and correctly calibrated. Changes would regress quality. **Impact: Positive (preventing harm).**

---

## Appendix: Files Read

All files were read in full (with chunked reads for files exceeding the 25000-token limit):

- `C:\claudeblox-git\.claude\agents\luau-scripter.md` (2539 lines, read in 5 chunks)
- `C:\claudeblox-git\.claude\agents\luau-reviewer.md` (full, persisted output)
- `C:\claudeblox-git\.claude\agents\world-builder.md` (1698 lines, read in 4 chunks)
- `C:\claudeblox-git\.claude\agents\general-purpose-luau-notes.md` (557 lines, full)
- `C:\claudeblox-git\.claude\agents\roblox-architect.md` (full, ~1388 lines)
- `C:\claudeblox-git\.claude\agents\story-teller.md` (full, ~927 lines)
- `C:\claudeblox-git\.claude\agents\ai-developer.md` (456 lines, full)
- `C:\claudeblox-git\CLAUDE.md` (read as system context)
- `C:\claudeblox-git\scripts\GameStateBridge.lua` (513 lines, full -- discovered reference file)
- `C:\claudeblox-git\scripts\AgentControl.lua` (363 lines, full -- discovered reference file)

## Appendix: Files Modified

- `C:\claudeblox-git\.claude\agents\roblox-architect.md` -- complete rewrite (conservative, LOW severity changes)
- `C:\claudeblox-git\.claude\agents\story-teller.md` -- complete rewrite (significant de-scripting, ~927 -> ~420 lines, 55% reduction)
- `C:\claudeblox-git\.claude\agents\world-builder.md` -- complete rewrite (major de-scripting, ~1698 -> 437 lines, 74% reduction)
- `C:\claudeblox-git\.claude\agents\luau-scripter.md` -- complete rewrite (major de-scripting, ~2539 -> 553 lines, 78% reduction)
- `C:\claudeblox-git\gamemaster\audit-report.md` -- this report (updated with all rewrite details)
