// Recruitment pipeline status labels
// These labels are used as Chatwoot conversation labels to track candidate status.
// They must be created in the Chatwoot admin panel with matching titles.

export const RECRUITMENT_STATUSES = [
  { key: 'screening', title: 'Screening', color: '#3B82F6', bgClass: 'bg-blue-100', textClass: 'text-blue-700' },
  { key: 'cv_pendiente', title: 'CV Pendiente', color: '#F59E0B', bgClass: 'bg-amber-100', textClass: 'text-amber-700' },
  { key: 'presentado', title: 'Presentado', color: '#10B981', bgClass: 'bg-emerald-100', textClass: 'text-emerald-700' },
  { key: 'desestimado', title: 'Desestimado', color: '#EF4444', bgClass: 'bg-red-100', textClass: 'text-red-700' },
  { key: 'bench', title: 'Bench', color: '#8B5CF6', bgClass: 'bg-violet-100', textClass: 'text-violet-700' },
];

export const RECRUITMENT_STATUS_TITLES = RECRUITMENT_STATUSES.map(s => s.title);

export function getRecruitmentStatus(labels) {
  if (!labels || !labels.length) return null;
  const lowered = labels.map(l => l.toLowerCase());
  return RECRUITMENT_STATUSES.find(s => lowered.includes(s.title.toLowerCase())) || null;
}

export function isRecruitmentStatusLabel(labelTitle) {
  return RECRUITMENT_STATUS_TITLES.some(
    t => t.toLowerCase() === labelTitle.toLowerCase()
  );
}
