require 'rack/cors'
require_relative 'apartment'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :options] 
  end
end

run Apartment
