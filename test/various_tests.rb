require "./test_core.rb"

store = OBFS::Store.new({ path: "/tmp/obfs_test" })

iteration = 10000


# ============================================================
# HELPERS
# ============================================================

def assert(condition, message)
    raise "FAILED: #{message}" unless condition
    puts "PASS: #{message}"
end


def assert_raises(message)
    begin
        yield
    rescue RuntimeError
        puts "PASS: #{message}"
        return true
    end

    raise "FAILED: #{message}"
end


# ============================================================
# CLEAN START
# ============================================================

puts "CLEANING PREVIOUS TEST DATA..."

store["uuid_generator"] = nil
store["basic_test"] = nil
store["search_test"] = nil
store["traversal_test"] = nil

puts "DONE!"
puts


# ============================================================
# ORIGINAL UUID / RECURSION BENCHMARK
# ============================================================

puts "START:"
puts

Benchmark.bmbm do |x|

    x.report("UUID Generator") {

        iteration.times do |i|

            puts "Iteration: #{i}"

            store["uuid_generator"][
                SecureRandom.uuid
            ][
                SecureRandom.uuid
            ][
                SecureRandom.uuid
            ][
                SecureRandom.uuid
            ][
                SecureRandom.uuid
            ][
                SecureRandom.uuid
            ] = SecureRandom.uuid

        end

    }

end

puts


# ============================================================
# BASIC READ / WRITE
# ============================================================

puts "BASIC READ / WRITE TESTS:"
puts

store["basic_test"]["string"] = "hello"
assert(
    store["basic_test"]["string"] == "hello",
    "String write/read"
)


store["basic_test"]["integer"] = 12345
assert(
    store["basic_test"]["integer"] == 12345,
    "Integer write/read"
)


store["basic_test"]["boolean"] = true
assert(
    store["basic_test"]["boolean"] == true,
    "Boolean write/read"
)


store["basic_test"]["array"] = [1, 2, 3]
assert(
    store["basic_test"]["array"] == [1, 2, 3],
    "Array write/read"
)


store["basic_test"]["hash"] = {
    "foo" => "bar",
    "number" => 123
}

assert(
    store["basic_test"]["hash"] == {
        "foo" => "bar",
        "number" => 123
    },
    "Hash write/read"
)


# ============================================================
# RECURSION
# ============================================================

puts
puts "RECURSION TESTS:"
puts

store["basic_test"]["deep"]["one"]["two"]["three"] = "success"

assert(
    store["basic_test"]["deep"]["one"]["two"]["three"] == "success",
    "Recursive bracket access"
)


store.basic_test.dot_notation.recursive.test = "success"

assert(
    store.basic_test.dot_notation.recursive.test == "success",
    "Recursive dot notation"
)


# ============================================================
# PATH / INDEX
# ============================================================

puts
puts "PATH / INDEX TESTS:"
puts

assert(
    store["basic_test"]._path.end_with?("/basic_test"),
    "_path returns correct path"
)


index = store["basic_test"]._index

assert(
    index.include?("string"),
    "_index contains written data"
)


keys = store["basic_test"]._keys

assert(
    keys.include?("string"),
    "_keys alias works"
)


# ============================================================
# EXISTENCE
# ============================================================

puts
puts "EXISTENCE TESTS:"
puts

assert(
    store["basic_test"]._exists,
    "_exists detects existing node"
)


assert(
    store["basic_test"]._exists?,
    "_exists? detects existing node"
)


assert(
    !store["does_not_exist"]._exists?,
    "_exists? returns false for missing node"
)


assert(
    store._exist("basic_test"),
    "Legacy _exist detects direct child"
)


assert(
    store._has("basic_test"),
    "_has detects direct child"
)


assert(
    store._has?("basic_test"),
    "_has? detects direct child"
)


assert(
    !store._has?("does_not_exist"),
    "_has? returns false for missing child"
)


# ============================================================
# TIMESTAMP
# ============================================================

puts
puts "TIMESTAMP TEST:"
puts

timestamp = store["basic_test"]._timestamp

assert(
    timestamp.is_a?(Time),
    "_timestamp returns Time"
)


assert(
    store["does_not_exist"]._timestamp.nil?,
    "_timestamp returns nil for missing node"
)


# ============================================================
# SEARCH DATA
# ============================================================

store["search_test"]["systems"]["services"]["nginx"]["certificates"]["current"] = true
store["search_test"]["systems"]["services"]["nginx"]["configuration"]["current"] = true

store["search_test"]["systems"]["services"]["postgresql"]["configuration"]["current"] = true

