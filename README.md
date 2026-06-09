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
```

## Features

- **Embed components in Markdown** — `@counter(initial: 0)` inline. Not a shortcode, not a template tag. Just part of your prose.
- **Composable, not configurable** — write your own components with [rabbita](https://github.com/moonbit-community/rabbita). Static, interactive, container — you decide what they do.
- **Zero-config build** — `moonblox build` scans your components, compiles to JavaScript, and assembles `dist/` in one command.

## Quick Start

Requires [MoonBit](https://www.moonbitlang.com/download/) toolchain.

```bash
git clone https://github.com/xz-xuezhe/moonblox
cd moonblox

# Scaffold a new site
moon run --target native cmd/moonblox -- init my-site

# Build and open
MOONBLOX_PATH=. moon run --target native cmd/moonblox -- build my-site
open my-site/dist/index.html
```

## Project Structure

```
my-site/
  posts/index.md           # your Markdown content
  components/
    badge/                 # @badge(text: "new", tone: "info")
    counter/               # @counter(initial: 0)
    callout/               # :::callout ... :::
  theme/base.css           # global styles
  dist/                    # built output
```

## Components

A component is a directory under `components/<name>/`:

- **`moon.pkg`** — declares `supported_targets = "js+native"`
- **`<name>.mbt`** — exports `pub fn <name>_cell(args) -> @rabbita.Cell`
- **`<name>.css`** — optional, component styles

See the [built-in components](lib/templates/components/) for examples.

## Dependencies

- [rabbita](https://github.com/moonbit-community/rabbita) — UI framework
- [mizchi/markdown](https://github.com/mizchi/markdown) — Markdown parser

## License

[Apache 2.0](LICENSE)
