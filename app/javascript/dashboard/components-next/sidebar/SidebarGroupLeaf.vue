<!--
  SidebarGroupLeaf.vue  —  item terminal del rail (canal, folder, etc.).
  REEMPLAZA: app/javascript/dashboard/components-next/sidebar/SidebarGroupLeaf.vue

  Cambios sólo cosméticos:
  ─ Hex hardcodeados (#6a6779, #34353f/*) → CSS vars en sidebar-theme.css.
  ─ Active state: white pill + aqua ring (era tinted slate /10).
  ─ Hover: gradient sutil usando --rail-hover.
  ─ Las "rails" entre items (before/after pseudo) usan --rail-line-strong.
-->
<script setup>
import { isVNode, computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import Policy from 'dashboard/components/policy.vue';
import { useSidebarContext } from './provider';

const props = defineProps({
  label: { type: String, required: true },
  to: { type: [String, Object], required: true },
  icon: { type: [String, Object], default: null },
  active: { type: Boolean, default: false },
  component: { type: Function, default: null },
});

const { resolvePermissions, resolveFeatureFlag } = useSidebarContext();

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Policy
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    as="li"
    class="py-0.5 ltr:pl-2 rtl:pr-2 rtl:mr-3 ltr:ml-3 relative text-[var(--rail-fg)] dark:text-white/70 child-item before:bg-[var(--rail-line-strong)] dark:before:bg-white/20 after:bg-transparent after:border-[var(--rail-line-strong)] dark:after:border-white/20 before:left-0 rtl:before:right-0 min-w-0"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      :title="label"
      class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg transition-colors group min-w-0
        hover:bg-gradient-to-r from-transparent via-[var(--rail-hover)] to-[var(--rail-hover)]
        dark:via-white/5 dark:to-white/5"
      :class="{
        'text-[var(--rail-active-text)] dark:text-white bg-[var(--rail-active-bg)] dark:bg-white/10 ring-1 ring-[var(--rail-active-ring)] dark:ring-white/0 active':
          active,
      }"
    >
      <component
        :is="component"
        v-if="shouldRenderComponent"
        :label
        :icon
        :active
      />
      <template v-else>
        <span v-if="icon" class="size-4 grid place-content-center rounded-full">
          <Icon :icon="icon" class="size-4 inline-block" />
        </span>
        <div class="flex-1 truncate min-w-0 text-xs">{{ label }}</div>
      </template>
    </component>
  </Policy>
</template>
