# Concern responsible for helper methods for rendering JSON error objects
module JSONErrors
  extend ActiveSupport::Concern

  included do
    def unauthorized_error
      {
        status: 'failed',
        errors: 'unauthorized access'
      }
    end
  end
end
