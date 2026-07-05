name = "xz-xuezhe/moonblox"

version = "0.1.0"

supported_targets = "js+native"

preferred_target = "js"

import {
  "mizchi/markdown@0.6.2",
  "moonbitlang/x@0.4.45",
  "moonbit-community/rabbita@0.12.4",
  "TheWaWaR/clap@0.2.6",
}

readme = "README.md"

repository = "https://github.com/xz-xuezhe/moonblox"

license = "Apache-2.0"

keywords = [ "markdown", "ssg", "composable", "rabbita" ]

description = "MoonBit-native programmable site generator with interactive components"

options(
  exclude: [
    ".agents",
    ".claude",
    ".github",
    ".playwright-cli",
    "_build",
    "cmd",
    "dist",
    "docs-site",
    "openspec",
    "tests",
  ],
  "bin-deps": { "moonbitlang/yacc": "0.7.13" },
)
