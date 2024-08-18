import gleam/io
import gleeunit/should
import internal/dispatcher

pub fn dispatcher_test() {
  let dispatcher = dispatcher.new()
  dispatcher.insert(dispatcher, "a", 1)
  dispatcher.insert(dispatcher, "b", 2)
  dispatcher.insert(dispatcher, "c", 3)

  io.debug(dispatcher)
  dispatcher.get(dispatcher, "a")
  |> should.be_ok
  |> should.equal(1)

  io.debug(dispatcher)
  dispatcher.get(dispatcher, "b")
  |> should.be_ok
  |> should.equal(2)

  io.debug(dispatcher)
  dispatcher.get(dispatcher, "c")
  |> should.be_ok
  |> should.equal(3)

  io.debug(dispatcher)
  dispatcher.get(dispatcher, "d")
  |> should.be_error

  io.debug(dispatcher)
  dispatcher.remove(dispatcher, "a")

  io.debug(dispatcher)
  dispatcher.get(dispatcher, "a")
  |> should.be_error
}
