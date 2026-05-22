<!--
  ConversationBox.vue  —  container del chat view (header + msgs + composer).
  REEMPLAZA: app/javascript/dashboard/routes/dashboard/conversation/ConversationBox.vue

  CAMBIOS (sólo cosméticos, lógica intacta):
  ─ Wallpaper sigue siendo /assets/images/dashboard/chat-bg.jpeg.
  ─ El overlay encima del wallpaper pasa de blanco puro `bg-white/40` a un
    blanco con micro-tint marine. Visualmente queda como un velo limpio que
    deja respirar el patrón sin lavarlo.
  ─ Sumo un 2do gradient layer (radial-soft) para dar profundidad sutil
    al área del chat, en línea con el design canvas.
  ─ Todo lo demás (computed, watchers, dispatch de labels, tabs de dashboard
    apps, slot, isInboxView) queda IDÉNTICO.
-->
<script>
import { mapGetters } from 'vuex';
import ConversationHeader from './ConversationHeader.vue';
import DashboardAppFrame from '../DashboardApp/Frame.vue';
import EmptyState from './EmptyState/EmptyState.vue';
import MessagesView from './MessagesView.vue';

export default {
  components: {
    ConversationHeader,
    DashboardAppFrame,
    EmptyState,
    MessagesView,
  },
  props: {
    inboxId: {
      type: [Number, String],
      default: '',
      required: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
    isContactPanelOpen: {
      type: Boolean,
      default: true,
    },
    isOnExpandedLayout: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return { activeIndex: 0 };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      dashboardApps: 'dashboardApps/getRecords',
    }),
    dashboardAppTabs() {
      return [
        {
          key: 'messages',
          index: 0,
          name: this.$t('CONVERSATION.DASHBOARD_APP_TAB_MESSAGES'),
        },
        ...this.dashboardApps.map((dashboardApp, index) => ({
          key: `dashboard-${dashboardApp.id}`,
          index: index + 1,
          name: dashboardApp.title,
        })),
      ];
    },
    showContactPanel() {
      return this.isContactPanelOpen && this.currentChat.id;
    },
  },
  watch: {
    'currentChat.inbox_id': {
      immediate: true,
      handler(inboxId) {
        if (inboxId) {
          this.$store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
        }
      },
    },
    'currentChat.id'() {
      this.fetchLabels();
      this.activeIndex = 0;
    },
  },
  mounted() {
    this.fetchLabels();
    this.$store.dispatch('dashboardApps/get');
  },
  methods: {
    fetchLabels() {
      if (!this.currentChat.id) {
        return;
      }
      this.$store.dispatch('conversationLabels/get', this.currentChat.id);
    },
    onDashboardAppTabChange(index) {
      this.activeIndex = index;
    },
  },
};
</script>

<template>
  <div
    class="conversation-details-wrap flex flex-col min-w-0 w-full relative"
    :style="{
      backgroundImage: `url('/assets/images/dashboard/chat-bg.jpeg')`,
      backgroundSize: '400px',
      backgroundRepeat: 'repeat',
    }"
    :class="{
      'border-l rtl:border-l-0 rtl:border-r border-n-weak': !isOnExpandedLayout,
    }"
  >
    <!--
      Overlay marine — dos capas:
       1) Velo de fondo casi blanco con un toque aqua-pale (matchea --wr-aqua-pale
          del brand). Suaviza el wallpaper sin lavarlo.
       2) Glow radial sutil desde arriba — añade profundidad al área del chat.
    -->
    <div
      class="absolute inset-0 pointer-events-none"
      style="
        background:
          radial-gradient(120% 60% at 50% 0%, rgba(202, 247, 248, 0.18), transparent 60%),
          linear-gradient(0deg, rgba(244, 250, 250, 0.62), rgba(244, 250, 250, 0.62));
      "
    />
    <ConversationHeader
      v-if="currentChat.id"
      :chat="currentChat"
      :show-back-button="isOnExpandedLayout && !isInboxView"
      :class="{
        'border-b border-b-n-weak !pt-2': !dashboardApps.length,
      }"
    />
    <woot-tabs
      v-if="dashboardApps.length && currentChat.id"
      :index="activeIndex"
      class="h-10"
      @change="onDashboardAppTabChange"
    >
      <woot-tabs-item
        v-for="tab in dashboardAppTabs"
        :key="tab.key"
        :index="tab.index"
        :name="tab.name"
        :show-badge="false"
        is-compact
      />
    </woot-tabs>
    <div v-show="!activeIndex" class="flex h-full min-h-0 m-0">
      <MessagesView
        v-if="currentChat.id"
        :inbox-id="inboxId"
        :is-inbox-view="isInboxView"
      />
      <EmptyState
        v-if="!currentChat.id && !isInboxView"
        :is-on-expanded-layout="isOnExpandedLayout"
      />
      <slot />
    </div>
    <DashboardAppFrame
      v-for="(dashboardApp, index) in dashboardApps"
      v-show="activeIndex - 1 === index"
      :key="currentChat.id + '-' + dashboardApp.id"
      :is-visible="activeIndex - 1 === index"
      :config="dashboardApps[index].content"
      :position="index"
      :current-chat="currentChat"
    />
  </div>
</template>
