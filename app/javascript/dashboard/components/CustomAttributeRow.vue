<!--
  CustomAttribute.vue  —  fila individual de atributo.
  Drop-in para: app/javascript/dashboard/.../customAttributes/CustomAttribute.vue

  Comportamiento:
  ─ Presentational. NO dispatchea — sólo emite `update` y `delete`.
  ─ Click sobre el valor abre el editor inline (dropdown / input / checkbox).
  ─ Atributos vacíos muestran un placeholder "+ Agregar" gris.
  ─ Drag handle (`.js-attr-drag`) sólo en hover, no rompe vuedraggable.
  ─ Dos variantes visuales: `pinned` (strip oscuro) y `row` (default).
-->
<script setup>
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { onClickOutside } from '@vueuse/core';

const props = defineProps({
  definition: { type: Object, required: true },
  value: { type: [String, Number, Boolean, Array, null], default: null },
  variant: { type: String, default: 'row', validator: (v) => ['row', 'pinned'].includes(v) },
});

const emit = defineEmits(['update', 'delete']);

const { t } = useI18n();

// ── State ────────────────────────────────────────────────────────────────
const editing = ref(false);
const draft   = ref(null);
const rowEl   = ref(null);
const inputEl = ref(null);

const isEmpty = computed(() => {
  const v = props.value;
  return v === null || v === undefined || v === '' || v === false;
});

const displayValue = computed(() => {
  if (isEmpty.value) return null;
  const v = props.value;
  if (props.definition.attribute_display_type === 'checkbox') return v ? t('COMMON.YES') : t('COMMON.NO');
  if (props.definition.attribute_display_type === 'date' && typeof v === 'string') {
    return new Date(v).toLocaleDateString();
  }
  return String(v);
});

// Pinned tone: si la key tiene una opción "Desestimado" / "Rechazado" y está
// elegida, usamos pink. Si es un estado positivo conocido, aqua. Si nada, neutro.
const negativeWords = ['desestimado', 'rechazado', 'no'];
const positiveWords = ['contratado', 'aceptado', 'activo', 'en proceso'];
const tone = computed(() => {
  if (isEmpty.value) return 'neutral';
  const v = String(props.value).toLowerCase();
  if (negativeWords.some((w) => v.includes(w))) return 'danger';
  if (positiveWords.some((w) => v.includes(w))) return 'success';
  return 'info';
});

const dotColor = computed(() => ({
  neutral: 'bg-n-slate-7',
  info:    'bg-n-teal-9',
  success: 'bg-n-teal-9',
  danger:  'bg-n-ruby-9',
})[tone.value]);

// ── Edit lifecycle ───────────────────────────────────────────────────────
const startEdit = async () => {
  draft.value = props.value;
  editing.value = true;
  await nextTick();
  inputEl.value?.focus?.();
};

const cancelEdit = () => {
  editing.value = false;
  draft.value = null;
};

const commitEdit = () => {
  if (draft.value === props.value) {
    cancelEdit();
    return;
  }
  emit('update', draft.value);
  editing.value = false;
};

onClickOutside(rowEl, () => {
  if (editing.value) commitEdit();
});

// Para checkbox no usamos editor inline — el click toggles directo.
const toggleCheckbox = () => emit('update', !props.value);
</script>

