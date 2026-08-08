import type { MomentType } from '$lib/domain/types';
import type { Palette, ProductPaletteKey } from './types';
import { defaultDbzPalette } from './default';

/**
 * Built-in palette group: one physical-unit color scale per moment the app decodes
 * (src/lib/domain/types.ts `MomentType`). Thresholds, ranges and label steps are taken from the
 * NEXRAD CVG legend proposals the user supplied (the `legends/*.lgd` files, since removed): those
 * files carry physical scales + tick labels but only palette *indices*, not RGB, so the colors
 * here are standard published radar ramps rather than a byte-for-byte port. Stops are in the same
 * physical units the parsers decode into (dBZ, m/s, dB, degrees, unitless) so `colorForValue`
 * (a step lookup) can be fed channel values directly.
 *
 * All of this is a *seed*: the palette book store (platform/paletteStore.ts) copies these in on
 * first run and lets the user edit both the palettes and the moment->palette assignment.
 */

// Reflectivity (dBZ). Reuses the standard NWS ramp already shipped as the P1 default; renamed to
// match the legacy Vesta palette title (legacy/Palettes/DBZ.pal "Reflectividad"). Proposal range
// refl_5/hires_refl span roughly -30..85 dBZ; the common 5..70 ramp is kept.
const reflectivity: Palette = {
	name: 'Reflectividad',
	smooth: false,
	stops: defaultDbzPalette.stops.map((s) => ({ ...s }))
};

// Radial velocity (V), m/s. Bidirectional: greens inbound (negative), reds outbound (positive),
// grey near zero. Thresholds from vel_2.lgd (-64..+56 by 8 m/s).
const velocity: Palette = {
	name: 'Velocidad radial',
	smooth: false,
	stops: [
		{ value: -64, color: [0, 224, 224], caption: '-64' },
		{ value: -56, color: [0, 192, 192], caption: '-56' },
		{ value: -48, color: [0, 160, 160], caption: '-48' },
		{ value: -40, color: [0, 128, 255], caption: '-40' },
		{ value: -32, color: [0, 100, 0], caption: '-32' },
		{ value: -24, color: [0, 160, 0], caption: '-24' },
		{ value: -16, color: [0, 210, 0], caption: '-16' },
		{ value: -8, color: [130, 255, 130], caption: '-8' },
		{ value: 0, color: [160, 160, 160], caption: '0' },
		{ value: 8, color: [255, 140, 140], caption: '8' },
		{ value: 16, color: [255, 0, 0], caption: '16' },
		{ value: 24, color: [210, 0, 0], caption: '24' },
		{ value: 32, color: [160, 0, 0], caption: '32' },
		{ value: 40, color: [255, 128, 0], caption: '40' },
		{ value: 48, color: [255, 192, 0], caption: '48' },
		{ value: 56, color: [255, 255, 0], caption: '56' }
	]
};

// Spectrum width (W), m/s. Grey -> blue -> green -> yellow -> red. Range from hires_spw_2.lgd
// (0..30 m/s), color feel from legacy/Palettes/W.pal "Ancho_Espectral".
const spectrumWidth: Palette = {
	name: 'Ancho espectral',
	smooth: false,
	stops: [
		{ value: 0, color: [176, 176, 176], caption: '0' },
		{ value: 4, color: [0, 0, 200], caption: '4' },
		{ value: 8, color: [0, 96, 255], caption: '8' },
		{ value: 12, color: [0, 210, 255], caption: '12' },
		{ value: 16, color: [0, 200, 0], caption: '16' },
		{ value: 20, color: [255, 255, 0], caption: '20' },
		{ value: 24, color: [255, 128, 0], caption: '24' },
		{ value: 30, color: [255, 0, 0], caption: '30' }
	]
};

// Differential reflectivity (ZDR), dB. Diverging around 0. Range from zdr_raw_5.lgd
// (scale 16, offset 128 => physical (level-offset)/scale, i.e. about -7..+7 dB).
const zdr: Palette = {
	name: 'ZDR',
	smooth: false,
	stops: [
		{ value: -7, color: [0, 0, 128], caption: '-7' },
		{ value: -4, color: [0, 0, 255], caption: '-4' },
		{ value: -2, color: [0, 200, 255], caption: '-2' },
		{ value: -1, color: [0, 200, 0], caption: '-1' },
		{ value: 0, color: [160, 160, 160], caption: '0' },
		{ value: 1, color: [255, 255, 0], caption: '1' },
		{ value: 2, color: [255, 160, 0], caption: '2' },
		{ value: 4, color: [255, 0, 0], caption: '4' },
		{ value: 7, color: [180, 0, 0], caption: '7' }
	]
};

