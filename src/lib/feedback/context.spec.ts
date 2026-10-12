import { afterEach, describe, expect, it, vi } from 'vitest';
import { buildContext, type FeedbackContextInput } from './context';

afterEach(() => vi.unstubAllGlobals());

const FULL: FeedbackContextInput = {
	format: 'insmet',
	siteCode: 'rdCMW',
	elevationDeg: 1.5,
	productsOpen: ['ppi', 'rhi'],
	paletteName: 'dbz-nws',
	filtersActive: ['speckle'],
	locale: 'es'
};

describe('buildContext', () => {
	it('marca siempre producto, plataforma, build y clientId', () => {
		const context = buildContext();
		expect(context.app).toBe('process');
		expect(context.platform).toBe('web');
		expect(typeof context.buildId).toBe('string');
		expect(context.clientId).toMatch(/[0-9a-f-]{36}/);
	});

	it('respeta el clientId recibido, para que cuadre con la cola', () => {
		expect(buildContext({ clientId: 'fijo' }).clientId).toBe('fijo');
	});

	it('copia los campos de diagnóstico permitidos', () => {
		const context = buildContext(FULL);
		expect(context).toMatchObject({
			format: 'insmet',
			siteCode: 'rdCMW',
			elevationDeg: 1.5,
			productsOpen: ['ppi', 'rhi'],
			paletteName: 'dbz-nws',
			filtersActive: ['speckle'],
			locale: 'es'
		});
	});

	it('omite los campos vacíos en vez de mandar nulos', () => {
		const context = buildContext({ format: null, productsOpen: [], elevationDeg: Number.NaN });
		expect('format' in context).toBe(false);
		expect('productsOpen' in context).toBe(false);
		expect('elevationDeg' in context).toBe(false);
	});

	it('no se queda con la referencia de los arrays del llamante', () => {
		const productsOpen = ['ppi'];
		const context = buildContext({ productsOpen });
		productsOpen.push('vil');
		expect(context.productsOpen).toEqual(['ppi']);
	});

	it('recoge viewport y userAgent cuando existen', () => {
		vi.stubGlobal('window', { innerWidth: 1920, innerHeight: 1080 });
		vi.stubGlobal('navigator', { userAgent: 'Mozilla/5.0 (X11)' });

		const context = buildContext();
		expect(context.viewport).toBe('1920x1080');
		expect(context.userAgent).toBe('Mozilla/5.0 (X11)');
	});

	// PUERTA DE PRIVACIDAD. Son ficheros operativos del INSMET y del IDEAM: ni el nombre ni la
	// ruta del fichero abierto pueden salir de la máquina del usuario, nunca.
	it('el payload serializado no contiene ningún nombre ni ruta de fichero', () => {
		const leaky = {
			...FULL,
			fileName: 'KBYX20260726_113948_V06',
			label: 'rdCMW_20260726_1139.obs',
			path: '/datos/insmet/rdCMW/20260726/1139.obs',
			s3Key: '2026/07/26/KBYX/KBYX20260726_113948_V06'
		} as FeedbackContextInput;

		const serialized = JSON.stringify(buildContext(leaky));

		expect(serialized).not.toContain('KBYX20260726_113948_V06');
		expect(serialized).not.toContain('.obs');
		expect(serialized).not.toContain('/datos/');
		expect(serialized).not.toContain('s3Key');
		// Y lo que sí debe estar, está: con esto se reproduce el bug.
		expect(serialized).toContain('rdCMW');
		expect(serialized).toContain('insmet');
	});

	it('la lista de claves está cerrada: nada nuevo se cuela sin tocar este módulo', () => {
		// `viewport` y `userAgent` dependen del entorno, así que se comprueba pertenencia, no
		// igualdad: lo que importa es que NO pueda aparecer una clave fuera de esta lista.
		const allowed = new Set([
			'app',
			'buildId',
			'clientId',
			'elevationDeg',
			'filtersActive',
			'format',
			'locale',
			'paletteName',
			'platform',
			'productsOpen',
			'siteCode',
			'userAgent',
			'viewport'
		]);

		vi.stubGlobal('window', { innerWidth: 800, innerHeight: 600 });
		vi.stubGlobal('navigator', { userAgent: 'test' });

		const keys = Object.keys(buildContext(FULL));
		expect(keys).toContain('viewport');
		for (const key of keys) {
			expect(allowed.has(key), `clave inesperada en el contexto: ${key}`).toBe(true);
		}
	});
});
