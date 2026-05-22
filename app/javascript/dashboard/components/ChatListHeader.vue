<!--
  ChatListHeader.vue  —  header del listado de conversaciones.
  REEMPLAZA: app/javascript/dashboard/components/ChatListHeader.vue

  CONTRATO REAL DEL FORK (verificado contra patodorf1/chatwoot @develop):
  ─ Props:
      pageTitle           String  required
      hasAppliedFilters   Bool    required
      hasActiveFolders    Bool    required
      activeStatus        String  required   (open|resolved|pending|snoozed|all)
      isOnExpandedLayout  Bool    required
      conversationStats   Object  required   (count por status)
      isListLoading       Bool    required
      hideStatusFilter    Bool    default false
  ─ Emits:
      addFolders          Crear carpeta a partir de filtros aplicados
      deleteFolders       Borrar la carpeta activa
      resetFilters        Limpiar filtros básicos / volver al view default
      basicFilterChange   ({ status })  cambio de tab Abiertas/Resueltas/…
      filtersModal        Abrir modal de filtros avanzados (era openFilter)
      searchQuery         (text)  búsqueda inline — dispara on @input

  ⚠️ Diferencias con la entrega anterior:
    - openSearch NO existe → la búsqueda es inline (input embebido).
    - markAllRead NO existe → fuera del header.
    - openFilter → filtersModal.
-->
<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  pageTitle: { type: String, required: true },
  hasAppliedFilters: { type: Boolean, required: true },
  hasActiveFolders: { type: Boolean, required: true },
  activeStatus: { type: String, required: true },
  isOnExpandedLayout: { type: Boolean, required: true },
  conversationStats: { type: Object, required: true },
  isListLoading: { type: Boolean, required: true },
  hideStatusFilter: { type: Boolean, default: false },
});

const emit = defineEmits([
  'addFolders',
  'deleteFolders',
  'resetFilters',
  'basicFilterChange',
  'filtersModal',
  'searchQuery',
]);

const { t } = useI18n();

// ── Inline search ───────────────────────────────────────────────────────
const isSearchOpen = ref(false);
const searchValue = ref('');
const searchInputRef = ref(null);

const openSearch = async () => {
  isSearchOpen.value = true;
  await Promise.resolve();
  searchInputRef.value?.focus?.();
};
const closeSearch = () => {
  isSearchOpen.value = false;
  if (searchValue.value) {
    searchValue.value = '';
    emit('searchQuery', '');
  }
};
const onSearchInput = (e) => {
  emit('searchQuery', e.target.value);
};

// ── Status tabs (basicFilterChange) ─────────────────────────────────────
const statuses = computed(() => [
  { key: 'open',      label: t('CHAT_LIST.TAB_OPEN'),      count: props.conversationStats.open },
  { key: 'mine',      label: t('CHAT_LIST.TAB_MINE'),      count: props.conversationStats.mine },
  { key: 'all',       label: t('CHAT_LIST.TAB_ALL'),       count: props.conversationStats.all },
  { key: 'resolved',  label: t('CHAT_LIST.TAB_RESOLVED'),  count: props.conversationStats.resolved },
  { key: 'pending',   label: t('CHAT_LIST.TAB_PENDING'),   count: props.conversationStats.pending },
  { key: 'snoozed',   label: t('CHAT_LIST.TAB_SNOOZED'),   count: props.conversationStats.snoozed },
]);

const onStatusChange = (status) => {
  if (status === props.activeStatus) return;
  emit('basicFilterChange', { status });
};
</script>

