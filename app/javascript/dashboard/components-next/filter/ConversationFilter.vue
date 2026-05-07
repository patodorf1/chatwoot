<script setup>
import { useTemplateRef, onBeforeUnmount, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useConversationFilterContext } from './provider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Button from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import ConditionRow from './ConditionRow.vue';

const props = defineProps({
  isFolderView: {
    type: Boolean,
    default: false,
  },
  folderName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['applyFilter', 'updateFolder', 'close']);
const { filterTypes } = useConversationFilterContext();

const filters = defineModel({
  type: Array,
  default: [],
});
const folderNameLocal = ref(props.folderName);

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
};

const { t } = useI18n();
const store = useStore();

const resetFilter = () => {
  filters.value = [{ ...DEFAULT_FILTER }];
};

const removeFilter = index => {
  if (filters.value.length === 1) {
    resetFilter();
  } else {
    filters.value.splice(index, 1);
  }
};

const addFilter = () => {
  filters.value.push({ ...DEFAULT_FILTER });
};

const conditionsRef = useTemplateRef('conditionsRef');

const isConditionsValid = () => {
  return conditionsRef.value.every(condition => condition.validate());
};

const updateSavedCustomViews = () => {
  if (isConditionsValid()) {
    emit('updateFolder', filters.value, folderNameLocal.value);
  }
};

function validateAndSubmit() {
  if (!isConditionsValid()) {
    return;
  }

  store.dispatch(
    'setConversationFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
  useTrack(CONVERSATION_EVENTS.APPLY_FILTER, {
    appliedFilters: filters.value.map(filter => ({
      key: filter.attributeKey,
      operator: filter.filterOperator,
      queryOperator: filter.queryOperator,
    })),
  });
}

const filterModalHeaderTitle = computed(() => {
  return !props.isFolderView
    ? t('FILTER.TITLE')
    : t('FILTER.EDIT_CUSTOM_FILTER');
});

onBeforeUnmount(() => emit('close'));
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleConversationFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl lg:w-[750px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-3 grid gap-3"
  >
    <h3 class="text-[10px] font-medium leading-4 text-n-slate-12">
      {{ filterModalHeaderTitle }}
    </h3>
    <div v-if="props.isFolderView">
      <div class="border-b border-n-weak pb-3">
        <Input
          v-model="folderNameLocal"
          :label="t('FILTER.FOLDER_LABEL')"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </div>
    </div>
    <ul class="grid gap-2 list-none">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
          ref="conditionsRef"
          :key="`filter-${filter.attributeKey}-0`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          :filter-types="filterTypes"
          :show-query-operator="false"
          @remove="removeFilter(index)"
        />
        <ConditionRow
          v-else
          :key="`filter-${filter.attributeKey}-${index}`"
          ref="conditionsRef"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:query-operator="filters[index - 1].queryOperator"
          v-model:values="filter.values"
          show-query-operator
          :filter-types="filterTypes"
          @remove="removeFilter(index)"
        />
      </template>
    </ul>
    <div class="flex gap-1.5 justify-between items-center">
      <Button
        xs
        ghost
        blue
        icon="i-lucide-plus"
        :title="$t('FILTER.ADD_NEW_FILTER')"
        @click="addFilter"
      />
      <div class="flex gap-1.5">
        <Button
          xs
          faded
          slate
          icon="i-lucide-eraser"
          :title="t('FILTER.CLEAR_BUTTON_LABEL')"
          @click="resetFilter"
        />
        <Button
          v-if="isFolderView"
          xs
          solid
          blue
          icon="i-lucide-check"
          :title="t('FILTER.UPDATE_BUTTON_LABEL')"
          :disabled="!folderNameLocal"
          @click="updateSavedCustomViews"
        />
        <Button
          v-else
          xs
          solid
          blue
          icon="i-lucide-check"
          :title="t('FILTER.SUBMIT_BUTTON_LABEL')"
          @click="validateAndSubmit"
        />
      </div>
    </div>
  </div>
</template>
