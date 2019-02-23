# frozen_string_literal: true

require 'test_helper'

class ControlPanelControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get control_panel_index_url
    assert_response :success
  end
end
