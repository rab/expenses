class CreateMileages < ActiveRecord::Migration
  def self.up
    create_table :mileages do |t|
      t.date :driven_on
      t.integer :starting
      t.integer :ending
      t.integer :trip
      t.string :purpose

      t.timestamps
    end
  end

  def self.down
    drop_table :mileages
  end
end
