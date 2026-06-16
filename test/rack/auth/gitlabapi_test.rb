require 'test_helper'
require 'tempfile'

MockGitlabUser = Struct.new(:username, :email)

class GitlabapiTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    @yaml_file = Tempfile.new(['gitlab', '.yml'])
    @yaml_file.write("endpoint: https://gitlab.example.com/api/v4\n")
    @yaml_file.flush

    @inner_app = ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
    @app = Rack::Auth::Gitlabapi.new(@inner_app, file: @yaml_file.path)
  end

  def teardown
    @yaml_file.close
    @yaml_file.unlink
  end

  def app
    @app
  end

  # Build a fake Gitlab client stub that returns the given user (or raises)
  def mock_gitlab_client(user: nil, raise_error: false)
    client = Object.new
    if raise_error
      client.define_singleton_method(:user) { raise StandardError, 'Unauthorized' }
    else
      client.define_singleton_method(:user) { user }
    end
    client
  end

  # Stub both configure (no-op) and client, then yield
  def with_gitlab_client(client, &block)
    # configure must be stubbed with a callable so its block is not executed
    no_op = ->(*_args, &_blk) {}
    Gitlab.stub(:configure, no_op) do
      Gitlab.stub(:client, client, &block)
    end
  end

  # -------------------------------------------------------------------------
  # Authentication header checks
  # -------------------------------------------------------------------------

  def test_returns_401_when_no_authorization_header_provided
    get '/'
    assert_equal 401, last_response.status
  end

  def test_response_includes_www_authenticate_header_on_401
    get '/'
    assert last_response.headers.key?('WWW-Authenticate'),
           'Expected WWW-Authenticate header in 401 response'
  end

  def test_returns_400_for_non_basic_auth_scheme
    header 'Authorization', 'Bearer some_token'
    get '/'
    assert_equal 400, last_response.status
  end

  # -------------------------------------------------------------------------
  # Valid credentials — matched by username
  # -------------------------------------------------------------------------

  def test_returns_200_when_credentials_match_username
    mock_user = MockGitlabUser.new('john', 'john@example.com')
    with_gitlab_client(mock_gitlab_client(user: mock_user)) do
      authorize 'john', 'valid_token'
      get '/'
      assert_equal 200, last_response.status
    end
  end

  # -------------------------------------------------------------------------
  # Valid credentials — matched by email
  # -------------------------------------------------------------------------

  def test_returns_200_when_credentials_match_email
    mock_user = MockGitlabUser.new('john', 'john@example.com')
    with_gitlab_client(mock_gitlab_client(user: mock_user)) do
      authorize 'john@example.com', 'valid_token'
      get '/'
      assert_equal 200, last_response.status
    end
  end

  # -------------------------------------------------------------------------
  # Invalid credentials
  # -------------------------------------------------------------------------

  def test_returns_401_when_username_does_not_match_gitlab_user
    mock_user = MockGitlabUser.new('other_user', 'other@example.com')
    with_gitlab_client(mock_gitlab_client(user: mock_user)) do
      authorize 'john', 'valid_token'
      get '/'
      assert_equal 401, last_response.status
    end
  end

  def test_returns_401_when_gitlab_raises_an_exception
    with_gitlab_client(mock_gitlab_client(raise_error: true)) do
      authorize 'john', 'bad_token'
      get '/'
      assert_equal 401, last_response.status
    end
  end

  # -------------------------------------------------------------------------
  # REMOTE_USER env variable
  # -------------------------------------------------------------------------

  def test_sets_remote_user_in_env_on_successful_auth
    captured_env = nil
    inner_app = ->(env) { captured_env = env; [200, {}, ['OK']] }
    app = Rack::Auth::Gitlabapi.new(inner_app, file: @yaml_file.path)

    mock_user = MockGitlabUser.new('john', 'john@example.com')
    with_gitlab_client(mock_gitlab_client(user: mock_user)) do
      env = Rack::MockRequest.env_for('/', 'HTTP_AUTHORIZATION' => "Basic #{Base64.strict_encode64('john:token')}")
      app.call(env)
    end

    assert_equal 'john', captured_env['REMOTE_USER']
  end

  def test_does_not_reach_inner_app_when_auth_fails
    captured_env = nil
    inner_app = ->(env) { captured_env = env; [200, {}, ['OK']] }
    app = Rack::Auth::Gitlabapi.new(inner_app, file: @yaml_file.path)

    mock_user = MockGitlabUser.new('other', 'other@example.com')
    with_gitlab_client(mock_gitlab_client(user: mock_user)) do
      env = Rack::MockRequest.env_for('/', 'HTTP_AUTHORIZATION' => "Basic #{Base64.strict_encode64('john:token')}")
      app.call(env)
    end

    assert_nil captured_env
  end

  # -------------------------------------------------------------------------
  # Rack::Auth::Gitlabapi::Request
  # -------------------------------------------------------------------------

  def test_request_exposes_password_from_basic_credentials
    env = Rack::MockRequest.env_for(
      '/',
      'HTTP_AUTHORIZATION' => "Basic #{Base64.strict_encode64('user:s3cr3t')}"
    )
    request = Rack::Auth::Gitlabapi::Request.new(env)
    assert_equal 's3cr3t', request.password
  end

  def test_request_password_with_colon_in_password
    # RFC 7617: only the first colon splits user from password; the rest is the password
    env = Rack::MockRequest.env_for(
      '/',
      'HTTP_AUTHORIZATION' => "Basic #{Base64.strict_encode64('user:pass:word')}"
    )
    request = Rack::Auth::Gitlabapi::Request.new(env)
    assert_equal 'pass:word', request.password
  end
end

