class User

  attr_accessor :username

  def medusa_admin?
    group = Configuration.instance.medusa_admins_group
    LdapQuery.new.is_member_of?(group, username)
  end

  def to_s
    username
  end

end
