---
title: Configuration
order: 6
---

# Configuration

MoonBlox sites are configured via `moonblox.json`:

```json
{
  "input": "posts",
  "output": "dist",
  "components": "./components",
  "theme": "blog"
}
```

## Fields

| Field | Default | Description |
|-------|---------|-------------|
| `input` | `"posts"` | Directory for markdown content |
| `output` | `"dist"` | Build output directory |
| `components` | `"./components"` | User component directory |
| `theme` | `"blog"` | Theme name (`"blog"` or `"docs"`) |

## Theme: Blog

The `blog` theme provides:
- Reverse-chronological article listing
- Date-based sorting
- Tag-based metadata

## Theme: Docs

The `docs` theme provides:
- Hierarchical content organization
- Sidebar navigation
- Manual ordering via `order` field