// Differential phase (uPhiDP), degrees. Rainbow across the 0..360 span from phi_raw_5.lgd.
const phiDp: Palette = {
	name: 'PhiDP',
	smooth: false,
	stops: [
		{ value: 0, color: [0, 0, 255], caption: '0' },
		{ value: 45, color: [0, 128, 255], caption: '45' },
		{ value: 90, color: [0, 210, 210], caption: '90' },
		{ value: 135, color: [0, 200, 0], caption: '135' },
		{ value: 180, color: [255, 255, 0], caption: '180' },
		{ value: 225, color: [255, 160, 0], caption: '225' },
		{ value: 270, color: [255, 0, 0], caption: '270' },
		{ value: 315, color: [200, 0, 128], caption: '315' },
		{ value: 360, color: [128, 0, 255], caption: '360' }
	]
};

// Correlation coefficient (RhoHV), unitless 0..1. Range/labels from cc_064.lgd & cc_raw_5.lgd
// (scale 300, offset -60 => physical (level-offset)/300, i.e. about 0.2..1.0).
const rhoHv: Palette = {
	name: 'RhoHV',
	smooth: false,
	stops: [
		{ value: 0.2, color: [0, 0, 128], caption: '0.20' },
		{ value: 0.45, color: [0, 0, 255], caption: '0.45' },
		{ value: 0.65, color: [0, 200, 255], caption: '0.65' },
		{ value: 0.8, color: [0, 200, 0], caption: '0.80' },
		{ value: 0.9, color: [255, 255, 0], caption: '0.90' },
		{ value: 0.93, color: [255, 160, 0], caption: '0.93' },
		{ value: 0.96, color: [255, 0, 0], caption: '0.96' },
		{ value: 0.98, color: [180, 0, 0], caption: '0.98' },
		{ value: 1.0, color: [128, 0, 128], caption: '1.00' }
	]
};

// Specific differential phase (KDP), °/km. No legend proposal covered this moment (KDP wasn't
// among the .lgd files); thresholds/colors follow the common published dual-pol KDP operational
// range (-2..8 °/km, diverging around 0 like ZDR) rather than a Vesta-legacy or NEXRAD scale.
const kdp: Palette = {
	name: 'KDP',
	smooth: false,
	stops: [
		{ value: -2, color: [0, 0, 128], caption: '-2' },
		{ value: -1, color: [0, 0, 255], caption: '-1' },
		{ value: 0, color: [160, 160, 160], caption: '0' },
		{ value: 1, color: [0, 200, 0], caption: '1' },
		{ value: 2, color: [255, 255, 0], caption: '2' },
		{ value: 3, color: [255, 160, 0], caption: '3' },
		{ value: 5, color: [255, 0, 0], caption: '5' },
		{ value: 8, color: [180, 0, 0], caption: '8' }
	]
};

// Echo-top / column-max height, metres. `computeTops`/`computeMaxs` (products/tops.ts,
// products/maxs.ts) report a height, not a moment, so it can't share the reflectivity ramp --
// 1500 m of echo top isn't "5 dBZ". Thresholds from `hreet.lgd` (NEXRAD "echo top" legend: 14
// levels, 5 kft steps up to 70 kft), converted to round 1500 m (~5 kft) steps; colors are
// reflectivity's ramp index-paired onto the new thresholds (same severity-progression feel, see
// [[project_palette_book]]).
const topsHeight: Palette = {
	name: 'Topes (altura)',
	smooth: false,
	stops: [
		1500, 3000, 4500, 6000, 7500, 9000, 10500, 12000, 13500, 15000, 16500, 18000, 19500, 21000
	].map((value, i) => ({ value, color: defaultDbzPalette.stops[i].color, caption: String(value) }))
};

// VIL (Vertically Integrated Liquid), kg/m². `computeVil` (products/vil.ts) integrates dBZ into a
// different physical quantity, so it needs its own scale. Thresholds from `dvil_2.lgd` (NEXRAD
// "Digital VIL" legend, exact kg/m² values for its 14 levels -- the nonlinear growth is the real
// product's, not a guess); colors are reflectivity's ramp index-paired onto them, same rationale
// as `topsHeight`.
const vil: Palette = {
	name: 'VIL',
	smooth: false,
	stops: [0.05, 0.19, 0.36, 0.66, 1.23, 2.11, 3.63, 6.23, 9.89, 15.7, 25.0, 36.7, 54.0, 80].map(
		(value, i) => ({ value, color: defaultDbzPalette.stops[i].color, caption: String(value) })
	)
};

