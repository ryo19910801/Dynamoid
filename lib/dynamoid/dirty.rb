module Dynamoid
  module Dirty
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    module ClassMethods
      def from_database(*)
        super.tap { |d| d.changed_attributes.clear }
      end
    end

    def save(*)
      clear_changes { super }
    end

    def update!(*)
      ret = super
      clear_changes # update! completely reloads all fields on the class, so any extant changes are wiped out
      ret
    end

    def reload
      super.tap { clear_changes }
    end

    def clear_changes
      previous = changes
      (block_given? ? yield : true).tap do |result|
        unless result == false # failed validation; nil is OK.
          @previously_changed = previous
          changed_attributes.clear
        end
      end
    end

    def write_attribute(name, value)
      attribute_will_change!(name) unless self.read_attribute(name) == value
      super
    end

    # TODO: not supported "mutations_from_database"
    def changes_include?(attr_name)
      begin
        # activemodel (5.2.0)
        # attributes_changed_by_setter.include?(attr_name) || mutations_from_database.changed?(attr_name)
        super
      rescue => _
        # activemodel (5.1.2)
        attributes_changed_by_setter.include?(attr_name)
      end
    end

    # TODO: not supported "mutations_from_database"
    def changed_attributes
      begin
        # activemodel (5.2.0)
        # if defined?(@cached_changed_attributes)
        #   @cached_changed_attributes
        # else
        #   attributes_changed_by_setter.reverse_merge(mutations_from_database.changed_values).freeze
        # end
        super
      rescue => _
        # activemodel (5.1.2)
        @changed_attributes ||= ActiveSupport::HashWithIndifferentAccess.new
      end
    end

    protected

    def attribute_method?(attr)
      super || self.class.attributes.has_key?(attr.to_sym)
    end
  end
end
