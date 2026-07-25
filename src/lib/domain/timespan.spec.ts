import { describe, it, expect } from 'vitest';
import type { Observation } from './types';
import { createTimeSpan, firstTimeMs, lastTimeMs, maxTimeGapMs, parseTmsList } from './timespan';

function obs(code: string, timestamp: string): Observation {
	return {
		id: `${code}-${timestamp}`,
		site: { name: code, code },
		timestamp,
		design: 'VCP_11',
		movements: []
	};
}

describe('createTimeSpan', () => {
	it('sorts observations ascending by time', () => {
		const { span } = createTimeSpan([
			obs('CMW', '2026-07-25T12:10:00Z'),
			obs('CMW', '2026-07-25T12:00:00Z'),
			obs('CMW', '2026-07-25T12:05:00Z')
		]);
		expect(span.observations.map((o) => o.timestamp)).toEqual([
			'2026-07-25T12:00:00Z',
			'2026-07-25T12:05:00Z',
			'2026-07-25T12:10:00Z'
		]);
	});

	it('drops observations from a different radar and reports them', () => {
		const { span, skipped } = createTimeSpan([
			obs('CMW', '2026-07-25T12:00:00Z'),
			obs('HAV', '2026-07-25T12:05:00Z')
		]);
		expect(span.observations).toHaveLength(1);
		expect(skipped).toHaveLength(1);
		expect(skipped[0].site.code).toBe('HAV');
	});

	it('computes first/last time and the largest gap', () => {
		const { span } = createTimeSpan([
			obs('CMW', '2026-07-25T12:00:00Z'),
			obs('CMW', '2026-07-25T12:05:00Z'),
			obs('CMW', '2026-07-25T12:20:00Z')
		]);
		expect(lastTimeMs(span) - firstTimeMs(span)).toBe(20 * 60 * 1000);
		expect(maxTimeGapMs(span)).toBe(15 * 60 * 1000);
	});
});

describe('parseTmsList', () => {
	it('reads one relative path per non-empty line', () => {
		expect(parseTmsList('a.obs\r\nsub/b.vol\n\n  c.gz  \n')).toEqual([
			'a.obs',
			'sub/b.vol',
			'c.gz'
		]);
	});
});
