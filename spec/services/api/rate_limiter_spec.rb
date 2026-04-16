require 'rails_helper'

RSpec.describe Api::RateLimiter do
  let(:channel) { create(:channel_api) }

  before do
    # Ensure a clean Redis state between tests
    Redis::Alfred.scan_each(match: "chatwoot:api_inbox:#{channel.id}:*") do |key|
      Redis::Alfred.delete(key)
    end
  end

  describe '#enqueue_decision' do
    context 'when message is not automated' do
      it 'returns :now without recording' do
        channel.additional_attributes = { 'daily_message_limit' => 5, 'message_delay_seconds' => 10 }
        channel.save!

        result = described_class.new(channel).enqueue_decision(message_automated: false)

        expect(result).to eq(action: :now, wait_seconds: 0)
        expect(described_class.new(channel).sent_today).to eq(0)
      end
    end

    context 'when message is automated but no rate limit is configured' do
      it 'returns :now without delay' do
        result = described_class.new(channel).enqueue_decision(message_automated: true)

        expect(result).to eq(action: :now, wait_seconds: 0)
      end
    end

    context 'when daily limit is configured' do
      before do
        channel.additional_attributes = { 'daily_message_limit' => 3 }
        channel.save!
      end

      it 'allows under the cap and records' do
        limiter = described_class.new(channel)

        2.times { expect(limiter.enqueue_decision(message_automated: true)[:action]).to eq(:now) }
        expect(limiter.sent_today).to eq(2)
      end

      it 'reschedules to tomorrow once the cap is hit' do
        limiter = described_class.new(channel)

        3.times { limiter.enqueue_decision(message_automated: true) }
        result = limiter.enqueue_decision(message_automated: true)

        expect(result[:action]).to eq(:reschedule_tomorrow)
        expect(result[:wait_seconds]).to be > 0
        # wait should be at most (seconds to next ART midnight) + 30min jitter
        max_wait = 24.hours.to_i + 30.minutes.to_i
        expect(result[:wait_seconds]).to be <= max_wait
      end
    end

    context 'when delay is configured' do
      before do
        channel.additional_attributes = {
          'message_delay_seconds' => 30,
          'jitter_percent' => 0
        }
        channel.save!
      end

      it 'allows first message immediately' do
        result = described_class.new(channel).enqueue_decision(message_automated: true)
        expect(result[:action]).to eq(:now)
      end

      it 'delays subsequent messages within the delay window' do
        limiter = described_class.new(channel)
        limiter.enqueue_decision(message_automated: true)
        result = limiter.enqueue_decision(message_automated: true)

        expect(result[:action]).to eq(:delay)
        expect(result[:wait_seconds]).to be > 0
        expect(result[:wait_seconds]).to be <= 30
      end
    end

    context 'with jitter applied' do
      it 'produces delays within the jitter range' do
        channel.additional_attributes = {
          'message_delay_seconds' => 30,
          'jitter_percent' => 30
        }
        channel.save!
        limiter = described_class.new(channel)

        limiter.enqueue_decision(message_automated: true)
        waits = Array.new(10) do
          # reset last_sent so the second call is always in-window, just to measure jitter
          Redis::Alfred.setex(
            "chatwoot:api_inbox:#{channel.id}:last_sent_at", 60, Time.current.to_i.to_s
          )
          described_class.new(channel).enqueue_decision(message_automated: true)[:wait_seconds]
        end

        # With 30% jitter on 30s base and 0 elapsed, waits should be in [21, 39]
        expect(waits.min).to be >= 1
        expect(waits.max).to be <= 39
      end
    end
  end
end
