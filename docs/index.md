---
title: MoonBlox Documentation
order: 1
---

# MoonBlox

A Markdown-first programmable site generator powered by [MoonBit](https://moonbitlang.com) and [rabbita](https://github.com/moonbit-community/rabbita).

Write Markdown, embed interactive components in MoonBit, and `moonblox-cli build` outputs a static site.

## Features

- **Markdown-first** — Write content in Markdown with YAML front matter
- **Interactive Components** — Embed MoonBit components with `@name(args)` syntax
- **Container Blocks** — Wrap Markdown in styled containers with `:::name(args)`
- **Structured Blocks** — Shared-state components with `::name { model } body ::`
- **Live Reload** — Dev server with WebSocket-based hot reload
- **Themes** — Blog and Documentation themes built-in
- **Static Output** — Produces a zero-dependency static site

## Quick Start

```bash
moon install xz-xuezhe/moonblox-cli
moonblox-cli init my-site
cd my-site
moonblox-cli serve
```

Open `http://localhost:3000` to see your site with live reload.
