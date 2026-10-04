Gem::Specification.new do |s|
    s.name              = 'obfs'
    s.version           = '0.2.0'
    s.date              = '2026-10-04'
    s.summary           = "OBFS"
    s.description       = "File-based, object-oriented data store for Ruby"
    s.authors           = ["Jensel Gatchalian"]
    s.email             = 'jensel.gatchalian@gmail.com'
    s.files             = Dir.glob("lib/**/*")
    s.require_path      = 'lib'
    s.homepage          = 'https://github.com/jenselg/obfs-ruby'
    s.license           = 'MIT'
    s.required_ruby_version = '>= 2.0.0'
end