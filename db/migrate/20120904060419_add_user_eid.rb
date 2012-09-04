class AddUserEid < ActiveRecord::Migration
  def change
    add_column :users, :eid, :string, :size => 16
  end
end
