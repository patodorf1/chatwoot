<!--
  CustomAttributes.vue  —  pinned status strip + grupos plegables.
  Drop-in para: app/javascript/dashboard/.../customAttributes/CustomAttributes.vue

  Convenciones del fork respetadas:
  ─ PINNED_ATTRIBUTES y HIDDEN_ATTRIBUTES viven acá como constantes locales
    (también recibidas como props para que ContactPanel.vue pueda overridear).
  ─ allowedAttributeKeys whitelist en ContactPanel.vue, recibido vía prop.
  ─ Toda la lógica de dispatch para updates queda en este componente
    (los CustomAttribute hijos sólo emiten `update`/`delete`).
  ─ vuedraggable se mantiene — ahora un dragger por grupo. Lo Pinned no es
    draggable (orden fijo por contrato del fork).
-->
<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';

import CustomAttributeRow from 'dashboard/components/CustomAttributeRow.vue';
import AttributeGroup from './AttributeGroup.vue';

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  conversationId: { type: [Number, String], required: true },
  allAttributes: { type: Array, required: true },
  allowedKeys: { type: Array, default: () => [] },
  pinnedKeys: { type: Array, default: () => ['como_continua', 'origen', 'tecnologia_principal'] },
  hiddenKeys: { type: Array, default: () => ['airtable_record_id', 'supabase_id'] },
  groups: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
});

const store = useStore();
const { t } = useI18n();

// ── Helpers ───────────────────────────────────────────────────────────────
const isAllowed = (key) =>
  props.allowedKeys.length === 0 || props.allowedKeys.includes(key);
const isHidden  = (key) => props.hiddenKeys.includes(key);
const isPinned  = (key) => props.pinnedKeys.includes(key);

// Para cada atributo, devolvemos { definition, value }. La definición viene
// del store (custom_attribute_definitions). El valor del propio contacto.
const contactAttrs = computed(() =>
  store.getters['contacts/getContact'](props.contactId)?.custom_attributes || {}
);
const conversationAttrs = computed(() =>
  store.getters['getSelectedChat']?.custom_attributes || {}
);

const decorate = (def) => ({
  key: def.attribute_key,
  definition: def,
  value: contactAttrs.value[def.attribute_key] ?? conversationAttrs.value[def.attribute_key],
});

// Visible attributes only (whitelist + not hidden).
const visibleAttrs = computed(() =>
  props.allAttributes
    .filter((d) => !isHidden(d.attribute_key) && isAllowed(d.attribute_key))
);

// Pinned in the order declared in pinnedKeys.
const pinnedAttrs = computed(() =>
  props.pinnedKeys
    .map((key) => visibleAttrs.value.find((d) => d.attribute_key === key))
    .filter(Boolean)
    .map(decorate)
);

// Group buckets respetando el orden declarado en props.groups; las claves no
// asignadas caen en "otros" al final.
const groupedAttrs = computed(() => {
  const claimed = new Set(props.pinnedKeys);
  const buckets = props.groups.map((g) => ({ id: g.id, items: [] }));

  props.groups.forEach((g, i) => {
    g.keys.forEach((key) => {
      if (claimed.has(key)) return;
      const def = visibleAttrs.value.find((d) => d.attribute_key === key);
      if (!def) return;
      buckets[i].items.push(decorate(def));
      claimed.add(key);
    });
  });

  const others = visibleAttrs.value
    .filter((d) => !claimed.has(d.attribute_key))
    .map(decorate);
  if (others.length) buckets.push({ id: 'otros', items: others });

  return buckets.filter((b) => b.items.length > 0);
});

// ── Updates (todo el dispatch vive acá) ───────────────────────────────────
const updateAttribute = async (def, newValue) => {
  const payload = {
    [def.attribute_key]: newValue,
  };
  if (def.attribute_model === 'conversation_attribute') {
    await store.dispatch('updateCustomAttributes', {
      conversationId: props.conversationId,
      customAttributes: { ...conversationAttrs.value, ...payload },
    });
  } else {
    await store.dispatch('contacts/update', {
      id: props.contactId,
      custom_attributes: { ...contactAttrs.value, ...payload },
    });
  }
};

