import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vitest/config';
import adapter from '@sveltejs/adapter-static';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig({
	// First build-time constants in this repo. `buildId` is only useful if it ships in the same
	// commit as the field that reports it (in lamula-webviewer it sat at 'dev' for months because
	// the two were split). `PUBLIC_FEEDBACK_API` empty = the feedback feature is off, which is the
	// default in development. Not `$env/static/public`: with adapter-static and no server routes
	// this repo doesn't use SvelteKit's env machinery, and one value doesn't justify adopting it.
	define: {
		__BUILD_ID__: JSON.stringify(process.env.GIT_SHA ?? 'dev'),
		__FEEDBACK_API__: JSON.stringify(process.env.PUBLIC_FEEDBACK_API ?? '')
	},
	server: {
		allowedHosts: true
	},
	plugins: [
		tailwindcss(),
		sveltekit({
			compilerOptions: {
				// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
				runes: ({ filename }) =>
					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
			},
			adapter: adapter({ fallback: 'index.html' })
		})
	],
	test: {
		expect: { requireAssertions: true },
		projects: [
			{
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	}
});
