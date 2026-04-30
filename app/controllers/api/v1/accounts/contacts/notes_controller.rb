class Api::V1::Accounts::Contacts::NotesController < Api::V1::Accounts::Contacts::BaseController
  before_action :note, except: [:index, :create]

  def index
    @notes = @contact.notes.latest.includes(:user, attachments_attachments: :blob)
  end

  def show; end

  def create
    @note = @contact.notes.new(note_params)
    @note.attachments.attach(attachment_files) if attachment_files.present?
    @note.save!
  end

  def update
    @note.update(note_params)
    @note.attachments.attach(attachment_files) if attachment_files.present?
  end

  def destroy
    @note.destroy!
    head :ok
  end

  private

  def note
    @note ||= @contact.notes.find(params[:id])
  end

  def note_params
    # Allow content to be optional when an attachment is uploaded.
    permitted = params.require(:note).permit(:content)
    permitted.merge(contact_id: @contact.id, user_id: Current.user.id)
  end

  def attachment_files
    # Accept either `attachments[]` (multipart upload from Vue file input)
    # or a single `attachment` param.
    params[:attachments].presence || Array(params[:attachment]).compact_blank
  end
end
