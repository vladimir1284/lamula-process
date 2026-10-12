/**
 * Hand-kept mirror of lamula-webviewer's `shared/contract/feedback.ts`.
 *
 * Both products write to the SAME inbox (decision 50 in that repo's docs/decisiones.md); the
 * `app` field is what tells them apart, so it is required here, never defaulted. There is no
 * shared package or monorepo between the two repos -- if the source file changes, this one has
 * to be updated by hand. The enums have been stable since decision 39.
 *
 * No zod: the server is the authority on validation. What we do here is check what the user
 * typed before paying a round trip.
 */

export const FEEDBACK_ROLES = [
	'profesor',
	'meteorologo',
	'investigador',
	'estudiante',
	'aficionado',
	'otro'
] as const;
export type FeedbackRole = (typeof FEEDBACK_ROLES)[number];

export const FEEDBACK_KINDS = ['mejora', 'bug', 'dato', 'otro'] as const;
export type FeedbackKind = (typeof FEEDBACK_KINDS)[number];

export const FEEDBACK_STATUSES = ['nuevo', 'leido', 'respondido', 'cerrado'] as const;
export type FeedbackStatus = (typeof FEEDBACK_STATUSES)[number];

export const FEEDBACK_APPS = ['webviewer', 'process'] as const;
export type FeedbackApp = (typeof FEEDBACK_APPS)[number];

/** This repo only ever sends one of them. */
export const THIS_APP: FeedbackApp = 'process';

export const MAX_MESSAGE_LENGTH = 5000;

export interface FeedbackProfile {
	role: FeedbackRole;
	roleOther?: string | null;
	displayName?: string | null;
	email?: string | null;
	organization?: string | null;
	country?: string | null;
	locale?: string | null;
}

export type FeedbackContext = Record<string, unknown>;

export interface FeedbackSubmission {
	app: FeedbackApp;
	kind: FeedbackKind;
	rating?: number | null;
	message: string;
	role: FeedbackRole;
	roleOther?: string | null;
	profile?: Partial<FeedbackProfile> | null;
	context?: FeedbackContext | null;
}

export interface AdminReply {
	id: string;
	feedbackId: string;
	body: string;
	author: string;
	createdAt: string;
	readAt?: string | null;
}

export interface FeedbackThreadItem {
	id: string;
	kind: FeedbackKind;
	rating?: number | null;
	message: string;
	status: FeedbackStatus;
	createdAt: string;
	context?: FeedbackContext | null;
	replies: AdminReply[];
}

export function isFeedbackRole(v: unknown): v is FeedbackRole {
	return FEEDBACK_ROLES.includes(v as FeedbackRole);
}

export function isFeedbackKind(v: unknown): v is FeedbackKind {
	return FEEDBACK_KINDS.includes(v as FeedbackKind);
}

// Deliberately loose: the server's zod `.email()` is the real gate. This only catches the
// obvious typo before the user pays a round trip to find out.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Returns i18n KEYS, not sentences -- the caller runs them through `$_()`. Empty array = valid.
 */
export function validateSubmission(body: Partial<FeedbackSubmission>): string[] {
	const errors: string[] = [];

	if (!isFeedbackRole(body.role)) {
		errors.push('feedback.errors.roleRequired');
	} else if (body.role === 'otro' && !body.roleOther?.trim()) {
		errors.push('feedback.errors.roleOtherRequired');
	}

	if (!isFeedbackKind(body.kind)) {
		errors.push('feedback.errors.kindRequired');
	}

	const message = body.message?.trim() ?? '';
	if (message.length === 0) {
		errors.push('feedback.errors.messageRequired');
	} else if (message.length > MAX_MESSAGE_LENGTH) {
		errors.push('feedback.errors.messageTooLong');
	}

	if (body.rating !== undefined && body.rating !== null) {
		if (!Number.isInteger(body.rating) || body.rating < 1 || body.rating > 5) {
			errors.push('feedback.errors.ratingRange');
		}
	}

	const email = body.profile?.email?.trim();
	if (email && !EMAIL_RE.test(email)) {
		errors.push('feedback.errors.emailInvalid');
	}

	return errors;
}
