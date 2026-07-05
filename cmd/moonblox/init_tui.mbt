///|
/// MoonBlox init TUI wizard — interactive project scaffolding.

///|
fn theme_names() -> Array[String] {
  ["blog", "docs"]
}

///|
fn all_component_names() -> Array[String] {
  [
    "badge", "counter", "callout", "card", "grid", "metric", "chart", "graph", "sidebar",
    "breadcrumbs", "prev_next",
  ]
}

///|
fn component_label(name : String) -> String {
  match name {
    "badge" => "badge         Status badge"
    "counter" => "counter       Interactive counter"
    "callout" => "callout       Callout box"
    "card" => "card          Content card"
    "grid" => "grid          CSS grid layout"
    "metric" => "metric        Metric display"
    "chart" => "chart         Bar chart"
    "graph" => "graph         Value graph"
    "sidebar" => "sidebar       Docs sidebar"
    "breadcrumbs" => "breadcrumbs   Breadcrumb nav"
    "prev_next" => "prev_next     Prev/next page"
    _ => name
  }
}

///|
enum Step {
  Dir
  Theme
  Components
  Confirm
  Scaffolding
  Done
} derive(Eq, Debug)

///|
struct Model {
  step : Step
  dir_input : @widgets.TextInput
  theme_list : @widgets.List
  comp_cursor : Int
  comp_selected : @vector.Vector[Bool]
  width : Int
  height : Int
  status : String
} derive(Debug)

///|
enum Msg {
  KeyPressed(@tui.Key)
  Resize(@tui.Size)
} derive(Debug)

///|
fn initial_model(default_dir : String) -> Model {
  let names = all_component_names()
  let bools = Array::makei(names.length(), fn(_i) { true })
  {
    step: Dir,
    dir_input: @widgets.TextInput(placeholder="my-site", value=default_dir),
    theme_list: @widgets.List(items=theme_names()),
    comp_cursor: 0,
    comp_selected: @vector.Vector::from_array(bools),
    width: 80,
    height: 24,
    status: "Welcome to MoonBlox!",
  }
}

///|
fn accent_style() -> @tui.Style {
  @tui.Style::default().fg(@tui.Ansi(33)).bold()
}

///|
fn muted_style() -> @tui.Style {
  @tui.Style::default().fg(@tui.Ansi(244))
}

///|
fn title_style() -> @tui.Style {
  @tui.Style::default().fg(@tui.Ansi(36)).bold()
}

///|
fn step_title(step : Step) -> String {
  match step {
    Dir => "1/4  Project directory"
    Theme => "2/4  Choose theme"
    Components => "3/4  Select components"
    Confirm => "4/4  Review & confirm"
    Scaffolding => "Creating project..."
    Done => "Done!"
  }
}

///|
fn step_index(step : Step) -> Int {
  match step {
    Dir => 1
    Theme => 2
    Components => 3
    Confirm => 4
    Scaffolding => 5
    Done => 5
  }
}

///|
fn dir_value(model : Model) -> String {
  model.dir_input.value
}

///|
fn selected_theme_index(model : Model) -> Int {
  model.theme_list.selected
}

///|
fn next_step(step : Step) -> Step {
  match step {
    Dir => Theme
    Theme => Components
    Components => Confirm
    Confirm => Scaffolding
    Scaffolding => Done
    Done => Done
  }
}

///|
fn prev_step(step : Step) -> Step {
  match step {
    Dir => Dir
    Theme => Dir
    Components => Theme
    Confirm => Components
    Scaffolding => Confirm
    Done => Dir
  }
}

