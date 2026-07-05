---
title: Syntax Reference
order: 3
---

# Syntax Reference

## Inline Components

Use `@name(args)` to embed interactive components in your Markdown:

@badge(text: "stable", tone: "success")
@badge(text: "experimental", tone: "warning")
@metric(value: 42, label: "Stars")

```
@badge(text: "stable", tone: "success")
@metric(value: 42, label: "Stars")
```

## Container Components

Use `:::name(args)` to wrap Markdown content:

:::callout(type: "note", title: "Information")
This is a callout with **Markdown** content inside.
:::

```
:::callout(type: "note", title: "Information")
This is a callout with **Markdown** content inside.
:::
```

## Structured Blocks

Use `::name { model } body ::` for components with shared state.  
The model variables use `=` syntax (MoonBit style).

**Example** — a counter component with shared state.  
The model `count = 0` initializes `count` to `0`:

- `::counter { count = 0 }` starts the block
- `@badge(text: "{count}", tone: "info")` displays the current count
- `@counter(value: "{count}", on_change: set_count)` renders the counter
- `::` ends the block

## Code Blocks

Code blocks are safe — directives inside them are NOT expanded:

```
@badge(text: "this stays as text", tone: "info")
```

## Front Matter

YAML front matter at the top of each `.md` file:

```yaml
---
title: Page Title
date: 2024-01-15
tags: [demo, tutorial]
---
```
