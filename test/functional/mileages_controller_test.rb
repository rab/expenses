require File.dirname(__FILE__) + '/../test_helper'

class MileagesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:mileages)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_mileage
    assert_difference('Mileage.count') do
      post :create, :mileage => { }
    end

    assert_redirected_to new_mileage_path
  end

  def test_should_show_mileage
    get :show, :id => mileages(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => mileages(:one).id
    assert_response :success
  end

  def test_should_update_mileage
    put :update, :id => mileages(:one).id, :mileage => { }
    assert_redirected_to mileages_path
  end

  def test_should_destroy_mileage
    assert_difference('Mileage.count', -1) do
      delete :destroy, :id => mileages(:one).id
    end

    assert_redirected_to mileages_path
  end
end