///|
fn update(
  _emit : @tui.Emit[Msg],
  msg : Msg,
  model : Model,
) -> (@tui.Cmd, Model) {
  match msg {
    KeyPressed(@tui.Key::Ctrl("c")) => (@tui.Cmd::quit(), model)
    KeyPressed(@tui.Key::Escape) =>
      (@tui.Cmd::none(), { ..model, step: prev_step(model.step) })
    KeyPressed(@tui.Key::Enter) =>
      (
        @tui.Cmd::none(),
        match model.step {
          Dir => {
            let name = dir_value(model)
            if name == "" {
              { ..model, status: "Please enter a project name" }
            } else {
              { ..model, step: next_step(model.step) }
            }
          }
          Theme => { ..model, step: next_step(model.step) }
          Components => { ..model, step: next_step(model.step) }
          Confirm => {
            let name = dir_value(model)
            let theme_name = theme_names()[selected_theme_index(model)]
            let selected_comps : Array[String] = []
            let names = all_component_names()
            for i = 0; i < names.length(); i = i + 1 {
              if i < model.comp_selected.length() && model.comp_selected[i] {
                selected_comps.push(names[i])
              }
            }
            scaffold(name, theme=theme_name, components=selected_comps)
            { ..model, step: Scaffolding, status: "Project created!" }
          }
          Scaffolding => { ..model, step: Done }
          Done => { ..model, step: Dir }
        },
      )
    KeyPressed(@tui.Key::Up) =>
      (
        @tui.Cmd::none(),
        match model.step {
          Theme => {
            let msg = @widgets.ListMove(-1, 5)
            { ..model, theme_list: model.theme_list.update(msg) }
          }
          Components => {
            let count = all_component_names().length()
            {
              ..model,
              comp_cursor: if model.comp_cursor > 0 {
                model.comp_cursor - 1
              } else {
                count - 1
              },
            }
          }
          _ => model
        },
      )
    KeyPressed(@tui.Key::Down) =>
      (
        @tui.Cmd::none(),
        match model.step {
          Theme => {
            let msg = @widgets.ListMove(1, 5)
            { ..model, theme_list: model.theme_list.update(msg) }
          }
          Components => {
            let count = all_component_names().length()
            {
              ..model,
              comp_cursor: if model.comp_cursor + 1 < count {
                model.comp_cursor + 1
              } else {
                0
              },
            }
          }
          _ => model
        },
      )
    KeyPressed(@tui.Key::Char(" ")) if model.step == Components =>
      (
        @tui.Cmd::none(),
        {
          ..model,
          comp_selected: model.comp_selected.set(
            model.comp_cursor,
            !model.comp_selected[model.comp_cursor],
          ),
        },
      )
    KeyPressed(key) =>
      (
        @tui.Cmd::none(),
        match model.step {
          Dir => {
            let msg = @widgets.TextInputKey(key)
            { ..model, dir_input: model.dir_input.update(msg) }
          }
          _ => model
        },
      )
    Resize(size) =>
      (@tui.Cmd::none(), { ..model, width: size.width, height: size.height })
  }
}

///|
fn view(model : Model) -> @tui.Node {
  let width = model.width

  let step_label = step_title(model.step)
  let progress = step_index(model.step).to_string() + "/5"

  @tui.vstack([
    @tui.hstack([
      @tui.text(style=title_style(), @tui.fit_line("MoonBlox Init", width / 2)),
      @tui.text(style=muted_style(), @tui.fit_line(progress, width / 2)),
    ]),
    @tui.text(style=accent_style(), @tui.fit_line(step_label, width)),
    @tui.text(style=muted_style(), "  "),
    match model.step {
      Dir => dir_view(model, width)
      Theme => theme_view(model, width)
      Components => components_view(model, width)
      Confirm => confirm_view(model, width)
      Scaffolding => scaffold_view(model, width)
      Done => done_view(model, width)
    },
    @tui.text("  "),
    @tui.text(style=muted_style(), @tui.fit_line(model.status, width)),
    @tui.text(
      style=muted_style(),
      @tui.fit_line(
        "Enter confirm  Esc back  Ctrl+C quit  Up/Down move  Space toggle", width,
      ),
    ),
  ])
}

///|
fn dir_view(model : Model, _width : Int) -> @tui.Node {
  @tui.vstack([
    @tui.text("Enter the project directory name:"),
    @tui.text("  "),
    model.dir_input.view(width=40, style=@tui.Style::default().border()),
    @tui.text("  "),
    @tui.text(
      style=muted_style(),
      "This will create a new directory with your MoonBlox site.",
    ),
  ])
}

