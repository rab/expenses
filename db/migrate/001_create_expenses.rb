class CreateExpenses < ActiveRecord::Migration
  def self.up
    create_table :expenses do |t|
      t.datetime :when
      t.string   :vendor
      t.decimal  :amount, :precision => 7, :scale => 2
      t.integer  :category_id

      t.timestamps
    end
  end

  def self.down
    drop_table :expenses
  end
end
