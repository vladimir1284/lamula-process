<script lang="ts">
	import type { Palette, PaletteStop } from '$lib/palette/types';
	import { addStop, removeStop, updateStop, renamePalette } from '$lib/palette/edit';
	import { serializePalette } from '$lib/palette/serialize';

	interface Props {
		palette: Palette;
		/** Fired on every edit so the caller can re-render with the new palette. */
		onchange?: (p: Palette) => void;
	}

	let { palette, onchange }: Props = $props();

	function commit(p: Palette) {
		palette = p;
		onchange?.(p);
	}

	function hex(c: readonly [number, number, number]): string {
		return '#' + c.map((v) => Math.round(v).toString(16).padStart(2, '0')).join('');
	}
	function fromHex(h: string): [number, number, number] {
		return [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
	}

	function exportPal() {
		const blob = new Blob([serializePalette(palette) as BlobPart], {
			type: 'application/octet-stream'
		});
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `${palette.name || 'palette'}.pal`;
		a.click();
		URL.revokeObjectURL(url);
	}

	function newStop(): PaletteStop {
		const last = palette.stops[palette.stops.length - 1];
		return { value: last ? last.value + 10 : 0, color: [255, 255, 255], caption: '' };
	}
</script>

<div class="flex flex-col gap-2 text-sm">
	<label class="flex items-center gap-2">
		<span class="w-16 text-gray-500">Nombre</span>
		<input
			class="flex-1 rounded border border-gray-300 px-2 py-1"
			value={palette.name}
			oninput={(e) => commit(renamePalette(palette, e.currentTarget.value))}
		/>
	</label>

	<table class="w-full border-collapse">
		<thead>
			<tr class="text-left text-xs text-gray-500">
				<th class="py-1">Umbral</th>
				<th>Color</th>
				<th>Etiqueta</th>
				<th></th>
			</tr>
		</thead>
		<tbody>
			{#each palette.stops as stop, i (i)}
				<tr>
					<td class="py-0.5 pr-2">
						<input
							type="number"
							class="w-20 rounded border border-gray-300 px-1 py-0.5"
							value={stop.value}
							oninput={(e) =>
								commit(updateStop(palette, i, { value: Number(e.currentTarget.value) }))}
						/>
					</td>
					<td class="pr-2">
						<input
							type="color"
							value={hex(stop.color)}
							oninput={(e) =>
								commit(updateStop(palette, i, { color: fromHex(e.currentTarget.value) }))}
						/>
					</td>
					<td class="pr-2">
						<input
							class="w-full rounded border border-gray-300 px-1 py-0.5"
							value={stop.caption}
							oninput={(e) => commit(updateStop(palette, i, { caption: e.currentTarget.value }))}
						/>
					</td>
					<td>
						<button
							class="rounded px-2 py-0.5 text-red-600 hover:bg-red-50"
							onclick={() => commit(removeStop(palette, i))}
							aria-label="Eliminar stop">✕</button
						>
					</td>
				</tr>
			{/each}
		</tbody>
	</table>

	<div class="flex gap-2">
		<button
			class="rounded bg-gray-200 px-3 py-1 hover:bg-gray-300"
			onclick={() => commit(addStop(palette, newStop()))}>+ Stop</button
		>
		<button class="rounded bg-blue-600 px-3 py-1 text-white" onclick={exportPal}>
			Exportar .pal
		</button>
	</div>
</div>
