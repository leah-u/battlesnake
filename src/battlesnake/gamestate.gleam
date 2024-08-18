import decode
import gleam/dynamic.{type Dynamic}
import gleam/result

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
  |> result.nil_error
}
