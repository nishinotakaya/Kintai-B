class AddBasicInfoToStaffs < ActiveRecord::Migration[5.1]
  def change
    add_column :staffs, :basic_time, :datetime, default: Time.current.change(hour: 8, min: 0, sec: 0)
    add_column :staffs, :work_time, :datetime, default: Time.current.change(hour: 7, min: 30, sec: 0)
  end
end