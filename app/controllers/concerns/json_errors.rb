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

    def errors(obj)
      raise ArgumentError, 'Object does not contain errors' if obj.errors.blank?
      {
        status: 'failed',
        errors: obj.errors.full_messages
      }
    end

    def custom_error(error_msg)
      {
        status: 'failed',
        errors: error_msg
      }
    end
  end
end
