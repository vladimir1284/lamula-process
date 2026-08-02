import { browser } from '$app/environment';
import { init, addMessages, getLocaleFromNavigator, locale as localeStore } from 'svelte-i18n';
import es from './locales/es.json';
import en from './locales/en.json';

export const SUPPORTED_LOCALES = ['es', 'en'] as const;
export type Locale = (typeof SUPPORTED_LOCALES)[number];
export const DEFAULT_LOCALE: Locale = 'es';
const STORAGE_KEY = 'lamula.locale';

// Messages are tiny (a few KB) and statically imported (not lazy-registered), so translations
// are available synchronously -- both for components and for plain modules like
// analysis/report.ts that call `get(_)` outside any component lifecycle.
addMessages('es', es);
addMessages('en', en);

function isSupported(value: string | null | undefined): value is Locale {
	return SUPPORTED_LOCALES.includes(value as Locale);
}

function detectInitialLocale(): Locale {
	if (!browser) return DEFAULT_LOCALE;

	const stored = window.localStorage.getItem(STORAGE_KEY);
	if (isSupported(stored)) return stored;

	const navLocale = getLocaleFromNavigator()?.split('-')[0];
	if (isSupported(navLocale)) return navLocale;

	return DEFAULT_LOCALE;
}

init({
	fallbackLocale: DEFAULT_LOCALE,
	initialLocale: detectInitialLocale()
});

export function setLocale(next: Locale): void {
	if (browser) window.localStorage.setItem(STORAGE_KEY, next);
	localeStore.set(next);
}

export { locale, _, waitLocale } from 'svelte-i18n';