const deleteAttribute = async (def) => {
  if (!window.confirm(t('ATTRIBUTES_MGMT.CONFIRM_DELETE'))) return;
  if (def.attribute_model === 'conversation_attribute') {
    const next = { ...conversationAttrs.value };
    delete next[def.attribute_key];
    await store.dispatch('updateCustomAttributes', {
      conversationId: props.conversationId,
      customAttributes: next,
    });
  } else {
    const next = { ...contactAttrs.value };
    delete next[def.attribute_key];
    await store.dispatch('contacts/update', {
      id: props.contactId,
      custom_attributes: next,
    });
  }
};

// Reorder dentro de un grupo. Persiste localmente — el backend no maneja
// orden de custom attributes; lo guardamos en localStorage por contacto.
const onReorder = (groupId, newList) => {
  const key = `wri.attrOrder.${props.contactId}.${groupId}`;
  localStorage.setItem(
    key,
    JSON.stringify(newList.map((x) => x.definition.attribute_key))
  );
};

// ── UI state ──────────────────────────────────────────────────────────────
const expandedGroups = ref(new Set());
const toggleGroup = (id) => {
  if (expandedGroups.value.has(id)) expandedGroups.value.delete(id);
  else expandedGroups.value.add(id);
  expandedGroups.value = new Set(expandedGroups.value);
};
</script>

<template>
  <div class="flex flex-col">
    <!-- ─── Pinned status strip ─────────────────────────────────────────── -->
    <section
      v-if="pinnedAttrs.length"
      class="px-4 py-3 bg-n-slate-12 text-white"
    >
      <p
        class="text-[10px] font-semibold tracking-[0.1em] uppercase
               text-n-teal-9 mb-2 font-display"
      >
        {{ t('ATTRIBUTES_MGMT.PINNED_HEADING') }}
      </p>

      <div class="flex flex-col gap-1.5">
        <CustomAttributeRow
          v-for="attr in pinnedAttrs"
          :key="attr.definition.attribute_key"
          :definition="attr.definition"
          :value="attr.value"
          variant="pinned"
          @update="(v) => updateAttribute(attr.definition, v)"
          @delete="deleteAttribute(attr.definition)"
        />
      </div>
    </section>

    <!-- ─── Collapsible groups ──────────────────────────────────────────── -->
    <AttributeGroup
      v-for="group in groupedAttrs"
      :key="group.id"
      :title="t(`ATTRIBUTES_MGMT.GROUPS.${group.id.toUpperCase()}`)"
      :filled-count="group.items.filter((a) => a.value !== null && a.value !== '' && a.value !== undefined && a.value !== false).length"
      :total-count="group.items.length"
      :collapsed="!expandedGroups.has(group.id)"
      @toggle="toggleGroup(group.id)"
    >
      <draggable
        :model-value="group.items"
        item-key="key"
        handle=".js-attr-drag"
        :animation="150"
        ghost-class="opacity-40"
        @update:model-value="(list) => onReorder(group.id, list)"
      >
        <template #item="{ element }">
          <CustomAttributeRow
            :definition="element.definition"
            :value="element.value"
            variant="row"
            @update="(v) => updateAttribute(element.definition, v)"
            @delete="deleteAttribute(element.definition)"
          />
        </template>
      </draggable>
    </AttributeGroup>

    <p
      v-if="!loading && pinnedAttrs.length === 0 && groupedAttrs.length === 0"
      class="px-4 py-6 text-xs text-n-slate-10 text-center"
    >
      {{ t('ATTRIBUTES_MGMT.EMPTY') }}
    </p>
  </div>
</template>
