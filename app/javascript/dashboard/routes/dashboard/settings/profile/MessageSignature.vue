<script setup>
import { ref, watch } from 'vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  messageSignature: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['updateSignature']);
const signature = ref(props.messageSignature);
const isHtmlMode = ref(false);

watch(
  () => props.messageSignature ?? '',
  newValue => {
    signature.value = newValue;
  }
);

const updateSignature = () => {
  emit('updateSignature', signature.value);
};

const toggleMode = () => {
  isHtmlMode.value = !isHtmlMode.value;
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="updateSignature()">
    <div class="flex items-center justify-between">
      <button
        type="button"
        class="text-xs text-n-slate-11 hover:text-n-slate-12 underline"
        @click="toggleMode"
      >
        {{ isHtmlMode ? 'Visual editor' : 'Edit HTML' }}
      </button>
    </div>
    <textarea
      v-if="isHtmlMode"
      v-model="signature"
      class="w-full h-[12rem] font-mono text-xs p-3 rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 resize-y"
      placeholder="<p>Your HTML signature here...</p>"
    />
    <WootMessageEditor
      v-else
      id="message-signature-input"
      v-model="signature"
      class="message-editor h-[10rem] !px-3"
      is-format-mode
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
      channel-type="Context::MessageSignature"
      :enable-suggestions="false"
      show-image-resize-toolbar
    />
    <div>
      <NextButton
        type="submit"
        :label="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT')"
      />
    </div>
  </form>
</template>
