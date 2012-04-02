class Mileage < ActiveRecord::Base
  before_validation_on_create :fix_ending_and_trip
  validates_numericality_of :starting, :greater_than => 0

  def ending
    read_attribute(:ending) || self.starting
  end
  def trip
    read_attribute(:trip) || (self.ending - self.starting)
  end

  private

  def fix_ending_and_trip
    if read_attribute(:ending).nil?
      if read_attribute(:trip).nil?
        self.ending = self.starting
      else
        self.ending = self.starting + self.trip
      end
    end
    if read_attribute(:trip).nil?
      self.trip = self.ending - self.starting
    end
  end
end
