---
title: Components
order: 4
---

# Components

MoonBlox components are MoonBit functions that return `@rabbita.Html`. You can call them from Markdown with inline, container, or structured block syntax.

## Inline Components

Inline components render at the call site:

```md
@badge(text: "stable", tone: "success")
@metric(value: 42, label: "Stars")
```

A matching component exposes a plain function:

```moonbit
pub fn badge(text? : String = "", tone? : String = "default") -> @rabbita.Html {
  @html.span(class="badge badge--\{tone}", [@html.text(text)])
}
```

## Interactive Components

Interactive components use the same function shape, with callback parameters when they need to update state:

```moonbit
pub fn counter(
  value? : Double = 0.0,
  on_change? : (Double) -> @cmd.Cmd = fn(_) { @cmd.none },
) -> @rabbita.Html {
  @html.div(class="counter", [
    @html.button(on_click=on_change(value - 1.0), [@html.text("-")]),
    @html.span([@html.text(value.to_string())]),
    @html.button(on_click=on_change(value + 1.0), [@html.text("+")]),
  ])
}
```

## Component Interaction

Structured blocks let components share one model. If an interactive component receives a model value, MoonBlox wires its callback back to that model variable:

For a complete example, see [Component Interaction](../component-interaction/).

## Container Components

Container components accept rendered Markdown children:

```md
:::callout(type: "note", title: "Tip")
Regular **Markdown** content here.
:::
```

The component receives those children as `Array[@rabbita.Html]`:

```moonbit
pub fn callout(children : Array[@rabbita.Html], type_? : String = "note", title? : String = "") -> @rabbita.Html {
  ...
}
```

## Generated Adapter

The build system auto-generates `_props.mbt` for type-safe prop extraction and a `_cell` adapter that wires the pure HTML function into rabbita's Cell tree. Component authors do not need to write Props structs or Model/Msg types for ordinary components.
