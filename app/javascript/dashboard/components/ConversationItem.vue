<!--
  ConversationItem.vue  —  fila individual del listado de conversaciones.
  REEMPLAZA: app/javascript/dashboard/components/ConversationItem.vue

  CONTRATO REAL DEL FORK (verificado contra patodorf1/chatwoot @develop):
  ─ Options API (no Composition / no <script setup>) para que match con
    el resto del archivo del fork.
  ─ Props: source, teamId, label, conversationType, foldersId, showAssignee.
    NO existen hideInboxName / hideThumbnail / selected como props del Item —
    esos viven en ConversationCard.vue (hijo, en components/widgets/conversation/).
  ─ Acciones via INJECT (no emit): selectConversation, deSelectConversation,
    assignAgent, assignTeam, assignLabels, removeLabels, updateConversationStatus,
    toggleContextMenu, markAsUnread, markAsRead, assignPriority,
    isConversationSelected, deleteConversation.
  ─ El "selected state" se calcula con isConversationSelected(source.id).
  ─ ChatList.vue lo invoca pasando :source / :team-id / :label / :folders-id /
    :conversation-type / :show-assignee y NO le pasa `selected` ni hide-*.

  Render compacto (hasta 4 líneas):
  1) Nombre del sender · timestamp (a la derecha)
  2) Preview del último mensaje · badge no-leídas
  3) Labels (máx 2 + "+N")
  4) Assignee mini-pill · inbox name

  Diseño Marine: bg-n-teal-3/40 + border-l aqua para activo.
-->
<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { messageStamp } from 'shared/helpers/timeHelper';

// Inject keys que ChatList / ConversationView ya proveen — los listamos a
// todos aunque acá sólo usemos un subset; cualquier handler adicional que
// el fork agregue (context menu items, etc.) sigue funcionando.
const INJECT_KEYS = [
  'selectConversation',
  'deSelectConversation',
  'assignAgent',
  'assignTeam',
  'assignLabels',
  'removeLabels',
  'updateConversationStatus',
  'toggleContextMenu',
  'markAsUnread',
  'markAsRead',
  'assignPriority',
  'isConversationSelected',
  'deleteConversation',
];

