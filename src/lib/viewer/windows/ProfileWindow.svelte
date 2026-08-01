<script lang="ts">
	import type { ChannelRef } from '$lib/pipeline';
	import { computeProfile } from '$lib/products';
	import { ProfilePanel, ZoomControl } from '$lib/viewer';
	import {
		windowStore,
		type RadarWindow,
		type ProfileWindowPayload,
		type MapWindowPayload
	} from '$lib/windows';

	interface Props {
		win: RadarWindow;
		channels: ChannelRef[];
		effectiveSiteAltM: number;
		onEditScale: (paletteKey: string) => void;
	}

	let { win, channels, effectiveSiteAltM, onEditScale }: Props = $props();

	const payload = $derived(win.payload as ProfileWindowPayload);

	const sourceMap = $derived(windowStore.find(payload.sourceMapWindowId));
	const sourceClosed = $derived(!sourceMap);
	const sourceChannel = $derived(
		sourceMap ? channels[(sourceMap.payload as MapWindowPayload).channelIndex]?.channel : undefined
	);

	const profile = $derived.by(() => {
		if (!sourceChannel || !payload.point) return null;
		return computeProfile(sourceChannel.scans, {
			xEastM: payload.point.xEastM,
			yNorthM: payload.point.yNorthM,
			beamWidthDeg: sourceChannel.beamWidthDeg ?? 1.0,
			topM: payload.maxHeightKm * 1000,
			siteAltM: effectiveSiteAltM
		});
	});

	let zoom = $state(1);
</script>

<div class="flex h-full flex-col">
	<div
		class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>PERFIL VERTICAL</span
		>
		{#if sourceClosed}
			<span class="rounded bg-dbz-heavy/20 px-2 py-0.5 font-mono text-[10px] text-dbz-heavy">
				Origen cerrado
			</span>
		{/if}
		{#if payload.point}
			<button
				type="button"
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={() => (payload.point = null)}
			>
				<span class="material-symbols-outlined text-[14px]">restart_alt</span> Rehacer punto
			</button>
		{/if}
		<ZoomControl {zoom} onZoom={(z) => (zoom = z)} />
		<button
			type="button"
			class="flex h-7 w-7 shrink-0 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-primary-container hover:text-primary-container"
			onclick={() => onEditScale(sourceChannel?.moment ?? 'dBZ')}
			aria-label="Editar escala"
			title="Editar escala"
		>
			<span class="material-symbols-outlined text-[14px]">palette</span>
		</button>
		<label
			class="ml-auto flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant">ALT MÁX</span>
			<input
				type="number"
				step="1"
				class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.maxHeightKm}
			/>
			<span class="font-mono text-[9px] text-on-surface-variant">km</span>
		</label>
	</div>

	<div class="flex min-h-0 flex-1 flex-col bg-surface-container-lowest">
		{#if profile}
			<ProfilePanel {profile} valueLabel={sourceChannel?.moment ?? 'dBZ'} {zoom} />
		{:else}
			<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
				Haz clic en el mapa de origen para ver el perfil vertical.
			</p>
		{/if}
	</div>
</div>
