import decode
import gleam/dynamic.{type Dynamic}
import gleam/result

pub type RulesetSettings {
  RulesetSettings(
    /// Percentage chance of spawning a new food every round.
    food_spawn_chance: Int,
    /// Minimum food to keep on the board every turn.
    minimum_food: Int,
    /// Health damage a snake will take when ending its turn in a hazard. This stacks on top of the regular 1 damage a snake takes per turn.
    hazard_damage_per_turn: Int,
    royale: RoyaleSettings,
    squad: SquadSettings,
  )
}

pub type RoyaleSettings {
  RoyaleSettings(
    /// In Royale mode, the number of turns between generating new hazards (shrinking the safe board space).
    shrink_every_n_turns: Int,
  )
}

pub type SquadSettings {
  SquadSettings(
    /// In Squad mode, allow members of the same squad to move over each other without dying.
    allow_body_collisions: Bool,
    /// In Squad mode, all squad members are eliminated when one is eliminated.
    shared_elimination: Bool,
    /// In Squad mode, all squad members share health.
    shared_health: Bool,
    /// In Squad mode, all squad members share length.
    shared_length: Bool,
  )
}

fn squad_settings_decoder() -> decode.Decoder(SquadSettings) {
  decode.into({
    use allow_body_collisions <- decode.parameter
    use shared_elimination <- decode.parameter
    use shared_health <- decode.parameter
    use shared_length <- decode.parameter
    SquadSettings(
      allow_body_collisions:,
      shared_elimination:,
      shared_health:,
      shared_length:,
    )
  })
  |> decode.field("allowBodyCollisions", decode.bool)
  |> decode.field("sharedElimination", decode.bool)
  |> decode.field("sharedHealth", decode.bool)
  |> decode.field("sharedLength", decode.bool)
}

fn royale_settings_decoder() -> decode.Decoder(RoyaleSettings) {
  decode.into({
    use shrink_every_n_turns <- decode.parameter
    RoyaleSettings(shrink_every_n_turns:)
  })
  |> decode.field("shrinkEveryNTurns", decode.int)
}

fn ruleset_settings_decoder() -> decode.Decoder(RulesetSettings) {
  decode.into({
    use food_spawn_chance <- decode.parameter
    use minimum_food <- decode.parameter
    use hazard_damage_per_turn <- decode.parameter
    use royale <- decode.parameter
    use squad <- decode.parameter
    RulesetSettings(
      food_spawn_chance:,
      minimum_food:,
      hazard_damage_per_turn:,
      royale:,
      squad:,
    )
  })
  |> decode.field("foodSpawnChance", decode.int)
  |> decode.field("minimumFood", decode.int)
  |> decode.field("hazardDamagePerTurn", decode.int)
  |> decode.field("royale", royale_settings_decoder())
  |> decode.field("squad", squad_settings_decoder())
}

pub type Ruleset {
  Ruleset(name: String, version: String, settings: RulesetSettings)
}

fn ruleset_decoder() -> decode.Decoder(Ruleset) {
  decode.into({
    use name <- decode.parameter
    use version <- decode.parameter
    use settings <- decode.parameter
    Ruleset(name:, version:, settings:)
  })
  |> decode.field("name", decode.string)
  |> decode.field("version", decode.string)
  |> decode.field("settings", ruleset_settings_decoder())
}

pub type Board {
  Board(
    height: Int,
    width: Int,
    food: List(Position),
    hazards: List(Position),
    snakes: List(Battlesnake),
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

pub type Battlesnake {
  Battlesnake(
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

fn snake_decoder() -> decode.Decoder(Battlesnake) {
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
    Battlesnake(
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
  GameState(game: Game, turn: Int, board: Board, you: Battlesnake)
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

@internal
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
