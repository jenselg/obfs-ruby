# dependencies
require 'fileutils'
require 'json'
require 'text'

# main
class OBFS

        def initialize(attributes = {}) # hash argument
            @path = (attributes.keys.include? :path) ? attributes[:path] : (File.join(Dir.home, '.obfs'))
        end

        # regular methods

        def method_missing(m, *args, &block)

            # normalize
            method_name = m.to_s
            dataA = args[0]
            dataB = args[1]

            # setter call
            if  method_name.end_with?('=')

                # clean up name
                method_name = method_name.gsub('=','')

                # reassign if square bracket notation
                if method_name == "[]"
                    method_name = dataA
                    data = dataB
                else # make sure we load the proper method_name and data
                    method_name = m.to_s.gsub('=','')
                    data = args[0]
                end
                    
                # write data
                if data == nil
                    FileUtils.rm_rf (File.join @path, method_name)
                else
                    FileUtils.rm_rf (File.join @path, method_name) if File.exist? (File.join @path, method_name)
                    FileUtils.mkpath @path if !File.directory? @path
                    write(@path, method_name, data)
                end
            
            # bracket notation
            elsif method_name == "[]"

                method_name = dataA.to_s.gsub(/\["/,'').gsub(/"\]/,'')
                if (!File.directory? File.join(@path, method_name)) && (File.exist? File.join(@path, method_name))
                    read(@path, method_name)
                else
                    OBFS.new({ path: File.join(@path, method_name.to_s) })
                end

            # recurse or read
            else

                if (!File.directory? File.join(@path, method_name)) && (File.exist? File.join(@path, method_name))
                    read(@path, method_name)
                else
                    OBFS.new({ path: File.join(@path, method_name.to_s) })
                end

            end
            
        end

        # special methods

        # returns current working path for obfs
        def _path
            @path
        end

        # returns directory contents in an array
        def _index
            Dir.entries(@path).reject { |k| k == '.' || k == '..' } rescue nil
        end

        # searches directory contents (1 level) and returns array sorted by relevance
        def _find(term = '', records = 1000, tolerance = 10)
            output = []
            search_space = Dir.entries(@path).reject { |k| k == '.' || k == '..' } rescue []
            search_space.each do |search_space_term|
                if Text::Levenshtein.distance(search_space_term, term) <= tolerance && Text::WhiteSimilarity.similarity(search_space_term, term) > 0.0
                    output << search_space_term
                end
            end
            output.first(records)
        end

        # searches directory contents (1 level) and returns boolean if term exist
        def _exist(term = '')
            exist_space = Dir.entries(@path).reject { |k| k != term.to_s }
            if exist_space.length > 0
                true
            else
                false
            end
        end

        private

        # filesystem R/W

        def write(path, filename, data)
            Thread.new {
                curr_path = File.join path, filename
                File.write(curr_path, JSON.unparse(data))
            }
        end

        def read(path, filename)
            curr_path = File.join path, filename
            JSON.parse(File.open(curr_path).read) rescue File.open(curr_path).read
        end

end