store["search_test"]["incidents"]["nginx_certificate_failure"]["event"] = true
store["search_test"]["incidents"]["database_failure"]["event"] = true


# ============================================================
# LEGACY _find
# ============================================================

puts
puts "_find TESTS:"
puts

find_results =
    store["search_test"]["systems"]["services"]._find(
        "nginx"
    )

puts "_find results:"
puts find_results.inspect

assert(
    find_results.include?("nginx"),
    "_find returns matching entry"
)


assert(
    find_results.first == "nginx",
    "_find sorts strongest match first"
)


# ============================================================
# RECURSIVE _search
# ============================================================

puts
puts "_search TESTS:"
puts

search_results =
    store["search_test"]._search(
        "nginx"
    )

puts "_search results:"
search_results.each do |result|
    puts "  #{result[:score]} - #{result[:path]}"
end


assert(
    !search_results.empty?,
    "_search returns results"
)


assert(
    search_results.any? {
        |result|

        result[:path].include?("nginx")
    },
    "_search finds nested nginx directory"
)


# ============================================================
# SCOPED SEARCH
# ============================================================

puts
puts "SCOPED _search TEST:"
puts

scoped_results =
    store[
        "search_test"
    ][
        "systems"
    ][
        "services"
    ][
        "nginx"
    ]._search(
        "certificate"
    )

puts "Scoped results:"
scoped_results.each do |result|
    puts "  #{result[:score]} - #{result[:path]}"
end


assert(
    scoped_results.any? {
        |result|

        result[:path].include?("certificates")
    },
    "Scoped _search finds certificates"
)


# ============================================================
# NON-RECURSIVE SEARCH
# ============================================================

puts
puts "NON-RECURSIVE _search TEST:"
puts

non_recursive =
    store["search_test"]._search(
        "nginx",
        {
            recursive: false
        }
    )

assert(
    non_recursive.none? {
        |result|

        result[:path].include?("nginx")
    },
    "recursive: false does not search nested directories"
)


# ============================================================
# SEARCH LIMIT
# ============================================================

puts
puts "SEARCH LIMIT TEST:"
puts

limited_results =
    store["search_test"]._search(
        "configuration",
        {
            min_score: 0.0,
            limit: 2
        }
    )

assert(
    limited_results.length <= 2,
    "_search respects limit"
)


# ============================================================
# SEARCH SCORE ORDER
# ============================================================

puts
puts "SEARCH SORT TEST:"
puts

sorted_results =
    store["search_test"]._search(
        "nginx",
        {
            min_score: 0.0
        }
    )

scores =
    sorted_results.map {
        |result|

        result[:score]
    }

assert(
    scores == scores.sort.reverse,
    "_search results sorted by score descending"
)


# ============================================================
# TRAVERSAL PROTECTION
# ============================================================

puts
puts "PATH TRAVERSAL TESTS:"
puts

assert_raises(
    "Rejects .."
) do

    store[".."] = "bad"

end


assert_raises(
    "Rejects ../foo"
) do

    store["../foo"] = "bad"

end


assert_raises(
    "Rejects ../../etc/passwd"
) do

    store["../../etc/passwd"] = "bad"

end


assert_raises(
    "Rejects foo/bar"
) do

    store["foo/bar"] = "bad"

end


assert_raises(
    "Rejects Windows-style traversal"
) do

    store["..\\Windows"] = "bad"

end


assert_raises(
    "Rejects embedded path traversal"
) do

    store["foo/../../etc"] = "bad"

end


assert_raises(
    "Rejects null byte"
) do

    store["foo\0bar"] = "bad"

end


# ============================================================
# VERIFY TRAVERSAL DID NOT WRITE OUTSIDE STORE
# ============================================================

puts
puts "TRAVERSAL WRITE CHECK:"
puts

assert(
    !File.exist?("/tmp/foo"),
    "Traversal did not create /tmp/foo"
)


# ============================================================
# DELETE
# ============================================================

puts
puts "DELETE TESTS:"
puts

store["basic_test"]["delete_me"] = "exists"

assert(
    store["basic_test"]._has?("delete_me"),
    "Delete test value created"
)


store["basic_test"]["delete_me"] = nil

assert(
    !store["basic_test"]._has?("delete_me"),
    "nil assignment deletes node"
)


# ============================================================
# CLEANUP
# ============================================================

puts
puts "CLEANING UP..."

store["uuid_generator"] = nil
store["basic_test"] = nil
store["search_test"] = nil
store["traversal_test"] = nil

puts "DONE!"
puts
puts "ALL TESTS PASSED!"