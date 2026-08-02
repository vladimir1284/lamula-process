<script lang="ts">
	import {
		type VadProfileResult,
		type HeightBinStep,
		binVadLevels
	} from '$lib/products/vadProfile';
	import { _ } from '$lib/i18n';

	interface Props {
		profile: VadProfileResult;
		onclose?: () => void;
	}

	let { profile, onclose }: Props = $props();

	let activeTab = $state<'barbs' | 'hodograph' | 'table'>('barbs');
	let heightStep = $state<HeightBinStep>('1kft');
	let hoverLevelIndex = $state<number | null>(null);

	let barbsCanvas: HTMLCanvasElement | undefined = $state();
	let hodoCanvas: HTMLCanvasElement | undefined = $state();

	const binnedLevels = $derived(binVadLevels(profile.levels, heightStep));

	const DEG = Math.PI / 180;

	// Draw meteorological wind barb on canvas
	function drawWindBarb(
		ctx: CanvasRenderingContext2D,
		x: number,
		y: number,
		spdKts: number,
		dirDeg: number,
		scale = 1.0
	) {
		ctx.save();
		ctx.translate(x, y);
		const rotRad = dirDeg * DEG;
		ctx.rotate(rotRad);

		if (spdKts <= 2.5) {
			ctx.beginPath();
			ctx.arc(0, 0, 4 * scale, 0, Math.PI * 2);
			ctx.strokeStyle = 'rgba(255, 255, 255, 0.9)';
			ctx.lineWidth = 1.5 * scale;
			ctx.stroke();
			ctx.restore();
			return;
		}

		const staffLen = 30 * scale;
		ctx.strokeStyle = 'rgba(255, 255, 255, 0.9)';
		ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
		ctx.lineWidth = 1.5 * scale;

		ctx.beginPath();
		ctx.moveTo(0, 0);
		ctx.lineTo(0, -staffLen);
		ctx.stroke();

		let rem = Math.round(spdKts / 5) * 5;
		const numFlags = Math.floor(rem / 50);
		rem %= 50;
		const numBarbs = Math.floor(rem / 10);
		rem %= 10;
		const numHalfBarbs = Math.floor(rem / 5);

		let pos = -staffLen;
		const barbLen = 9 * scale;
		const barbGap = 4 * scale;

		for (let i = 0; i < numFlags; i++) {
			ctx.beginPath();
			ctx.moveTo(0, pos);
			ctx.lineTo(barbLen, pos + 2 * scale);
			ctx.lineTo(0, pos + 6 * scale);
			ctx.closePath();
			ctx.fill();
			pos += 7 * scale;
		}

		for (let i = 0; i < numBarbs; i++) {
			ctx.beginPath();
			ctx.moveTo(0, pos);
			ctx.lineTo(barbLen, pos - 3 * scale);
			ctx.stroke();
			pos += barbGap;
		}

		for (let i = 0; i < numHalfBarbs; i++) {
			if (pos === -staffLen) pos += barbGap;
			ctx.beginPath();
			ctx.moveTo(0, pos);
			ctx.lineTo(barbLen * 0.5, pos - 1.5 * scale);
			ctx.stroke();
			pos += barbGap;
		}

		ctx.restore();
	}

	// Render Wind Barbs Canvas
	$effect(() => {
		if (activeTab !== 'barbs' || !barbsCanvas) return;
		const canvas = barbsCanvas;
		const ctx = canvas.getContext('2d');
		if (!ctx) return;

		const W = canvas.width;
		const H = canvas.height;
		ctx.clearRect(0, 0, W, H);

		// Dark background
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, W, H);

		const PAD = { top: 30, bottom: 40, left: 70, right: 190 };
		const plotW = W - PAD.left - PAD.right;
		const plotH = H - PAD.top - PAD.bottom;

		const levels = binnedLevels;
		const maxH = Math.max(profile.maxHeightM, 3000);
		const maxSpd = Math.max(profile.maxSpeedMs, 10);

		const yOf = (h: number) => PAD.top + plotH - (h / maxH) * plotH;
		const xOf = (spd: number) => PAD.left + (spd / maxSpd) * plotW;

		// Grid lines for height (every 2 km)
		ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
		ctx.lineWidth = 1;
		ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
		ctx.font = '11px monospace';
		ctx.textAlign = 'right';

		for (let h = 0; h <= maxH; h += 2000) {
			const y = yOf(h);
			ctx.beginPath();
			ctx.moveTo(PAD.left, y);
			ctx.lineTo(PAD.left + plotW, y);
			ctx.stroke();

			const km = (h / 1000).toFixed(0);
			const kft = (h * 0.00328084).toFixed(0);
			ctx.fillText(`${km}km (${kft}kft)`, PAD.left - 8, y + 4);
		}

		// Grid lines for speed (every 5 m/s)
		ctx.textAlign = 'center';
		for (let s = 0; s <= maxSpd; s += 5) {
			const x = xOf(s);
			ctx.beginPath();
			ctx.moveTo(x, PAD.top);
			ctx.lineTo(x, PAD.top + plotH);
			ctx.stroke();
			ctx.fillText(`${s} m/s`, x, PAD.top + plotH + 18);
		}

		// Speed profile curve
		if (levels.length > 0) {
			ctx.strokeStyle = '#4ea1ff';
			ctx.lineWidth = 2;
			ctx.beginPath();
			for (let i = 0; i < levels.length; i++) {
				const lvl = levels[i];
				const x = xOf(lvl.speedMs);
				const y = yOf(lvl.heightM);
				if (i === 0) ctx.moveTo(x, y);
				else ctx.lineTo(x, y);
			}
			ctx.stroke();
		}

		// Draw points, barbs, and text labels (with vertical overlap guard)
		let lastLabelY = -Infinity;

		for (let i = 0; i < levels.length; i++) {
			const lvl = levels[i];
			const x = xOf(lvl.speedMs);
			const y = yOf(lvl.heightM);
			const isHover = hoverLevelIndex === i;

			// Draw point
			ctx.beginPath();
			ctx.arc(x, y, isHover ? 6 : 4, 0, Math.PI * 2);
			ctx.fillStyle = isHover ? '#00f2ff' : '#ffd166';
			ctx.fill();

			// Draw wind barb at a fixed right-hand column offset
			const barbX = PAD.left + plotW + 30;
			drawWindBarb(ctx, barbX, y, lvl.speedKts, lvl.directionDeg, 0.9);

			// Draw text label if vertical gap is >= 18px or hovered
			if (Math.abs(y - lastLabelY) >= 18 || isHover) {
				ctx.fillStyle = isHover ? '#00f2ff' : 'rgba(255, 255, 255, 0.85)';
				ctx.font = isHover ? 'bold 11px monospace' : '10px monospace';
				ctx.textAlign = 'left';
				ctx.fillText(
					`${lvl.cardinalDir} ${lvl.speedMs.toFixed(1)}m/s (${lvl.speedKts.toFixed(0)}kt)`,
					barbX + 22,
					y + 3
				);
				lastLabelY = y;
			}
		}
	});

	// Render Hodograph Canvas
	$effect(() => {
		if (activeTab !== 'hodograph' || !hodoCanvas) return;
		const canvas = hodoCanvas;
		const ctx = canvas.getContext('2d');
		if (!ctx) return;

		const W = canvas.width;
		const H = canvas.height;
		ctx.clearRect(0, 0, W, H);

		// Background
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, W, H);

		const cx = W / 2;
		const cy = H / 2;
		const maxSpd = Math.max(profile.maxSpeedMs, 15);
		const radius = Math.min(cx, cy) - 35;
		const scale = radius / maxSpd;

		// Concentric rings for speed
		ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
		ctx.lineWidth = 1;
		ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
		ctx.font = '10px monospace';
		ctx.textAlign = 'center';

		for (let s = 5; s <= maxSpd; s += 5) {
			const r = s * scale;
			ctx.beginPath();
			ctx.arc(cx, cy, r, 0, Math.PI * 2);
			ctx.stroke();
			ctx.fillText(`${s} m/s`, cx + r - 12, cy - 4);
		}

		// N-S and E-W axes
		ctx.beginPath();
		ctx.moveTo(cx - radius, cy);
		ctx.lineTo(cx + radius, cy);
		ctx.moveTo(cx, cy - radius);
		ctx.lineTo(cx, cy + radius);
		ctx.stroke();

		// Direction labels
		ctx.font = 'bold 12px monospace';
		ctx.fillStyle = '#4ea1ff';
		ctx.fillText('N', cx, cy - radius - 8);
		ctx.fillText('S', cx, cy + radius + 16);
		ctx.fillText('E', cx + radius + 12, cy + 4);
		ctx.fillText('W', cx - radius - 12, cy + 4);

		// Hodograph curve
		const levels = binnedLevels;
		if (levels.length > 0) {
			ctx.strokeStyle = '#00f2ff';
			ctx.lineWidth = 2;
			ctx.beginPath();
			for (let i = 0; i < levels.length; i++) {
				const lvl = levels[i];
				const px = cx + lvl.vx * scale;
				const py = cy - lvl.vy * scale;
				if (i === 0) ctx.moveTo(px, py);
				else ctx.lineTo(px, py);
			}
			ctx.stroke();

			for (let i = 0; i < levels.length; i++) {
				const lvl = levels[i];
				const px = cx + lvl.vx * scale;
				const py = cy - lvl.vy * scale;
				const isHover = hoverLevelIndex === i;

				ctx.beginPath();
				ctx.arc(px, py, isHover ? 6 : 4, 0, Math.PI * 2);
				ctx.fillStyle = isHover ? '#ffd166' : '#ff4e6a';
				ctx.fill();

				if (isHover) {
					ctx.fillStyle = '#ffffff';
					ctx.font = '11px monospace';
					ctx.fillText(`${(lvl.heightM / 1000).toFixed(1)}km`, px + 10, py - 4);
				}
			}
		}
	});
