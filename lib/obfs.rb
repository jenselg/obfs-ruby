class OBFS

        def initialize(name = ".obfs", path = Dir.home)
            # arguments:
            # name
            # absolute path
            #
            @name = name
            @path = path
        end

        def method_missing(m, *args, &block)
        end

end