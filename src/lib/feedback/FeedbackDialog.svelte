<script lang="ts">
	import { _ } from '$lib/i18n';
	import Modal from '$lib/viewer/Modal.svelte';
	import { FEEDBACK_KINDS, FEEDBACK_ROLES, MAX_MESSAGE_LENGTH } from './contract';
	import type { FeedbackKind, FeedbackRole } from './contract';
	import { feedbackStore } from './store.svelte';

	const store = feedbackStore;

	// Seeded from the saved profile so that, from the second message on, the user only writes
	// the message. Seeded once per mount: the dialog owns its fields afterwards.
	let role = $state<FeedbackRole | ''>(store.profile?.role ?? '');
	let roleOther = $state(store.profile?.roleOther ?? '');
	let kind = $state<FeedbackKind>('mejora');
	let rating = $state<number | null>(null);
	let message = $state('');
	let displayName = $state(store.profile?.displayName ?? '');
	let email = $state(store.profile?.email ?? '');
	let organization = $state(store.profile?.organization ?? '');
	let country = $state(store.profile?.country ?? '');
	let contactOpen = $state(false);

	const charsLeft = $derived(MAX_MESSAGE_LENGTH - message.length);
	const sending = $derived(store.sendState === 'sending');

	function onSubmit(event: SubmitEvent) {
		event.preventDefault();
		if (role === '') {
			store.formErrors = ['feedback.errors.roleRequired'];
			return;
		}
		void store.submit({
			role,
			roleOther: roleOther || undefined,
			kind,
			rating,
			message,
			profile: {
				displayName: displayName || null,
				email: email || null,
				organization: organization || null,
				country: country || null
			}
		});
	}

	function selectTab(tab: 'send' | 'mine') {
		store.dialogTab = tab;
		if (tab === 'mine') {
			void store.refreshThread();
			void store.markThreadRead();
		}
	}

	function formatDate(iso: string): string {
		const parsed = new Date(iso);
		return Number.isNaN(parsed.getTime())
			? iso
			: parsed.toISOString().replace('T', ' ').slice(0, 16);
	}
</script>

<Modal
	open={store.dialogOpen}
	title={$_('feedback.dialog.title')}
	icon="feedback"
	maxWidthClass="max-w-xl"
	onclose={() => store.closeDialog()}
