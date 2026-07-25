export { rasterizePPI } from './rasterizePPI';
export type { RasterOptions, RasterResult } from './rasterizePPI';
export {
	sampleGround,
	buildAzimuthLUT,
	rayCentersDeg,
	gateForGroundRange,
	maxGroundRangeM,
	normDeg
} from './scanSample';
export type { SampleResult, AzimuthLUT } from './scanSample';
export { PpiRenderer } from './renderClient';
export { rasterizeRHI, rayElevationsDeg, nearestRayByElev, rhiReadoutAt } from './rasterizeRHI';
export type { RhiRasterOptions, RhiRasterResult, RhiReadout } from './rasterizeRHI';
export { makeRhiScan } from './rhiFixtures';
