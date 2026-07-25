<script lang="ts">
	import { openObservationFile, loadConfig, addRecentFile } from '$lib/platform';
	import { parseObservation } from '$lib/parsers';
	import type { Observation } from '$lib/domain';

	let observation = $state<Observation | null>(null);
	let error = $state<string | null>(null);
	let busy = $state(false);
	let recentFiles = $state<string[]>([]);

	$effect(() => {
		loadConfig().then((config) => {
			recentFiles = config.recentFiles;
		});
	});

	async function handleOpen() {
		error = null;
		busy = true;
		try {
			const picked = await openObservationFile();
			if (!picked) return; // user cancelled the picker
			observation = await parseObservation({ fileName: picked.fileName, bytes: picked.bytes });
			const config = await addRecentFile(picked.fileName);
			recentFiles = config.recentFiles;
		} catch (err) {
			observation = null;
			error = err instanceof Error ? err.message : String(err);
		} finally {
			busy = false;
		}
	}
</script>

<main class="mx-auto max-w-2xl p-8">
	<h1 class="text-2xl font-semibold">LAMULA Process</h1>

	<button
		class="mt-4 rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
		onclick={handleOpen}
		disabled={busy}
	>
		{busy ? 'Abriendo…' : 'Abrir archivo'}
	</button>

	{#if error}
		<p class="mt-4 text-red-600">{error}</p>
	{/if}

	{#if observation}
		<section class="mt-6 rounded border border-gray-300 p-4">
			<h2 class="font-semibold">{observation.id}</h2>
			<dl class="mt-2 grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-sm">
				<dt class="text-gray-500">Sitio</dt>
				<dd>{observation.site.name} ({observation.site.code})</dd>
				<dt class="text-gray-500">Fecha</dt>
				<dd>{observation.timestamp}</dd>
				<dt class="text-gray-500">Diseño</dt>
				<dd>{observation.design}</dd>
				<dt class="text-gray-500">Canales</dt>
				<dd>
					{observation.movements
						.flatMap((m) => m.channels)
						.map((c) => `${c.moment} (${c.scans.length} scans)`)
						.join(', ')}
				</dd>
			</dl>
		</section>
	{/if}

	{#if recentFiles.length > 0}
		<section class="mt-6">
			<h2 class="font-semibold">Recientes</h2>
			<ul class="mt-2 text-sm text-gray-600">
				{#each recentFiles as name (name)}
					<li>{name}</li>
				{/each}
			</ul>
		</section>
	{/if}
</main>
