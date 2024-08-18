import battlesnake/dispatcher
import battlesnake/gamestate.{type GameState}
import battlesnake/move
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/io
import gleam/json
import gleam/otp/actor
import gleam/result
import wisp

pub type GameMessage {
  Move(client: Subject(move.Move), gamestate: GameState)
  End(gamestate: GameState)
}

fn create_game_handler(
  move: fn(GameState, state) -> #(move.Move, state),
  end: fn(GameState, state) -> Nil,
) -> fn(GameMessage, state) -> actor.Next(GameMessage, state) {
  fn(message, state) {
    case message {
      Move(client:, gamestate:) -> {
        let #(next_move, next_state) = move(gamestate, state)
        process.send(client, next_move)
        actor.continue(next_state)
      }
      End(gamestate:) -> {
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

pub fn stateful(
  request,
  battlesnake: wisp.Response,
  dispatcher,
  start: fn(GameState) -> state,
  move: fn(GameState, state) -> #(move.Move, state),
  end: fn(GameState, state) -> Nil,
) -> wisp.Response {
  io.debug(dispatcher)
  let game_handler = create_game_handler(move, end)

  case wisp.path_segments(request) {
    [] -> {
      battlesnake
    }
    ["start"] -> {
      use <- wisp.require_method(request, http.Post)
      use json <- wisp.require_json(request)

      use gamestate <- try(gamestate.decode(json), fn() {
        io.println("Could not decode game state")
        wisp.bad_request()
      })
      let initial_state = start(gamestate)
      use actor <- try(
        actor.start(initial_state, game_handler),
        wisp.internal_server_error,
      )
      let game_id = gamestate.game.id
      io.debug(dispatcher)
      dispatcher.insert(dispatcher, game_id, actor)
      wisp.ok()
    }
    ["move"] -> {
      use <- wisp.require_method(request, http.Post)
      use json <- wisp.require_json(request)

      use gamestate <- try(gamestate.decode(json), fn() {
        io.println("Could not decode game state")
        wisp.bad_request()
      })
      let game_id = gamestate.game.id
      io.debug(dispatcher)
      use actor <- try(dispatcher.get(dispatcher, game_id), wisp.bad_request)
      use move <- try(
        process.try_call(actor, Move(client: _, gamestate:), 500),
        wisp.internal_server_error,
      )
      move
      |> move.to_json
      |> json.to_string_builder
      |> wisp.json_response(200)
    }
    ["end"] -> {
      use <- wisp.require_method(request, http.Post)
      use json <- wisp.require_json(request)

      use gamestate <- try(gamestate.decode(json), fn() {
        io.println("Could not decode game state")
        wisp.bad_request()
      })
      let game_id = gamestate.game.id
      use actor <- try(dispatcher.get(dispatcher, game_id), wisp.bad_request)
      process.send(actor, End(gamestate:))
      dispatcher.remove(dispatcher, game_id)
      wisp.ok()
    }
    _ -> wisp.not_found()
  }
}
