require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'medusa_admin? returns true for medusa admins' do
    user = User.new.tap do |u|
      u.username = 'alexd'
    end
    assert user.medusa_admin?
  end

  test 'medusa_admin? returns false for non-medusa admins' do
    user = User.new.tap do |u|
      u.username = 'bogus'
    end
    assert !user.medusa_admin?
  end

end