<template>
  <header
    class="px-4 pt-4 pb-2 bg-n-background border-b border-n-slate-3 shrink-0"
  >
    <!-- Row 1: title + actions -->
    <div class="flex items-center justify-between gap-2">
      <h2
        v-if="!isSearchOpen"
        class="font-display font-bold text-[15px] text-n-slate-12 truncate"
        :title="pageTitle"
      >
        {{ pageTitle }}
        <span
          v-if="isListLoading"
          class="ml-1.5 inline-block size-1.5 rounded-full bg-n-teal-9 animate-pulse align-middle"
        />
      </h2>

      <!-- Inline search input (when open) -->
      <div
        v-else
        class="flex-1 flex items-center gap-1.5 h-7 px-2 rounded-md bg-n-slate-2 border border-n-slate-3"
      >
        <span class="i-lucide-search size-3.5 text-n-slate-10 shrink-0" />
        <input
          ref="searchInputRef"
          v-model="searchValue"
          type="text"
          :placeholder="t('CHAT_LIST.SEARCH_PLACEHOLDER')"
          class="flex-1 bg-transparent outline-none text-[12px] font-ui text-n-slate-12 placeholder:text-n-slate-10"
          @input="onSearchInput"
          @keyup.esc="closeSearch"
        />
        <button
          type="button"
          class="size-5 rounded grid place-items-center text-n-slate-10 hover:text-n-slate-12 hover:bg-n-slate-3 transition-colors"
          :aria-label="t('CHAT_LIST.CLOSE_SEARCH')"
          @click="closeSearch"
        >
          <span class="i-lucide-x size-3" />
        </button>
      </div>

      <div v-if="!isSearchOpen" class="flex items-center gap-0.5 shrink-0">
        <!-- Reset filters -->
        <button
          v-if="hasAppliedFilters || hasActiveFolders"
          type="button"
          class="text-[11px] font-medium font-ui text-n-ruby-9 hover:underline px-2 py-1"
          @click="emit('resetFilters')"
        >
          {{ t('CHAT_LIST.RESET_FILTERS') }}
        </button>

        <!-- Save current filters as folder -->
        <button
          v-if="hasAppliedFilters && !hasActiveFolders"
          type="button"
          class="size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 transition-colors"
          :aria-label="t('CHAT_LIST.SAVE_FOLDER')"
          @click="emit('addFolders')"
        >
          <span class="i-lucide-folder-plus size-3.5" />
        </button>

        <!-- Delete active folder -->
        <button
          v-if="hasActiveFolders"
          type="button"
          class="size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-ruby-9 transition-colors"
          :aria-label="t('CHAT_LIST.DELETE_FOLDER')"
          @click="emit('deleteFolders')"
        >
          <span class="i-lucide-trash-2 size-3.5" />
        </button>

        <!-- Advanced filters modal -->
        <button
          type="button"
          class="relative size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 transition-colors"
          :aria-label="t('CHAT_LIST.FILTER')"
          @click="emit('filtersModal')"
        >
          <span class="i-lucide-filter size-3.5" />
          <span
            v-if="hasAppliedFilters"
            class="absolute top-1 right-1 size-1.5 rounded-full bg-n-teal-9"
          />
        </button>

        <!-- Search toggle -->
        <button
          type="button"
          class="size-7 rounded-md grid place-items-center text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12 transition-colors"
          :aria-label="t('CHAT_LIST.SEARCH')"
          @click="openSearch"
        >
          <span class="i-lucide-search size-3.5" />
        </button>
      </div>
    </div>

    <!-- Row 2: status tabs (basicFilterChange) -->
    <div
      v-if="!hideStatusFilter && isOnExpandedLayout"
      class="flex items-center gap-1 mt-2 -mx-1 overflow-x-auto"
    >
      <button
        v-for="s in statuses"
        :key="s.key"
        type="button"
        class="inline-flex items-center gap-1.5 px-2 py-1 rounded-md text-[11px] font-medium font-ui transition-colors shrink-0"
        :class="
          activeStatus === s.key
            ? 'bg-n-teal-3 text-n-slate-12'
            : 'text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12'
        "
        @click="onStatusChange(s.key)"
      >
        <span>{{ s.label }}</span>
        <span
          v-if="s.count !== undefined && s.count !== null"
          class="text-[10px] tabular-nums px-1.5 rounded font-semibold"
          :class="activeStatus === s.key ? 'bg-white/70 text-n-slate-12' : 'bg-n-slate-3 text-n-slate-11'"
        >{{ s.count > 99 ? '99+' : s.count }}</span>
      </button>
    </div>
  </header>
</template>
