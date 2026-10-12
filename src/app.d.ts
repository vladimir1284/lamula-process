// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	// Injected by vite's `define` (see vite.config.ts). `__BUILD_ID__` is the git SHA in CI and
	// 'dev' locally; `__FEEDBACK_API__` is the base URL of the feedback API ('' = feature off).
	// They must live inside `declare global`: this file has an `export {}`, so top-level
	// declarations would be module-scoped and invisible to the rest of the app.
	const __BUILD_ID__: string;
	const __FEEDBACK_API__: string;

	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
