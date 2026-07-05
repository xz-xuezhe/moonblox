# MoonBlox CLI

Command-line tool for MoonBlox, a Markdown-first programmable site generator.

## Install

```bash
moon install xz-xuezhe/moonblox-cli
```

Make sure Moon's global binary directory is on your `PATH`:

```bash
export PATH="$HOME/.moon/bin:$PATH"
```

## Usage

```bash
moonblox-cli init my-site
cd my-site
moonblox-cli serve
moonblox-cli build
```

## Commands

- `moonblox-cli init <dir>` - scaffold a new project
- `moonblox-cli build <dir>` - build static site output to `dist/`
- `moonblox-cli serve <dir> [--port 3000]` - start dev server with live reload
