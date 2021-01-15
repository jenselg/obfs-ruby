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
            if method_name.start_with? "obfs_"

                case method_name
                when 'obfs_path'
                    @path
                when 'obfs_keys'
                    # array of directory contents
                end

            # setter
            elsif  method_name.end_with?('=')

                # clean up name
                method_name = method_name.gsub('=','')

                # reassign if square bracket notation
                if method_name == "[]"
                    method_name = dataA
                    data = dataB
                end

                # clear out current files
                FileUtils.rm_rf @path
                FileUtils.mkpath @path
                    
                # write data
                if data == nil
                    FileUtils.rm_rf File.join @path, method_name
                else
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