name = "xz-xuezhe/moonblox"

version = "0.1.0"

import {
  "mizchi/markdown@0.6.2",
  "moonbitlang/x@0.4.45",
}

readme = "README.md"

repository = ""

license = "Apache-2.0"

keywords = [ "markdown", "ssg", "static-site-generator" ]

description = "MoonBit-native programmable site generator with interactive components"

preferred_target = "native"

options(
  "bin-deps": { "moonbitlang/yacc": "0.7.13" },
)
