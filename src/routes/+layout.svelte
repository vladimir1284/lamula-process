<script lang="ts">
	import './layout.css';
	import { waitLocale } from '$lib/i18n';

	let { children } = $props();
</script>

<svelte:head>
	<title>LAMULA Process</title>
	<!-- i18n-ignore: static SEO/social-share metadata, not reactive app UI -->
	<meta
		name="description"
		content="Procesamiento y visualización de radar meteorológico: NEXRAD Level II, Rainbow5, Vesta .obs"
	/>
	<meta name="theme-color" content="#0b0e11" />

	<!-- Open Graph / Facebook -->
	<meta property="og:type" content="website" />
	<meta property="og:title" content="LAMULA Process" />
	<!-- i18n-ignore: static SEO/social-share metadata, not reactive app UI -->
	<meta
		property="og:description"
		content="Procesamiento y visualización de radar meteorológico: NEXRAD Level II, Rainbow5, Vesta .obs"
	/>
	<meta property="og:image" content="/og-image.png" />

	<!-- Twitter -->
	<meta name="twitter:card" content="summary_large_image" />
	<meta name="twitter:title" content="LAMULA Process" />
	<!-- i18n-ignore: static SEO/social-share metadata, not reactive app UI -->
	<meta
		name="twitter:description"
		content="Procesamiento y visualización de radar meteorológico: NEXRAD Level II, Rainbow5, Vesta .obs"
	/>
	<meta name="twitter:image" content="/og-image.png" />

	<link rel="icon" type="image/x-icon" href="/favicon.ico" />
	<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
	<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
	<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
	<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
	<link rel="manifest" href="/site.webmanifest" />
</svelte:head>
{#await waitLocale()}
	<!-- locale JSON is tiny and inlined at build time; this await resolves before first paint -->
{:then}
	{@render children()}
{/await}
