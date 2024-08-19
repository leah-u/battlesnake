import battlesnake/internal/cache
import gleam/io
import gleeunit/should

pub fn cache_test() {
  let cache = cache.new()
  cache.insert(cache, "a", 1)
  cache.insert(cache, "b", 2)
  cache.insert(cache, "c", 3)

  io.debug(cache)
  cache.get(cache, "a")
  |> should.be_ok
  |> should.equal(1)

  io.debug(cache)
  cache.get(cache, "b")
  |> should.be_ok
  |> should.equal(2)

  io.debug(cache)
  cache.get(cache, "c")
  |> should.be_ok
  |> should.equal(3)

  io.debug(cache)
  cache.get(cache, "d")
  |> should.be_error

  io.debug(cache)
  cache.remove(cache, "a")

  io.debug(cache)
  cache.get(cache, "a")
  |> should.be_error
}