>
	<div class="flex flex-col gap-3 font-mono text-label-mono">
		<div class="flex gap-1 border-b border-outline-variant">
			{#each [['send', 'feedback.dialog.tabSend'], ['mine', 'feedback.dialog.tabMine']] as const as [tab, key] (tab)}
				<button
					type="button"
					class="rounded-t px-3 py-1 text-[11px] uppercase transition-colors {store.dialogTab ===
					tab
						? 'bg-primary-container/15 text-primary-container'
						: 'text-on-surface-variant hover:text-primary-container'}"
					onclick={() => selectTab(tab)}
				>
					{$_(key)}
					{#if tab === 'mine' && store.unreadReplies > 0}
						<span class="ml-1 inline-block h-1.5 w-1.5 rounded-full bg-error align-middle"></span>
					{/if}
				</button>
			{/each}
		</div>

		{#if store.dialogTab === 'send'}
			{#if store.sendState === 'sent' || store.sendState === 'queued'}
				<p class="flex items-center gap-2 text-body-sm text-primary-container">
					<span class="material-symbols-outlined text-[18px]">
						{store.sendState === 'sent' ? 'check_circle' : 'schedule_send'}
					</span>
					{store.sendState === 'sent' ? $_('feedback.dialog.sent') : $_('feedback.dialog.queued')}
				</p>
				{#if store.queueDropped}
					<p class="text-[11px] text-dbz-heavy">{$_('feedback.queue.dropped')}</p>
				{/if}
				<div class="flex justify-end border-t border-outline-variant pt-3">
					<button
						type="button"
						class="rounded border border-outline-variant bg-surface-container-high px-3 py-1 text-on-surface transition-colors hover:border-primary-container"
						onclick={() => store.closeDialog()}
					>
						{$_('feedback.dialog.close')}
					</button>
				</div>
			{:else}
				<p class="text-body-sm text-on-surface-variant">{$_('feedback.dialog.intro')}</p>

				<form class="flex flex-col gap-3" onsubmit={onSubmit}>
					<div class="flex flex-wrap gap-3">
						<label class="flex flex-col gap-1">
							<span class="text-[11px] text-on-surface-variant">{$_('feedback.form.role')}</span>
							<select
								bind:value={role}
								class="cyan-glow w-48 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
							>
								<option value="">{$_('feedback.form.rolePlaceholder')}</option>
								{#each FEEDBACK_ROLES as value (value)}
									<option {value}>{$_(`feedback.roles.${value}`)}</option>
								{/each}
							</select>
						</label>

						{#if role === 'otro'}
							<label class="flex flex-col gap-1">
								<span class="text-[11px] text-on-surface-variant"
									>{$_('feedback.form.roleOther')}</span
								>
								<input
									bind:value={roleOther}
									class="cyan-glow w-48 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
								/>
							</label>
						{/if}

						<label class="flex flex-col gap-1">
							<span class="text-[11px] text-on-surface-variant">{$_('feedback.form.kind')}</span>
							<select
								bind:value={kind}
								class="cyan-glow w-40 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
							>
								{#each FEEDBACK_KINDS as value (value)}
									<option {value}>{$_(`feedback.kinds.${value}`)}</option>
								{/each}
							</select>
						</label>

						<label class="flex flex-col gap-1">
							<span class="text-[11px] text-on-surface-variant">{$_('feedback.form.rating')}</span>
							<select
								bind:value={rating}
								class="cyan-glow w-32 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
							>
								<option value={null}>{$_('feedback.form.ratingNone')}</option>
								{#each [1, 2, 3, 4, 5] as value (value)}
									<option {value}>{value}</option>
								{/each}
							</select>
						</label>
					</div>

					<label class="flex flex-col gap-1">
						<span class="text-[11px] text-on-surface-variant">{$_('feedback.form.message')}</span>
						<textarea
							bind:value={message}
							rows="5"
							maxlength={MAX_MESSAGE_LENGTH}
							placeholder={$_('feedback.form.messagePlaceholder')}
							class="cyan-glow w-full rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
						></textarea>
						<span class="self-end text-[11px] text-on-surface-variant">
							{$_('feedback.form.charsLeft', { values: { count: charsLeft } })}
						</span>
					</label>

					<details bind:open={contactOpen}>
						<summary class="cursor-pointer text-[11px] text-on-surface-variant"
							>{$_('feedback.dialog.contact')}</summary
						>
						<div class="mt-2 flex flex-wrap gap-3">
							<label class="flex flex-col gap-1">
								<span class="text-[11px] text-on-surface-variant"
									>{$_('feedback.form.displayName')}</span
								>
								<input
									bind:value={displayName}
									class="cyan-glow w-40 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
								/>
							</label>
							<label class="flex flex-col gap-1">
								<span class="text-[11px] text-on-surface-variant">{$_('feedback.form.email')}</span>
								<input
									bind:value={email}
									type="email"
									class="cyan-glow w-52 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
								/>
							</label>
							<label class="flex flex-col gap-1">
								<span class="text-[11px] text-on-surface-variant"
									>{$_('feedback.form.organization')}</span
								>
								<input
									bind:value={organization}
									class="cyan-glow w-40 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
								/>
							</label>
							<label class="flex flex-col gap-1">
								<span class="text-[11px] text-on-surface-variant"
									>{$_('feedback.form.country')}</span
								>
								<input
									bind:value={country}
									class="cyan-glow w-32 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
								/>
							</label>
						</div>
					</details>

					{#if store.formErrors.length > 0}
						<ul class="flex flex-col gap-1 text-[11px] text-dbz-heavy">
							{#each store.formErrors as key (key)}
								<li>{$_(key)}</li>
							{/each}
						</ul>
					{/if}

					{#if store.serverMessage}
						<p class="text-[11px] text-dbz-heavy">
							{$_('feedback.errors.rejected', { values: { detail: store.serverMessage } })}
						</p>
					{/if}

					{#if store.pending > 0}
						<p class="text-[11px] text-on-surface-variant">
							{$_('feedback.queue.pending', { values: { count: store.pending } })}
						</p>
					{/if}

					<p class="text-[11px] text-on-surface-variant">{$_('feedback.dialog.privacy')}</p>

					<div class="flex justify-end gap-2 border-t border-outline-variant pt-3">
						<button
							type="button"
							class="rounded border border-outline-variant bg-surface-container-high px-3 py-1 text-on-surface transition-colors hover:border-primary-container"
							onclick={() => store.closeDialog()}
						>
							{$_('feedback.dialog.close')}
						</button>
						<button
							type="submit"
							disabled={sending}
							class="flex items-center gap-1 rounded bg-primary-container px-3 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
						>
							<span class="material-symbols-outlined text-[16px]">send</span>
							{sending ? $_('feedback.dialog.sending') : $_('feedback.dialog.submit')}
						</button>
					</div>
				</form>
			{/if}
		{:else}
			{#if store.threadLoading}
				<p class="text-body-sm text-on-surface-variant">{$_('feedback.thread.loading')}</p>
			{:else if store.threadFailed}
				<p class="text-body-sm text-dbz-heavy">{$_('feedback.thread.error')}</p>
			{:else if store.thread.length === 0}
				<p class="text-body-sm text-on-surface-variant">{$_('feedback.thread.empty')}</p>
			{:else}
				<ul class="flex flex-col gap-3">
					{#each store.thread as item (item.id)}
						<li class="rounded border border-outline-variant bg-surface-container-high p-3">
							<div class="flex items-center justify-between gap-2 text-[11px]">
								<span class="text-primary-container uppercase"
									>{$_(`feedback.kinds.${item.kind}`)}</span
								>
								<span class="text-on-surface-variant"
									>{$_(`feedback.thread.status.${item.status}`)}</span
								>
							</div>
							<p class="mt-1 text-body-sm whitespace-pre-wrap text-on-surface">{item.message}</p>
							<p class="mt-1 text-[11px] text-on-surface-variant">
								{$_('feedback.thread.sentAt', { values: { value: formatDate(item.createdAt) } })}
							</p>

							{#if item.replies.length > 0}
								<div class="mt-2 border-t border-outline-variant pt-2">
									<p class="text-[11px] text-on-surface-variant uppercase">
										{$_('feedback.thread.replies')}
									</p>
									{#each item.replies as reply (reply.id)}
										<p class="mt-1 text-body-sm whitespace-pre-wrap text-primary-container">
											{reply.body}
										</p>
									{/each}
								</div>
							{:else}
								<p class="mt-2 text-[11px] text-on-surface-variant">
									{$_('feedback.thread.noReplies')}
								</p>
							{/if}
						</li>
					{/each}
				</ul>
			{/if}
		{/if}
	</div>
</Modal>
