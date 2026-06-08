# MoonBlox Demo

This is a **MoonBlox** demo showing inline components.

Here is a badge: @badge(text: "experimental", tone: "warning")

And another: @badge(text: "stable", tone: "success")

## Code Example

This `@badge` inside inline code should NOT be expanded:

```
@badge(text: "ignored", tone: "info")
```

The one inside a fenced code block should also stay as-is.

:::callout(type: "note", title: "Did you know?")
MoonBlox supports container blocks written in **Markdown**. You can use *emphasis*, `code`, and more inside callouts.
:::

## Final Thoughts

This document was generated from Markdown with MoonBlox directives.
