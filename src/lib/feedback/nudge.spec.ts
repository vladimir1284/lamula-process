import { describe, expect, it } from 'vitest';
import { defaultNudgeState, type NudgeState } from './identity';
import {
	MAX_SHOWS,
	MIN_UPTIME_MS,
	SNOOZE_MS,
	dismissNudgeForever,
	markFeedbackSubmitted,
	markNudgeShown,
	shouldShowNudge,
	snoozeNudge
} from './nudge';

const BOOT = 1_700_000_000_000;

function input(over: Partial<Parameters<typeof shouldShowNudge>[0]> = {}) {
	return {
		state: defaultNudgeState(),
		now: BOOT + MIN_UPTIME_MS,
		bootedAt: BOOT,
		productWindowClosed: true,
		shownThisSession: false,
		...over
	};
}

describe('shouldShowNudge', () => {
	it('aparece tras cerrar el primer producto, pasado el minuto', () => {
		expect(shouldShowNudge(input())).toBe(true);
	});

	// El disparador no es tiempo de sesión: mirar un mapa no es haber usado la app.
	it('no aparece si todavía no se cerró ningún producto, por mucho que pase el tiempo', () => {
		expect(
			shouldShowNudge(input({ productWindowClosed: false, now: BOOT + 10 * MIN_UPTIME_MS }))
		).toBe(false);
	});

	it('no aparece antes de 60 s desde el arranque', () => {
		expect(shouldShowNudge(input({ now: BOOT + MIN_UPTIME_MS - 1 }))).toBe(false);
		expect(shouldShowNudge(input({ now: BOOT + MIN_UPTIME_MS }))).toBe(true);
	});

	it('no aparece dos veces en la misma sesión', () => {
		expect(shouldShowNudge(input({ shownThisSession: true }))).toBe(false);
	});

	it('tope de 3 apariciones en la vida del navegador', () => {
		let state: NudgeState = defaultNudgeState();
		for (let i = 0; i < MAX_SHOWS; i++) {
			expect(shouldShowNudge(input({ state }))).toBe(true);
			state = markNudgeShown(state);
		}
		expect(state.shownCount).toBe(MAX_SHOWS);
		expect(shouldShowNudge(input({ state }))).toBe(false);
	});

	it('"más tarde" lo pospone exactamente 3 días', () => {
		const state = snoozeNudge(defaultNudgeState(), BOOT);
		expect(state.snoozeUntil).toBe(BOOT + SNOOZE_MS);

		expect(shouldShowNudge(input({ state, now: BOOT + SNOOZE_MS - 1 }))).toBe(false);
		expect(shouldShowNudge(input({ state, now: BOOT + SNOOZE_MS }))).toBe(true);
	});

	// El webviewer devuelve 7 días acá, lo que contradice el propio botón.
	it('"no, gracias" es permanente', () => {
		const state = dismissNudgeForever(defaultNudgeState());
		expect(shouldShowNudge(input({ state, now: BOOT + 365 * SNOOZE_MS }))).toBe(false);
	});

	it('tras enviar no vuelve a aparecer', () => {
		const state = markFeedbackSubmitted(defaultNudgeState());
		expect(shouldShowNudge(input({ state }))).toBe(false);
	});

	it('las transiciones no mutan el estado recibido', () => {
		const state = defaultNudgeState();
		markNudgeShown(state);
		snoozeNudge(state, BOOT);
		dismissNudgeForever(state);
		markFeedbackSubmitted(state);
		expect(state).toEqual(defaultNudgeState());
	});
});
