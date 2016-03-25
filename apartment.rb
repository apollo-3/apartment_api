require 'grape'
require_relative 'classes/login'
require_relative 'classes/project'

class Apartment < Grape::API
  mount Login 
  mount Project
end