// Rain rate, mm/h (products/rainRate.ts, Z-R relation). No legend proposal covered this product;
// thresholds are the common light/moderate/heavy/violent rain-rate breakpoints, ramped blue (light)
// through green/yellow/orange to red/magenta (extreme) like other published precip-rate scales.
const rainRate: Palette = {
	name: 'Intensidad de lluvia',
	smooth: false,
	stops: [
		{ value: 1, color: [4, 233, 231], caption: '1' },
		{ value: 2, color: [1, 159, 244], caption: '2' },
		{ value: 5, color: [2, 253, 2], caption: '5' },
		{ value: 10, color: [1, 197, 1], caption: '10' },
		{ value: 20, color: [253, 248, 2], caption: '20' },
		{ value: 30, color: [229, 188, 0], caption: '30' },
		{ value: 50, color: [253, 149, 0], caption: '50' },
		{ value: 75, color: [253, 0, 0], caption: '75' },
		{ value: 100, color: [212, 0, 0], caption: '100' },
		{ value: 150, color: [248, 0, 253], caption: '150' }
	]
};

// Wind speed (products/wind.ts), m/s -- unsigned magnitude, unlike the bidirectional Doppler `V`
// moment. Reuses the outbound (positive) half of the `velocity` ramp below: same unit, same
// severity feel, no new colors invented.
const windSpeed: Palette = {
	name: 'Velocidad del viento',
	smooth: false,
	stops: [
		{ value: 0, color: [160, 160, 160], caption: '0' },
		{ value: 8, color: [255, 140, 140], caption: '8' },
		{ value: 16, color: [255, 0, 0], caption: '16' },
		{ value: 24, color: [210, 0, 0], caption: '24' },
		{ value: 32, color: [160, 0, 0], caption: '32' },
		{ value: 40, color: [255, 128, 0], caption: '40' },
		{ value: 48, color: [255, 192, 0], caption: '48' },
		{ value: 56, color: [255, 255, 0], caption: '56' }
	]
};

// Accumulated precipitation, mm depth (products/accumulate.ts). Different physical quantity from
// `rainRate`'s mm/h -- storm-total depth, not instantaneous rate -- so it needs its own scale even
// though the unit label looks similar. `legacy/Palettes/MM.pal` ("Precipitación") exists but, like
// `MMH.pal` before it, its raw byte stops have no known decode formula; thresholds here are the
// common published storm-total depth bands (light/moderate/heavy/extreme) instead, same convention
// already used for `rainRate` in this file.
// i18n-ignore: palette name, a user-editable library entry like every other name in this file
// (Reflectividad, Intensidad de lluvia, ...), not app-chrome copy routed through the locale files.
const accumulate: Palette = {
	name: 'Precipitación acumulada',
	smooth: false,
	stops: [
		{ value: 1, color: [4, 233, 231], caption: '1' },
		{ value: 5, color: [1, 159, 244], caption: '5' },
		{ value: 10, color: [2, 253, 2], caption: '10' },
		{ value: 25, color: [1, 197, 1], caption: '25' },
		{ value: 50, color: [253, 248, 2], caption: '50' },
		{ value: 75, color: [229, 188, 0], caption: '75' },
		{ value: 100, color: [253, 149, 0], caption: '100' },
		{ value: 150, color: [253, 0, 0], caption: '150' },
		{ value: 200, color: [212, 0, 0], caption: '200' },
		{ value: 300, color: [248, 0, 253], caption: '300' }
	]
};

/** The built-in palette library, in a stable display order. */
export const defaultPalettes: Palette[] = [
	reflectivity,
	velocity,
	spectrumWidth,
	zdr,
	phiDp,
	rhoHv,
	kdp,
	topsHeight,
	vil,
	rainRate,
	windSpeed,
	accumulate
];

/**
 * Default moment -> palette-name assignment. `dBZ` and `dBuZ` (corrected/uncorrected
 * reflectivity) share the reflectivity ramp since they carry the same units.
 */
export const defaultAssignments: Record<MomentType, string> = {
	dBZ: 'Reflectividad',
	dBuZ: 'Reflectividad',
	V: 'Velocidad radial',
	W: 'Ancho espectral',
	ZDR: 'ZDR',
	uPhiDP: 'PhiDP',
	RhoHV: 'RhoHV',
	KDP: 'KDP'
};

/**
 * Default assignment for derived ground products (see `ProductPaletteKey`). `COLUMN_MAX` isn't
 * here -- it reports the source moment's own unit (`valueUnit: momentUnit(channel.moment)`), so it
 * correctly keeps following the channel's moment assignment above.
 */
// i18n-ignore: values reference palette names (see `accumulate` above), not app-chrome copy.
export const defaultProductAssignments: Record<ProductPaletteKey, string> = {
	TOPS_HEIGHT: 'Topes (altura)',
	VIL: 'VIL',
	RAIN: 'Intensidad de lluvia',
	WIND_SPEED: 'Velocidad del viento',
	ACCUMULATE: 'Precipitación acumulada' // i18n-ignore: palette name, see `accumulate` above
};
