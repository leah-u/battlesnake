import battlesnake/gamestate.{type GameState}
import battlesnake/internal/cache
import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import wisp

/// The direction for your Battlesnake to move in.
pub type Direction {
  Up
  Down
  Left
  Right
}

fn direction_to_string(direction: Direction) -> String {
  case direction {
    Up -> "up"
    Down -> "down"
    Left -> "left"
    Right -> "right"
  }
}

/// The response to move requests.
pub type Move {
  Move(direction: Direction, shout: Option(String))
}

/// Create a move response with the given direction
pub fn move(direction: Direction) -> Move {
  Move(direction:, shout: None)
}

/// Add an optional message to the move response that the other snakes can see
pub fn shout(move: Move, shout: String) -> Move {
  Move(..move, shout: Some(shout))
}

fn move_to_json(move: Move) -> Json {
  json.object([
    #("move", json.string(move.direction |> direction_to_string)),
    #(
      "shout",
      json.nullable(
        // Limit the message to 256 characters as per the docs
        move.shout |> option.map(string.slice(_, 0, 256)),
        json.string,
      ),
    ),
  ])
}

/// A representation of the color of a Battlesnake
pub opaque type Color {
  Color(red: Int, green: Int, blue: Int)
}

/// Convert a hex string to a Battlesnake color.
/// 
/// Accepts the formats '#000000' or '000000'.
pub fn color_from_hex(color: String) -> Result(Color, Nil) {
  use hex <- result.try(case color, string.length(color) {
    "#" <> rest, 7 -> Ok(rest)
    _, 6 -> Ok(color)
    _, _ -> Error(Nil)
  })
  use red <- result.try(string.slice(hex, 0, 2) |> int.base_parse(16))
  use green <- result.try(string.slice(hex, 2, 2) |> int.base_parse(16))
  use blue <- result.try(string.slice(hex, 4, 2) |> int.base_parse(16))

  color_from_rgb(red, green, blue)
}

/// Create a Battlesnake color from red, green and blue components.
/// 
/// Each value must be in the range 0..255.
pub fn color_from_rgb(
  r red: Int,
  g green: Int,
  b blue: Int,
) -> Result(Color, Nil) {
  use <- bool.guard(
    red < 0
      || red >= 256
      || green < 0
      || green >= 256
      || blue < 0
      || blue >= 256,
    Error(Nil),
  )

  let color = Color(red:, green:, blue:)
  Ok(color)
}

@internal
pub fn color_to_string(color: Color) -> String {
  let red_string = int.to_base16(color.red) |> string.pad_left(to: 2, with: "0")
  let green_string =
    int.to_base16(color.green) |> string.pad_left(to: 2, with: "0")
  let blue_string =
    int.to_base16(color.blue) |> string.pad_left(to: 2, with: "0")

  "#" <> red_string <> green_string <> blue_string
}

/// Configures how your snake looks.
pub type SnakeConfig {
  SnakeConfig(
    /// Version of the Battlesnake API implemented by this Battlesnake. Currently only API version 1 is valid. Example: "1"
    apiversion: String,
    /// Username of the author of this Battlesnake. If provided, this will be used to verify ownership. Example: "BattlesnakeOfficial"
    author: Option(String),
    /// Color of the Battlesnake.
    color: Option(Color),
    /// Head customization. Example: "default"
    head: Option(String),
    /// Tail customization. Example: "default"
    tail: Option(String),
    /// Optional version string for your Battlesnake. This value is not used in gameplay, but can be useful for tracking deployments on your end.
    version: Option(String),
  )
}

/// Create a base Battlesnake config.
pub fn config() -> SnakeConfig {
  SnakeConfig(
    apiversion: "1",
    author: None,
    color: None,
    head: None,
    tail: None,
    version: None,
  )
}

/// Add your Battlesnake username. If provided, this will be used to verify ownership.
pub fn with_author(battlesnake: SnakeConfig, author: String) -> SnakeConfig {
  SnakeConfig(..battlesnake, author: Some(author))
}

/// Add a color to your Battlesnake.
pub fn with_color(battlesnake: SnakeConfig, color: Color) -> SnakeConfig {
  SnakeConfig(..battlesnake, color: Some(color))
}

/// Add a head customization.
pub fn with_head(battlesnake: SnakeConfig, head: String) -> SnakeConfig {
  SnakeConfig(..battlesnake, head: Some(head))
}

