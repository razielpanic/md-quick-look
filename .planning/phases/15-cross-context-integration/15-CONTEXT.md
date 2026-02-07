# Phase 15: Cross-Context Integration - Context

**Gathered:** 2026-02-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify all v1.2 features (YAML front matter, layout/sizing, table rendering, task list checkboxes) work together correctly across every Quick Look presentation context. Fix any rendering issues found. This is a verification and integration phase, not a feature-building phase.

</domain>

<decisions>
## Implementation Decisions

### Verification approach
- Automated snapshot test suite that persists for future regression testing
- Render markdown to image/view in a test harness, compare pixel output against saved baselines
- On mismatch: attempt one automated fix iteration, then warn for human review if it persists
- Issue tracking via descriptive git commit messages — no separate issues log needed

### Issue handling policy
- Zero tolerance for visible defects — any rendering problem must be fixed before v1.2 ships
- This phase can apply minimal targeted patches to code from previous phases (11-14) to resolve integration issues
- Major rework of a previous phase's feature should become a new phase, not be absorbed here

### Context coverage
- Test all three main Quick Look contexts: spacebar popup, Finder column preview pane (narrow), fullscreen
- Test at multiple representative widths matching the existing WidthTier breakpoints (e.g., ~260px narrow, ~500px medium, ~800px wide)
- Single comprehensive markdown test file that exercises all v1.2 features together (YAML front matter + tables + task lists + regular content)
- Test both light mode and dark mode — snapshots for each context in both appearances

### Claude's Discretion
- Snapshot test target placement (existing vs separate test target)
- Specific snapshot testing library/approach
- Exact pixel tolerance for snapshot comparison
- Test file content details beyond the required feature coverage

</decisions>

<specifics>
## Specific Ideas

- User wants an automated verification suite that stays in the project for future tests — not throwaway verification
- The test matrix is: 3 contexts x multiple widths x 2 appearances (light/dark)
- Success criteria from roadmap requires testing with "the same file" across contexts

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 15-cross-context-integration*
*Context gathered: 2026-02-07*
