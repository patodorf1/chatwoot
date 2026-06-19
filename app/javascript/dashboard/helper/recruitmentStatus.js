// Recruitment pipeline status labels
// These labels are used as Chatwoot conversation labels to track candidate status.
// `title` must match exactly what Chatwoot stores (lowercase, no spaces).
// `displayName` is what we show in the UI.

export const RECRUITMENT_STATUSES = [
  { key: 'screening', title: 'screening', displayName: 'Screening', color: '#3B82F6', bgClass: 'bg-blue-100', textClass: 'text-blue-700' },
  { key: 'cv_pendiente', title: 'cv_pendiente', displayName: 'CV Pendiente', color: '#F59E0B', bgClass: 'bg-amber-100', textClass: 'text-amber-700' },
  { key: 'presentado', title: 'presentado', displayName: 'Presentado', color: '#10B981', bgClass: 'bg-emerald-100', textClass: 'text-emerald-700' },
  { key: 'desestimado', title: 'desestimado', displayName: 'Desestimado', color: '#EF4444', bgClass: 'bg-red-100', textClass: 'text-red-700' },
  { key: 'bench', title: 'bench', displayName: 'Bench', color: '#8B5CF6', bgClass: 'bg-violet-100', textClass: 'text-violet-700' },
];

export const RECRUITMENT_STATUS_TITLES = RECRUITMENT_STATUSES.map(s => s.title);

export function getRecruitmentStatus(labels) {
  if (!labels || !labels.length) return null;
  return RECRUITMENT_STATUSES.find(s => labels.includes(s.title)) || null;
}

export function isRecruitmentStatusLabel(labelTitle) {
  return RECRUITMENT_STATUS_TITLES.includes(labelTitle);
}

// Internal/system labels that should never be shown as badges on conversation
// cards: the Airtable writeback bookkeeping labels, plus 'nl' (the retired
// unread marker — read state now uses Chatwoot's native unread, not this label).
export const HIDDEN_CARD_LABEL_TITLES = [
  'creado_por_writeback',
  'crear_igual_en_airtable',
  'datos_insuficientes_writeback',
  'linkear_a_airtable',
  'revisar_duplicado_airtable',
  'nl',
];

export function isHiddenCardLabel(labelTitle) {
  return HIDDEN_CARD_LABEL_TITLES.includes(labelTitle);
}
