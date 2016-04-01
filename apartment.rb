require 'grape'
require_relative 'classes/login'
require_relative 'classes/project'
require_relative 'classes/image'

class Apartment < Grape::API
  mount Login 
  mount Project
  mount Image
end
