# Puma configuration for Sinatra

# Define Puma threads & workers (adjust based on your server)
threads_count = ENV.fetch("PUMA_THREADS", 5).to_i
workers ENV.fetch("PUMA_WORKERS", 2).to_i

threads threads_count, threads_count

environment ENV.fetch("RACK_ENV", "production").to_s

port ENV.fetch("PORT", 9292)

# PID and state file locations
pidfile "tmp/puma.pid"
state_path "tmp/puma.state"

# Preload the application before forking workers
preload_app!

on_worker_boot do
  # Reconnect to database (Mongoid, ActiveRecord, etc.)
  puts "Worker booting..."
end
