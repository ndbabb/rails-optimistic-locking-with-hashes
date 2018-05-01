module StaleObjectProtection
  extend ActiveSupport::Concern

  included do
    after_initialize :set_lock_fingerprint
    attribute :lock_fingerprint, :string
    before_update :throw_error_if_fingerprint_changed
    after_save :set_lock_fingerprint

    # Checks if latest data from DB has a different fingerprint.
    # If true, that means it's unsafe to save / overwrite
    def fingerprint_changed?
      latest = self.class.where(id: id).pluck(*fields_for_fingerprint).first.try(:join)
      return true unless latest
      hash_string(latest) != lock_fingerprint
    end

    # Optionally override this method in your ActiveRecord model to indicate additional exclusions
    def fingerprint_excluded_fields
      []
    end

    def fields_for_fingerprint
      exclusions = [:created_at, :updated_at] + fingerprint_excluded_fields
      self.class.column_names.map(&:to_sym) - exclusions
    end

    private

      def set_lock_fingerprint
        self.lock_fingerprint = hash_string(concatenated_field_values)
      end

      def concatenated_field_values
        (fields_for_fingerprint.map { |field_name| self.send(field_name) }).join
      end

      def hash_string(str)
        Digest::SHA256.hexdigest(str)
      end

      def throw_error_if_fingerprint_changed
        raise ActiveRecord::StaleObjectError.new(self, 'update') if fingerprint_changed?
      end
  end

  class_methods do
    def find_with_fingerprint(id, lock_fingerprint)
      obj = self.find(id)
      stale_fingerprint = lock_fingerprint != obj.lock_fingerprint
      raise ActiveRecord::StaleObjectError.new(self, 'find') if stale_fingerprint
      obj
    end
  end
end
