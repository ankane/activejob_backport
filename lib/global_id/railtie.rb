begin
require 'rails/railtie'
rescue LoadError
else
require 'global_id'
require 'active_support'
require 'active_support/core_ext/string/inflections'

class GlobalID
  # = GlobalID Railtie
  # Set up the signed GlobalID verifier and include Active Record support.
  class Railtie < Rails::Railtie # :nodoc:
    config.global_id = ActiveSupport::OrderedOptions.new

    initializer 'global_id' do |app|
      app.config.global_id.app ||= app.railtie_name.sub('_application', '').dasherize
      GlobalID.app = app.config.global_id.app

      ActiveSupport.on_load(:active_record) do
        require 'global_id/identification'
        send :include, GlobalID::Identification
      end
    end
  end
end

end
