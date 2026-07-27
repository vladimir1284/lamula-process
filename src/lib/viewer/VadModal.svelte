<script lang="ts">
	import type { VadProfileResult } from '$lib/products/vadProfile';
	import VadPanel from './VadPanel.svelte';
	import Modal from './Modal.svelte';

	interface Props {
		open: boolean;
		profile: VadProfileResult | null;
		onclose: () => void;
	}

	let { open, profile, onclose }: Props = $props();
</script>

<Modal
	{open}
	title="PERFIL DE VIENTO VAD (VELOCITY AZIMUTH DISPLAY)"
	maxWidthClass="max-w-5xl"
	{onclose}
>
	{#if profile}
		<VadPanel {profile} {onclose} />
	{:else}
		<div class="flex h-32 items-center justify-center font-mono text-xs text-on-surface-variant">
			No hay datos de perfil VAD disponibles.
		</div>
	{/if}
</Modal>
