import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'fs';
import { execSync, spawnSync } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');
const staticDir = path.join(rootDir, 'static');
const scratchDir = path.join(rootDir, '.temp_assets');

mkdirSync(staticDir, { recursive: true });
mkdirSync(scratchDir, { recursive: true });

console.log('Generating app icon variants and favicons from logo-gear.svg...');

// 1. Copy raw logo to static/logo.svg
const originalSvgPath = path.join(rootDir, 'logo-gear.svg');
copyFileSync(originalSvgPath, path.join(staticDir, 'logo.svg'));

// 2. Square crop for favicon.svg: viewBox units match the mm width/height here,
// so center the shorter axis inside a square sized to the longer one.
const svgRaw = readFileSync(originalSvgPath, 'utf8');
const width = Number(svgRaw.match(/width="([\d.]+)mm"/)[1]);
const height = Number(svgRaw.match(/height="([\d.]+)mm"/)[1]);
const side = Math.max(width, height);
const minX = width < side ? -(side - width) / 2 : 0;
const minY = height < side ? -(side - height) / 2 : 0;

const squareSvg = svgRaw
	.replace(/width="[\d.]+mm"/, 'width="512"')
	.replace(/height="[\d.]+mm"/, 'height="512"')
	.replace(/viewBox="0 0 [\d.]+ [\d.]+"/, `viewBox="${minX} ${minY} ${side} ${side}"`);

writeFileSync(path.join(staticDir, 'favicon.svg'), squareSvg);

// 3. Write site.webmanifest (pure Node, never needs ImageMagick)
console.log('Writing site.webmanifest...');
const webManifest = {
	name: 'LAMULA Process',
	short_name: 'LAMULA',
	description:
		'Procesamiento y visualización de radar meteorológico (NEXRAD Level II, Rainbow5, Vesta .obs)',
	icons: [
		{
			src: '/android-chrome-192x192.png',
			sizes: '192x192',
			type: 'image/png'
		},
		{
			src: '/android-chrome-512x512.png',
			sizes: '512x512',
			type: 'image/png'
		},
		{
			src: '/favicon.svg',
			sizes: 'any',
			type: 'image/svg+xml'
		}
	],
	theme_color: '#0b0e11',
	background_color: '#0b0e11',
	display: 'standalone',
	orientation: 'any',
	start_url: '/'
};

writeFileSync(path.join(staticDir, 'site.webmanifest'), JSON.stringify(webManifest, null, 2));

// 4. Resolve ImageMagick. ImageMagick 7 dropped `convert` in favour of `magick`.
const convertBin = ['convert', 'magick'].find(
	(bin) => spawnSync(bin, ['-version'], { stdio: 'ignore' }).status === 0
);

// Every raster below is committed to the repo, so a machine without ImageMagick
// can install and build with the icons already in the checkout. Only fail when
// one is actually missing.
const rasterOutputs = [
	'favicon-16x16.png',
	'favicon-32x32.png',
	'favicon-48x48.png',
	'icon-192.png',
	'icon-512.png',
	'android-chrome-192x192.png',
	'android-chrome-512x512.png',
	'favicon.ico',
	'apple-touch-icon.png',
	'og-image.png'
];

if (!convertBin) {
	const missing = rasterOutputs.filter((name) => !existsSync(path.join(staticDir, name)));
	rmSync(scratchDir, { recursive: true, force: true });
	if (missing.length > 0) {
		console.error(
			`ImageMagick not found and these icons are missing: ${missing.join(', ')}.\n` +
				'Install ImageMagick (apt install imagemagick) and run this script again.'
		);
		process.exit(1);
	}
	console.warn('ImageMagick not found; keeping the icons already in static/.');
	process.exit(0);
}

// 5. Generate PNG variants using ImageMagick
const sizes = [
	{ name: 'favicon-16x16.png', size: 16 },
	{ name: 'favicon-32x32.png', size: 32 },
	{ name: 'favicon-48x48.png', size: 48 },
	{ name: 'icon-192.png', size: 192 },
	{ name: 'icon-512.png', size: 512 },
	{ name: 'android-chrome-192x192.png', size: 192 },
	{ name: 'android-chrome-512x512.png', size: 512 }
];

for (const { name, size } of sizes) {
	const dest = path.join(staticDir, name);
	console.log(`Generating ${name} (${size}x${size})...`);
	execSync(
		`${convertBin} -background none "${path.join(staticDir, 'favicon.svg')}" -resize ${size}x${size} "${dest}"`
	);
}

// 6. Generate multi-resolution ICO file (favicon.ico)
console.log('Generating favicon.ico...');
execSync(
	`${convertBin} "${path.join(staticDir, 'favicon-16x16.png')}" "${path.join(staticDir, 'favicon-32x32.png')}" "${path.join(staticDir, 'favicon-48x48.png')}" "${path.join(staticDir, 'favicon.ico')}"`
);

// 7. Generate apple-touch-icon.png (180x180 on the app's dark background)
console.log('Generating apple-touch-icon.png (180x180 with dark background)...');
const appleIconSvg = `
<svg width="180" height="180" viewBox="0 0 180 180" xmlns="http://www.w3.org/2000/svg">
  <rect width="180" height="180" rx="36" fill="#0b0e11"/>
  <g transform="translate(18, 18) scale(0.84)">
    ${squareSvg.slice(squareSvg.indexOf('<g'), squareSvg.indexOf('</svg>'))}
  </g>
</svg>
`;
const tempAppleSvg = path.join(scratchDir, 'apple-touch-icon.svg');
writeFileSync(tempAppleSvg, appleIconSvg);
execSync(
	`${convertBin} -background none "${tempAppleSvg}" "${path.join(staticDir, 'apple-touch-icon.png')}"`
);

// 8. Generate Social OpenGraph Preview Card (og-image.png - 1200x630)
console.log('Generating og-image.png (1200x630)...');
const ogSvg = `
<svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0b0e11"/>
      <stop offset="100%" stop-color="#151a20"/>
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#51c5ab" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#51c5ab" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <!-- Background -->
  <rect width="1200" height="630" fill="url(#bgGrad)"/>
  <rect width="1200" height="630" fill="url(#glow)"/>

  <!-- Top Accent Bar -->
  <rect x="0" y="0" width="1200" height="6" fill="#00f0ff"/>

  <!-- Centered Logo Mark (400x400) -->
  <g transform="translate(400, 115) scale(2.32)">
    ${squareSvg.slice(squareSvg.indexOf('<g'), squareSvg.indexOf('</svg>'))}
  </g>
</svg>
`;
const tempOgSvg = path.join(scratchDir, 'og-image.svg');
writeFileSync(tempOgSvg, ogSvg);
execSync(`${convertBin} -background none "${tempOgSvg}" "${path.join(staticDir, 'og-image.png')}"`);

// Cleanup temp folder
rmSync(scratchDir, { recursive: true, force: true });

console.log('All favicons and icon variants successfully generated!');
