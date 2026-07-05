<div align="center">
  <h1>MoonBlox</h1>
  <p><em>Write Markdown. Embed MoonBit components. Ship interactive pages.</em></p>
</div>

```
@badge(text: "new", tone: "info")

@counter(value: 0)

:::callout(type: "note", title: "Tip")
Your Markdown content here.
:::

::score_panel { count = 0 }
  @metric(value=count, label="Clicks")
  @chart(value=count, max=10, label="Progress")
  @counter(value=count)
::
```

## Features

- **Front matter**: YAML metadata (title, date, tags) rendered in page output
- **Tables**: Markdown table support with alignment
- **8 built-in components**: badge, counter, callout, card, grid, metric, chart, graph
- **Configuration**: `moonblox.json` for custom input/output/component paths
- **Live reload**: `moonblox serve` with file watcher and WebSocket reload
- **Incremental builds**: Dev server skips unchanged files, uses debug builds

## Quick Start

Requires [MoonBit](https://www.moonbitlang.com/download/) toolchain.

```bash
moonblox init my-site
cd my-site
moonblox serve        # dev server with live reload
moonblox build        # production build
```

## Project Structure

```
my-site/
  posts/index.md           # your Markdown content
  components/        — your components (8 built-in: badge, counter, callout, card, grid, metric, chart, graph)
  theme/base.css           # global styles
  dist/                    # built output
```

## Components

Use built-in or project-local components directly from Markdown:

```md
@badge(text: "stable", tone: "success")

:::callout(type: "note", title: "Tip")
Markdown content can live inside container components.
:::
```

For custom component authoring and the MoonBit interface details, see
[`docs-site/content/components.md`](docs-site/content/components.md).

### Structured Block Syntax

Use `::name { model } body ::` to share state between components:

```md
::dashboard { count = 0 }
  @metric(value=count, label="Clicks")
  @chart(value=count, max=10, label="Progress")
  @counter(value=count)
::
```

Here, `counter` updates `count`; `metric` and `chart` read the same value and
re-render when it changes. Interactive components auto-wire callbacks to update
the shared model.

## Dependencies

- [rabbita](https://github.com/moonbit-community/rabbita) — UI framework
- [mizchi/markdown](https://github.com/mizchi/markdown) — Markdown parser
- [moonbitlang/x](https://github.com/moonbitlang/x) — filesystem utilities
- [moonbitlang/async](https://github.com/moonbitlang/core) — async runtime
- [Yoorkin/ArgParser](https://github.com/Yoorkin/ArgParser) — CLI argument parsing

## CLI Commands

- `moonblox init <dir>` — scaffold a new project
- `moonblox build <dir>` — build static site to dist/
- `moonblox serve <dir> [--port 3000]` — start dev server with live reload

## License

[Apache 2.0](LICENSE)
