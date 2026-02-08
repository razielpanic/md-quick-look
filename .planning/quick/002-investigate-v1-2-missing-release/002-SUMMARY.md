# Quick Task 002: Investigate v1.2 Missing GitHub Release — Summary

**Completed:** 2026-02-07
**Type:** Investigation (no code changes)

## Findings

### Root Cause: Human Error — `gh release create` step was skipped

The v1.2 milestone completion created and pushed a git tag (`v1.2`) but did not create a GitHub Release with DMG asset. This was a manual oversight — the release creation step was simply not performed.

### Evidence

| Item | v1.1 (working) | v1.2 (missing) |
|------|-----------------|----------------|
| Git tag | `v1.1.0` (local + remote) | `v1.2` (local + remote) |
| GitHub Release | Yes — "v1.1.0 — First Public Release" | **No** |
| DMG asset | Yes — MD.Quick.Look.1.1.0.dmg (3.7 MB) | **No** |
| Tag format | `v1.1.0` (with patch) | `v1.2` (no patch) |

### Tag Details

The v1.2 tag exists and points to commit `592c592` with a proper annotated tag message:

```
v1.2 Rendering Polish & Features

Delivered: Width-adaptive rendering with YAML front matter display, responsive tables,
task list checkboxes, and cross-context snapshot testing.
```

### What Needs to Happen

To create the v1.2 release:

1. Build the DMG: `make build && create-dmg 'build/Build/Products/Release/MD Quick Look.app' --overwrite`
2. Create release: `gh release create v1.2 --title "v1.2 — Rendering Polish & Features" --notes "..." "MD Quick Look 1.2.0.dmg"`

**Note:** Consider whether to use `v1.2` or `v1.2.0` tag format. The existing tag is `v1.2`. Creating a release for an existing tag works fine with `gh release create v1.2`.

### Secondary Finding: Tag Format Inconsistency

- v1.0 tag: `v1.0`
- v1.1 tag: `v1.1` (but release used `v1.1.0`)
- v1.2 tag: `v1.2`

The v1.1 release created a separate `v1.1.0` tag for the GitHub Release, diverging from the `v1.1` tag created during milestone completion. This is a minor naming inconsistency but doesn't cause issues.

## Files Modified

None — investigation only.
