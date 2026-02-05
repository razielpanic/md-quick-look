# Phase 9: Code Signing & Notarization - Context

**Gathered:** 2026-02-05
**Status:** Phase removed from v1.1

<domain>
## Phase Boundary

Originally: configure code signing and notarization for secure macOS distribution. After discussion, this phase is being **removed from v1.1** entirely. Signing will be deferred to a future milestone when organization enrollment is established.

</domain>

<decisions>
## Implementation Decisions

### Distribution approach
- Ship unsigned (ad-hoc signed via Xcode default) for v1.1
- No paid Apple Developer Program enrollment for now
- Users will see "unidentified developer" Gatekeeper warning — documented in README troubleshooting (right-click > Open)

### Why not sign now
- Personal enrollment exposes legal name in macOS UI (Gatekeeper dialogs, certificate, System Settings)
- Organization enrollment requires registered business entity + D-U-N-S number
- Ad-hoc and self-signed certificates provide zero benefit for GitHub downloaders — Gatekeeper blocks them identically to unsigned
- Cost-benefit doesn't justify $99/year until org enrollment is ready

### Phase 9 disposition
- Remove Phase 9 from v1.1 roadmap entirely
- Defer code signing & notarization to future milestone (when org enrollment is established)
- Phase 10 no longer depends on Phase 9

### Phase 10 impact
- Phase 10 slimmed down: promote existing v1.1-beta pre-release to full v1.1 release
- ZIP distribution (not DMG) — .zip of .app bundle is sufficient
- No signing step in packaging workflow

</decisions>

<specifics>
## Specific Ideas

- Mac App Store naming restrictions are more restrictive than expected — another reason to defer Store distribution
- Want brand/org name in macOS UI, not personal legal name — drives the org enrollment requirement

</specifics>

<deferred>
## Deferred Ideas

- Apple Developer Program Organization enrollment — future milestone prerequisite
- Developer ID code signing & notarization — future milestone (after org enrollment)
- Mac App Store distribution — deferred indefinitely (naming restrictions)
- DMG packaging with professional layout — deferred to signed release milestone

</deferred>

---

*Phase: 09-code-signing-notarization*
*Context gathered: 2026-02-05*
