require 'active_job' if !defined?(ActiveJob)
require 'action_mailer/message_delivery' if Rails.version >= 4.0 && Rails.version < 4.2.0
