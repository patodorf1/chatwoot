<!--
  SidebarGroupHeader.vue  —  header de cada grupo top-level del rail.
  REEMPLAZA: app/javascript/dashboard/components-next/sidebar/SidebarGroupHeader.vue

  Sólo cambios cosméticos: los hex hardcodeados salen a CSS vars
  (`sidebar-theme.css` define la paleta Marine y Lavanda).

  Active state:
  ─ isActive && !hasActiveChild   → white pill + aqua ring + text strong
  ─ hasActiveChild (grupo abierto) → sólo text strong (sin pill)
  ─ idle                           → text muted, hover muestra hover bg

  El badge contador (`count`) sigue como outline pequeño; cambia su contraste
  según el estado activo.
-->
<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  to: { type: [Object, String], default: '' },
  label: { type: String, default: '' },
  icon: { type: [String, Object], default: '' },
  expandable: { type: Boolean, default: false },
  isExpanded: { type: Boolean, default: false },
  isActive: { type: Boolean, default: false },
  hasActiveChild: { type: Boolean, default: false },
  getterKeys: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['toggle']);

const showBadge = useMapGetter(props.getterKeys.badge);
const dynamicCount = useMapGetter(props.getterKeys.count);
const count = computed(() =>
  dynamicCount.value > 99 ? '99+' : dynamicCount.value
);
</script>

<template>
  <component
    :is="to ? 'router-link' : 'div'"
    class="flex items-center gap-2 px-1.5 py-1 rounded-lg h-6 min-w-0 transition-colors"
    role="button"
    draggable="false"
    :to="to"
    :title="label"
    :class="{
      'text-[var(--rail-active-text)] dark:text-white bg-[var(--rail-active-bg)] dark:bg-white/10 ring-1 ring-[var(--rail-active-ring)] dark:ring-white/0 font-medium':
        isActive && !hasActiveChild,
      'text-[var(--rail-fg-strong)] dark:text-white font-medium':
        hasActiveChild,
      'text-[var(--rail-fg)] dark:text-white/70 hover:bg-[var(--rail-hover)] dark:hover:bg-white/10':
        !isActive && !hasActiveChild,
    }"
    @click.stop="emit('toggle')"
  >
    <div v-if="icon" class="relative flex items-center gap-2">
      <Icon v-if="icon" :icon="icon" class="size-4" />
      <span
        v-if="showBadge"
        class="size-2 -top-px ltr:-right-px rtl:-left-px bg-n-brand absolute rounded-full border border-n-solid-2"
      />
    </div>
    <div class="flex items-center gap-1.5 flex-grow min-w-0 flex-1">
      <span
        class="truncate"
        :class="{
          'text-xs': !isActive,
          'font-medium text-xs': isActive || hasActiveChild,
        }"
      >
        {{ label }}
      </span>
      <span
        v-if="dynamicCount && !expandable"
        class="rounded-md capitalize text-xs leading-5 font-medium text-center outline outline-1 px-1 flex-shrink-0"
        :class="{
          'text-[var(--rail-active-text)] dark:text-white outline-[var(--rail-line-strong)] dark:outline-white/40':
            isActive,
          'text-[var(--rail-fg)] dark:text-white/70 outline-[var(--rail-line)] dark:outline-white/20':
            !isActive,
        }"
      >
        {{ count }}
      </span>
    </div>
    <span
      v-if="expandable"
      v-show="isExpanded"
      class="i-lucide-chevron-up size-3"
      @click.stop="emit('toggle')"
    />
  </component>
</template>
