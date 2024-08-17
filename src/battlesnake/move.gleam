import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/string

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

pub type Move {
  Move(direction: Direction, shout: Option(String))
}

pub fn new(direction: Direction) -> Move {
  Move(direction:, shout: None)
}

pub fn with_shout(move: Move, shout: String) -> Move {
  Move(..move, shout: Some(shout))
}

// Limits the shout to 256 characters or less as per the specs
fn limit_shout_length(shout: String) -> String {
  string.slice(shout, 0, 256)
}

pub fn to_json(move: Move) -> Json {
  json.object([
    #("move", json.string(move.direction |> direction_to_string)),
    #(
      "shout",
      json.nullable(move.shout |> option.map(limit_shout_length), json.string),
    ),
  ])
}
