class Category < ActiveRecord::Base
  has_many :expenses
  validates_uniqueness_of :name

  acts_as_list

  def self.choices_for_select
    find(:all, :select => 'name, id', :order => 'position').collect {|c| [c.name, c.id]}
  end

end
