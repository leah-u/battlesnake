import battlesnake/internal/cache
import gleeunit/should

pub fn cache_test() {
  let cache = cache.new()
  cache.insert(cache, "a", 1)
  cache.insert(cache, "b", 2)
  cache.insert(cache, "c", 3)

  cache.get(cache, "a")
  |> should.be_ok
  |> should.equal(1)

  cache.get(cache, "b")
  |> should.be_ok
  |> should.equal(2)

  cache.get(cache, "c")
  |> should.be_ok
  |> should.equal(3)

  cache.get(cache, "d")
  |> should.be_error

  cache.remove(cache, "a")

  cache.get(cache, "a")
  |> should.be_error
}
