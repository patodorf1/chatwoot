<!--
  ConversationHeader.vue  —  barra superior del chat.
  REEMPLAZA: app/javascript/dashboard/components/widgets/conversation/ConversationHeader.vue

  CONTRATO REAL DEL FORK (verificado contra patodorf1/chatwoot @develop):
  ─ Composition API ✓ (no cambia respecto al original).
  ─ Props: `chat` (default {}), `showBackButton`. Nada más.
    NO existe `isContactPanelOpen` como prop — se lee con useUISettings().
  ─ NO emits. El padre (ConversationBox.vue) sólo pasa props, no escucha.
  ─ Resolve / reopen / snooze / toggle contact panel se hacen INTERNAMENTE
    via vuex + useUISettings().

  Layout:
  ─ Avatar (con presencia) · nombre + inbox · meta línea 2 (channel · last seen)
  ─ Acciones primarias: Etiquetar, Resolver (verde) o Reabrir
  ─ Acciones secundarias: Snooze, More, Toggle ContactPanel
-->
<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

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

const store = useStore();
const { t } = useI18n();
const inboxes = useMapGetter('inboxes/getInboxes');

// Contact panel state vive en uiSettings — NO es prop.
const { uiSettings, updateUISettings } = useUISettings();
const isContactPanelOpen = computed(
  () => !uiSettings.value?.is_contact_sidebar_open === false
);
const toggleContactPanel = () => {
  updateUISettings({
    is_contact_sidebar_open: !uiSettings.value?.is_contact_sidebar_open,
  });
};

// ── Derived display data ────────────────────────────────────────────────
const sender = computed(() => props.chat.meta?.sender || {});
const inbox = computed(
  () => inboxes.value.find((i) => i.id === props.chat.inbox_id) || {}
);

const senderName = computed(
  () =>
    sender.value.name ||
    sender.value.phone_number ||
    sender.value.email ||
    t('CONVERSATION.NO_NAME')
);

const senderMeta = computed(() => {
  const extra = sender.value.additional_attributes || {};
  if (extra.company_name || extra.job_title) {
    return [extra.company_name, extra.job_title].filter(Boolean).join(' · ');
  }
  return sender.value.email || sender.value.identifier || '';
});

const phone = computed(() => sender.value.phone_number);
const isOnline = computed(() => sender.value.availability_status === 'online');

// ── Status + actions ────────────────────────────────────────────────────
const status = computed(() => props.chat.status);
const isOpen = computed(() => status.value === 'open');
const isResolved = computed(() => status.value === 'resolved');
const isSnoozed = computed(() => status.value === 'snoozed');

// Toggle status via store (no emit).
const setStatus = (next) => {
  if (!props.chat.id) return;
  store.dispatch('toggleStatus', {
    conversationId: props.chat.id,
    status: next,
  });
};
const resolveConversation = () => setStatus('resolved');
const reopenConversation = () => setStatus('open');

// Snooze abre el menú existente — si tu fork dispara un modal/popover
// distinto, cambialo acá. El store action es el mismo punto de entrada.
const openSnoozeMenu = () => {
  store.dispatch('conversationPage/setSnoozeMenu', {
    conversationId: props.chat.id,
    open: true,
  });
};

const openLabelEditor = () => {
  // En el fork, esto se hace via context menu / inline editor en
  // ConversationActions.vue. Para evitar romper esos flujos, acá
  // sólo togglemos la visibilidad de los labels (si existe el setting),
  // sin abrir un editor propio.
  store.dispatch('conversationLabels/openEditor', {
    conversationId: props.chat.id,
  });
};

const openMoreActions = () => {
  store.dispatch('conversationPage/setMoreActionsMenu', {
    conversationId: props.chat.id,
    open: true,
  });
};

const goBack = () => {
  store.dispatch('setActiveChat', { data: null });
};
</script>

