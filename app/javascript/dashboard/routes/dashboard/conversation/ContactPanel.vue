<script setup>
import { computed, watch, onMounted } from 'vue';
import {
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactInfo from './contact/ContactInfo.vue';
import ContactNotes from './contact/ContactNotes.vue';
import ConversationLabels from './labels/LabelBox.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const {
  updateUISettings,
} = useUISettings();

const store = useStore();
const currentChat = useMapGetter('getSelectedChat');
const conversationId = computed(() => props.conversationId);
const contactGetter = useMapGetter('contacts/getContact');
const contactId = computed(() => currentChat.value.meta?.sender?.id);
const contact = computed(() => contactGetter.value(contactId.value));

const getContactDetails = () => {
  if (contactId.value) {
    store.dispatch('contacts/show', { id: contactId.value });
  }
};

watch(contactId, (newContactId, prevContactId) => {
  if (newContactId && newContactId !== prevContactId) {
    getContactDetails();
  }
});

const closeContactPanel = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
  });
};

onMounted(() => {
  getContactDetails();
  store.dispatch('attributes/get', 0);
});
</script>

<template>
  <div class="w-full">
    <SidebarActionsHeader
      :title="$t('CONVERSATION.SIDEBAR.CONTACT')"
      @close="closeContactPanel"
    />
    <ContactInfo :contact="contact" />
    <div class="px-2 pb-8">
      <!-- Custom contact attributes (flat, no accordion) -->
      <CustomAttributes
        attribute-type="contact_attribute"
        attribute-from="conversation_contact_panel"
        :contact-id="contact.id"
        :empty-state-message="
          $t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')
        "
      />

      <!-- Conversation labels (flat, no accordion) -->
      <div class="mt-3">
        <ContactDetailsItem
          compact
          :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_LABELS')"
        />
        <ConversationLabels :conversation-id="conversationId" />
      </div>

      <!-- Contact notes (flat, no accordion) -->
      <div class="mt-3">
        <ContactNotes :contact-id="contactId" />
      </div>
    </div>
  </div>
</template>
