---
created: 2026-02-06T12:20
title: Fix dark mode background color inconsistency across sections
area: rendering
files:
  - MDQuickLook/MDQuickLook Extension/MarkdownLayoutManager.swift
  - MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift
---

## Problem

In light mode, background colors for all sections (YAML front matter, blockquotes, code blocks) look consistent and match well. In dark mode, the background colors vary noticeably between sections — YAML front matter and blockquotes use different fill levels that don't harmonize in dark appearance.

Current fill colors:
- Front matter: `.tertiarySystemFill` (LayoutManager rounded rect)
- Code blocks: `.secondarySystemFill` (LayoutManager rect)
- Blockquotes: `.quaternarySystemFill` (LayoutManager rect)

These semantic colors have different opacity/contrast ratios in dark mode vs light mode, causing visual inconsistency.

Also applies to preview pane context (narrow column view) where the issue may be more pronounced.

## Solution

TBD — audit all background fill colors in dark mode, possibly unify to a single fill level or choose fills that have better dark mode harmony. May also need to check the text container background color interaction.
