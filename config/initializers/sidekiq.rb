require "sidekiq"
require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/0" }

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.join(Rails.root, "config", "sidekiq_schedule.yml"))
    Sidekiq::Scheduler.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/0" }
end
