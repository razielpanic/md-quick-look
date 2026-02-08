# Quick Task 002: Investigate v1.2 Missing GitHub Release — Summary

**Completed:** 2026-02-08
**Type:** Investigation (no code changes)

## Findings

### Root Cause: No release infrastructure existed during v1.2 completion

The `complete-milestone` workflow has a `github_release` step, but it's **conditional on `release` config existing in `.planning/config.json`**. At the time of v1.2 milestone completion (commit `592c592`), config.json had **no `release` key** — only `workflow` settings. The `release` config was added to the working tree later but never committed.

This means the version bump, build, package, and GitHub release steps were all correctly **skipped** by the workflow — not an error, but by design (no config = no release).

### How v1.1 Got a Release

The v1.1 release was **not** created by `complete-milestone`. It was created during **Phase 9: Distribution Packaging** — a dedicated development phase with 2 plans:
- **09-01**: DMG creation with create-dmg
- **09-02**: Release notes & GitHub release v1.1.0

The release was built and published as part of the planned development work, with the `gh release create` command run during plan 09-02 (commit `21dcd42`). The `complete-milestone` workflow then archived everything afterward.

### Why v1.2 Had No Release

v1.2 was a rendering-focused milestone (phases 11-15: YAML, Layout, Tables, Task Lists, Testing). **No distribution phase was included** in the v1.2 roadmap because the focus was on rendering polish, not packaging. The expectation was apparently that the existing v1.1 DMG distribution was sufficient, or that release packaging would happen separately.

### Evidence

| Item | v1.1 | v1.2 |
|------|------|------|
| Distribution phase? | Yes (Phase 9) | **No** |
| `release` config in config.json? | No | **No** (added later, uncommitted) |
| `complete-milestone` → `github_release`? | Skipped (no config) | Skipped (no config) |
| GitHub Release created by? | Phase 09-02 executor | **Nobody** |
| Git tag? | `v1.1` (local) + `v1.1.0` (release) | `v1.2` (local + remote) |

### config.json at v1.2 completion

```json
{
  "project_name": "md-quick-look",
  "workflow": {
    "mode": "yolo",
    "depth": "standard",
    "parallelization": true,
    "commit_docs": true
  }
}
```

No `release` key. The release config currently in the working tree was never committed:

```diff
+  "release": {
+    "enabled": true,
+    "version_files": [...],
+    "build_command": "make build",
+    "package_command": "create-dmg '...' --overwrite",
+    "artifact_glob": "*.dmg"
+  }
```

### What Needs to Happen

1. **Commit the `release` config** so future milestones automatically build + release
2. **Create v1.2 release manually** (or wait until v1.3 ships, which will include it via the now-configured release pipeline):
   - Version bump Info.plist + project.pbxproj to 1.2.0
   - `make build`
   - `create-dmg 'build/Build/Products/Release/MD Quick Look.app' --overwrite`
   - `gh release create v1.2 --title "v1.2 — Rendering Polish & Features" --notes "..." *.dmg`

### Conclusion

**Not human error.** The v1.1 release was created by a dedicated distribution phase (Phase 9). The v1.2 milestone had no such phase, and the `complete-milestone` workflow correctly skipped release creation because the `release` config didn't exist in config.json. The release config was added to the working tree afterward but never committed, so it had no effect.

## Files Modified

None — investigation only.
