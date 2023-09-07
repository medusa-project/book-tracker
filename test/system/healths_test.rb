require "application_system_test_case"

class HealthsTest < ApplicationSystemTestCase
  setup do
    @health = healths(:one)
  end

  test "visiting the index" do
    visit healths_url
    assert_selector "h1", text: "Healths"
  end

  test "should create health" do
    visit healths_url
    click_on "New health"

    click_on "Create Health"

    assert_text "Health was successfully created"
    click_on "Back"
  end

  test "should update Health" do
    visit health_url(@health)
    click_on "Edit this health", match: :first

    click_on "Update Health"

    assert_text "Health was successfully updated"
    click_on "Back"
  end

  test "should destroy Health" do
    visit health_url(@health)
    click_on "Destroy this health", match: :first

    assert_text "Health was successfully destroyed"
  end
end
