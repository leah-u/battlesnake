import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/actor
import gleam/result

pub type DispatcherMessage(a) {
  Insert(game_id: String, actor: a)
  Get(game_id: String, client: Subject(Result(a, Nil)))
  Remove(game_id: String)
}

pub fn new() {
  let assert Ok(actor) = actor.start(dict.new(), handle_message)
  actor
}

fn handle_message(
  message: DispatcherMessage(a),
  games: Dict(String, a),
) -> actor.Next(DispatcherMessage(a), Dict(String, a)) {
  case message {
    Insert(game_id:, actor:) -> {
      let games = dict.insert(games, game_id, actor)
      io.debug(games)
      actor.continue(games)
    }
    Get(game_id:, client:) -> {
      io.debug(games)
      io.println("getting game id: " <> game_id)
      case dict.get(games, game_id) {
        Error(err) -> {
          io.println("not found: ")
          io.debug(err)
          process.send(client, Error(Nil))
          actor.continue(games)
        }
        Ok(actor) -> {
          io.print("found: ")
          io.debug(actor)
          process.send(client, Ok(actor))
          actor.continue(games)
        }
      }
    }
    Remove(game_id) -> {
      let games = dict.delete(games, game_id)
      actor.continue(games)
    }
  }
}

pub fn insert(
  dispatcher: Subject(DispatcherMessage(a)),
  game_id: String,
  actor: a,
) -> Nil {
  actor.send(dispatcher, Insert(game_id, actor))
}

pub fn get(
  dispatcher: Subject(DispatcherMessage(a)),
  game_id: String,
) -> Result(a, Nil) {
  process.try_call(dispatcher, Get(client: _, game_id:), 10)
  |> io.debug
  |> result.nil_error
  |> result.flatten
}

pub fn remove(dispatcher: Subject(DispatcherMessage(a)), game_id: String) -> Nil {
  actor.send(dispatcher, Remove(game_id))
}