</script>

<div class="flex flex-col gap-3 font-sans text-on-surface">
	<!-- Top Bar / Controls -->
	<div
		class="flex flex-wrap items-center justify-between gap-3 border-b border-outline-variant pb-2"
	>
		<div class="flex items-center gap-2">
			<span class="material-symbols-outlined text-[22px] text-primary-container">air</span>
			<h2 class="text-title-md font-mono font-semibold text-primary-container">
				{$_('vad.title')}
			</h2>
			{#if onclose}
				<button
					class="ml-2 rounded p-1 text-on-surface-variant hover:bg-surface-container-highest"
					onclick={onclose}
					aria-label={$_('vad.close')}
				>
					<span class="material-symbols-outlined text-[20px]">close</span>
				</button>
			{/if}
		</div>

		<!-- Step Bin & View Tabs Controls -->
		<div class="flex flex-wrap items-center gap-3">
			<label class="flex items-center gap-2 font-mono text-xs text-on-surface-variant">
				<span>{$_('vad.heightStepLabel')}</span>
				<select
					class="cursor-pointer rounded border border-outline-variant bg-surface-container-high px-2 py-1 font-mono text-xs text-primary-container focus:ring-0"
					bind:value={heightStep}
				>
					<option value="1kft">1 kft (~300m NEXRAD)</option>
					<option value="500m">500 m</option>
					<option value="1km">1 km</option>
					<option value="2km">2 km</option>
					<option value="all"
						>{$_('vad.stepAll', { values: { count: profile.levels.length } })}</option
					>
				</select>
			</label>

			<div
				class="flex rounded-lg border border-outline-variant bg-surface-container-high p-1 text-label-mono"
			>
				<button
					class="flex items-center gap-1.5 rounded px-3 py-1 text-xs transition-all {activeTab ===
					'barbs'
						? 'bg-primary-container font-semibold text-on-primary-container shadow'
						: 'text-on-surface-variant hover:text-on-surface'}"
					onclick={() => (activeTab = 'barbs')}
				>
					<span class="material-symbols-outlined text-[16px]">show_chart</span>
					{$_('vad.tabBarbs')}
				</button>
				<button
					class="flex items-center gap-1.5 rounded px-3 py-1 text-xs transition-all {activeTab ===
					'hodograph'
						? 'bg-primary-container font-semibold text-on-primary-container shadow'
						: 'text-on-surface-variant hover:text-on-surface'}"
					onclick={() => (activeTab = 'hodograph')}
				>
					<span class="material-symbols-outlined text-[16px]">radar</span>
					{$_('vad.tabHodograph')}
				</button>
				<button
					class="flex items-center gap-1.5 rounded px-3 py-1 text-xs transition-all {activeTab ===
					'table'
						? 'bg-primary-container font-semibold text-on-primary-container shadow'
						: 'text-on-surface-variant hover:text-on-surface'}"
					onclick={() => (activeTab = 'table')}
				>
					<span class="material-symbols-outlined text-[16px]">table_rows</span>
					{$_('vad.tabTable', { values: { count: binnedLevels.length } })}
				</button>
			</div>
		</div>
	</div>

	<!-- Main Content Display -->
	<div class="min-h-[420px] w-full">
		{#if profile.levels.length === 0}
			<div
				class="flex h-[380px] flex-col items-center justify-center gap-2 rounded-lg border border-dashed border-outline-variant text-center"
			>
				<span class="material-symbols-outlined text-[36px] text-on-surface-variant"
					>do_not_disturb_on</span
				>
				<p class="text-body-md text-on-surface-variant">
					{$_('vad.noData')}
				</p>
			</div>
		{:else if activeTab === 'barbs'}
			<div class="flex flex-col gap-2">
				<div class="relative overflow-hidden rounded-lg border border-outline-variant bg-[#0b0f14]">
					<canvas bind:this={barbsCanvas} width={820} height={420} class="w-full"></canvas>
				</div>
				<div
					class="flex items-center justify-between font-mono text-[11px] text-on-surface-variant"
				>
					<span>
						{$_('vad.barbsLegend')}
					</span>
					<span class="text-primary-container">
						{$_('vad.showingLevels', { values: { count: binnedLevels.length, step: heightStep } })}
					</span>
				</div>
			</div>
		{:else if activeTab === 'hodograph'}
			<div class="flex flex-col items-center gap-2">
				<div class="relative overflow-hidden rounded-lg border border-outline-variant bg-[#0b0f14]">
					<canvas bind:this={hodoCanvas} width={560} height={420}></canvas>
				</div>
				<p class="font-mono text-[11px] text-on-surface-variant">
					{$_('vad.hodographLegend')}
				</p>
			</div>
		{:else if activeTab === 'table'}
			<div class="max-h-[420px] overflow-auto rounded-lg border border-outline-variant">
				<table class="w-full text-left font-mono text-xs">
					<thead class="sticky top-0 bg-surface-container-high text-on-surface-variant">
						<tr class="border-b border-outline-variant">
							<th class="px-3 py-2">{$_('vad.table.height')}</th>
							<th class="px-3 py-2">{$_('vad.table.elevation')}</th>
							<th class="px-3 py-2">{$_('vad.table.range')}</th>
							<th class="px-3 py-2">{$_('vad.table.speed')}</th>
							<th class="px-3 py-2">{$_('vad.table.direction')}</th>
							<th class="px-3 py-2">{$_('vad.table.rms')}</th>
							<th class="px-3 py-2">{$_('vad.table.cf1')}</th>
							<th class="px-3 py-2">{$_('vad.table.n')}</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-outline-variant/30">
						{#each binnedLevels as lvl, i (lvl.heightM)}
							<tr
								class="cursor-pointer transition-colors hover:bg-surface-container-highest {hoverLevelIndex ===
								i
									? 'bg-primary-container/20 font-semibold'
									: ''}"
								onmouseenter={() => (hoverLevelIndex = i)}
								onmouseleave={() => (hoverLevelIndex = null)}
							>
								<td class="px-3 py-1.5 text-primary-container">
									{lvl.heightM.toFixed(0)} m ({lvl.heightKft.toFixed(1)} kft)
								</td>
								<td class="px-3 py-1.5">{lvl.elevationDeg.toFixed(1)}°</td>
								<td class="px-3 py-1.5">{(lvl.slantRangeM / 1000).toFixed(1)} km</td>
								<td class="px-3 py-1.5 font-bold">
									{lvl.speedMs.toFixed(1)} m/s ({lvl.speedKts.toFixed(0)} kt)
								</td>
								<td class="px-3 py-1.5">
									{lvl.directionDeg.toFixed(0)}° {lvl.cardinalDir}
								</td>
								<td class="px-3 py-1.5">{lvl.rmsMs.toFixed(2)}</td>
								<td class="px-3 py-1.5">{lvl.cf1.toFixed(2)}</td>
								<td class="px-3 py-1.5">{lvl.npt}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>
</div>
