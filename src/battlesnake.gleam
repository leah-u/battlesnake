import battlesnake/gamestate.{type GameState}
import battlesnake/move
import gleam/bool
import gleam/http
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string
import internal/stateful
import wisp

// move shared types to internal/types, re-export from here
// only require immporting battlesnake

pub opaque type Color {
  Color(color: String)
}

/// Convert a hex string to a Battlesnake color
/// '#000000' or '000000'
pub fn color_from_hex(color: String) -> Result(Color, Nil) {
  // Todo check if valid
  Ok(Color(color))
}

/// Create a Battlesnake color from red, green and blue components
/// Each value must be in the range 0..255
pub fn color_from_rgb(
  r red: Int,
  g green: Int,
  b blue: Int,
) -> Result(Color, Nil) {
  use <- bool.guard(red >= 256 || green >= 256 || blue >= 256, Error(Nil))

  let red_string = int.to_base16(red) |> string.pad_left(to: 2, with: "0")
  let green_string = int.to_base16(green) |> string.pad_left(to: 2, with: "0")
  let blue_string = int.to_base16(blue) |> string.pad_left(to: 2, with: "0")

  let color = Color("#" <> red_string <> green_string <> blue_string)
  Ok(color)
}

pub fn color_to_string(color: Color) -> String {
  color.color
}

pub type Battlesnake {
  Battlesnake(
    /// Version of the Battlesnake API implemented by this Battlesnake. Currently only API version 1 is valid. Example: "1"
    apiversion: String,
    /// Username of the author of this Battlesnake. If provided, this will be used to verify ownership. Example: "BattlesnakeOfficial"
    author: Option(String),
    /// Hex color code used to display this Battlesnake. Must start with "#", followed by 6 hexadecimal characters. Example: "#888888"
    color: Option(Color),
    /// Head customization. Example: "default"
    head: Option(String),
    /// Tail customization. Example: "default"
    tail: Option(String),
    /// optional version string for your Battlesnake. This value is not used in gameplay, but can be useful for tracking deployments on your end.
    version: Option(String),
  )
}

pub fn new() -> Battlesnake {
  Battlesnake(
    apiversion: "1",
    author: None,
    color: None,
    head: None,
    tail: None,
    version: None,
  )
}

pub fn with_author(battlesnake: Battlesnake, author: String) -> Battlesnake {
  Battlesnake(..battlesnake, author: Some(author))
}

pub fn with_color(battlesnake: Battlesnake, color: Color) -> Battlesnake {
  Battlesnake(..battlesnake, color: Some(color))
}

pub fn with_head(battlesnake: Battlesnake, head: String) -> Battlesnake {
  Battlesnake(..battlesnake, head: Some(head))
}

pub fn with_tail(battlesnake: Battlesnake, tail: String) -> Battlesnake {
  Battlesnake(..battlesnake, tail: Some(tail))
}

pub fn with_version(battlesnake: Battlesnake, version: String) -> Battlesnake {
  Battlesnake(..battlesnake, version: Some(version))
}

pub fn to_json(battlesnake: Battlesnake) -> Json {
  json.object([
    #("apiversion", json.string(battlesnake.apiversion)),
    #("author", json.nullable(battlesnake.author, json.string)),
    #(
      "color",
      json.nullable(
        battlesnake.color |> option.map(color_to_string),
        json.string,
      ),
    ),
    #("head", json.nullable(battlesnake.head, json.string)),
    #("tail", json.nullable(battlesnake.tail, json.string)),
    #("version", json.nullable(battlesnake.version, json.string)),
  ])
}

pub fn stateful(
  battlesnake battlesnake: Battlesnake,
  on_start start: fn(GameState) -> state,
  on_move move: fn(GameState, state) -> #(move.Move, state),
  on_end end: fn(GameState, state) -> Nil,
) -> fn(wisp.Request) -> wisp.Response {
  let battlesnake =
    battlesnake
    |> to_json
    |> json.to_string_builder
    |> wisp.json_response(200)

  stateful.stateful(battlesnake, start, move, end)
}

pub fn simple(
  battlesnake battlesnake: Battlesnake,
  on_move callback: fn(GameState) -> move.Move,
) -> fn(wisp.Request) -> wisp.Response {
  fn(request) {
    case wisp.path_segments(request) {
      [] -> {
        battlesnake
        |> to_json
        |> json.to_string_builder
        |> wisp.json_response(200)
      }
      ["start"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        let _ = gamestate.decode(json)

        wisp.ok()
      }
      ["move"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        case gamestate.decode(json) {
          Error(_) -> wisp.bad_request()
          Ok(turn) -> {
            callback(turn)
            |> move.to_json
            |> json.to_string_builder
            |> wisp.json_response(200)
          }
        }
      }
      ["end"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        let _ = gamestate.decode(json)

        wisp.ok()
      }
      _ -> wisp.not_found()
    }
  }
}
