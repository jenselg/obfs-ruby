# OBFS
[![Gem Version](https://badge.fury.io/rb/obfs.svg)](https://badge.fury.io/rb/obfs)

File-based, object-oriented data store for Ruby.


## Quickstart

- Add in your gemfile: `gem "obfs"`
- Require in your project: `require "obfs"`
- Start a new store: `datastore = OBFS::Store.new`
- Reading data from store: `datastore.somefile` or `datastore["somefile"]` 
- Writing data to store: `datastore.somefile = "some value"` or `datastore["somefile"] = "some value"`
- Deleting data from store: `datastore.somefile = nil` or `datastore["somefile"] = nil` or set to another value
- Valid values: string, array, hash, integer, float, boolean


## Usage / Notes

- A hash `{}` argument can be passed to `OBFS::Store.new`
- By default, the `path` is set to an `.obfs` folder inside your home folder
- A custom `path` can be set by providing an absolute path to the hash argument in `OBFS::Store.new`, i.e. `datastore = OBFS::Store.new { path: "/some/other/folder" }`
- Paths are recursively created, i.e. `datastore.some.long.path.to.create = "some string"` will recursively create the folders `datastore/some/long/path/to`, and create a file called `create` containing the string value `"some string"`
- You can also do: `datastore["some"]["long"]["path"]["to"]["create"] = "some string"`
- You can mix and match between dot and bracket notation: `datastore.some["long"].path["to"].create`
- Tested in Ruby 2.6.3 and 3.0.0, in Linux. Untested in Windows and MacOS.


## Special Methods

`_path`
- Basic usage: `datastore.some.data._path`
- Returns the current filesystem path in a string

`_index`
- Basic usage: `datastore.some.data._index`
- Returns the current directory's content filenames in an array

`_find term, records, tolerance`
- Basic usage: `datastore.some.data._find "some term"`
- Searches the current directory's content filenames and returns the results in an array
- `term` - term to search for - should be a string
- `records` - number of records to return - set to `1000` by default 
- `tolerance` - Levenshtein distance between the term and possible results - set to `50` by default

`_exist term`
- Basic usage: `datastore.some.data._exist "some term"`
- Searches the current directory's content filenames and returns `true` if the term exists, else it returns `false`


## Links
- [RubyGems](https://rubygems.org/gems/obfs) 
- [GitHub](https://github.com/jenselg/obfs-ruby)
- [JavaScript / Node.js Version](https://github.com/jenselg/obfs)


## Credits
- [Text](https://github.com/threedaymonk/text) - Ruby gem with a collection of text algorithms


## License

#### MIT License

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
