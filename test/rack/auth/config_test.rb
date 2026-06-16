require 'test_helper'
require 'tempfile'

class ConfigTest < Minitest::Test
  def setup
    @yaml_file = Tempfile.new(['gitlab', '.yml'])
  end

  def teardown
    @yaml_file.close
    @yaml_file.unlink
  end

  def write_config(content)
    @yaml_file.rewind
    @yaml_file.truncate(0)
    @yaml_file.write(content)
    @yaml_file.flush
  end

  def test_loads_endpoint_from_yaml
    write_config("endpoint: https://gitlab.example.com/api/v4\n")
    config = Rack::Auth::Config.new(file: @yaml_file.path)
    assert_equal 'https://gitlab.example.com/api/v4', config.endpoint
  end

  def test_loads_multiple_keys_from_yaml
    write_config("endpoint: https://gitlab.example.com/api/v4\nprivate_token: secret123\n")
    config = Rack::Auth::Config.new(file: @yaml_file.path)
    assert_equal 'https://gitlab.example.com/api/v4', config.endpoint
    assert_equal 'secret123', config.private_token
  end

  def test_converts_string_keys_to_symbol_methods
    write_config("endpoint: https://gitlab.example.com/api/v4\n")
    config = Rack::Auth::Config.new(file: @yaml_file.path)
    # The method must be callable (not raise NoMethodError)
    assert_respond_to config, :endpoint
  end

  def test_raises_when_file_does_not_exist
    assert_raises(Errno::ENOENT) do
      Rack::Auth::Config.new(file: '/nonexistent/path/gitlab.yml')
    end
  end

  def test_default_file_is_relative_to_working_directory
    # Without a ./gitlab.yml in cwd, the default must raise Errno::ENOENT
    Dir.chdir(Dir.tmpdir) do
      assert_raises(Errno::ENOENT) do
        Rack::Auth::Config.new
      end
    end
  end
end
