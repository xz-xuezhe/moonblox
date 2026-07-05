---
title: Getting Started
order: 2
---

# Getting Started

## Installation

MoonBlox requires the [MoonBit toolchain](https://moonbitlang.com/download/).

```bash
moon install xz-xuezhe/moonblox-cli
moonblox-cli init my-site
cd my-site
```

## Project Structure

```
my-site/
  moonblox.json      → site configuration
  posts/             → markdown content (blog theme)
  components/        → user components
  theme/
    base.css         → global styles
```

## Writing Content

Create a `.md` file in your content directory:

```markdown
---
title: My First Post
date: 2024-01-15
tags: [demo]
---

Welcome to my MoonBlox site! Here is a @badge(text: "new", tone: "info") component.

:::callout(type: "note", title: "Tip")
MoonBlox supports **Markdown** inside container blocks.
:::
```

## Building

```bash
moonblox-cli build
```

Output goes to `dist/` — a complete static site ready to deploy.
