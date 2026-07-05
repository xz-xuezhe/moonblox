---
title: Component Showcase
date: 2026-07-05
tags: [components, demo]
---

This page uses every built-in MoonBlox component:
@badge(text: "badge", tone: "info")
@badge(text: "stable", tone: "success")
@badge(text: "preview", tone: "warning")

## Interactive

Use the buttons to change the value:

@counter(value: 3)

## Metrics

@metric(label: "Visitors", value: 1280, prefix: "", suffix: " today")

@metric(label: "Conversion", value: 7.5, prefix: "", suffix: "%")

## Charts

@chart(label: "Build progress", value: 72, max: 100)

@graph(label: "CPU load", value: 46, max: 100)

## Containers

:::callout(type: "note", title: "Callout")
Callouts can wrap normal **Markdown** content, including links, lists, and inline
components like @badge(text: "inside", tone: "info").
:::

:::card(title: "Card", image: "https://placehold.co/640x240")
Cards are useful for grouping a short piece of content with an optional image.

This card keeps its body to Markdown text so the current container parser can
close the block cleanly.

:::

:::grid(cols: 2, gap: "1rem")
Grid item A shows regular Markdown content in the first column.

Grid item B shows regular Markdown content in the second column.
:::
