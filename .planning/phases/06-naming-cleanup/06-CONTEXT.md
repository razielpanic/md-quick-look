# Phase 6: Naming Cleanup - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace all legacy "spotlighter" references throughout the codebase, Xcode project structure, and documentation with consistent "MD Quick Look" naming and "com.rocketpop.MDQuickLook" bundle identifiers. This establishes the proper public identity before v1.1 release.

**Scope:** Renaming only — no functionality changes, no new features.

</domain>

<decisions>
## Implementation Decisions

### Bundle Identifiers & Naming Scheme
- **Domain:** `com.rocketpop.*` (Rocketpop Laboratories brand identity)
- **Main app bundle ID:** `com.rocketpop.MDQuickLook` (PascalCase)
- **Extension bundle ID:** `com.rocketpop.MDQuickLook.Extension` (nested under main app, follows Apple's App Extension convention)
- **Rationale:** Professional branding under Rocketpop Labs, following Apple's nested extension pattern

### User-Facing Name Formatting
- **Canonical display name:** "MD Quick Look" (with space, both words capitalized)
- **MD formatting:** Always uppercase "MD" in all contexts (never "Md" or "md")
- **Follows:** Apple's "Quick Look" style guide (two words, capitalized)
- **Used in:** App menus, window titles, About window, documentation user-facing text

### File & Directory Naming
- **Xcode project file:** `MDQuickLook.xcodeproj` (PascalCase, no spaces)
- **GitHub repository:** `md-quick-look` (kebab-case, follows GitHub conventions)
- **Internal code style:** `MDQuickLook` prefix for Swift types/classes (PascalCase)
- **Target names:** Claude's discretion (follow Xcode/Swift conventions)
- **Swift source files:** Claude's discretion (balance consistency with readability)

### Git History & Transition
- **Commit strategy:** Single atomic commit for all renaming changes
- **Repository rename:** Yes — rename GitHub repo from `md-spotlighter` to `md-quick-look`
- **Xcode project rename:** Claude's discretion (use safest approach that preserves build)
- **Git tagging:** No special tag needed (regular commit, part of v1.1 work)

### Claude's Discretion
- Exact approach for Xcode project renaming (in-place vs manual)
- Target naming details (follow Xcode conventions while staying consistent)
- Swift file naming strategy (balance prefixes with context-appropriate shorter names)
- Handling edge cases in comments or documentation during transition
- Order of operations within the single atomic commit

</decisions>

<specifics>
## Specific Ideas

- Apple's official stylization is "Quick Look" (two words, both capitalized) — follow that pattern
- User's Apple ID is under "razielpanic" but business operates as "Rocketpop Laboratories" with rocketpop.com domain
- GitHub redirects automatically preserve old links when renaming repository
- Single atomic commit provides clean before/after boundary for review

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope (renaming only, no feature additions).

</deferred>

---

*Phase: 06-naming-cleanup*
*Context gathered: 2026-02-02*
