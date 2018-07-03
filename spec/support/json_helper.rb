module Requests
  module JsonHelpers
    def json(to_parse = response.body)
      JSON.parse(to_parse, symbolize_names: true)
    end
  end
end
