require 'test_helper'

class VersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil Rack::Auth::GITLABAPI_VERSION
  end

  def test_version_is_a_string
    assert_instance_of String, Rack::Auth::GITLABAPI_VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, Rack::Auth::GITLABAPI_VERSION)
  end
end
