class AddPasswordDigestToStaffs < ActiveRecord::Migration[5.1]
  def change
    add_column :staffs, :password_digest, :string
  end
end
