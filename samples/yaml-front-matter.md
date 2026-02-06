---
title: Sample Document
author: Jane Smith
date: 2024-03-15
tags: [swift, markdown, yaml]
categories: ["tutorial", "reference"]
published: true
version: 1.2.3
description: A sample document for testing YAML front matter rendering
---

# Sample Document

This document has YAML front matter that should appear as a styled metadata section above this heading.

## Features

- The front matter section should have a distinct background
- Keys should be bold, values should be in secondary color
- List values like tags should show as comma-separated text
- The `---` delimiters should NOT appear as horizontal rules

## Code Example

```yaml
---
title: This is inside a code block
---
```

This YAML inside a code block should render as code, NOT be extracted as front matter.

> This is a blockquote to verify no regression in existing rendering.

**Bold text**, *italic text*, and `inline code` should all still work correctly.
