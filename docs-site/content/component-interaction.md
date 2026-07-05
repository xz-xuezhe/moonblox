---
title: Component Interaction
order: 5
---

# Component Interaction

Use a structured block when multiple components need to read or update the same state.

::score_panel { count = 0 }
  @metric(value=count, label="Clicks")
  @chart(value=count, max=10, label="Progress")
  @counter(value=count)
::

The model at the top of the block creates a shared `count` value. Components inside the block can pass `count` as a bare identifier:

- `counter` receives `value=count`, so MoonBlox auto-wires its `on_change` callback to update `count`.
- `metric` receives the same `count` and displays the current value.
- `chart` receives the same `count` and visualizes the current value.

You do not need to write `on_change` by hand for the common case. If a component exposes a command-producing callback and receives a model variable, MoonBlox connects that callback to the matching model setter.

## When To Use This

Use structured blocks for small local interactions where components belong to one section of a page: counters with summaries, sliders with charts, toggles with previews, or any panel where several components reflect the same value.
