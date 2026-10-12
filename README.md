# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project
npx sv create my-app
```

To recreate this project with the same configuration:

```sh
# recreate this project
pnpm dlx sv@0.16.5 create --template minimal --types ts --add prettier eslint vitest="usages:unit" tailwindcss="plugins:none" sveltekit-adapter="adapter:static" --no-download-check --install pnpm .
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

### Build-time variables

Two constants are baked in at build time (vite `define`, see `vite.config.ts`) — the app is a
static bundle, there is no server to read them at runtime:

- `PUBLIC_FEEDBACK_API` — base URL of the shared feedback API. **Empty (the default) turns the
  whole feedback feature off**: no Help menu, no nudge, no requests.
- `GIT_SHA` — reported as `buildId` with each feedback message. Falls back to `dev`.

See `docs/feedback.md`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
