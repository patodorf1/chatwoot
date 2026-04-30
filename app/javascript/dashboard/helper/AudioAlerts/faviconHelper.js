// Cache the original document title once so we can restore it when the unread
// count drops to zero.
let originalDocumentTitle = null;
let badgeFaviconUrl = null;

const captureOriginalTitle = () => {
  if (originalDocumentTitle === null) {
    originalDocumentTitle = document.title.replace(/^\(\d+\)\s*/, '');
  }
};

// Build a 64x64 favicon with the unread count drawn as a red badge in the
// upper-right corner. Falls back to a solid red dot if the count is 0.
const buildBadgeFavicon = count => {
  const size = 64;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');

  // Background circle (Chatwoot brand-ish blue) so the badge stays visible
  // when the original favicon is not available (e.g. during initial render).
  ctx.fillStyle = '#1F93FF';
  ctx.beginPath();
  ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
  ctx.fill();

  // Letter "W" placeholder for the brand
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 38px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('W', size / 2, size / 2 + 2);

  // Red badge in the upper-right corner with the count
  if (count > 0) {
    const radius = 22;
    const cx = size - radius;
    const cy = radius;
    ctx.fillStyle = '#EF4444';
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();

    const label = count > 99 ? '99+' : String(count);
    ctx.fillStyle = '#ffffff';
    ctx.font = `bold ${label.length > 2 ? 18 : 26}px sans-serif`;
    ctx.fillText(label, cx, cy + 1);
  }

  return canvas.toDataURL('image/png');
};

const swapFavicons = href => {
  const favicons = document.querySelectorAll('.favicon');
  favicons.forEach(favicon => {
    favicon.href = href;
  });
};

// Public: legacy badge swap (red dot). Kept for backwards compatibility with
// the recurring audio-notification helper that does not know the count.
export const showBadgeOnFavicon = () => {
  if (!badgeFaviconUrl) {
    badgeFaviconUrl = buildBadgeFavicon(0);
  }
  swapFavicons(badgeFaviconUrl);
};

// Public: reset to the configured per-size favicon when the tab becomes
// visible again.
export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        const oldFileName = `/favicon-${favicon.sizes[[0]]}.png`;
        favicon.href = oldFileName;
      });
    }
  });
};

// Public: surfaces the unread conversation count across the OS surfaces a
// browser exposes (tab title, favicon, PWA/taskbar badge).
export const setUnreadBadge = count => {
  captureOriginalTitle();
  const safeCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;

  // 1) Tab title
  document.title = safeCount > 0
    ? `(${safeCount > 99 ? '99+' : safeCount}) ${originalDocumentTitle}`
    : originalDocumentTitle;

  // 2) Favicon with number badge drawn via canvas
  badgeFaviconUrl = buildBadgeFavicon(safeCount);
  swapFavicons(badgeFaviconUrl);

  // 3) PWA / OS taskbar app badge (Chrome desktop, Edge, etc.)
  if ('setAppBadge' in navigator) {
    if (safeCount > 0) {
      navigator.setAppBadge(safeCount).catch(() => {});
    } else {
      navigator.clearAppBadge?.().catch(() => {});
    }
  }
};
