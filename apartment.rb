require 'grape'
require_relative 'classes/login'

class Apartment < Grape::API
  mount Login 
end
