name = "xz-xuezhe/moonblox"

version = "0.1.0"

supported_targets = "js+native"

import {
  "mizchi/markdown@0.6.2",
  "moonbitlang/x@0.4.45",
  "moonbit-community/rabbita@0.12.4",
}

readme = "README.md"

repository = ""

license = "Apache-2.0"

keywords = [ "markdown", "ssg", "static-site-generator" ]

description = "MoonBit-native programmable site generator with interactive components"

options(
  "bin-deps": { "moonbitlang/yacc": "0.7.13" },
)
