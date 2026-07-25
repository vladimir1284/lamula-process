import { describe, it, expect } from 'vitest';
import { parseXml, child, children, childText, requireChild, requireAttr } from './xml';

describe('parseXml', () => {
	it('parses nested elements, attributes, self-closing tags and leaf text', () => {
		const xml = `<volume version="5.34.56" datetime="2014-10-06T00:06:31">
			<scan name="HNS_250_ZVW_new.vol">
				<slice refid="0">
					<dynz min="-31.5" max="95.5"/>
					<posangle>0.0</posangle>
				</slice>
				<slice refid="1">
					<posangle>0.5</posangle>
				</slice>
			</scan>
			<sensorinfo id="HNS" name="Tegucigalpa">
				<lon>-87.130992</lon>
			</sensorinfo>
		</volume>`;

		const root = parseXml(xml);
		const volume = requireChild(root, 'volume');
		expect(volume.attrs.version).toBe('5.34.56');

		const scan = requireChild(volume, 'scan');
		const slices = children(scan, 'slice');
		expect(slices).toHaveLength(2);
		expect(slices[0].attrs.refid).toBe('0');
		expect(childText(slices[0], 'posangle')).toBe('0.0');

		const dynz = requireChild(slices[0], 'dynz');
		expect(dynz.attrs).toEqual({ min: '-31.5', max: '95.5' });
		expect(dynz.children).toHaveLength(0);

		const sensorinfo = requireChild(volume, 'sensorinfo');
		expect(requireAttr(sensorinfo, 'id')).toBe('HNS');
		expect(childText(sensorinfo, 'lon')).toBe('-87.130992');

		expect(child(volume, 'nonexistent')).toBeUndefined();
	});

	it('requireChild/requireAttr throw with a descriptive message when missing', () => {
		const root = parseXml('<a><b/></a>');
		const a = requireChild(root, 'a');
		expect(() => requireChild(a, 'missing')).toThrow(/expected <a> to have a <missing> child/);
		const b = requireChild(a, 'b');
		expect(() => requireAttr(b, 'missing')).toThrow(/expected <b> to have attribute "missing"/);
	});
});
