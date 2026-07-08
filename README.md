# MoonBlox

*A Markdown-first programmable site generator powered by MoonBit.*

Write Markdown, embed interactive MoonBit components, and `moonblox-cli build`
outputs a static site.

## Try It

See a live demo of components sharing state:
**[Component Interaction Playground](https://xz-xuezhe.github.io/moonblox/component-interaction/)**

## Quick Start

Requires the [MoonBit](https://www.moonbitlang.com/download/) toolchain.

```bash
moon install xz-xuezhe/moonblox-cli
moonblox-cli init my-site
cd my-site
moonblox-cli serve        # dev server with live reload
moonblox-cli build        # production build
```

Open `http://localhost:3000`. Edit any Markdown file — the browser reloads
automatically.

## Examples

```md
---
title: Hello MoonBlox
date: 2025-01-15
tags: [demo]
---

@badge(text: "new", tone: "info")

:::callout(type: "note", title: "Tip")
Regular **Markdown** content here.
:::

::score_panel { count = 0 }
  @metric(value=count, label="Clicks")
  @chart(value=count, max=10, label="Progress")
  @counter(value=count)
::
```

- **Inline** `@name(args)` — embed a component anywhere in a line
- **Container** `:::name(args)` — wrap Markdown content in a component
- **Structured block** `::name { model } body ::` — share state across multiple components

## Documentation

Full docs at **[xz-xuezhe.github.io/moonblox](https://xz-xuezhe.github.io/moonblox/)**:

- [Getting Started](https://xz-xuezhe.github.io/moonblox/getting-started/)
- [Syntax Reference](https://xz-xuezhe.github.io/moonblox/syntax/)
- [Components](https://xz-xuezhe.github.io/moonblox/components/)
- [Configuration](https://xz-xuezhe.github.io/moonblox/configuration/)

## License

[Apache 2.0](LICENSE)
