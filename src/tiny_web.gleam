import gleam/string
import gleam/atom
import gleam/list
import gleam/iodata
import gleam/elli
import gleam/http
import tiny_db
import tiny_html

fn home() {
  elli.Response(200, [], tiny_html.home())
}

fn extract_link(formdata) {
  formdata
  |> string.split(_, "\n")
  |> list.map(_, string.split(_, "="))
  |> list.find(_, fn(parts) {
    case parts {
    | ["link", link] -> link |> elli.uri_decode |> Ok
    | _other -> Error(0)
    }
  })
}

fn create_link(payload) {
  case extract_link(payload) {
  | Ok(link) ->
      let id = tiny_db.save(link)
      // TODO. HTML
      elli.Response(201, [], iodata.new(id))

  | Error(_) ->
      // TODO. HTML
      elli.Response(422, [], iodata.new("That doesn't look right."))
  }
}

fn get_link(id) {
  case tiny_db.get(id) {
  | Ok(link) ->
      elli.Response(200, [], iodata.new(link))

  | Error(_) ->
      elli.Response(404, [], tiny_html.not_found())
  }
}

fn not_found() {
  elli.Response(404, [], tiny_html.not_found())
}

struct Pair(a, b) {
  first: a
  second: b
}

pub fn handle(request, _args) -> elli.Response {
  let method = elli.method(request)
  let path = elli.path(request)

  case Pair(method, path) {
  | Pair(http.Get, []) ->
      home()

  | Pair(http.Post, ["link"]) ->
      request |> elli.body |> create_link

  | Pair(http.Get, ["link", id]) ->
      get_link(id)

  | _ ->
      not_found()
  }
}

pub enum Unit =
| Ok

pub fn handle_event(_event, _data, _args) -> Unit {
  Ok
}