<template>
  <header
    class="h-14 px-4 flex items-center gap-3 border-b border-n-slate-3 bg-n-background shrink-0"
  >
    <!-- Back button (mobile) -->
    <button
      v-if="showBackButton"
      type="button"
      class="size-7 -ml-1 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 transition-colors"
      :aria-label="t('CONVERSATION.HEADER.BACK')"
      @click="goBack"
    >
      <span class="i-lucide-arrow-left size-4" />
    </button>

    <!-- Avatar -->
    <div class="relative shrink-0">
      <Thumbnail
        v-if="sender.thumbnail"
        :src="sender.thumbnail"
        :username="senderName"
        size="36px"
      />
      <div
        v-else
        class="size-9 rounded-full bg-n-slate-3 text-n-slate-12 grid place-items-center text-[12px] font-bold font-ui"
      >
        {{ (senderName[0] || '?').toUpperCase() }}
      </div>
      <span
        v-if="isOnline"
        class="absolute -bottom-0.5 -right-0.5 size-2.5 rounded-full bg-n-teal-9 border-2 border-n-background"
      />
    </div>

    <!-- Title block -->
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2">
        <span class="font-display font-bold text-[14.5px] text-n-slate-12 truncate">
          {{ senderName }}
        </span>
        <span v-if="senderMeta" class="size-1 rounded-full bg-n-slate-6 shrink-0" />
        <span
          v-if="senderMeta"
          class="text-[11.5px] text-n-slate-11 truncate font-ui"
        >{{ senderMeta }}</span>
      </div>
      <div class="flex items-center gap-2 mt-0.5">
        <span
          v-if="isOnline"
          class="inline-flex items-center gap-1 text-[10.5px] text-n-slate-11 font-ui"
        >
          <span class="size-1.5 rounded-full bg-n-teal-9" />
          {{ t('CONVERSATION.HEADER.ONLINE') }}
        </span>
        <span v-if="phone && isOnline" class="text-[10.5px] text-n-slate-8">·</span>
        <span
          v-if="phone"
          class="text-[10.5px] text-n-slate-10 font-ui truncate"
        >{{ phone }}</span>
        <span
          v-if="inbox.name"
          class="text-[10.5px] text-n-slate-10 font-ui truncate"
        >
          <template v-if="phone">· </template>{{ inbox.name }}
        </span>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex items-center gap-1 shrink-0">
      <button
        type="button"
        class="h-7 px-2 rounded-md text-[11.5px] font-semibold font-ui text-n-slate-12 bg-n-slate-2 hover:bg-n-slate-3 inline-flex items-center gap-1 transition-colors"
        @click="openLabelEditor"
      >
        <span class="i-lucide-tag size-3" />
        {{ t('CONVERSATION.HEADER.LABEL') }}
      </button>

      <button
        v-if="isOpen"
        type="button"
        class="h-7 px-2.5 rounded-md text-[11.5px] font-semibold font-ui text-white bg-n-teal-9 hover:bg-n-teal-10 inline-flex items-center gap-1 transition-colors"
        @click="resolveConversation"
      >
        <span class="i-lucide-check size-3" />
        {{ t('CONVERSATION.HEADER.RESOLVE') }}
      </button>
      <button
        v-else-if="isResolved || isSnoozed"
        type="button"
        class="h-7 px-2.5 rounded-md text-[11.5px] font-semibold font-ui text-n-slate-12 bg-n-amber-3 hover:bg-n-amber-4 inline-flex items-center gap-1 transition-colors"
        @click="reopenConversation"
      >
        <span class="i-lucide-rotate-ccw size-3" />
        {{ t('CONVERSATION.HEADER.REOPEN') }}
      </button>

      <button
        v-if="isOpen"
        type="button"
        class="size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 transition-colors"
        :aria-label="t('CONVERSATION.HEADER.SNOOZE')"
        @click="openSnoozeMenu"
      >
        <span class="i-lucide-moon size-3.5" />
      </button>

      <span class="w-px h-5 bg-n-slate-3 mx-1" />

      <button
        type="button"
        class="size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 transition-colors"
        :aria-label="t('CONVERSATION.HEADER.MORE')"
        @click="openMoreActions"
      >
        <span class="i-lucide-more-horizontal size-3.5" />
      </button>
      <button
        type="button"
        class="size-7 rounded-md grid place-items-center transition-colors"
        :class="
          isContactPanelOpen
            ? 'bg-n-teal-3 text-n-slate-12'
            : 'text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12'
        "
        :aria-label="t('CONVERSATION.HEADER.TOGGLE_CONTACT')"
        :aria-pressed="isContactPanelOpen"
        @click="toggleContactPanel"
      >
        <span class="i-lucide-panel-right size-3.5" />
      </button>
    </div>
  </header>
</template>
