import battlesnake/move
import decode
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/io
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import wisp

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
  red r: Int,
  green g: Int,
  blue b: Int,
) -> Result(Color, Nil) {
  todo
}

pub fn color_to_string(color: Color) -> String {
  color.color
}

pub type Battlesnake {
  Battlesnake(
    // Version of the Battlesnake API implemented by this Battlesnake. Currently only API version 1 is valid. Example: "1"
    apiversion: String,
    // Username of the author of this Battlesnake. If provided, this will be used to verify ownership. Example: "BattlesnakeOfficial"
    author: Option(String),
    // Hex color code used to display this Battlesnake. Must start with "#", followed by 6 hexadecimal characters. Example: "#888888"
    color: Option(Color),
    // Head customization. Example: "default"
    head: Option(String),
    // Tail customization. Example: "default"
    tail: Option(String),
    // optional version string for your Battlesnake. This value is not used in gameplay, but can be useful for tracking deployments on your end.
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

pub type RulesetSettings {
  RulesetSettings
}

pub type Ruleset {
  Ruleset(name: String, version: String, settings: RulesetSettings)
}

fn ruleset_decoder() -> decode.Decoder(Ruleset) {
  decode.into({
    use name <- decode.parameter
    use version <- decode.parameter
    // use settings <- decode.parameter
    Ruleset(name:, version:, settings: RulesetSettings)
  })
  |> decode.field("name", decode.string)
  |> decode.field("version", decode.string)
  // |> decode.field("settings", ruleset_settings_decoder())
}

pub type Board {
  Board(
    height: Int,
    width: Int,
    food: List(Position),
    hazards: List(Position),
    snakes: List(Snake),
  )
}

fn board_decoder() -> decode.Decoder(Board) {
  decode.into({
    use height <- decode.parameter
    use width <- decode.parameter
    use food <- decode.parameter
    use hazards <- decode.parameter
    use snakes <- decode.parameter
    Board(height:, width:, food:, hazards:, snakes:)
  })
  |> decode.field("height", decode.int)
  |> decode.field("width", decode.int)
  |> decode.field("food", decode.list(position_decoder()))
  |> decode.field("hazards", decode.list(position_decoder()))
  |> decode.field("snakes", decode.list(snake_decoder()))
}

pub type Position {
  Position(x: Int, y: Int)
}

fn position_decoder() -> decode.Decoder(Position) {
  decode.into({
    use x <- decode.parameter
    use y <- decode.parameter
    Position(x:, y:)
  })
  |> decode.field("x", decode.int)
  |> decode.field("y", decode.int)
}

pub type Snake {
  Snake(
    id: String,
    name: String,
    health: Int,
    body: List(Position),
    latency: String,
    head: Position,
    length: Int,
    shout: String,
    squad: String,
    customizations: Nil,
  )
}

fn snake_decoder() -> decode.Decoder(Snake) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use health <- decode.parameter
    use body <- decode.parameter
    use latency <- decode.parameter
    use head <- decode.parameter
    use length <- decode.parameter
    use shout <- decode.parameter
    use squad <- decode.parameter
    // use customizations <- decode.parameter
    Snake(
      id:,
      name:,
      health:,
      body:,
      latency:,
      head:,
      length:,
      shout:,
      squad:,
      customizations: Nil,
    )
  })
  |> decode.field("id", decode.string)
  |> decode.field("name", decode.string)
  |> decode.field("health", decode.int)
  |> decode.field("body", decode.list(position_decoder()))
  |> decode.field("latency", decode.string)
  |> decode.field("head", position_decoder())
  |> decode.field("length", decode.int)
  |> decode.field("shout", decode.string)
  |> decode.field("squad", decode.string)
}

pub type GameState {
  GameState(game: Game, turn: Int, board: Board, you: Snake)
}

pub type Game {
  Game(id: String, ruleset: Ruleset, map: String, timeout: Int, source: String)
}

fn game_decoder() -> decode.Decoder(Game) {
  decode.into({
    use id <- decode.parameter
    use ruleset <- decode.parameter
    use map <- decode.parameter
    use timeout <- decode.parameter
    use source <- decode.parameter
    Game(id:, ruleset:, map:, timeout:, source:)
  })
  |> decode.field("id", decode.string)
  |> decode.field("ruleset", ruleset_decoder())
  |> decode.field("map", decode.string)
  |> decode.field("timeout", decode.int)
  |> decode.field("source", decode.string)
}

pub fn decode(json: Dynamic) -> Result(GameState, Nil) {
  let decoder =
    decode.into({
      use game <- decode.parameter
      use turn <- decode.parameter
      use board <- decode.parameter
      use you <- decode.parameter
      GameState(game:, turn:, board:, you:)
    })
    |> decode.field("game", game_decoder())
    |> decode.field("turn", decode.int)
    |> decode.field("board", board_decoder())
    |> decode.field("you", snake_decoder())

  decoder
  |> decode.from(json)
  |> io.debug
  |> result.nil_error
}

pub fn stateful(
  battlesnake: Battlesnake,
  start: fn(GameState) -> state,
  move: fn(GameState, state) -> #(move.Move, state),
  end: fn(GameState, state) -> Nil,
) -> fn(wisp.Request) -> wisp.Response {
  todo
}

pub fn simple(
  battlesnake: Battlesnake,
  callback: fn(GameState) -> move.Move,
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

        let _ = decode(json)

        wisp.ok()
      }
      ["move"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        case decode(json) {
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

        let _ = decode(json)

        wisp.ok()
      }
      _ -> wisp.not_found()
    }
  }
}

pub fn handler(
  request: wisp.Request,
  battlesnake: Battlesnake,
  callback: fn(GameState) -> move.Move,
) -> wisp.Response {
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

      let _ = decode(json)

      wisp.ok()
    }
    ["move"] -> {
      use <- wisp.require_method(request, http.Post)
      use json <- wisp.require_json(request)

      case decode(json) {
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

      let _ = decode(json)

      wisp.ok()
    }
    _ -> wisp.not_found()
  }
}
