class Conversations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

  def initialize(params, user, account)
    @account = account
    super(params, user)
  end

  def perform
    validate_query_operator
    @conversations = query_builder(@filters['conversations'])
    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  def base_relation
    conversations = @account.conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team, :messages, :contact_inbox
    )

    # When filtering by contact-level custom attributes the WHERE clause
    # references the `contacts` table. `includes` alone resolves with a
    # separate query, so the SQL fails / hangs. Add an explicit join when
    # any payload entry targets a contact_attribute.
    conversations = conversations.joins(:contact) if filters_contact_attributes?

    Conversations::PermissionFilterService.new(
      conversations,
      @user,
      @account
    ).perform
  end

  def filters_contact_attributes?
    return false if @params[:payload].blank?

    @params[:payload].any? { |q| q['custom_attribute_type'] == 'contact_attribute' }
  end

  def current_page
    @params[:page] || 1
  end

  def filter_config
    {
      entity: 'Conversation',
      table_name: 'conversations'
    }
  end

  def conversations
    @conversations.sort_on_last_activity_at.page(current_page)
  end
end
