<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

import ContactCustomAttributeItem from 'dashboard/components-next/Contacts/ContactsSidebar/ContactCustomAttributeItem.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();

const { uiSettings } = useUISettings();

const searchQuery = ref('');

const contactAttributes = useMapGetter('attributes/getContactAttributes') || [];

const hasContactAttributes = computed(
  () => contactAttributes.value?.length > 0
);

// Internal attributes that should not be visible or editable in the UI
const HIDDEN_ATTRIBUTES = ['airtable_record_id', 'supabase_id'];

// Default attribute order when user has no custom UI ordering set.
// Place pipeline-critical attributes at the top of the contact sidebar.
const DEFAULT_ATTRIBUTE_ORDER = [
  'como_continua',
  'origen',
  'tecnologia_principal',
];

const processContactAttributes = (
  attributes,
  customAttributes,
  filterCondition
) => {
  if (!attributes.length || !customAttributes) {
    return [];
  }

  return attributes.reduce((result, attribute) => {
    const { attributeKey } = attribute;
    if (HIDDEN_ATTRIBUTES.includes(attributeKey)) return result;
    const meetsCondition = filterCondition(attributeKey, customAttributes);

    if (meetsCondition) {
      result.push({
        ...attribute,
        value: customAttributes[attributeKey] ?? '',
      });
    }

    return result;
  }, []);
};

const sortAttributesOrder = computed(
  () =>
    uiSettings.value.conversation_elements_order_conversation_contact_panel ??
    []
);

const sortByUISettings = attributes => {
  // Pipeline-critical attributes (Cómo continúa?, Origen, Tecnología Principal)
  // ALWAYS come first, in the order defined in DEFAULT_ATTRIBUTE_ORDER, even
  // when the user has dragged attributes into a custom order — keeps those
  // recruiter-essential fields anchored at the top of the sidebar.
  const userOrder = sortAttributesOrder.value?.length
    ? sortAttributesOrder.value.filter(k => !DEFAULT_ATTRIBUTE_ORDER.includes(k))
    : [];

  const combinedOrder = [...DEFAULT_ATTRIBUTE_ORDER, ...userOrder];
  const orderMap = new Map(combinedOrder.map((key, index) => [key, index]));

  // Sort attributes based on their position in combined order.
  return [...attributes].sort((a, b) => {
    const aPos = orderMap.get(a.attributeKey) ?? Infinity;
    const bPos = orderMap.get(b.attributeKey) ?? Infinity;
    return aPos - bPos;
  });
};

// Attributes that should always be visible in the "used" section, even
// when the contact hasn't initialized them yet — keeps the pipeline-critical
// fields (Cómo continúa?, Origen, Tecnología) discoverable.
const ALWAYS_VISIBLE_ATTRIBUTES = new Set(DEFAULT_ATTRIBUTE_ORDER);

const usedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) => key in custom || ALWAYS_VISIBLE_ATTRIBUTES.has(key)
  );

  return sortByUISettings(attributes);
});

const unusedAttributes = computed(() => {
  const attributes = processContactAttributes(
    contactAttributes.value,
    props.selectedContact?.customAttributes,
    (key, custom) =>
      !(key in custom) && !ALWAYS_VISIBLE_ATTRIBUTES.has(key)
  );

  return sortByUISettings(attributes);
});

const filteredUnusedAttributes = computed(() => {
  return unusedAttributes.value?.filter(attribute =>
    attribute.attributeDisplayName
      .toLowerCase()
      .includes(searchQuery.value.toLowerCase())
  );
});

const unusedAttributesCount = computed(() => unusedAttributes.value?.length);
const hasNoUnusedAttributes = computed(() => unusedAttributesCount.value === 0);
const hasNoUsedAttributes = computed(() => usedAttributes.value.length === 0);
const showUnused = ref(false);
</script>

<template>
  <div v-if="hasContactAttributes" class="flex flex-col gap-3 px-6 py-4">
    <div v-if="!hasNoUsedAttributes" class="flex flex-col gap-1">
      <ContactCustomAttributeItem
        v-for="attribute in usedAttributes"
        :key="attribute.id"
        is-editing-view
        :attribute="attribute"
      />
    </div>
    <button
      v-if="!hasNoUnusedAttributes"
      class="flex items-center gap-2 py-1 text-xs font-medium text-n-slate-10 hover:text-n-slate-12 transition-colors"
      @click="showUnused = !showUnused"
    >
      <span
        class="size-3.5 transition-transform"
        :class="showUnused ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
      />
      {{
        t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.UNUSED_ATTRIBUTES', {
          count: unusedAttributesCount,
        })
      }}
    </button>
    <div v-if="showUnused" class="flex flex-col gap-2">
      <div class="relative">
        <span class="absolute i-lucide-search size-3.5 top-2 left-3" />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="
            t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.SEARCH_PLACEHOLDER')
          "
          class="w-full h-8 py-2 pl-10 pr-2 text-sm reset-base outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        />
      </div>
      <div
        v-if="filteredUnusedAttributes.length === 0"
        class="flex items-center justify-start h-8"
      >
        <p class="text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.NO_ATTRIBUTES') }}
        </p>
      </div>
      <div v-else class="flex flex-col gap-1">
        <ContactCustomAttributeItem
          v-for="attribute in filteredUnusedAttributes"
          :key="attribute.id"
          :attribute="attribute"
        />
      </div>
    </div>
  </div>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.ATTRIBUTES.EMPTY_STATE') }}
  </p>
</template>
