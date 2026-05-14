<!--
  ContactInfo.vue  —  header colapsable.
  Drop-in para: app/javascript/dashboard/routes/dashboard/conversation/ContactInfo.vue

  Comportamiento:
  ─ Colapsado por defecto: avatar + nombre + atajos a WhatsApp / Email / LinkedIn.
  ─ Expandido: añade líneas de email, teléfono, LinkedIn con copy-on-hover.
  ─ Sin <style>; solo Tailwind + tokens n-*.
-->
<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

const props = defineProps({
  contact: { type: Object, required: true },
  expanded: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle']);

const { t } = useI18n();

const linkedin = computed(() => {
  const social = props.contact.additional_attributes?.social_profiles || {};
  return social.linkedin || null;
});

const phone     = computed(() => props.contact.phone_number || null);
const email     = computed(() => props.contact.email || null);

const copyToClipboard = (value) => {
  if (!value) return;
  navigator.clipboard?.writeText(value);
};
</script>

<template>
  <section
    class="px-4 py-3 border-b border-n-slate-3 bg-n-background"
  >
    <div class="flex items-center gap-2.5">
      <Thumbnail
        :src="contact.thumbnail"
        :username="contact.name"
        size="36px"
        class="shrink-0"
      />

      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-1.5">
          <router-link
            :to="`/app/accounts/${contact.account_id}/contacts/${contact.id}`"
            class="font-display font-semibold text-sm text-n-slate-12 truncate
                   hover:underline decoration-dotted underline-offset-2"
          >
            {{ contact.name }}
          </router-link>
          <span class="i-lucide-external-link size-3 text-n-slate-10 shrink-0" />
        </div>

        <!-- Compact contact strip -->
        <div class="flex items-center gap-2 text-xs text-n-slate-11 mt-0.5">
          <a
            v-if="phone"
            :href="`https://wa.me/${phone.replace(/[^0-9]/g, '')}`"
            target="_blank"
            rel="noopener"
            class="inline-flex items-center gap-1 hover:text-n-slate-12 transition-colors"
          >
            <span class="i-lucide-phone size-3" />
            <span>{{ t('CONTACT.PANEL.WHATSAPP') }}</span>
          </a>
          <span v-if="phone && (email || linkedin)" class="text-n-slate-8">·</span>
          <a
            v-if="email"
            :href="`mailto:${email}`"
            class="inline-flex items-center gap-1 hover:text-n-slate-12 transition-colors min-w-0"
          >
            <span class="i-lucide-mail size-3" />
            <span class="truncate">{{ t('CONTACT.PANEL.EMAIL') }}</span>
          </a>
          <span v-if="email && linkedin" class="text-n-slate-8">·</span>
          <a
            v-if="linkedin"
            :href="linkedin"
            target="_blank"
            rel="noopener"
            class="inline-flex items-center gap-1 hover:text-n-slate-12 transition-colors"
          >
            <span class="i-lucide-linkedin size-3" />
            <span>LinkedIn</span>
          </a>
        </div>
      </div>

      <button
        class="size-6 grid place-items-center rounded text-n-slate-11
               hover:bg-n-slate-3 transition-colors"
        :aria-label="t(expanded ? 'CONTACT.PANEL.COLLAPSE' : 'CONTACT.PANEL.EXPAND')"
        :aria-expanded="expanded"
        @click="emit('toggle')"
      >
        <span
          class="size-3 transition-transform"
          :class="expanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        />
      </button>
    </div>

    <!-- Expanded details -->
    <div
      v-if="expanded"
      class="mt-3 grid grid-cols-[16px_1fr_auto] gap-x-2 gap-y-1.5 text-xs"
    >
      <span class="i-lucide-mail size-3 text-n-slate-10 mt-0.5" />
      <span v-if="email" class="text-n-slate-12 truncate">{{ email }}</span>
      <span v-else class="text-n-slate-10 italic">{{ t('CONTACT.PANEL.NO_EMAIL') }}</span>
      <button
        v-if="email"
        class="text-n-slate-10 hover:text-n-slate-12"
        :aria-label="t('CONTACT.PANEL.COPY')"
        @click="copyToClipboard(email)"
      >
        <span class="i-lucide-copy size-3" />
      </button>
      <span v-else />

      <template v-if="phone">
        <span class="i-lucide-phone size-3 text-n-slate-10 mt-0.5" />
        <span class="text-n-slate-12 truncate">{{ phone }}</span>
        <button
          class="text-n-slate-10 hover:text-n-slate-12"
          :aria-label="t('CONTACT.PANEL.COPY')"
          @click="copyToClipboard(phone)"
        >
          <span class="i-lucide-copy size-3" />
        </button>
      </template>

      <template v-if="linkedin">
        <span class="i-lucide-linkedin size-3 text-n-slate-10 mt-0.5" />
        <a
          :href="linkedin"
          target="_blank"
          rel="noopener"
          class="text-n-slate-12 truncate hover:underline decoration-dotted underline-offset-2"
        >{{ linkedin.replace(/^https?:\/\//, '') }}</a>
        <span />
      </template>
    </div>
  </section>
</template>
