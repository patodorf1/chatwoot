<script setup>
import { watch, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useStore, useMapGetter } from 'dashboard/composables/store';

import NextButton from 'dashboard/components-next/button/Button.vue';
import ContactNoteItem from 'next/Contacts/ContactsSidebar/components/ContactNoteItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
});

const { t } = useI18n();
const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const uiFlags = useMapGetter('contactNotes/getUIFlags');
const notesByContact = useMapGetter('contactNotes/getAllNotesByContactId');
const isFetchingNotes = computed(() => uiFlags.value.isFetching);
const isCreatingNote = computed(() => uiFlags.value.isCreating);
const contactId = computed(() => props.contactId);
const noteContent = ref('');
const noteAttachments = ref([]);
const fileInputRef = ref(null);
const notes = computed(() => {
  if (!contactId.value) {
    return [];
  }
  return notesByContact.value(contactId.value) || [];
});

const getWrittenBy = ({ user } = {}) => {
  const currentUserId = currentUser.value?.id;
  return user?.id === currentUserId
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : user?.name || t('CONVERSATION.BOT');
};

const onPickFiles = event => {
  const files = Array.from(event.target.files || []);
  if (!files.length) return;
  noteAttachments.value = [...noteAttachments.value, ...files];
  if (fileInputRef.value) fileInputRef.value.value = '';
};

const removeAttachment = index => {
  noteAttachments.value = noteAttachments.value.filter((_, i) => i !== index);
};

const onAdd = async () => {
  if (!contactId.value || isCreatingNote.value) return;
  if (!noteContent.value && noteAttachments.value.length === 0) return;

  await store.dispatch('contactNotes/create', {
    content: noteContent.value,
    contactId: contactId.value,
    attachments: noteAttachments.value,
  });
  noteContent.value = '';
  noteAttachments.value = [];
};

const onDelete = noteId => {
  if (!contactId.value || !noteId) {
    return;
  }

  store.dispatch('contactNotes/delete', {
    noteId,
    contactId: contactId.value,
  });
};

const keyboardEvents = {
  '$mod+Enter': {
    action: onAdd,
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);

watch(
  contactId,
  newContactId => {
    noteContent.value = '';
    noteAttachments.value = [];
    if (newContactId) {
      store.dispatch('contactNotes/get', { contactId: newContactId });
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-3 px-4 py-3">
    <!-- Compact attachment uploader: paperclip + save, no editor -->
    <div class="flex flex-col gap-2">
      <div
        v-if="noteAttachments.length"
        class="flex flex-col gap-1"
      >
        <div
          v-for="(file, index) in noteAttachments"
          :key="`${file.name}-${index}`"
          class="flex items-center gap-2 px-2 py-1 rounded-md bg-n-alpha-black2"
        >
          <span class="i-lucide-paperclip size-3.5 text-n-slate-11" />
          <span class="text-xs text-n-slate-12 truncate flex-1">
            {{ file.name }}
          </span>
          <span class="text-xxs text-n-slate-10">
            {{ Math.round(file.size / 1024) }} KB
          </span>
          <button
            type="button"
            class="text-n-slate-10 hover:text-ruby-600"
            @click="removeAttachment(index)"
          >
            <span class="i-lucide-x size-3.5" />
          </button>
        </div>
      </div>
      <input
        ref="fileInputRef"
        type="file"
        multiple
        class="hidden"
        @change="onPickFiles"
      />
      <div class="flex items-center justify-between gap-2">
        <NextButton
          ghost
          slate
          xs
          icon="i-lucide-paperclip"
          label="CV"
          :disabled="!contactId"
          @click="() => fileInputRef?.click()"
        />
        <NextButton
          solid
          blue
          xs
          label="Subir"
          :is-loading="isCreatingNote"
          :disabled="!contactId || noteAttachments.length === 0 || isCreatingNote"
          @click="onAdd"
        />
      </div>
    </div>

    <div
      v-if="isFetchingNotes"
      class="flex items-center justify-center py-4 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div
      v-else-if="notes.length"
      class="flex flex-col max-h-[300px] overflow-y-auto"
    >
      <ContactNoteItem
        v-for="note in notes"
        :key="note.id"
        class="py-3 last-of-type:border-b-0"
        :note="note"
        :written-by="getWrittenBy(note)"
        allow-delete
        collapsible
        @delete="onDelete"
      />
    </div>
  </div>
</template>