///|
fn theme_view(model : Model, width : Int) -> @tui.Node {
  @tui.vstack([
    @tui.text("Choose a theme for your site:"),
    @tui.text("  "),
    model.theme_list.view(
      size={ width, height: 3 },
      style=@tui.Style::default(),
    ),
    @tui.text("  "),
    @tui.text(
      style=muted_style(),
      "blog \u{2014} Posts with dates, tags, article listing",
    ),
    @tui.text(
      style=muted_style(),
      "docs \u{2014} Hierarchical docs with sidebar navigation",
    ),
  ])
}

///|
fn components_view(model : Model, width : Int) -> @tui.Node {
  let names = all_component_names()
  let rows : Array[@tui.Node] = [
    @tui.text("Select components to include:"),
    @tui.text("  "),
  ]
  for i = 0; i < names.length(); i = i + 1 {
    let checked = if i < model.comp_selected.length() && model.comp_selected[i] {
      "[x]"
    } else {
      "[ ]"
    }
    let cursor = if model.comp_cursor == i { ">" } else { " " }
    let label = component_label(names[i])
    rows.push(
      @tui.text(
        style=if model.comp_cursor == i {
          accent_style()
        } else {
          @tui.Style::default()
        },
        @tui.fit_line("\{cursor} \{checked} \{label}", width),
      ),
    )
  }
  @tui.vstack(rows)
}

///|
fn confirm_view(model : Model, _width : Int) -> @tui.Node {
  let dir = dir_value(model)
  let theme_name = theme_names()[selected_theme_index(model)]
  let mut comp_list = ""
  let names = all_component_names()
  let mut count = 0
  for i = 0; i < names.length(); i = i + 1 {
    if i < model.comp_selected.length() && model.comp_selected[i] {
      if count > 0 {
        comp_list = comp_list + ", "
      }
      comp_list = comp_list + names[i]
      count = count + 1
    }
  }

  @tui.vstack([
    @tui.text(style=accent_style(), "Review your choices:"),
    @tui.text("  "),
    @tui.text("  Directory:    \{dir}"),
    @tui.text("  Theme:        \{theme_name}"),
    @tui.text("  Components:   \{comp_list}"),
    @tui.text("  "),
    @tui.text(style=accent_style(), "Press Enter to create the project."),
  ])
}

///|
fn scaffold_view(_model : Model, _width : Int) -> @tui.Node {
  @tui.text(style=accent_style(), "Creating your MoonBlox project...")
}

///|
fn done_view(_model : Model, _width : Int) -> @tui.Node {
  @tui.vstack([
    @tui.text(style=accent_style(), "Project created successfully!"),
    @tui.text("  "),
    @tui.text("Next steps:"),
    @tui.text("  cd <project>"),
    @tui.text("  moonblox serve"),
    @tui.text("  "),
    @tui.text("Press Enter to start a new project, or Ctrl+C to quit."),
  ])
}

///|
fn subscriptions(_model : Model) -> @tui.Sub[Msg] {
  @tui.Sub::batch([
    @tui.Sub::keys(fn(key : @tui.Key) -> Msg { KeyPressed(key) }),
    @tui.Sub::resize(fn(size : @tui.Size) -> Msg { Resize(size) }),
  ])
}

///|
pub async fn init_tui(default_dir? : String = "") -> Unit {
  let app = @tui.cell(model=initial_model(default_dir), update~, view~, subscriptions~)
  app.run_with_options(
    @tui.ProgramOptions::inline().hide_cursor(true).bracketed_paste(true),
  ) catch {
    @tui.NotATty(_) => println("No terminal detected. Use: moonblox init <dir>")
    @tui.NativeError(msg) => {
      println("Terminal error: \{msg}")
      println("Use: moonblox init <dir>")
    }
    @tui.UnsupportedPlatform => {
      println("This platform does not support interactive mode.")
      println("Use: moonblox init <dir>")
    }
  }
}
