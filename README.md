# rack-auth-gitlabapi

Rack Middleware for GitLab API authentication

## Presentation

Rack::Auth::Gitlabapi is a basic authentication module with GitLab API authentication support.

It's based on Rack:Auth::Basic from the Rack main Project.

This is an additional module for Rack to authenticate users against the GitLab API.

## Installation

In your Gemfile, add :

```ruby
gem "rack-auth-gitlabapi"
```

Create a gitlab.yml at the same level as the config.ru file :

```yml
endpoint: https://example.net/api/v4
```

In you config.ru, simply add :

```ruby
require 'rubygems'
require 'bundler'
require 'rack'

Bundler.require

require File.dirname(__FILE__) + '/your_app.rb'

use Rack::Auth::Gitlabapi
run Sinatra::Application
```

This configuration activate the Basic Authentication for the entire application.

To use custom configuration file :
```ruby
use Rack::Auth::Gitlabapi, file: '/path/to/my/gitlab.yml'
```

## Advanced

To protect some routes according to the parameters of the Gitlab user :

```ruby
require 'rubygems'
require 'bundler'
require 'rack'

Bundler.require

require File.dirname(__FILE__) + '/myapp.rb'

class CustomGitlabapi < Rack::Auth::Gitlabapi
   def call(env)
      request = Rack::Request.new(env)
      response = super(env)

      return unauthorized if user.nil?

      if request.path == '/upload' or request.post?
         return unauthorized if (!user.can_create_project || user.external)
      end

      return response
   end
end

use CustomGitlabapi
run Sinatra::Application
```
