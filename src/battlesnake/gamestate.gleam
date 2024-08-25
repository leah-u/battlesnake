import decode
import gleam/dynamic.{type Dynamic}
import gleam/result

/// This gets sent by the server every time a game starts, ends, or a turn is requested.
pub type GameState {
  GameState(
    game: Game,
    /// Turn number (starting at 0 for new games).
    turn: Int,
    board: Board,
    you: Battlesnake,
  )
}

/// Holds general information about the current game.
pub type Game {
  Game(
    /// A unique identifier for this game.
    id: String,
    /// Information about the ruleset being used to run this game.
    ruleset: Ruleset,
    /// The name of the map being played on.
    map: String,
    /// How much time your snake has to respond to requests for this game in milliseconds. 
    timeout: Int,
    /// The source of this game. One of:
    /// * "tournament"
    /// * "league" (for League Arenas)
    /// * "arena" (for all other Arenas)
    /// * "challenge"
    /// * "custom" (for all other games sources)
    ///
    /// The values for this field may change in the near future.
    source: String,
  )
}

/// A position on the game board. (0,0) is in the bottom left.
pub type Position {
  Position(x: Int, y: Int)
}

pub type Board {
  Board(
    /// The number of rows in the y-axis of the game board.
    height: Int,
    /// The number of columns in the x-axis of the game board.
    width: Int,
    /// List of coordinates representing food locations on the game board.
    food: List(Position),
    /// List of coordinates representing hazardous locations on the game board. 
    hazards: List(Position),
    /// Array of Battlesnake Objects representing all Battlesnakes remaining on
    /// the game board (including yourself if you haven't been eliminated).
    snakes: List(Battlesnake),
  )
}

/// A Battlesnake on the board.
pub type Battlesnake {
  Battlesnake(
    /// Unique identifier for this Battlesnake in the context of the current game.
    id: String,
    /// Name given to this Battlesnake by its author.
    name: String,
    /// Health value of this Battlesnake, between 0 and 100 inclusively.
    health: Int,
    /// List of coordinates representing this Battlesnake's location on the game
    /// board. This list is ordered from head to tail.
    body: List(Position),
    /// The previous response time of this Battlesnake, in milliseconds. If the
    /// Battlesnake timed out and failed to respond, the game timeout will be
    /// returned (`game.timeout`).
    latency: String,
    /// Coordinates for this Battlesnake's head. Equivalent to the first element of the body list.
    head: Position,
    /// Length of this Battlesnake from head to tail. Equivalent to the length of the body list.
    length: Int,
    /// Message shouted by this Battlesnake on the previous turn.
    shout: String,
    /// The squad that the Battlesnake belongs to. Used to identify squad members in Squad Mode games.
    squad: String,
    /// The collection of customizations that control how this Battlesnake is displayed.
    customizations: Customizations,
  )
}

/// The collection of customizations that control how this Battlesnake is displayed.
pub type Customizations {
  Customizations(color: String, head: String, tail: String)
}

pub type Ruleset {
  Ruleset(
    /// Name of the ruleset being used to run this game.
    name: String,
    /// The release version of the [Rules](https://github.com/BattlesnakeOfficial/rules) module used in this game.
    version: String,
    /// A collection of specific settings being used by the current game that control how the rules are applied.
    settings: RulesetSettings,
  )
}

/// A collection of specific settings being used by the current game that control how the rules are applied.
pub type RulesetSettings {
  RulesetSettings(
    /// Percentage chance of spawning a new food every round.
    food_spawn_chance: Int,
    /// Minimum food to keep on the board every turn.
    minimum_food: Int,
    /// Health damage a snake will take when ending its turn in a hazard. This stacks on top of the regular 1 damage a snake takes per turn.
    hazard_damage_per_turn: Int,
    /// Ruleset settings for the Royale gamemode.
    royale: RoyaleSettings,
    /// Ruleset settings for the Squad gamemode.
    squad: SquadSettings,
  )
}

/// Ruleset settings for the Royale gamemode.
pub type RoyaleSettings {
  RoyaleSettings(
    /// In Royale mode, the number of turns between generating new hazards (shrinking the safe board space).
    shrink_every_n_turns: Int,
  )
}

/// Ruleset settings for the Squad gamemode.
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

fn position_decoder() -> decode.Decoder(Position) {
  decode.into({
    use x <- decode.parameter
    use y <- decode.parameter
    Position(x:, y:)
  })
  |> decode.field("x", decode.int)
  |> decode.field("y", decode.int)
}

fn customizations_decoder() -> decode.Decoder(Customizations) {
  decode.into({
    use color <- decode.parameter
    use head <- decode.parameter
    use tail <- decode.parameter
    Customizations(color:, head:, tail:)
  })
  |> decode.field("color", decode.string)
  |> decode.field("head", decode.string)
  |> decode.field("tail", decode.string)
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
    use customizations <- decode.parameter
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
      customizations:,
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
  |> decode.field("customizations", customizations_decoder())
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
