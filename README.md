# Gleam Battlesnake

[![Package Version](https://img.shields.io/hexpm/v/battlesnake)](https://hex.pm/packages/battlesnake)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/battlesnake/)

A wrapper for the Battlesnake API, allowing you to start building the logic for
your Battlesnake without worrying about decoding the requests.

To get started, add the following packages to your project:
```sh
gleam add battlesnake mist wisp gleam_erlang
```

You can use the `battlesnake.simple` function to set up a server like this:
```gleam
import battlesnake
import battlesnake/gamestate.{type GameState}
import gleam/erlang/process
import mist
import wisp/wisp_mist

fn on_move(gamestate: GameState) -> battlesnake.Move {
  // This function gets called every turn
  // Ideally your snake would do something more interesting than just
  // moving to the right!
  battlesnake.move(battlesnake.Right)
}

pub fn main() {
  let assert Ok(color) = battlesnake.color_from_hex("#ffaff3")

  let config =
    battlesnake.config()
    |> battlesnake.with_color(color)

  let handler = battlesnake.simple(config, on_move)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler("")
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
```

If you need to preserve some state between turns, you can use the
`battlesnake.stateful` function:
```gleam
import battlesnake
import battlesnake/gamestate.{type GameState}
import gleam/erlang/process
import mist
import wisp/wisp_mist

type MyState {
  MyState
}

fn on_start(gamestate: GameState) -> MyState {
  MyState
}

fn on_move(gamestate: GameState, state: MyState) -> #(battlesnake.Move, MyState) {
  #(battlesnake.move(battlesnake.Up), state)
}

fn on_end(gamestate: GameState, state: MyState) -> Nil {
  Nil
}

pub fn main() {
  let assert Ok(color) = battlesnake.color_from_hex("#ffaff3")

  let config =
    battlesnake.config()
    |> battlesnake.with_color(color)

  let handler = battlesnake.stateful(config, on_start, on_move, on_end)

  let assert Ok(_) =
    handler
    |> wisp_mist.handler("")
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
```

Further documentation can be found at <https://hexdocs.pm/battlesnake>.
