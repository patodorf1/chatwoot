import ApiClient from './ApiClient';

class ContactNotes extends ApiClient {
  constructor() {
    super('notes', { accountScoped: true });
    this.contactId = null;
  }

  get url() {
    return `${this.baseUrl()}/contacts/${this.contactId}/notes`;
  }

  get(contactId) {
    this.contactId = contactId;
    return super.get();
  }

  create(contactId, content, attachments = []) {
    this.contactId = contactId;

    // If files are attached, send as multipart so Rails ActiveStorage can
    // pick them up under params[:attachments][].
    if (attachments && attachments.length) {
      const formData = new FormData();
      formData.append('note[content]', content || '');
      attachments.forEach(file => formData.append('attachments[]', file));
      return axios.post(this.url, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }

    return super.create({ content });
  }

  delete(contactId, id) {
    this.contactId = contactId;
    return super.delete(id);
  }
}

export default new ContactNotes();
