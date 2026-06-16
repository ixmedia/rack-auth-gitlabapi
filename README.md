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

## Development

### Setup

Build the Docker image:

```bash
make install
```

### Running tests

Run the full test suite inside Docker:

```bash
make tests
```

### Building the gem

Build the `.gem` package using Docker:

```bash
docker compose run --rm app gem build rack-auth-gitlabapi.gemspec
```

This produces a file named `rack-auth-gitlabapi-<version>.gem` in the current directory.

### Publishing the gem

Push the built gem to [RubyGems.org](https://rubygems.org):

```bash
docker compose run --rm app gem push rack-auth-gitlabapi-<version>.gem
```

You need to be authenticated with RubyGems first. If not already done, run:

```bash
docker compose run --rm app gem signin
```

Or set your API key directly:

```bash
docker compose run --rm app gem push --key rubygems rack-auth-gitlabapi-<version>.gem
```

> The version number is defined in [lib/rack/auth/gitlabapi/version.rb](lib/rack/auth/gitlabapi/version.rb).
