# OBFS

- File-based, object-oriented data store for Ruby.


## Quickstart

- Gemfile: `gem "obfs"`
- Require in your project: `require "obfs"`
- Start a new store: `datastore = OBFS.new`
- Reading data from store: `datastore.somefile` or `datastore["somefile"]` 
- Writing data to store: `datastore.somefile = "some value"` or `datastore["somefile"] = "some value"`
- Deleting data from store: `datastore.somefile = nil` or `datastore["somefile"] = nil` 
- Valid values: String, Array, Hash, Integer, Float, Boolean


## Usage / Notes

- A Hash {} Argument can be passed to `OBFS.new`
- By default, the `path` is set to an `.obfs` folder inside your home folder
- A custom `path` can be set by providing an absolute path to the hash argument in `OBFS.new`, i.e. `datastore = OBFS.new { path: "/some/other/folder" }`
- Paths are recursively created, i.e. `datastore.some.long.path.to.create = "some string"` will recursively create the folders `datastore/some/long/path/to`, and create a file called `create` containing the string value
- You can also do: `datastore["some"]["long"]["path"]["to"]["create"] = "some string"`
- Tested on Ruby 3.0.0, in Linux. Untested in Windows, MacOS, and Ruby < 3.0.0


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
- `tolerance` - Levenshtein distance between the term and possible results - set to `10` by default

`_exist term`
- Basic usage: `datastore.some.data._exist "some term"`
- Searches the current directory's content filenames and returns `true` if the term exists, else it returns `false`


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
