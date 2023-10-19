class User

  attr_accessor :username

  def medusa_admin?
    group = Configuration.instance.medusa_admins_group
    user  = UiucLibAd::User.new(cn: self.username)
    begin
      return user.is_member_of?(group_cn: group)
    rescue UiucLibAd::NoDNFound
      return false
    end
  end

  def to_s
    username
  end

end
