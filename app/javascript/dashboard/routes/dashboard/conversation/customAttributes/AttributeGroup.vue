<!--
  AttributeGroup.vue  —  sección plegable con header y contador filled/total.
  Nuevo archivo: app/javascript/dashboard/.../customAttributes/AttributeGroup.vue
-->
<script setup>
import { computed } from 'vue';

const props = defineProps({
  title: { type: String, required: true },
  filledCount: { type: Number, default: 0 },
  totalCount: { type: Number, default: 0 },
  collapsed: { type: Boolean, default: false },
});

defineEmits(['toggle']);

const isComplete = computed(
  () => props.totalCount > 0 && props.filledCount === props.totalCount
);
</script>

<template>
  <section class="border-b border-n-slate-3">
    <button
      type="button"
      class="w-full flex items-center justify-between gap-2 px-4 py-2
             hover:bg-n-slate-2 transition-colors"
      :aria-expanded="!collapsed"
      @click="$emit('toggle')"
    >
      <span class="flex items-center gap-2">
        <span
          class="size-2.5 text-n-slate-11 transition-transform"
          :class="collapsed ? 'i-lucide-chevron-right' : 'i-lucide-chevron-down'"
        />
        <span
          class="text-[11px] font-semibold tracking-[0.06em] uppercase
                 text-n-slate-12 font-display"
        >
          {{ title }}
        </span>
      </span>
      <span
        class="text-[10px] tabular-nums font-medium font-display"
        :class="isComplete ? 'text-n-teal-text' : 'text-n-slate-10'"
      >
        {{ filledCount }}/{{ totalCount }}
      </span>
    </button>

    <div v-show="!collapsed" class="pb-1">
      <slot />
    </div>
  </section>
</template>
