require 'fileutils'
require 'json'

class OBFS

        def initialize(attributes = {}) # hash argument
            @path = (attributes.keys.include? :path) ? attributes[:path] : (File.join(Dir.home, '.obfs'))
        end

        def method_missing(m, *args, &block)

            # normalize
            method_name = m.to_s
            dataA = args[0]
            dataB = args[1]

            # special obfs attributes
            if method_name.start_with? "_"

                case method_name
                when '_path'
                    @path
                when '_keys'
                    # array of directory contents
                    Dir.entries @path rescue []
                end

            # setter
            elsif  method_name.end_with?('=')

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
                    FileUtils.rm_rf File.join @path, method_name
                else
                    FileUtils.rm_rf @path, method_name if File.exist? File.join @path, method_name
                    FileUtils.mkpath @path if !File.directory? @path
                    write(@path, method_name, data)
                end
            
            elsif method_name == "[]"

                method_name = dataA.to_s.gsub(/\["/,'').gsub(/"\]/,'')
                if (!File.directory? File.join(@path, method_name)) && (File.exist? File.join(@path, method_name))
                    read(@path, method_name)
                else
                    OBFS.new({ path: File.join(@path, method_name.to_s) })
                end

            else

                if (!File.directory? File.join(@path, method_name)) && (File.exist? File.join(@path, method_name))
                    read(@path, method_name)
                else
                    OBFS.new({ path: File.join(@path, method_name.to_s) })
                end

            end
            
        end

        private

        def write(path, filename, data)
            curr_path = File.join path, filename
            File.write(curr_path, JSON.unparse(data))
        end

        def read(path, filename)
            curr_path = File.join path, filename
            JSON.parse(File.open(curr_path).read) rescue File.open(curr_path).read
        end

end