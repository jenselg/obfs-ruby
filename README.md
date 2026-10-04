# OBFS

[![Gem Version](https://badge.fury.io/rb/obfs.svg)](https://badge.fury.io/rb/obfs)

File-based, object-oriented data store for Ruby.

OBFS maps recursive Ruby object access directly to the filesystem, allowing data to be addressed using dot notation, bracket notation, or a combination of both.

```ruby
datastore.users.john.preferences.theme = "dark"

datastore["users"]["john"]["preferences"]["theme"]
# => "dark"
```

The resulting filesystem structure is:

```text
users/
└── john/
    └── preferences/
        └── theme
```

OBFS also includes filesystem discovery helpers, including direct existence checks, recursive fuzzy directory search, timestamps, and directory indexing.


## Quickstart

Add OBFS to your `Gemfile`:

```ruby
gem "obfs"
```

Require it:

```ruby
require "obfs"
```

Create a store:

```ruby
datastore = OBFS::Store.new
```

Write data:

```ruby
datastore.somefile = "some value"

datastore["somefile"] = "some value"
```

Read data:

```ruby
datastore.somefile

datastore["somefile"]
```

Delete data:

```ruby
datastore.somefile = nil

datastore["somefile"] = nil
```

Supported values include:

- String
- Array
- Hash
- Integer
- Float
- Boolean


## Usage

By default, OBFS stores data inside:

```text
~/.obfs
```

A custom path can be specified:

```ruby
datastore = OBFS::Store.new({
  path: "/some/other/folder"
})
```

Paths are recursively created as needed.

For example:

```ruby
datastore.some.long.path.to.create = "some string"
```

creates:

```text
some/
└── long/
    └── path/
        └── to/
            └── create
```

The file `create` contains the JSON-serialized value:

```text
"some string"
```

Bracket notation can also be used:

```ruby
datastore["some"]["long"]["path"]["to"]["create"] = "some string"
```

Dot and bracket notation may be mixed:

```ruby
datastore.some["long"].path["to"].create = "some string"
```

Hashes and arrays are serialized as JSON values into leaf files:

```ruby
datastore.settings = {
  "theme" => "dark",
  "notifications" => true
}

datastore.numbers = [1, 2, 3]
```

Reading those values returns the corresponding Ruby objects:

```ruby
datastore.settings
# => {"theme"=>"dark", "notifications"=>true}

datastore.numbers
# => [1, 2, 3]
```


## Path Safety

Each OBFS key represents exactly one filesystem node.

Nested paths should therefore be expressed recursively:

```ruby
datastore["foo"]["bar"]
```

rather than by embedding filesystem separators:

```ruby
datastore["foo/bar"]
```

OBFS rejects keys containing filesystem path separators, null bytes, `.` or `..`.

For example, the following are rejected:

```ruby
datastore[".."]
datastore["../foo"]
datastore["../../etc/passwd"]
datastore["foo/bar"]
datastore["..\\Windows"]
```

This prevents dynamic OBFS keys from traversing outside the intended datastore hierarchy.


## Special Methods

### `_path`

Returns the current filesystem path.

```ruby
datastore.some.data._path
```

Example:

```text
/home/user/.obfs/some/data
```


### `_index`

Returns the entries in the current directory.

```ruby
datastore.some.data._index
```

Example:

```ruby
[
  "foo",
  "bar",
  "baz"
]
```


### `_keys`

Alias for `_index`.

```ruby
datastore.some.data._keys
```


### `_find`

Performs a fuzzy search against entries in the current directory only.

```ruby
datastore.some.data._find("some term")
```

Full signature:

```ruby
datastore.some.data._find(term, records, tolerance)
```

Arguments:

- `term` - search term
- `records` - maximum number of records to return; defaults to `1000`
- `tolerance` - maximum Levenshtein distance; defaults to `50`

Results are returned as an array of entry names sorted by relevance.

Example:

```ruby
datastore.services._find("nginx")
```

might return:

```ruby
[
  "nginx",
  "nginx_config",
  "old_nginx"
]
```

`_find` searches only the current directory level.


### `_exist`

Checks whether an immediate child with the specified name exists.

```ruby
datastore.some.data._exist("some term")
```

Returns:

```ruby
true
```

or:

```ruby
false
```

This method is retained for compatibility with earlier versions of OBFS.


### `_exists`

Checks whether the current OBFS node physically exists.

```ruby
datastore.some.data._exists
```

A question-mark alias is also available:

```ruby
datastore.some.data._exists?
```

Example:

```ruby
datastore.services.nginx._exists?
# => true
```


### `_has`

Checks whether an immediate child exists.

```ruby
datastore.services._has("nginx")
```

A question-mark alias is also available:

```ruby
datastore.services._has?("nginx")
```

Returns:

```ruby
true
```

or:

```ruby
false
```

Unlike `_exist`, `_has` performs a direct filesystem existence check rather than enumerating the current directory.


### `_timestamp`

Returns the modification time of the current filesystem node.

```ruby
datastore.services.nginx._timestamp
```

Returns a Ruby `Time` object when the node exists:

```ruby
2026-10-04 14:30:00 -0700
```

or:

```ruby
nil
```

if the node does not exist or cannot be read.


### `_search`

Performs a fuzzy search against directory names and relative directory paths.

Unlike `_find`, `_search` can recursively search the entire directory hierarchy beneath the current OBFS node.

Basic usage:

```ruby
datastore._search("nginx")
```

Example result:

```ruby
[
  {
    path: "systems/services/nginx",
    score: 1.0
  },
  {
    path: "systems/services/nginx/certificates",
    score: 0.9
  }
]
```

Search may also be scoped to any recursive OBFS node:

```ruby
datastore.systems.services._search("nginx")
```

Options can be supplied using a hash:

```ruby
datastore._search(
  "nginx certificate",
  {
    recursive: true,
    min_score: 0.6,
    limit: 10
  }
)
```

Available options:

- `recursive` - recursively search child directories; defaults to `true`
- `min_score` - minimum fuzzy relevance score from `0.0` to `1.0`; defaults to `0.5`
- `limit` - maximum number of results; unlimited by default

`minScore` is also accepted for compatibility with the JavaScript version:

```ruby
datastore._search(
  "nginx",
  {
    minScore: 0.6
  }
)
```

Search results are sorted from highest to lowest relevance.

`_search`:

- searches directory names
- searches relative directory paths
- does not read stored file contents
- does not follow symbolic links
- ignores dot-prefixed entries
- is scoped to the current OBFS node


## `_find` vs `_search`

`_find` is intended for lightweight one-level discovery:

```ruby
datastore.services._find("nginx")
```

and returns:

```ruby
[
  "nginx",
  "nginx_config"
]
```

`_search` is intended for deeper discovery:

```ruby
datastore._search("nginx certificate")
```

and returns scored relative paths:

```ruby
[
  {
    path: "systems/services/nginx/certificates",
    score: 0.95
  }
]
```


## Recursive Object Storage

One of the primary goals of OBFS is to allow the filesystem to behave like an arbitrarily recursive Ruby object.

For example:

```ruby
datastore.projects.example.servers.production.services.nginx.status = "running"
```

can later be accessed using the same structure:

```ruby
datastore.projects.example.servers.production.services.nginx.status
# => "running"
```

The hierarchy itself is stored using physical directories and files, making the datastore directly inspectable using normal filesystem tools.


## Notes

- OBFS uses the filesystem directly as its persistence layer.
- Intermediate paths are created automatically when writing data.
- Setting a value to `nil` removes the corresponding file or directory recursively.
- Existing values are replaced when reassigned.
- JSON-compatible values are serialized using Ruby's JSON library.
- Files containing valid JSON are deserialized when read.
- Non-JSON files are returned as raw text.
- Fuzzy search uses OBFS's existing Levenshtein and text similarity implementations.
- No database server is required.


## Platform Support

OBFS has been tested with Ruby >= 2.0.0 on Linux.

Windows and macOS have not been formally tested.


## Links

- [RubyGems](https://rubygems.org/gems/obfs)
- [GitHub](https://github.com/jenselg/obfs-ruby)
- [JavaScript / Node.js Version](https://github.com/jenselg/obfs)


## Credits

- [Text](https://github.com/threedaymonk/text) - Ruby gem containing text-processing algorithms used by OBFS.


## License

### MIT License

Copyright (c) 2021 Jensel Gatchalian <jensel.gatchalian@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.