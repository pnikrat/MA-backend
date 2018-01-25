# Core App Controller
class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
end