<template>
  <!-- ═════════════ PINNED variant (dark strip) ═══════════════════════════ -->
  <div
    v-if="variant === 'pinned'"
    ref="rowEl"
    class="relative"
  >
    <button
      type="button"
      class="w-full flex items-center justify-between gap-2 px-1 -mx-1 py-0.5
             rounded hover:bg-white/5 group"
      @click="startEdit"
    >
      <span class="flex items-center gap-2 min-w-0">
        <span class="size-1.5 rounded-full shrink-0" :class="dotColor" />
        <span class="text-[11px] text-white/60 font-ui shrink-0">
          {{ definition.attribute_display_name }}
        </span>
      </span>
      <span class="flex items-center gap-1 min-w-0">
        <span
          class="text-xs font-semibold font-display truncate"
          :class="isEmpty ? 'text-white/40 italic font-normal' : 'text-white'"
        >
          {{ displayValue || t('ATTRIBUTES_MGMT.UNSET') }}
        </span>
        <span class="i-lucide-chevron-down size-2.5 text-white/40 group-hover:text-white shrink-0" />
      </span>
    </button>

    <!-- Edit popover -->
    <div
      v-if="editing"
      class="absolute z-30 right-0 top-full mt-1 w-[180px] rounded-md
             border border-n-slate-3 bg-n-background shadow-lg py-1"
    >
      <template v-if="definition.attribute_display_type === 'list'">
        <button
          v-for="opt in definition.attribute_values"
          :key="opt"
          type="button"
          class="w-full text-left px-3 py-1.5 text-xs font-display text-n-slate-12
                 hover:bg-n-slate-3"
          @click="emit('update', opt); editing = false"
        >{{ opt }}</button>
        <div class="border-t border-n-slate-3 mt-1 pt-1">
          <button
            type="button"
            class="w-full text-left px-3 py-1.5 text-xs text-n-slate-10 hover:bg-n-slate-3"
            @click="emit('update', null); editing = false"
          >{{ t('ATTRIBUTES_MGMT.CLEAR') }}</button>
        </div>
      </template>
      <input
        v-else
        ref="inputEl"
        v-model="draft"
        :type="definition.attribute_display_type === 'number' ? 'number' : 'text'"
        class="w-full px-3 py-1.5 text-xs font-display text-n-slate-12 bg-transparent
               outline-none placeholder:text-n-slate-9"
        :placeholder="t('ATTRIBUTES_MGMT.TYPE_VALUE')"
        @keydown.enter="commitEdit"
        @keydown.esc="cancelEdit"
      />
    </div>
  </div>

  <!-- ═════════════ ROW variant (default light list) ══════════════════════ -->
  <div
    v-else-if="definition.attribute_display_type === 'checkbox'"
    ref="rowEl"
    class="flex items-center justify-between gap-2 px-4 py-1.5
           hover:bg-n-slate-2 transition-colors group cursor-pointer"
    @click="toggleCheckbox"
  >
    <span class="inline-flex items-center gap-2 text-xs font-ui text-n-slate-12">
      <input
        type="checkbox"
        :checked="!!value"
        class="size-3.5 rounded border-n-slate-5 text-n-teal-9
               focus:ring-1 focus:ring-n-teal-9 cursor-pointer"
        @click.stop
        @change="(e) => emit('update', e.target.checked)"
      />
      {{ definition.attribute_display_name }}
    </span>
    <span class="flex items-center gap-2 shrink-0">
      <button
        type="button"
        class="js-attr-drag opacity-0 group-hover:opacity-100 cursor-grab text-n-slate-9
               active:cursor-grabbing"
        :aria-label="t('ATTRIBUTES_MGMT.DRAG')"
        @click.stop
      >
        <span class="i-lucide-grip-vertical size-3" />
      </button>
      <button
        type="button"
        class="opacity-0 group-hover:opacity-100 text-n-slate-9 hover:text-n-ruby-9"
        :aria-label="t('ATTRIBUTES_MGMT.ROW_DELETE')"
        @click.stop="emit('delete')"
      >
        <span class="i-lucide-trash-2 size-3" />
      </button>
    </span>
  </div>

  <div
    v-else
    ref="rowEl"
    class="flex flex-col gap-0.5 px-4 py-1.5
           hover:bg-n-slate-2 transition-colors group"
  >
    <span
      class="text-[10.5px] uppercase tracking-wide text-n-slate-10 leading-tight font-ui"
    >
      {{ definition.attribute_display_name }}
    </span>

    <div class="min-w-0 flex items-center gap-1">
      <!-- Editor -->
      <template v-if="editing">
        <!-- list → select -->
        <select
          v-if="definition.attribute_display_type === 'list'"
          ref="inputEl"
          :value="draft ?? ''"
          class="flex-1 min-w-0 text-xs font-display font-semibold text-n-slate-12
                 bg-n-background border border-n-slate-5 rounded px-1.5 py-1
                 outline-none focus:border-n-teal-9"
          @change="(e) => { draft = e.target.value || null; commitEdit(); }"
          @keydown.esc="cancelEdit"
        >
          <option value="">{{ t('ATTRIBUTES_MGMT.UNSET') }}</option>
          <option v-for="opt in definition.attribute_values" :key="opt" :value="opt">
            {{ opt }}
          </option>
        </select>

        <!-- date -->
        <input
          v-else-if="definition.attribute_display_type === 'date'"
          ref="inputEl"
          v-model="draft"
          type="date"
          class="flex-1 min-w-0 text-xs font-display font-semibold text-n-slate-12
                 bg-n-background border border-n-slate-5 rounded px-1.5 py-1 outline-none"
          @blur="commitEdit"
          @keydown.enter="commitEdit"
          @keydown.esc="cancelEdit"
        />

        <!-- text / number / link -->
        <input
          v-else
          ref="inputEl"
          v-model="draft"
          :type="definition.attribute_display_type === 'number' ? 'number' : 'text'"
          class="flex-1 min-w-0 text-xs font-display font-semibold text-n-slate-12
                 bg-n-background border border-n-slate-5 rounded px-1.5 py-1 outline-none"
          :placeholder="t('ATTRIBUTES_MGMT.TYPE_VALUE')"
          @keydown.enter="commitEdit"
          @keydown.esc="cancelEdit"
        />
      </template>

      <!-- Read mode -->
      <button
        v-else-if="isEmpty"
        type="button"
        class="inline-flex items-center gap-1 text-xs font-ui text-n-slate-9
               hover:text-n-slate-12 transition-colors"
        @click="startEdit"
      >
        <span class="i-lucide-plus size-2.5" />
        {{ t('ATTRIBUTES_MGMT.ADD_VALUE') }}
      </button>

      <button
        v-else
        type="button"
        class="text-xs font-display font-semibold text-n-slate-12 text-left
               leading-snug truncate hover:underline decoration-dotted underline-offset-2"
        :title="displayValue"
        @click="startEdit"
      >{{ displayValue }}</button>

      <span class="flex items-center gap-1 ml-auto shrink-0">
        <button
          type="button"
          class="js-attr-drag opacity-0 group-hover:opacity-100 cursor-grab text-n-slate-9
                 active:cursor-grabbing"
          :aria-label="t('ATTRIBUTES_MGMT.DRAG')"
        >
          <span class="i-lucide-grip-vertical size-3" />
        </button>
        <button
          type="button"
          class="opacity-0 group-hover:opacity-100 text-n-slate-9 hover:text-n-ruby-9"
          :aria-label="t('ATTRIBUTES_MGMT.ROW_DELETE')"
          @click="emit('delete')"
        >
          <span class="i-lucide-trash-2 size-3" />
        </button>
      </span>
    </div>
  </div>
</template>
