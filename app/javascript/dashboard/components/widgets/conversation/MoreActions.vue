<script setup>
import { computed, onUnmounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import { useUISettings } from 'dashboard/composables/useUISettings';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import wootConstants from 'dashboard/constants/globals';

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

const store = useStore();
const { t } = useI18n();

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);

const { uiSettings, updateUISettings } = useUISettings();
const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const toggleContactSidebar = () => {
  const opening = !isContactSidebarOpen.value;
  const settings = {
    is_contact_sidebar_open: opening,
    is_copilot_panel_open: false,
  };
  // When opening contact panel, collapse sidebar for more space
  if (opening) {
    settings.sidebar_width = 56;
  }
  updateUISettings(settings);
};

const currentChat = computed(() => store.getters.getSelectedChat);

const isOpen = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.OPEN
);
const isResolved = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.RESOLVED
);

const toggleStatus = async status => {
  try {
    await store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status,
    });
  } catch (error) {
    // silent
  }
};

const actionMenuItems = computed(() => {
  const items = [];

  // Resolve/Reopen action
  if (isOpen.value) {
    items.push({
      icon: 'i-lucide-check-circle',
      label: t('CONVERSATION.HEADER.RESOLVE_ACTION'),
      action: 'resolve',
      value: 'resolve',
    });
  } else if (isResolved.value) {
    items.push({
      icon: 'i-lucide-refresh-cw',
      label: t('CONVERSATION.HEADER.REOPEN_ACTION'),
      action: 'reopen',
      value: 'reopen',
    });
  } else {
    items.push({
      icon: 'i-lucide-circle-play',
      label: t('CONVERSATION.HEADER.OPEN_ACTION'),
      action: 'reopen',
      value: 'reopen',
    });
  }

  // Snooze
  items.push({
    icon: 'i-lucide-alarm-clock-minus',
    label: t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE_UNTIL'),
    action: 'snooze',
    value: 'snooze',
  });

  // Mark pending
  items.push({
    icon: 'i-lucide-circle-dot-dashed',
    label: t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING'),
    action: 'pending',
    value: 'pending',
  });

  // Separator (visual only via different section)
  if (!currentChat.value.muted) {
    items.push({
      icon: 'i-lucide-volume-off',
      label: t('CONTACT_PANEL.MUTE_CONTACT'),
      action: 'mute',
      value: 'mute',
    });
  } else {
    items.push({
      icon: 'i-lucide-volume-1',
      label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
      action: 'unmute',
      value: 'unmute',
    });
  }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  return items;
});

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'resolve') {
    toggleStatus(wootConstants.STATUS_TYPE.RESOLVED);
  } else if (action === 'reopen') {
    toggleStatus(wootConstants.STATUS_TYPE.OPEN);
  } else if (action === 'pending') {
    toggleStatus(wootConstants.STATUS_TYPE.PENDING);
  } else if (action === 'snooze') {
    // TODO: open snooze modal
    toggleStatus(wootConstants.STATUS_TYPE.SNOOZED);
  } else if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  }
};

const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_SEND_TRANSCRIPT, toggleEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_SEND_TRANSCRIPT, toggleEmailModal);
});
</script>

<template>
  <div class="relative flex items-center gap-1 actions--container">
    <ButtonV4
      v-tooltip="$t('CONVERSATION.SIDEBAR.CONTACT')"
      size="sm"
      variant="ghost"
      color="slate"
      icon="i-ph-user-bold"
      :class="{ 'bg-n-alpha-2': isContactSidebarOpen }"
      @click="toggleContactSidebar"
    />
    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      />
    </div>
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
  </div>
</template>
