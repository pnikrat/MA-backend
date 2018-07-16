module Requests
  module HeadersHelpers
    def headers(user_to_auth = nil)
      content_type = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      return content_type if user_to_auth.nil?
      content_type.merge(user_to_auth.create_new_auth_token)
    end
  end
end
