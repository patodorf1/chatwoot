<script setup>
import { computed, ref } from 'vue';
import Auth from 'dashboard/api/auth';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SidebarProfileMenuStatus from './SidebarProfileMenuStatus.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import {
  DropdownContainer,
  DropdownBody,
  DropdownSeparator,
  DropdownItem,
} from 'next/dropdown-menu/base';
import CustomBrandPolicyWrapper from '../../components/CustomBrandPolicyWrapper.vue';

defineProps({
  isCollapsed: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'openKeyShortcutModal']);

defineOptions({
  inheritAttrs: false,
});

const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const currentUser = useMapGetter('getCurrentUser');
const currentUserAvailability = useMapGetter('getCurrentUserAvailability');
const accountId = useMapGetter('getCurrentAccountId');
const globalConfig = useMapGetter('globalConfig/get');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showSettingsSubmenu = ref(false);

const showChatSupport = computed(() => {
  return (
    isFeatureEnabledonAccount.value(
      accountId.value,
      FEATURE_FLAGS.CONTACT_CHATWOOT_SUPPORT_TEAM
    ) && globalConfig.value.chatwootInboxToken
  );
});

const settingsItems = computed(() => [
  {
    label: t('SIDEBAR.ACCOUNT_SETTINGS'),
    icon: 'i-lucide-briefcase',
    link: accountScopedRoute('general_settings_index'),
  },
  {
    label: t('SIDEBAR.AGENTS'),
    icon: 'i-lucide-square-user',
    link: accountScopedRoute('agent_list'),
  },
  {
    label: t('SIDEBAR.TEAMS'),
    icon: 'i-lucide-users',
    link: accountScopedRoute('settings_teams_list'),
  },
  {
    label: t('SIDEBAR.INBOXES'),
    icon: 'i-lucide-inbox',
    link: accountScopedRoute('settings_inbox_list'),
  },
  {
    label: t('SIDEBAR.LABELS'),
    icon: 'i-lucide-tags',
    link: accountScopedRoute('labels_list'),
  },
  {
    label: t('SIDEBAR.CUSTOM_ATTRIBUTES'),
    icon: 'i-lucide-code',
    link: accountScopedRoute('attributes_list'),
  },
  {
    label: t('SIDEBAR.AUTOMATION'),
    icon: 'i-lucide-repeat',
    link: accountScopedRoute('automation_list'),
  },
  {
    label: t('SIDEBAR.CANNED_RESPONSES'),
    icon: 'i-lucide-message-square-quote',
    link: accountScopedRoute('canned_list'),
  },
  {
    label: t('SIDEBAR.INTEGRATIONS'),
    icon: 'i-lucide-blocks',
    link: accountScopedRoute('settings_applications'),
  },
]);

const menuItems = computed(() => {
  return [
    {
      show: showChatSupport.value,
      showOnCustomBrandedInstance: false,
      label: t('SIDEBAR_ITEMS.CONTACT_SUPPORT'),
      icon: 'i-lucide-life-buoy',
      click: () => {
        window.$chatwoot.toggle();
      },
    },
    {
      show: true,
      showOnCustomBrandedInstance: true,
      label: t('SIDEBAR_ITEMS.KEYBOARD_SHORTCUTS'),
      icon: 'i-lucide-keyboard',
      click: () => {
        emit('openKeyShortcutModal');
      },
    },
    {
      show: true,
      showOnCustomBrandedInstance: true,
      label: t('SIDEBAR_ITEMS.PROFILE_SETTINGS'),
      icon: 'i-lucide-user-pen',
      link: { name: 'profile_settings_index' },
    },
    {
      show: true,
      showOnCustomBrandedInstance: true,
      label: t('SIDEBAR_ITEMS.APPEARANCE'),
      icon: 'i-lucide-palette',
      click: () => {
        const ninja = document.querySelector('ninja-keys');
        ninja.open({ parent: 'appearance_settings' });
      },
    },
    {
      show: currentUser.value.type === 'SuperAdmin',
      showOnCustomBrandedInstance: true,
      label: t('SIDEBAR_ITEMS.SUPER_ADMIN_CONSOLE'),
      icon: 'i-lucide-castle',
      link: '/super_admin',
      nativeLink: true,
      target: '_blank',
    },
    {
      show: true,
      showOnCustomBrandedInstance: true,
      label: t('SIDEBAR_ITEMS.LOGOUT'),
      icon: 'i-lucide-power',
      click: Auth.logout,
    },
  ];
});

const allowedMenuItems = computed(() => {
  return menuItems.value.filter(item => item.show);
});
</script>

<template>
  <DropdownContainer
    class="relative min-w-0"
    :class="isCollapsed ? 'w-auto' : 'w-full'"
    @close="emit('close')"
  >
    <template #trigger="{ toggle, isOpen }">
      <button
        class="flex gap-2 items-center p-1 text-left rounded-lg cursor-pointer hover:bg-[#34353f]/10"
        :class="[
          { 'bg-[#34353f]/10': isOpen },
          isCollapsed ? 'justify-center' : 'w-full',
        ]"
        :title="isCollapsed ? currentUser.available_name : undefined"
        @click="toggle"
      >
        <Avatar
          :size="32"
          :name="currentUser.available_name"
          :src="currentUser.avatar_url"
          :status="currentUserAvailability"
          class="flex-shrink-0"
          rounded-full
        />
        <div v-if="!isCollapsed" class="min-w-0">
          <div class="text-sm font-medium leading-4 truncate text-[#34353f]">
            {{ currentUser.available_name }}
          </div>
          <div class="text-xs truncate text-[#6a6779]">
            {{ currentUser.email }}
          </div>
        </div>
      </button>
    </template>
    <DropdownBody class="bottom-12 z-50 mb-2 w-80 ltr:left-0 rtl:right-0">
      <template v-if="showSettingsSubmenu">
        <li class="n-dropdown-item">
          <button
            class="flex items-center gap-3 p-2 text-sm text-n-slate-12 w-full rounded-lg hover:bg-n-alpha-2"
            @click="showSettingsSubmenu = false"
          >
            <Icon icon="i-lucide-arrow-left" class="size-4 text-n-slate-11" />
            {{ t('SIDEBAR.SETTINGS') }}
          </button>
        </li>
        <DropdownSeparator />
        <DropdownItem
          v-for="item in settingsItems"
          :key="item.label"
          v-bind="item"
        />
      </template>
      <template v-else>
        <SidebarProfileMenuStatus />
        <DropdownSeparator />
        <template v-for="item in allowedMenuItems" :key="item.label">
          <CustomBrandPolicyWrapper
            :show-on-custom-branded-instance="item.showOnCustomBrandedInstance"
          >
            <DropdownItem v-if="item.show" v-bind="item" />
          </CustomBrandPolicyWrapper>
        </template>
        <DropdownSeparator />
        <li class="n-dropdown-item">
          <button
            class="flex items-center gap-3 p-2 text-sm text-n-slate-12 w-full rounded-lg hover:bg-n-alpha-2"
            @click.stop="showSettingsSubmenu = true"
          >
            <Icon icon="i-lucide-settings" class="size-4 text-n-slate-11" />
            {{ t('SIDEBAR.SETTINGS') }}
          </button>
        </li>
      </template>
    </DropdownBody>
  </DropdownContainer>
</template>
