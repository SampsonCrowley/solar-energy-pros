class SleepHelperJob < ApplicationJob
  queue_as :default

  def perform(*args)
    require 'net/http'
    require 'uri'

    uri = URI.parse("https://solarenergypros.online/wake_up")
    response = Net::HTTP.get_response uri
    p response.body
    requeue
  rescue
    requeue
  end

  def requeue
    time = Rails.redis.get :next_wake_up
    unless (time.present? && (Time.zone.parse(time.to_s) > 10.minutes.from_now))
      count = Rails.redis.get :simultaneous_wakeups

      next_wake_up = (Time.zone.now > (Time.zone.now.beginning_of_day + 19.hours)) ? Time.zone.now.beginning_of_day + 33.hours : 20.minutes.from_now

      Rails.redis.set(:next_wake_up, next_wake_up)

      SleepHelperJob.set(wait_until: next_wake_up).perform_later
    end
  end
end
