class Expense < ActiveRecord::Base
  belongs_to :category
  validates_numericality_of :amount, :greater_than => 0.0

  def category_name
    self.category.name rescue '(none)'
  end

end
