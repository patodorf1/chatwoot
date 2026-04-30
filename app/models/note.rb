# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  contact_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_notes_on_account_id  (account_id)
#  index_notes_on_contact_id  (contact_id)
#  index_notes_on_user_id     (user_id)
#
class Note < ApplicationRecord
  before_validation :ensure_account_id
  before_validation :default_content_when_only_attachments
  # Allow notes that carry only file attachments (e.g. uploading a CV without
  # any free-text content). Validate presence only when both content and
  # attachments are missing.
  validate :content_or_attachments_present
  validates :account_id, presence: true
  validates :contact_id, presence: true

  belongs_to :account
  belongs_to :contact
  belongs_to :user, optional: true

  has_many_attached :attachments

  scope :latest, -> { order(created_at: :desc) }

  after_create_commit :dispatch_create_event

  def push_event_data
    {
      id: id,
      content: content,
      contact_id: contact_id,
      account_id: account_id,
      user_id: user_id,
      attachments: attachments_data,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end

  def attachments_data
    return [] unless attachments.attached?

    attachments.map do |att|
      {
        id: att.id,
        filename: att.filename.to_s,
        content_type: att.content_type,
        byte_size: att.byte_size,
        url: Rails.application.routes.url_helpers.rails_blob_url(att, only_path: false)
      }
    end
  end

  private

  def ensure_account_id
    self.account_id = contact&.account_id
  end

  def default_content_when_only_attachments
    # The DB column `content` is NOT NULL — keep the constraint happy when
    # the user uploads a file with no comment by storing a friendly default.
    return if content.present?
    return unless attachments.attached?

    self.content = attachments.first.filename.to_s
  end

  def content_or_attachments_present
    return if content.present? || attachments.attached?

    errors.add(:base, 'Note must have content or at least one attachment')
  end

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(
      'note.created',
      Time.zone.now,
      note: self,
      contact: contact,
      account: account,
      performed_by: user
    )
  rescue StandardError => e
    Rails.logger.warn("Note dispatch failed: #{e.message}")
  end
end
