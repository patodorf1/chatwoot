# == Schema Information
#
# Table name: channel_api
#
#  id                    :bigint           not null, primary key
#  additional_attributes :jsonb
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  identifier            :string
#  webhook_url           :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer          not null
#
# Indexes
#
#  index_channel_api_on_hmac_token  (hmac_token) UNIQUE
#  index_channel_api_on_identifier  (identifier) UNIQUE
#

class Channel::Api < ApplicationRecord
  include Channelable

  self.table_name = 'channel_api'
  EDITABLE_ATTRS = [:webhook_url, :hmac_mandatory, { additional_attributes: {} }].freeze

  has_secure_token :identifier
  has_secure_token :hmac_token
  validate :ensure_valid_agent_reply_time_window
  validate :ensure_valid_rate_limit_attributes
  validates :webhook_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  def name
    'API'
  end

  def daily_message_limit
    additional_attributes['daily_message_limit'].to_i
  end

  def message_delay_seconds
    additional_attributes['message_delay_seconds'].to_i
  end

  def jitter_percent
    value = additional_attributes['jitter_percent']
    value.blank? ? 30 : value.to_i
  end

  private

  def ensure_valid_agent_reply_time_window
    return if additional_attributes['agent_reply_time_window'].blank?
    return if additional_attributes['agent_reply_time_window'].to_i.positive?

    errors.add(:agent_reply_time_window, 'agent_reply_time_window must be greater than 0')
  end

  def ensure_valid_rate_limit_attributes
    %w[daily_message_limit message_delay_seconds].each do |key|
      value = additional_attributes[key]
      next if value.blank?
      next if value.to_i >= 0

      errors.add(key.to_sym, "#{key} must be zero or greater")
    end

    jitter = additional_attributes['jitter_percent']
    return if jitter.blank?
    return if jitter.to_i.between?(0, 100)

    errors.add(:jitter_percent, 'jitter_percent must be between 0 and 100')
  end
end
