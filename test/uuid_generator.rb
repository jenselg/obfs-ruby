require "./test_core.rb"

store = OBFS::Store.new({ path: "/tmp/obfs_test" })

iteration = 100000

puts "START:"

Benchmark.bmbm do |x|

    x.report("UUID Generator") {

        iteration.times do |i|
            puts "Iteration: #{i}"
            store["uuid_generator"][SecureRandom.uuid][SecureRandom.uuid][SecureRandom.uuid][SecureRandom.uuid][SecureRandom.uuid][SecureRandom.uuid] = SecureRandom.uuid
        end
    }

end

puts "CLEANING UP..."
store["uuid_generator"] = nil
puts "DONE!"