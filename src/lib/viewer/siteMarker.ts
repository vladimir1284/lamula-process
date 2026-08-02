import Feature from 'ol/Feature';
import Point from 'ol/geom/Point';
import { Style, Circle as CircleStyle, Stroke, Fill } from 'ol/style';

/**
 * Radar site position marker for the PPI overlay -- legacy's "Ubicación del Radar" toggle
 * (legacy/Forms/SettingsForm.pas `ShowRadar`) had no equivalent here at all (nothing drew it, see
 * [[project_settings_panel_audit]]). One feature, centred at the site in EPSG:3857.
 */
export function siteMarkerFeature(center3857: [number, number]): Feature {
	return new Feature(new Point(center3857));
}

export function siteMarkerStyle(): Style {
	return new Style({
		image: new CircleStyle({
			radius: 5,
			fill: new Fill({ color: '#f97316' }),
			stroke: new Stroke({ color: '#0b0f14', width: 2 })
		})
	});
}
