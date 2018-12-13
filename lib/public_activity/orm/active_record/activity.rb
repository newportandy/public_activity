module PublicActivity
  module ORM
    module ActiveRecord
      # The ActiveRecord model containing
      # details about recorded activity.
      class Activity < ::ActiveRecord::Base
        include Renderable
        self.table_name = PublicActivity.config.table_name
        self.abstract_class = true

        # Define polymorphic association to the parent
        belongs_to :trackable, :polymorphic => true

        case ::ActiveRecord::VERSION::MAJOR
        when 3..4
          # Define ownership to a resource responsible for this activity
          belongs_to :owner, :polymorphic => true
          # Define ownership to a resource targeted by this activity
          belongs_to :recipient, :polymorphic => true
        when 5
          with_options(:required => false) do
            # Define ownership to a resource responsible for this activity
            belongs_to :owner, :polymorphic => true
            # Define ownership to a resource targeted by this activity
            belongs_to :recipient, :polymorphic => true
          end
        end

        # We defer this configuration until runtime to allow Rails to load this code without a database connection.
        # #table_exists? forces the connection which is problematic in some cases, for example when we build a
        # production docker image and want to precompile assets without a database connection.
        def self.register_parameter_serialization
          if table_exists?
            serialize :parameters, Hash unless [:json, :jsonb, :hstore].include?(columns_hash['parameters'].type)
          else
            warn("[WARN] table #{name} doesn't exist. Skipping PublicActivity::Activity#parameters's serialization")
          end
        rescue ::ActiveRecord::NoDatabaseError
          warn("[WARN] database doesn't exist. Skipping PublicActivity::Activity#parameters's serialization")
        end

        klass = self
        ActiveSupport.on_load(:active_record) do
          klass.register_parameter_serialization
        end

        if ::ActiveRecord::VERSION::MAJOR < 4 || defined?(ProtectedAttributes)
          attr_accessible :key, :owner, :parameters, :recipient, :trackable
        end
      end
    end
  end
end