/// Add a head customization.
pub fn with_tail(battlesnake: SnakeConfig, tail: String) -> SnakeConfig {
  SnakeConfig(..battlesnake, tail: Some(tail))
}

/// Add an optional version string to your Battlesnake. This value is not used in gameplay, but can be useful for tracking deployments on your end.
pub fn with_version(battlesnake: SnakeConfig, version: String) -> SnakeConfig {
  SnakeConfig(..battlesnake, version: Some(version))
}

fn config_to_json(battlesnake: SnakeConfig) -> Json {
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

/// Use this function if your algorithm doesn't need to persist any state
/// between moves. The returned handler ignores `/start` and `/end` requests and
/// call your `on_move` function on every turn.
pub fn simple(
  config config: SnakeConfig,
  on_move callback: fn(GameState) -> Move,
) -> fn(wisp.Request) -> wisp.Response {
  fn(request) {
    case wisp.path_segments(request) {
      [] -> {
        config
        |> config_to_json
        |> json.to_string_builder
        |> wisp.json_response(200)
      }
      ["start"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        case gamestate.decode(json) {
          Ok(_) -> wisp.ok()
          Error(_) -> wisp.bad_request()
        }
      }
      ["move"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        case gamestate.decode(json) {
          Error(_) -> wisp.bad_request()
          Ok(gamestate) -> {
            callback(gamestate)
            |> move_to_json
            |> json.to_string_builder
            |> wisp.json_response(200)
          }
        }
      }
      ["end"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        case gamestate.decode(json) {
          Ok(_) -> wisp.ok()
          Error(_) -> wisp.bad_request()
        }
      }
      _ -> wisp.not_found()
    }
  }
}

type GameMessage {
  GameMove(client: Subject(Move), gamestate: GameState)
  GameEnd(gamestate: GameState)
}

fn create_game_handler(
  move: fn(GameState, state) -> #(Move, state),
  end: fn(GameState, state) -> Nil,
) -> fn(GameMessage, state) -> actor.Next(GameMessage, state) {
  fn(message, state) {
    case message {
      GameMove(client:, gamestate:) -> {
        let #(next_move, next_state) = move(gamestate, state)
        process.send(client, next_move)
        actor.continue(next_state)
      }
      GameEnd(gamestate:) -> {
        end(gamestate, state)
        actor.Stop(process.Normal)
      }
    }
  }
}

fn try(result: Result(a, b), on_error: fn() -> c, fun: fn(a) -> c) -> c {
  case result {
    Error(_) -> on_error()
    Ok(ok) -> fun(ok)
  }
}

/// This function lets you persist state between turns per game.
pub fn stateful(
  config config: SnakeConfig,
  on_start start: fn(GameState) -> state,
  on_move move: fn(GameState, state) -> #(Move, state),
  on_end end: fn(GameState, state) -> Nil,
) -> fn(wisp.Request) -> wisp.Response {
  let games_cache = cache.new()
  let game_handler = create_game_handler(move, end)

  fn(request) {
    case wisp.path_segments(request) {
      [] -> {
        config
        |> config_to_json
        |> json.to_string_builder
        |> wisp.json_response(200)
      }
      ["start"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        use gamestate <- try(gamestate.decode(json), wisp.bad_request)
        let initial_state = start(gamestate)
        use actor <- try(
          actor.start(initial_state, game_handler),
          wisp.internal_server_error,
        )
        let game_id = gamestate.game.id
        cache.insert(games_cache, game_id, actor)
        wisp.ok()
      }
      ["move"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        use gamestate <- try(gamestate.decode(json), wisp.bad_request)
        let game_id = gamestate.game.id
        use actor <- try(cache.get(games_cache, game_id), wisp.bad_request)
        use move <- try(
          process.try_call(actor, GameMove(client: _, gamestate:), 500),
          wisp.internal_server_error,
        )
        move
        |> move_to_json
        |> json.to_string_builder
        |> wisp.json_response(200)
      }
      ["end"] -> {
        use <- wisp.require_method(request, http.Post)
        use json <- wisp.require_json(request)

        use gamestate <- try(gamestate.decode(json), wisp.bad_request)
        let game_id = gamestate.game.id
        use actor <- try(cache.get(games_cache, game_id), wisp.bad_request)
        process.send(actor, GameEnd(gamestate:))
        cache.remove(games_cache, game_id)
        wisp.ok()
      }
      _ -> wisp.not_found()
    }
  }
}