export default {
  name: 'ConversationItem',

  components: { Thumbnail },

  // Inject como objeto (cada uno opcional para no crashear en tests).
  inject: INJECT_KEYS.reduce((acc, key) => {
    acc[key] = { default: () => {} };
    return acc;
  }, {}),

  props: {
    source: {
      type: Object,
      required: true,
    },
    teamId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
    showAssignee: {
      type: Boolean,
      default: false,
    },
  },

  computed: {
    ...mapGetters({
      inboxes: 'inboxes/getInboxes',
      allLabels: 'labels/getLabels',
    }),

    chat() {
      return this.source;
    },

    sender() {
      return this.chat.meta?.sender || {};
    },

    assignee() {
      return this.chat.meta?.assignee || {};
    },

    inbox() {
      return this.inboxes.find((i) => i.id === this.chat.inbox_id) || {};
    },

    senderName() {
      return (
        this.sender.name ||
        this.sender.phone_number ||
        this.sender.email ||
        this.$t('CONVERSATION.NO_NAME')
      );
    },

    initials() {
      const parts = (this.senderName || '').split(/\s+/).filter(Boolean);
      const a = parts[0]?.[0] || '';
      const b = parts[1]?.[0] || '';
      return (a + b).toUpperCase().slice(0, 2) || '?';
    },

    lastMessage() {
      const msgs = this.chat.messages || [];
      return msgs[msgs.length - 1];
    },

    messagePreview() {
      const m = this.lastMessage;
      if (!m) return '';
      if (m.attachments?.length) return this.$t('CONVERSATION.SHARED_ATTACHMENT');
      const content = (m.content || '').replace(/\s+/g, ' ').trim();
      if (m.message_type === 1) return `↪ ${content}`; // outgoing
      if (m.private) return `🔒 ${content}`;
      return content;
    },

    lastActivityAt() {
      return this.chat.timestamp || this.chat.last_activity_at;
    },

    formattedTime() {
      return this.lastActivityAt ? messageStamp(this.lastActivityAt) : '';
    },

    unreadCount() {
      return this.chat.unread_count || 0;
    },

    isUnread() {
      return this.unreadCount > 0;
    },

    labels() {
      const chatLabels = this.chat.labels || [];
      return chatLabels
        .map((title) => this.allLabels.find((l) => l.title === title))
        .filter(Boolean);
    },

    priority() {
      return this.chat.priority;
    },

    isSnoozed() {
      return this.chat.status === 'snoozed';
    },

    isActive() {
      // selected state derivado, no es prop.
      return Boolean(this.isConversationSelected?.(this.chat.id));
    },

    avatarToneClass() {
      const tones = [
        'bg-n-amber-3 text-n-amber-text',
        'bg-n-ruby-3 text-n-ruby-9',
        'bg-n-slate-3 text-n-slate-12',
        'bg-n-teal-3 text-n-teal-10',
        'bg-n-blue-3 text-n-blue-text',
      ];
      const id = this.sender.id || this.chat.id || 0;
      return tones[id % tones.length];
    },

    priorityClass() {
      return (
        {
          urgent: 'text-n-ruby-9',
          high: 'text-n-amber-text',
          medium: 'text-n-slate-10',
          low: 'text-n-slate-10',
        }[this.priority] || ''
      );
    },
  },

  methods: {
    onSelect() {
      // Match el flujo del fork: toggle via los callbacks inyectados.
      if (this.isActive) {
        this.deSelectConversation?.();
      } else {
        this.selectConversation?.(this.chat, this.conversationType);
      }
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="w-full flex items-start gap-2.5 px-4 py-2.5 text-left transition-colors border-l-[3px] group"
    :class="
      isActive
        ? 'bg-n-teal-3/40 border-l-n-teal-9'
        : 'border-l-transparent hover:bg-n-slate-2'
    "
    @click="onSelect"
  >
    <!-- Avatar with channel badge -->
    <div class="relative shrink-0">
      <Thumbnail
        v-if="sender.thumbnail"
        :src="sender.thumbnail"
        :username="senderName"
        size="36px"
        :status="sender.availability_status"
      />
      <div
        v-else
        class="size-9 rounded-full grid place-items-center font-bold text-[12px] font-ui"
        :class="avatarToneClass"
      >
        {{ initials }}
      </div>
      <span
        v-if="inbox.channel_type === 'Channel::Api' || inbox.channel_type?.includes('Whatsapp')"
        class="absolute -bottom-0.5 -right-0.5 size-3.5 rounded-full grid place-items-center bg-n-teal-9 border-2 border-n-background"
        :title="inbox.name"
      >
        <span class="i-lucide-message-circle size-2 text-white" />
      </span>
    </div>

    <!-- Body -->
    <div class="flex-1 min-w-0">
      <!-- L1: name · meta · time -->
      <div class="flex items-center gap-1.5 mb-0.5">
        <span
          v-if="priority"
          class="i-lucide-flag size-3 shrink-0"
          :class="priorityClass"
          :title="priority"
        />
        <span
          class="text-[13px] truncate font-display"
          :class="isUnread ? 'font-bold text-n-slate-12' : 'font-semibold text-n-slate-12'"
        >{{ senderName }}</span>
        <span
          v-if="isSnoozed"
          class="i-lucide-moon size-3 text-n-slate-10 shrink-0"
          :title="$t('CONVERSATION.SNOOZED')"
        />
        <span class="ml-auto text-[10px] text-n-slate-10 shrink-0 tabular-nums font-ui">{{ formattedTime }}</span>
      </div>

      <!-- L2: preview · unread -->
      <div class="flex items-start gap-1.5">
        <p
          class="flex-1 text-[12px] leading-snug truncate"
          :class="isUnread ? 'text-n-slate-12 font-medium' : 'text-n-slate-11'"
        >{{ messagePreview }}</p>
        <span
          v-if="isUnread"
          class="shrink-0 min-w-[18px] h-[18px] px-1.5 rounded-full bg-n-teal-9 text-white text-[10px] font-bold inline-flex items-center justify-center tabular-nums font-ui"
        >{{ unreadCount > 9 ? '9+' : unreadCount }}</span>
      </div>

      <!-- L3: labels (max 2 visible) -->
      <div v-if="labels.length" class="flex items-center gap-1 mt-1.5 flex-wrap">
        <span
          v-for="l in labels.slice(0, 2)"
          :key="l.id"
          class="text-[10px] px-1.5 py-[1px] rounded border font-medium truncate max-w-[180px] font-ui"
          :style="{
            backgroundColor: `${l.color}1A`,
            color: l.color,
            borderColor: `${l.color}40`,
          }"
        >{{ l.title }}</span>
        <span v-if="labels.length > 2" class="text-[10px] text-n-slate-10 font-ui">
          +{{ labels.length - 2 }}
        </span>
      </div>

      <!-- L4: assignee · inbox -->
      <div
        v-if="(showAssignee && assignee.name) || inbox.name"
        class="flex items-center gap-1.5 mt-1"
      >
        <span
          v-if="showAssignee && assignee.name"
          class="inline-flex items-center gap-1 text-[10px] text-n-slate-10 font-ui"
        >
          <span
            class="size-3 rounded-full bg-n-ruby-9 text-white text-[7px] font-bold inline-flex items-center justify-center"
          >{{ assignee.name[0] }}</span>
          {{ assignee.name }}
        </span>
        <span
          v-if="inbox.name"
          class="text-[10px] text-n-slate-10 truncate font-ui"
        >{{ showAssignee && assignee.name ? '·' : '' }} {{ inbox.name }}</span>
      </div>
    </div>
  </button>
</template>
