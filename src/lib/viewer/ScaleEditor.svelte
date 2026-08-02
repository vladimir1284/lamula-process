<script lang="ts">
	import type { Palette, PaletteStop } from '$lib/palette/types';
	import { addStop, removeStop, updateStop, renamePalette } from '$lib/palette/edit';
	import { serializePalette } from '$lib/palette/serialize';
	import { _ } from '$lib/i18n';

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

<div class="flex flex-col gap-3 font-mono text-label-mono">
	<label class="flex items-center gap-2">
		<span class="w-16 text-[11px] text-on-surface-variant">{$_('scaleEditor.name')}</span>
		<input
			class="cyan-glow flex-1 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-on-surface focus:ring-0"
			value={palette.name}
			oninput={(e) => commit(renamePalette(palette, e.currentTarget.value))}
		/>
	</label>

	<table class="w-full border-collapse">
		<thead>
			<tr class="text-left text-[10px] tracking-widest text-on-surface-variant uppercase">
				<th class="py-1 font-medium">{$_('scaleEditor.threshold')}</th>
				<th class="font-medium">{$_('scaleEditor.color')}</th>
				<th class="font-medium">{$_('scaleEditor.label')}</th>
				<th></th>
			</tr>
		</thead>
		<tbody>
			{#each palette.stops as stop, i (i)}
				<tr>
					<td class="py-0.5 pr-2">
						<input
							type="number"
							class="w-16 rounded border border-outline-variant bg-surface-container-high px-1 py-0.5 text-primary-container focus:ring-0"
							value={stop.value}
							oninput={(e) =>
								commit(updateStop(palette, i, { value: Number(e.currentTarget.value) }))}
						/>
					</td>
					<td class="pr-2">
						<input
							type="color"
							class="h-7 w-8 cursor-pointer rounded border border-outline-variant bg-surface-container-high"
							value={hex(stop.color)}
							oninput={(e) =>
								commit(updateStop(palette, i, { color: fromHex(e.currentTarget.value) }))}
						/>
					</td>
					<td class="pr-2">
						<input
							class="w-full rounded border border-outline-variant bg-surface-container-high px-1 py-0.5 text-on-surface focus:ring-0"
							value={stop.caption}
							oninput={(e) => commit(updateStop(palette, i, { caption: e.currentTarget.value }))}
						/>
					</td>
					<td>
						<button
							class="rounded px-2 py-0.5 text-error hover:bg-error-container/20"
							onclick={() => commit(removeStop(palette, i))}
							aria-label={$_('scaleEditor.deleteStopAria')}>✕</button
						>
					</td>
				</tr>
			{/each}
		</tbody>
	</table>

	<div class="flex gap-2">
		<button
			class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-1 text-on-surface transition-colors hover:border-primary-container"
			onclick={() => commit(addStop(palette, newStop()))}
			><span class="material-symbols-outlined text-[16px]">add</span>
			{$_('scaleEditor.addPoint')}</button
		>
		<button
			class="flex items-center gap-1 rounded bg-primary-container px-3 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95"
			onclick={exportPal}
			><span class="material-symbols-outlined text-[16px]">save</span>
			{$_('scaleEditor.exportPal')}</button
		>
	</div>
</div>
