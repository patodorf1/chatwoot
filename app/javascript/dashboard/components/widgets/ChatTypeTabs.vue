<!--
  ChatTypeTabs.vue  —  pill tabs con count para el ChatList.
  REEMPLAZA: app/javascript/dashboard/components/widgets/ChatTypeTabs.vue

  CONTRATO REAL DEL FORK (verificado contra patodorf1/chatwoot @develop):
  ─ props: items, activeTab, showBadge
  ─ emits: chatTabChange
  ─ ChatList.vue además le pasa `is-compact` — lo aceptamos silenciosamente
    (inheritAttrs:false + declarar) para que no caiga al root como atributo.

  Active state: bg aqua-pale + texto marine. Hover muted.
-->
<script setup>
defineOptions({ inheritAttrs: false });

const props = defineProps({
  items: { type: Array, required: true },
  activeTab: { type: [String, Number], required: true },
  showBadge: { type: Boolean, default: true },
  // Aceptamos el flag pero no lo usamos — el layout ya es compacto.
  isCompact: { type: Boolean, default: false },
});

const emit = defineEmits(['chatTabChange']);
</script>

<template>
  <div class="flex items-center gap-1 px-4 py-2 border-b border-n-slate-3">
    <button
      v-for="tab in items"
      :key="tab.key"
      type="button"
      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium font-ui transition-colors"
      :class="
        activeTab === tab.key
          ? 'bg-n-teal-3 text-n-slate-12'
          : 'text-n-slate-11 hover:bg-n-slate-2 hover:text-n-slate-12'
      "
      @click="emit('chatTabChange', tab.key)"
    >
      <span>{{ tab.name }}</span>
      <span
        v-if="showBadge && tab.count !== undefined && tab.count !== null"
        class="text-[10px] tabular-nums px-1.5 rounded font-semibold"
        :class="activeTab === tab.key ? 'bg-white/70 text-n-slate-12' : 'bg-n-slate-3 text-n-slate-11'"
      >{{ tab.count > 99 ? '99+' : tab.count }}</span>
    </button>

    <div class="ml-auto">
      <slot name="actions" />
    </div>
  </div>
</template>
