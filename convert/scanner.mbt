// Component auto-discovery: scan components/*.mbt for Props + render

///|
/// Info about a discovered component
pub(all) struct ComponentInfo {
  name : String
  is_container : Bool
}

///|
/// Scan `dir/*.mbt` for component definitions.
/// Detects files containing `pub(all) struct Props` or `pub struct Props`.
/// Component name = file name minus `.mbt` extension.
pub fn scan_components(dir : String) -> Map[String, ComponentInfo] raise {
  guard @fs.path_exists(dir) else { return Map([]) }
  let files = @fs.read_dir(dir)
  let map : Map[String, ComponentInfo] = Map([])
  for i = 0; i < files.length(); i = i + 1 {
    let name = files[i]
    if name.has_suffix(".mbt") {
      let path = "\{dir}/\{name}"
      let content = @fs.read_file_to_string(path)
      let comp_name = name.trim_end(chars=".mbt").to_owned()
      if has_props_struct(content) {
        let is_container = content.contains("render(props:") &&
          content.contains(", body:")
        map.set(comp_name, { name: comp_name, is_container })
      }
    }
  }
  map
}

///|
fn has_props_struct(source : String) -> Bool {
  source.contains("pub(all) struct Props") ||
  source.contains("pub struct Props")
}
