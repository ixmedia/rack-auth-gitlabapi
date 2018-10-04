require 'rack'
require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'
require 'gitlab'
require 'yaml'

module Rack
  module Auth

    class Config
      def initialize(options = { file: './gitlab.yml'})
        @values = ::YAML.load_file(::File.expand_path(options[:file], Dir.pwd))
        @values.keys.each do |key|
          @values[key.to_sym] = @values.delete(key)
        end
        @values.keys.each do |meth|
          bloc = Proc.new  {@values[meth] }
            self.class.send :define_method, meth, &bloc
        end
      end
    end

    class Gitlabapi < Basic

      attr_reader :config

      def initialize(app, config_options = {})
        super(app)
        @config = Config.new(config_options)
      end

      def call(env)
        auth = Gitlabapi::Request.new(env)
        return unauthorized unless auth.provided?
        return bad_request unless auth.basic?
        if valid?(auth)
          env['REMOTE_USER'] = auth.username
          return @app.call(env)
        end
        unauthorized
      end

      private

      def valid?(auth)
        Gitlab.configure do |config|
          config.endpoint       = @config.endpoint
          config.private_token  = auth.password
        end

        begin
          @user = Gitlab.user
          if @user.username == auth.username || @user.email == auth.username
            return true
          else
            return false
          end
        rescue
          return false
        end
      end

      def user
        return @user
      end

      class Request < Basic::Request
        def password
          credentials.last
        end
      end

    end
  end
end
