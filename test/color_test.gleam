import battlesnake
import gleam/string
import gleeunit/should

pub fn color_hex_hash_test() {
  battlesnake.color_from_hex("#123456")
  |> should.be_ok
  |> battlesnake.color_to_string
  |> string.uppercase
  |> should.equal("#123456")
}

pub fn color_hex_no_hash_test() {
  battlesnake.color_from_hex("1F3Cee")
  |> should.be_ok
  |> battlesnake.color_to_string
  |> string.uppercase
  |> should.equal("#1F3CEE")
}

pub fn color_too_short_fail_test() {
  battlesnake.color_from_hex("fff")
  |> should.be_error
}

pub fn color_nan_fail_test() {
  battlesnake.color_from_hex("#12345R")
  |> should.be_error
}

pub fn color_rgb_test() {
  battlesnake.color_from_rgb(0, 16, 255)
  |> should.be_ok
  |> battlesnake.color_to_string
  |> string.uppercase
  |> should.equal("#0010FF")
}

pub fn color_rgb_negative_fail_test() {
  battlesnake.color_from_rgb(-1, 16, 255)
  |> should.be_error
}

pub fn color_rgb_too_big_fail_test() {
  battlesnake.color_from_rgb(0, 256, 255)
  |> should.be_error
}
