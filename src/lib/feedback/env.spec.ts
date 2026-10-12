import { describe, expect, it } from 'vitest';
import { buildId, feedbackApiBase, isFeedbackEnabled } from './env';

// Guards the `define` plumbing in vite.config.ts: if the constants stopped being injected these
// would throw ReferenceError instead of returning the fallbacks.
describe('constantes de build', () => {
	it('expone un buildId no vacío', () => {
		expect(buildId().length).toBeGreaterThan(0);
	});

	it('la base de la API no lleva barra final', () => {
		expect(feedbackApiBase()).not.toMatch(/\/$/);
	});

	it('la feature está encendida exactamente cuando hay base', () => {
		expect(isFeedbackEnabled()).toBe(feedbackApiBase().length > 0);
	});
});
