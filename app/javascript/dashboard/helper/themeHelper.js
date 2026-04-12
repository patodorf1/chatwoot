import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = () => {
  // Force light mode only
  document.body.classList.remove('dark');
  document.documentElement.style.setProperty('color-scheme', 'light');
};
