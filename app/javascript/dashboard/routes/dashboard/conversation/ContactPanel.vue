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
import NextButton from 'dashboard/components-next/button/Button.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import EditContact from './contact/EditContact.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';
import { ref } from 'vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useRouter } from 'vue-router';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from 'dashboard/helper/routeHelpers';
import { useRoute } from 'vue-router';

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
const router = useRouter();
const route = useRoute();
const { isAdmin } = useAdmin();
const showEditModal = ref(false);
const showDeleteModal = ref(false);
const mergeModal = ref(null);
const uiFlags = computed(() => store.getters['contacts/getUIFlags']);
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

const toggleEditModal = () => {
  showEditModal.value = !showEditModal.value;
};
const openMergeModal = () => {
  mergeModal.value?.open();
};
const toggleDeleteModal = () => {
  showDeleteModal.value = !showDeleteModal.value;
};
const closeDelete = () => {
  showDeleteModal.value = false;
  showEditModal.value = false;
};
const confirmDeletion = async () => {
  try {
    await store.dispatch('contacts/delete', contact.value.id);
    closeContactPanel();
    useAlert('Contact deleted successfully');
    if (isAConversationRoute(route.name)) {
      router.push({ name: getConversationDashboardRoute(route.name) });
    }
  } catch (error) {
    useAlert(error.message || 'Could not delete contact');
  }
};
const openComposeConversationModal = (toggleFn) => {
  toggleFn();
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
};
const closeComposeConversationModal = () => {
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
};
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
        :allowed-attribute-keys="[
          'posicion_propuesta',
          'puesto_actual',
          'tecnologia_principal',
        ]"
        :empty-state-message="
          $t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')
        "
      />

      <!-- Conversation labels (flat, no accordion) -->
      <div class="mt-3">
        <ContactDetailsItem
          compact
          title="Estado"
        />
        <ConversationLabels :conversation-id="conversationId" />
      </div>

      <!-- Contact notes (flat, no accordion) -->
      <div class="mt-3">
        <ContactNotes :contact-id="contactId" />
      </div>

      <!-- Action buttons at bottom -->
      <div class="flex items-center w-full mt-4 pt-4 gap-2 border-t border-n-weak">
        <ComposeConversation
          :contact-id="String(contact.id)"
          is-modal
          @close="closeComposeConversationModal"
        >
          <template #trigger="{ toggle }">
            <NextButton
              v-tooltip.top-end="$t('CONTACT_PANEL.NEW_MESSAGE')"
              icon="i-ph-chat-circle-dots"
              slate
              faded
              sm
              @click="openComposeConversationModal(toggle)"
            />
          </template>
        </ComposeConversation>
        <VoiceCallButton
          :phone="contact.phone_number"
          :contact-id="contact.id"
          icon="i-ri-phone-fill"
          size="sm"
          :tooltip-label="$t('CONTACT_PANEL.CALL')"
          slate
          faded
        />
        <NextButton
          v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="i-ph-pencil-simple"
          slate
          faded
          sm
          @click="toggleEditModal"
        />
        <NextButton
          v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="i-ph-arrows-merge"
          slate
          faded
          sm
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <NextButton
          v-if="isAdmin"
          v-tooltip.top-end="$t('DELETE_CONTACT.BUTTON_LABEL')"
          icon="i-ph-trash"
          slate
          faded
          sm
          ruby
          :disabled="uiFlags.isDeleting"
          @click="toggleDeleteModal"
        />
      </div>
      <EditContact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
      />
      <ContactMergeModal ref="mergeModal" :primary-contact="contact" />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="$t('DELETE_CONTACT.CONFIRM.MESSAGE')"
      :confirm-text="$t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="$t('DELETE_CONTACT.CONFIRM.NO')"
    />
  </div>
</template>
