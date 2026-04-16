class Api::RateLimiter
  TIMEZONE = 'America/Argentina/Buenos_Aires'.freeze
  COUNTER_TTL = 26.hours
  LAST_SENT_TTL = 24.hours
  NEXT_DAY_JITTER_SECONDS = 1800 # up to 30 minutes spread on midnight-ART reschedule

  def initialize(channel)
    @channel = channel
  end

  # Decides whether an outgoing webhook should fire now, wait N seconds, or reschedule to next day
  # @param message_automated [Boolean] whether the message is automated (counts against daily limit)
  # @return [Hash] { action: :now|:delay|:reschedule_tomorrow, wait_seconds: Integer }
  def enqueue_decision(message_automated:)
    return now unless message_automated
    return now unless rate_limiting_configured?

    if daily_cap_hit?
      reschedule_tomorrow
    elsif delay_required?
      delay_until_allowed
    else
      now_and_record
    end
  end

  def sent_today
    Redis::Alfred.get(counter_key).to_i
  end

  def next_available_in_seconds
    return 0 if @channel.message_delay_seconds.zero?

    last_sent = Redis::Alfred.get(last_sent_key).to_i
    return 0 if last_sent.zero?

    elapsed = Time.current.to_i - last_sent
    remaining = @channel.message_delay_seconds - elapsed
    remaining.positive? ? remaining : 0
  end

  private

  def now
    { action: :now, wait_seconds: 0 }
  end

  def now_and_record
    record_send(wait_seconds: 0)
    { action: :now, wait_seconds: 0 }
  end

  def delay_until_allowed
    wait = calculate_delay
    record_send(wait_seconds: wait)
    { action: :delay, wait_seconds: wait }
  end

  def reschedule_tomorrow
    wait = seconds_to_next_day + rand(0..NEXT_DAY_JITTER_SECONDS)
    # Intentionally NOT recording the send: we want the counter to reset naturally tomorrow,
    # and this message will hit the limiter again when it fires then.
    { action: :reschedule_tomorrow, wait_seconds: wait }
  end

  def rate_limiting_configured?
    @channel.daily_message_limit.positive? || @channel.message_delay_seconds.positive?
  end

  def daily_cap_hit?
    return false unless @channel.daily_message_limit.positive?

    sent_today >= @channel.daily_message_limit
  end

  def delay_required?
    return false unless @channel.message_delay_seconds.positive?

    last_sent = Redis::Alfred.get(last_sent_key).to_i
    return false if last_sent.zero?

    min_delay_seconds = @channel.message_delay_seconds * (1 - @channel.jitter_percent / 100.0)
    (Time.current.to_i - last_sent) < min_delay_seconds
  end

  def calculate_delay
    last_sent = Redis::Alfred.get(last_sent_key).to_i
    elapsed = Time.current.to_i - last_sent
    jitter_range = @channel.jitter_percent / 100.0
    jitter_multiplier = 1 + (rand * 2 - 1) * jitter_range
    target_delay = (@channel.message_delay_seconds * jitter_multiplier).to_i
    remaining = target_delay - elapsed
    [remaining, 1].max
  end

  def record_send(wait_seconds:)
    Redis::Alfred.incr(counter_key)
    Redis::Alfred.expire(counter_key, COUNTER_TTL.to_i)
    Redis::Alfred.setex(last_sent_key, LAST_SENT_TTL.to_i, (Time.current.to_i + wait_seconds).to_s)
  end

  def seconds_to_next_day
    now = Time.current.in_time_zone(TIMEZONE)
    tomorrow_midnight = now.beginning_of_day + 1.day
    (tomorrow_midnight.to_i - now.to_i)
  end

  def counter_key
    date = Time.current.in_time_zone(TIMEZONE).strftime('%Y-%m-%d')
    "chatwoot:api_inbox:#{@channel.id}:daily_count:#{date}"
  end

  def last_sent_key
    "chatwoot:api_inbox:#{@channel.id}:last_sent_at"
  end
end
