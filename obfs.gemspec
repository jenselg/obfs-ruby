Gem::Specification.new do |s|
    s.name              = 'obfs'
    s.version           = '0.3.0'
    s.date              = '2026-10-04'
    s.summary           = "Filesystem-backed object store with fuzzy discovery"
    s.description       = "File-based, object-oriented data store for Ruby with recursive access, fuzzy discovery, and no external runtime dependencies."
    s.authors           = ["Jensel Gatchalian"]
    s.email             = 'jensel.gatchalian@gmail.com'
    s.files             = Dir.glob("lib/**/*").select { |path| File.file?(path) } + ["README.md"]
    s.require_path      = 'lib'
    s.homepage          = 'https://github.com/jenselg/obfs-ruby'
    s.license           = 'MIT'
    # Uses Ruby standard libraries and local OBFS similarity implementations.
    # No external runtime dependencies are required.
    s.required_ruby_version = '>= 2.0.0'
end
