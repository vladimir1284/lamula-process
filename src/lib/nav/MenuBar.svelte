<script lang="ts" module>
	export interface MenuItem {
		label: string;
		icon?: string;
		onclick?: () => void;
		disabled?: boolean;
		submenu?: MenuItem[];
		/** Shows a check mark next to the label (e.g. "this is the focused window"). */
		checked?: boolean;
		/** Renders as a plain divider instead of a clickable row; every other field is ignored. */
		separator?: true;
	}

	export interface MenuDef {
		label: string;
		items: MenuItem[];
	}
</script>

<script lang="ts">
	interface Props {
		menus: MenuDef[];
	}

	let { menus }: Props = $props();

	let openMenu = $state<string | null>(null);
	let openSubmenu = $state<string | null>(null);
	let root: HTMLElement | undefined = $state();

	function toggleMenu(label: string) {
		openMenu = openMenu === label ? null : label;
		openSubmenu = null;
	}

	function closeAll() {
		openMenu = null;
		openSubmenu = null;
	}

	function pick(item: MenuItem) {
		if (item.disabled || item.submenu) return;
		item.onclick?.();
		closeAll();
	}

	function handleWindowClick(e: MouseEvent) {
		if (root && !root.contains(e.target as Node)) closeAll();
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') closeAll();
	}
</script>

<svelte:window onclick={handleWindowClick} onkeydown={handleKeydown} />

<nav bind:this={root} class="flex items-center gap-0.5" aria-label="Menú principal">
	{#each menus as menu (menu.label)}
		<div class="relative">
			<button
				class="rounded px-3 py-1.5 font-mono text-label-mono uppercase transition-colors {openMenu ===
				menu.label
					? 'bg-surface-container-high text-primary-container'
					: 'text-on-surface hover:bg-surface-container-high'}"
				aria-haspopup="true"
				aria-expanded={openMenu === menu.label}
				onclick={() => toggleMenu(menu.label)}
			>
				{menu.label}
			</button>
			{#if openMenu === menu.label}
				<ul
					role="menu"
					class="absolute top-full left-0 z-50 mt-1 min-w-60 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
				>
					{#each menu.items as item, i (item.separator ? `sep-${i}` : item.label)}
						{#if item.separator}
							<li class="my-1 border-t border-outline-variant" aria-hidden="true"></li>
						{:else}
							<li class="relative">
								{#if item.submenu}
									<button
										class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-label-mono text-on-surface transition-colors hover:bg-surface-variant/20 disabled:opacity-50"
										disabled={item.disabled}
										onclick={() => (openSubmenu = openSubmenu === item.label ? null : item.label)}
									>
										{#if item.icon}
											<span class="material-symbols-outlined text-[18px]">{item.icon}</span>
										{/if}
										<span class="flex-1">{item.label}</span>
										<span class="material-symbols-outlined text-[16px]">chevron_right</span>
									</button>
									{#if openSubmenu === item.label}
										<ul
											role="menu"
											class="absolute top-0 left-full ml-1 min-w-60 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
										>
											{#each item.submenu as sub (sub.label)}
												<li>
													<button
														class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-label-mono text-on-surface transition-colors hover:bg-surface-variant/20 disabled:opacity-50"
														disabled={sub.disabled}
														onclick={() => pick(sub)}
													>
														{#if sub.icon}
															<span class="material-symbols-outlined text-[16px]">{sub.icon}</span>
														{/if}
														<span class="truncate">{sub.label}</span>
													</button>
												</li>
											{/each}
										</ul>
									{/if}
								{:else}
									<button
										class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-label-mono text-on-surface transition-colors hover:bg-surface-variant/20 disabled:opacity-50"
										disabled={item.disabled}
										onclick={() => pick(item)}
									>
										{#if item.icon}
											<span class="material-symbols-outlined text-[18px]">{item.icon}</span>
										{/if}
										<span class="flex-1">{item.label}</span>
										{#if item.checked}
											<span class="material-symbols-outlined text-[16px] text-primary-container"
												>check</span
											>
										{/if}
									</button>
								{/if}
							</li>
						{/if}
					{/each}
				</ul>
			{/if}
		</div>
	{/each}
</nav>
