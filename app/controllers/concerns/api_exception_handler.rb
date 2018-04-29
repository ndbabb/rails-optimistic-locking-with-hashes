module ApiExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      render json: { error: e.message }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { error: e.message }, status: :unprocessable_entity
    end

    rescue_from ActiveRecord::StaleObjectError do |e|
      error_msg = 'Record has been updated by another user. Refresh data and try again.'
      render json: { error: error_msg }, status: :unprocessable_entity
    end
  end
end
