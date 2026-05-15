<!--
  ContactPanel.vue  —  orchestrator del sidebar derecho.
  Drop-in para: app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue

  Cambios vs. la versión actual:
  ─ ContactInfo se colapsa por defecto (sólo nombre + WhatsApp/LinkedIn visibles).
  ─ CustomAttributes recibe la whitelist + las constantes PIN/HIDDEN como props
    (la lógica de fetch/dispatch sigue acá y en CustomAttributes.vue).
  ─ El layout queda en flex-col 100% para que el bloque de tags/files al pie
    quede pegado y los atributos scrolleen en el medio.
-->
<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';

import ContactInfo from './contact/ContactInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import ConversationActions from './ConversationAction.vue';
import ConversationInfo from './ConversationInfo.vue';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  onToggle: { type: Function, default: () => {} },
});

defineEmits(['close']);

const store = useStore();

// ── Whitelist explícita de atributos visibles en este sidebar.
//    Mantener el orden — define el orden cuando NO hay grupo asignado.
const allowedAttributeKeys = [
  'como_continua',
  'origen',
  'tecnologia_principal',
  'respondio_por',
  'puesto_actual',
  'posicion_propuesta',
  'pais',
  'motivo_desestimacion',
  'rem_local_ars',
  'rem_usd',
  'respuestas_screening',
  'generar_informe',
];

// ── Pinned: siempre arriba en este orden, no participan del grouping.
const pinnedAttributeKeys = ['como_continua', 'origen', 'tecnologia_principal'];

// ── Ocultos: nunca se muestran ni se permiten reordenar.
const hiddenAttributeKeys = ['airtable_record_id', 'supabase_id'];

// ── Grouping para Variant B (secciones plegables). El orden de las claves
//    define el orden de las secciones. Atributos sin grupo caen en "otros".
const attributeGroups = [
  { id: 'trayectoria',  keys: ['puesto_actual', 'posicion_propuesta', 'pais', 'respondio_por'] },
  { id: 'compensacion', keys: ['rem_local_ars', 'rem_usd'] },
  { id: 'screening',    keys: ['respuestas_screening'] },
  { id: 'estado',       keys: ['motivo_desestimacion', 'generar_informe'] },
];

// ── Store bindings (idénticos a la versión anterior).
const currentChat   = useMapGetter('getSelectedChat');
const contact       = computed(() => store.getters['contacts/getContact'](currentChat.value?.meta?.sender?.id));
const customAttrs   = useMapGetter('attributes/getAttributes');
const uiFlags       = useMapGetter('contacts/getUIFlags');

// ── Fetch SOLO acá; los hijos quedan presentational.
onMounted(async () => {
  const contactId = currentChat.value?.meta?.sender?.id;
  if (!contactId) return;
  await Promise.all([
    store.dispatch('contacts/show', { id: contactId }),
    store.dispatch('attributes/get', 0),
  ]);
});

// Header colapsable controlado acá para que ContactInfo se mantenga tonto.
const headerExpanded = ref(false);
</script>

<template>
  <div class="flex flex-col h-full bg-n-background border-l border-n-slate-3">
    <!-- Top bar -->
    <header
      class="flex items-center justify-between px-4 h-12 shrink-0
             border-b border-n-slate-3 bg-n-solid-1"
    >
      <span class="text-sm font-medium text-n-slate-12 font-display">
        {{ $t('CONTACT.PANEL.TITLE') }}
      </span>
      <button
        class="size-6 rounded grid place-items-center text-n-slate-11
               hover:bg-n-slate-3 transition-colors"
        :aria-label="$t('CONTACT.PANEL.CLOSE')"
        @click="$emit('close')"
      >
        <span class="i-lucide-x size-4" />
      </button>
    </header>

    <!-- Collapsible contact card -->
    <ContactInfo
      v-if="contact"
      :contact="contact"
      :expanded="headerExpanded"
      @toggle="headerExpanded = !headerExpanded"
    />

    <!-- Scrollable middle: pinned strip + grouped attrs.
         CustomAttributes maneja su propio dispatch para updates. -->
    <div class="flex-1 min-h-0 overflow-y-auto">
      <CustomAttributes
        v-if="contact"
        :contact-id="contact.id"
        :conversation-id="conversationId"
        :all-attributes="customAttrs"
        :allowed-keys="allowedAttributeKeys"
        :pinned-keys="pinnedAttributeKeys"
        :hidden-keys="hiddenAttributeKeys"
        :groups="attributeGroups"
        :loading="uiFlags.isFetchingItem"
      />

      <ConversationInfo
        v-if="currentChat?.meta"
        :conversation-attributes="currentChat.meta"
        :contact="contact"
      />

      <ConversationActions
        v-if="currentChat"
        :conversation-id="conversationId"
      />
    </div>
  </div>
</template>
