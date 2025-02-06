# Puma configuration for Sinatra (Single-Process Mode)

# Define Puma threads (Set both min and max threads to the same value)
threads_count = ENV.fetch("PUMA_THREADS", 5).to_i
threads threads_count, threads_count

environment ENV.fetch("RACK_ENV", "production").to_s

port ENV.fetch("PORT", 9292)

# PID and state file locations
pidfile "tmp/puma.pid"
state_path "tmp/puma.state"

on_worker_boot do
  puts "Worker booting..."
end
