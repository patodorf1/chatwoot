<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import BackButton from '../BackButton.vue';

import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useUISettings } from 'dashboard/composables/useUISettings';
import {
  RECRUITMENT_STATUSES,
  getRecruitmentStatus,
  isRecruitmentStatusLabel,
} from 'dashboard/helper/recruitmentStatus';

import { useI18n } from 'vue-i18n';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const conversationHeader = ref(null);
const { width } = useElementSize(conversationHeader);
const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const snoozedDisplayText = computed(() => {
  const { snoozed_until: snoozedUntil } = currentChat.value;
  if (snoozedUntil) {
    return `${t('CONVERSATION.HEADER.SNOOZED_UNTIL')} ${snoozedReopenTime(snoozedUntil)}`;
  }
  return t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
});

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

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
  if (opening) {
    settings.sidebar_width = 56;
  }
  updateUISettings(settings);
};

const isOpen = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.OPEN
);
const isResolved = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.RESOLVED
);

const resolveButtonIcon = computed(() =>
  isResolved.value ? 'i-lucide-refresh-cw' : 'i-lucide-check-circle'
);
const resolveButtonTooltip = computed(() =>
  isResolved.value
    ? t('CONVERSATION.HEADER.REOPEN_ACTION')
    : t('CONVERSATION.HEADER.RESOLVE_ACTION')
);

const toggleStatus = async () => {
  const status = isResolved.value
    ? wootConstants.STATUS_TYPE.OPEN
    : wootConstants.STATUS_TYPE.RESOLVED;
  try {
    await store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status,
    });
  } catch {
    // silent
  }
};

// Recruitment status dropdown
const showStatusDropdown = ref(false);

const currentRecruitmentStatus = computed(() => {
  const labels = currentChat.value.labels || [];
  return getRecruitmentStatus(labels);
});

const toggleStatusDropdown = () => {
  showStatusDropdown.value = !showStatusDropdown.value;
};

const closeStatusDropdown = () => {
  showStatusDropdown.value = false;
};

const selectRecruitmentStatus = async status => {
  const conversationId = currentChat.value.id;
  const currentLabels = currentChat.value.labels || [];
  // Remove any existing recruitment status labels
  const otherLabels = currentLabels.filter(l => !isRecruitmentStatusLabel(l));
  // Add the new status (or clear if same status clicked again)
  const isSameStatus =
    currentRecruitmentStatus.value?.key === status.key;
  const newLabels = isSameStatus
    ? otherLabels
    : [...otherLabels, status.title];

  try {
    await store.dispatch('conversationLabels/update', {
      conversationId,
      labels: newLabels,
    });
    // Also update labels on the conversation object so the card reflects the change immediately
    const conversation = store.getters.getSelectedChat;
    if (conversation) {
      conversation.labels = newLabels;
    }
  } catch {
    useAlert('Error al actualizar el estado');
  }
  closeStatusDropdown();
};
</script>

<template>
  <div
    ref="conversationHeader"
    class="flex flex-row items-center justify-between flex-1 w-full min-w-0 px-3 py-2 h-12 bg-white"
  >
    <div
      class="flex items-center justify-start max-w-full min-w-0 flex-1"
    >
      <BackButton
        v-if="showBackButton"
        class="ltr:mr-2 rtl:ml-2"
      />
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="32"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
      />
      <div
        class="flex flex-col items-start min-w-0 ml-2 overflow-hidden rtl:ml-0 rtl:mr-2"
      >
        <div class="flex flex-row items-center max-w-full gap-1 p-0 m-0">
          <span
            class="text-sm font-normal truncate leading-tight text-n-slate-12"
          >
            {{ currentContact.name }}
          </span>
          <!-- Identity verification warning removed -->
        </div>

        <div
          class="flex items-center gap-1.5 overflow-hidden text-xs conversation--header--actions text-ellipsis whitespace-nowrap"
        >
          <span
            v-if="currentRecruitmentStatus"
            class="inline-flex items-center px-1.5 py-0 rounded-md text-xxs font-medium"
            :style="{
              backgroundColor: currentRecruitmentStatus.color + '20',
              color: currentRecruitmentStatus.color,
            }"
          >
            {{ currentRecruitmentStatus.displayName }}
          </span>
          <span v-if="isSnoozed" class="font-medium text-n-amber-10">
            {{ snoozedDisplayText }}
          </span>
        </div>
      </div>
    </div>
    <div
      class="flex flex-row items-center justify-end flex-shrink-0 gap-1 header-actions-wrap"
    >
      <div class="relative">
        <ButtonV4
          v-tooltip="'Estado de reclutamiento'"
          size="sm"
          variant="ghost"
          color="slate"
          icon="i-lucide-tag"
          :class="{
            'bg-n-alpha-2': showStatusDropdown,
          }"
          @click="toggleStatusDropdown"
        />
        <span
          v-if="currentRecruitmentStatus"
          class="absolute -top-0.5 -right-0.5 size-2.5 rounded-full border border-white"
          :style="{ backgroundColor: currentRecruitmentStatus.color }"
        />
        <div
          v-if="showStatusDropdown"
          v-on-clickaway="closeStatusDropdown"
          class="absolute right-0 top-full mt-1 w-44 bg-white rounded-lg shadow-lg border border-n-weak py-1 z-50"
        >
          <button
            v-for="status in RECRUITMENT_STATUSES"
            :key="status.key"
            class="flex items-center gap-2 w-full px-3 py-1.5 text-xs text-left hover:bg-n-slate-2 transition-colors"
            :class="{
              'bg-n-slate-2 font-medium':
                currentRecruitmentStatus?.key === status.key,
            }"
            @click="selectRecruitmentStatus(status)"
          >
            <span
              class="size-2.5 rounded-full flex-shrink-0"
              :style="{ backgroundColor: status.color }"
            />
            {{ status.displayName }}
          </button>
        </div>
      </div>
      <ButtonV4
        v-tooltip="resolveButtonTooltip"
        size="sm"
        variant="ghost"
        color="slate"
        :icon="resolveButtonIcon"
        @click="toggleStatus"
      />
      <ButtonV4
        v-tooltip="t('CONVERSATION.SIDEBAR.CONTACT')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-user"
        :class="{ 'bg-n-alpha-2': isContactSidebarOpen }"
        @click="toggleContactSidebar"
      />
    </div>
  </div>
</template>
