<p align="center">
  <h1>MoonBlox</h1>
  <p><em>Write Markdown. Embed MoonBit components. Ship interactive pages.</em></p>
</p>

```
@badge(text: "new", tone: "info")

@counter(initial: 0)

:::callout(type: "note", title: "Tip")
Your Markdown content here.
:::

::badge_board { name = "guest", count = 0 }
  @badge(text=name, tone="info")
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

## Component Interface

All components use a unified `pub fn -> @rabbita.Html` interface:

**Inline component** (badge):
```moonbit
pub fn badge(text? : String = "", tone? : String = "default") -> @rabbita.Html {
  @html.span(class="badge badge--\{tone}", [@html.text(text)])
}
```

**Interactive component** (counter):
```moonbit
pub fn counter(value? : Double = 0.0, on_change? : (Double) -> Unit = fn(_) { () }) -> @rabbita.Html {
  @html.div(class="counter", [
    @html.button(on_click=fn() { on_change(value - 1.0) }, [@html.text("-")]),
    @html.span([@html.text(value.to_string())]),
    @html.button(on_click=fn() { on_change(value + 1.0) }, [@html.text("+")]),
  ])
}
```

**Container component** (callout):
```moonbit
pub fn callout(children : Array[@rabbita.Html], type_? : String = "note", title? : String = "") -> @rabbita.Html {
  ...
}
```

The build system auto-generates `_props.mbt` (type-safe prop extraction) and a `_cell` adapter
that wires your pure Html function into rabbita's Cell tree. No Props structs or Model/Msg types needed.

### Structured Block Syntax

Use `::name { model } { body }::` to share state between components:

```md
::dashboard { count = 0, name = "guest" }
  @counter(value=count)
  @badge(text=name, tone="info")
::
```

Model variables (`count`, `name`) are shared across all components within the block.
Interactive components auto-wire callbacks to update the shared model.

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
