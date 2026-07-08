# MoonBlox CLI

Command-line tool for [MoonBlox](https://github.com/xz-xuezhe/moonblox), a
Markdown-first programmable site generator powered by MoonBit.

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/) (latest stable)
- Moon's binary directory on your `PATH`:

  ```bash
  export PATH="$HOME/.moon/bin:$PATH"
  ```

## Install

```bash
moon install xz-xuezhe/moonblox-cli
```

This installs the `moonblox-cli` binary globally.

## Quick Start

```bash
moonblox-cli init my-site
cd my-site
moonblox-cli serve
```

Open `http://localhost:3000`. Edit any Markdown file — the browser reloads
automatically.

## Commands

### `init` — scaffold a new project

```bash
moonblox-cli init <dir> [options]
```

By default, `init` launches an interactive TUI that guides you through project
setup (name, theme, components).

**Options:**

| Flag | Description |
|------|-------------|
| `--headless`, `-H` | Skip interactive TUI (for CI / scripts) |
| `--theme`, `-t <name>` | Project theme: `blog` (default) or `docs` |
| `--empty`, `-E` | Skip generating sample content |
| `--quiet`, `-q` | Suppress non-essential output |

**Examples:**

```bash
moonblox-cli init .                     # TUI in current directory
moonblox-cli init my-blog --headless    # scaffold in CI, blog theme
moonblox-cli init my-docs -t docs -H    # scaffold docs theme, no TUI
moonblox-cli init my-site -H -E         # empty scaffold, no sample content
```

The scaffolded project includes:

```
my-site/
  moonblox.json         → site configuration
  posts/                → Markdown content (blog theme)
  components/           → selected built-in components
  theme/base.css        → global styles
  _moonblox/            → generated MoonBit project (build target)
```

### `build` — build static site

```bash
moonblox-cli build [dir]
```

Parses Markdown, resolves components, and compiles to `dist/` — a complete
static site ready for deployment. Defaults to the current directory.

### `serve` — dev server with live reload

```bash
moonblox-cli serve [dir] [--port <port>]
```

Starts a development server at `http://localhost:3000` with:

- **Live reload** — changes to Markdown files trigger automatic rebuild and
  browser refresh via WebSocket.
- **Incremental builds** — unchanged files are skipped, debug builds are used
  for faster iteration.

**Options:**

| Flag | Description |
|------|-------------|
| `--port`, `-p <port>` | Server port (default: `3000`) |

## Project Configuration

Site settings live in `moonblox.json` at the project root:

```json
{
  "input": "posts",
  "output": "dist",
  "components": "components",
  "theme": "blog"
}
```

## Documentation

Full docs: <https://xz-xuezhe.github.io/moonblox/>

- [Getting Started](https://xz-xuezhe.github.io/moonblox/getting-started/)
- [Syntax Reference](https://xz-xuezhe.github.io/moonblox/syntax/)
- [Configuration](https://xz-xuezhe.github.io/moonblox/configuration/)
- [Components](https://xz-xuezhe.github.io/moonblox/components/)

## License

[Apache 2.0](../../LICENSE)
