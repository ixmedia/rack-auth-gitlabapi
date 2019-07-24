$:.push File.expand_path("../lib", __FILE__)

require 'rack/auth/gitlabapi/version'

Gem::Specification.new do |s|
  s.name            = "rack-auth-gitlabapi"
  s.version         = Rack::Auth::GITLABAPI_VERSION
  s.authors         = ["iXmedia"]
  s.email           = "suivi@ixmedia.com"
  s.homepage        = "https://github.com/ixmedia/rack-auth-gitlabapi"
  s.summary         = %Q{Rack middleware providing GitLab API authentication}
  s.description     = %q{rack-auth-gitlabapi : provide GitLab API authentication for Rack middleware}
  s.license         = "MIT"

  s.files           = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency  'rack', '~> 2.0.5'
  s.add_dependency  'gitlab', '4.4.0'
end
