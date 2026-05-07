import { computed, h } from 'vue';
import { useI18n } from 'vue-i18n';
import { useOperators } from './operators';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useChannelIcon } from 'next/icon/provider';
import {
  buildAttributesFilterTypes,
  CONVERSATION_ATTRIBUTES,
} from './helper/filterHelper';
import { RECRUITMENT_STATUSES } from 'dashboard/helper/recruitmentStatus';

/**
 * @typedef {Object} FilterOption
 * @property {string|number} id
 * @property {string} name
 * @property {import('vue').VNode} [icon]
 */

/**
 * @typedef {Object} FilterOperator
 * @property {string} value
 * @property {string} label
 * @property {string} icon
 * @property {boolean} hasInput
 */

/**
 * @typedef {Object} FilterType
 * @property {string} attributeKey - The attribute key
 * @property {string} value - This is a proxy for the attribute key used in FilterSelect
 * @property {string} attributeName - The attribute name used to display on the UI
 * @property {string} label - This is a proxy for the attribute name used in FilterSelect
 * @property {'multiSelect'|'searchSelect'|'plainText'|'date'|'booleanSelect'} inputType - The input type for the attribute
 * @property {FilterOption[]} [options] - The options available for the attribute if it is a multiSelect or singleSelect type
 * @property {'text'|'number'} dataType
 * @property {FilterOperator[]} filterOperators - The operators available for the attribute
 * @property {'standard'|'additional'|'customAttributes'} attributeModel
 */

/**
 * @typedef {Object} FilterGroup
 * @property {string} name
 * @property {FilterType[]} attributes
 */

/**
 * Composable that provides conversation filtering context
 * @returns {{ filterTypes: import('vue').ComputedRef<FilterType[]>, filterGroups: import('vue').ComputedRef<FilterGroup[]> }}
 */
export function useConversationFilterContext() {
  const { t } = useI18n();

  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );
  const contactAttributes = useMapGetter(
    'attributes/getContactAttributes'
  );

  const labels = useMapGetter('labels/getLabels');
  const agents = useMapGetter('agents/getAgents');
  const inboxes = useMapGetter('inboxes/getInboxes');
  const campaigns = useMapGetter('campaigns/getAllCampaigns');

  const {
    equalityOperators,
    presenceOperators,
    getOperatorTypes,
  } = useOperators();

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  const customFilterTypes = computed(() => [
    ...buildAttributesFilterTypes(
      conversationAttributes.value,
      getOperatorTypes,
      'conversation'
    ),
    ...buildAttributesFilterTypes(
      contactAttributes.value,
      getOperatorTypes,
      'contact'
    ),
  ]);

  /**
   * @type {import('vue').ComputedRef<FilterType[]>}
   */
  // Helper to find a custom attribute filter by key
  const findCustomFilter = key =>
    customFilterTypes.value.find(f => f.attributeKey === key);

  const filterTypes = computed(() => {
    const posicionPropuesta = findCustomFilter('posicion_propuesta');
    const tecnologiaPrincipal = findCustomFilter('tecnologia_principal');
    const empresaEmpleadora = findCustomFilter('empresa_empleadora');
    const puestoActual = findCustomFilter('puesto_actual');

    return [
      // 1. Posición Propuesta
      ...(posicionPropuesta ? [posicionPropuesta] : []),
      // 2. Estado de Reclutamiento (recruitment status via labels)
      {
        attributeKey: CONVERSATION_ATTRIBUTES.LABELS,
        value: CONVERSATION_ATTRIBUTES.LABELS,
        attributeName: 'Estado de Reclutamiento',
        label: 'Estado de Reclutamiento',
        inputType: 'multiSelect',
        options: labels.value.map(label => ({
          id: label.title,
          name:
            RECRUITMENT_STATUSES.find(s => s.title === label.title)?.displayName ||
            label.title,
          icon: h('span', {
            class: `rounded-full`,
            style: {
              backgroundColor: label.color,
              height: '6px',
              width: '6px',
            },
          }),
        })),
        dataType: 'text',
        filterOperators: presenceOperators.value,
        attributeModel: 'standard',
      },
      // 4. Tecnología Principal
      ...(tecnologiaPrincipal ? [tecnologiaPrincipal] : []),
    ].filter(Boolean);
  });

  return { filterTypes };
}
