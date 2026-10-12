import { describe, expect, it } from 'vitest';
import es from '../i18n/locales/es.json';
import en from '../i18n/locales/en.json';
import {
	FEEDBACK_APPS,
	MAX_MESSAGE_LENGTH,
	THIS_APP,
	validateSubmission,
	type FeedbackSubmission
} from './contract';

function lookup(bundle: unknown, key: string): unknown {
	return key.split('.').reduce<unknown>((node, part) => {
		if (typeof node !== 'object' || node === null) return undefined;
		return (node as Record<string, unknown>)[part];
	}, bundle);
}

const VALID: FeedbackSubmission = {
	app: THIS_APP,
	kind: 'mejora',
	message: 'El RHI se ve cortado al final del barrido.',
	role: 'meteorologo'
};

describe('validateSubmission', () => {
	it('acepta un envío mínimo válido', () => {
		expect(validateSubmission(VALID)).toEqual([]);
	});

	it('exige ocupación y mensaje', () => {
		const errors = validateSubmission({ app: THIS_APP, kind: 'bug', message: '   ' });
		expect(errors).toContain('feedback.errors.roleRequired');
		expect(errors).toContain('feedback.errors.messageRequired');
	});

	it('exige el texto libre cuando la ocupación es "otro"', () => {
		expect(validateSubmission({ ...VALID, role: 'otro' })).toEqual([
			'feedback.errors.roleOtherRequired'
		]);
		expect(validateSubmission({ ...VALID, role: 'otro', roleOther: 'Piloto' })).toEqual([]);
	});

	it('corta el mensaje en el mismo límite que el servidor', () => {
		expect(validateSubmission({ ...VALID, message: 'a'.repeat(MAX_MESSAGE_LENGTH) })).toEqual([]);
		expect(validateSubmission({ ...VALID, message: 'a'.repeat(MAX_MESSAGE_LENGTH + 1) })).toEqual([
			'feedback.errors.messageTooLong'
		]);
	});

	it('acepta valoración ausente y rechaza la fuera de rango', () => {
		expect(validateSubmission({ ...VALID, rating: null })).toEqual([]);
		expect(validateSubmission({ ...VALID, rating: 5 })).toEqual([]);
		expect(validateSubmission({ ...VALID, rating: 0 })).toEqual(['feedback.errors.ratingRange']);
		expect(validateSubmission({ ...VALID, rating: 2.5 })).toEqual(['feedback.errors.ratingRange']);
	});

	it('rechaza un email con forma imposible, pero no exige email', () => {
		expect(validateSubmission({ ...VALID, profile: { email: '' } })).toEqual([]);
		expect(validateSubmission({ ...VALID, profile: { email: 'pepe@insmet.cu' } })).toEqual([]);
		expect(validateSubmission({ ...VALID, profile: { email: 'pepe@' } })).toEqual([
			'feedback.errors.emailInvalid'
		]);
	});

	// Si esto falla, la UI mostraría la clave cruda en vez de una frase.
	it('todas las claves devueltas existen en los dos idiomas', () => {
		const keys = new Set<string>();
		for (const body of [
			{},
			{ app: THIS_APP, kind: 'bug' as const, message: '', role: 'otro' as const },
			{ ...VALID, message: 'a'.repeat(MAX_MESSAGE_LENGTH + 1), rating: 9 },
			{ ...VALID, profile: { email: 'x' } }
		]) {
			for (const key of validateSubmission(body)) keys.add(key);
		}

		expect(keys.size).toBeGreaterThan(0);
		for (const key of keys) {
			expect(typeof lookup(es, key), `${key} falta en es.json`).toBe('string');
			expect(typeof lookup(en, key), `${key} falta en en.json`).toBe('string');
		}
	});
});

describe('contrato espejo del webviewer', () => {
	it('conoce los dos productos y solo manda el suyo', () => {
		expect(FEEDBACK_APPS).toEqual(['webviewer', 'process']);
		expect(THIS_APP).toBe('process');
	});
});
