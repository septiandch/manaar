<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import type { ConfigField, ConfigType } from '$lib/types/config';
	import { Loader } from '@lucide/svelte';
	import { onMount } from 'svelte';
	import ConfigInput from './config-input.svelte';

	const initialConfig: ConfigType = {
		logo: null as File | null,
		title: '',
		subtitle: '',
		latitude: -6.2474466,
		longitude: 107.1484521,
		hijriAdj: 0,
		carouselDuration: 5,
		beforeNotice: 5,
		beforeAdhan: 5,
		adhanDuration: 10,
		beforeIqamah: 7,
		prayerDuration: 10,
		jumuahDuration: 30,
		taraweehFromIsya: 30,
		taraweehDuration: 60
	};

	let logoUrl: string | undefined = $state(undefined);
	let updatedAt: string | undefined = $state(undefined);
	let loading = $state(true);

	let configValues = $state<ConfigType>(initialConfig);

	const fields: ConfigField[] = [
		{ key: 'logo', type: 'image', label: 'Logo', placeholder: 'Select file' },
		{ key: 'title', type: 'string', label: 'Title', placeholder: 'Title' },
		{ key: 'subtitle', type: 'string', label: 'Subtitle', placeholder: 'Subtitle' },
		{
			key: 'carouselDuration',
			type: 'number',
			label: 'Carousel duration (second)',
			placeholder: 'duration (second)',
			minValue: 5,
			withButton: true
		},
		{
			key: 'hijriAdj',
			type: 'number',
			label: 'Hijri date adjust',
			placeholder: 'day',
			minValue: -3,
			withButton: true
		},
		{ key: 'latitude', type: 'number', label: 'Latitude', placeholder: 'Latitude' },
		{ key: 'longitude', type: 'number', label: 'Longitude', placeholder: 'Longitude' },
		{
			key: 'beforeAdhan',
			type: 'number',
			label: 'Adzan countdown (minute)',
			placeholder: 'duration (minute)',
			minValue: 1,
			withButton: true
		},
		{
			key: 'adhanDuration',
			type: 'number',
			label: 'Adzan duration (minute)',
			placeholder: 'duration (minute)',
			minValue: 5,
			withButton: true
		},
		{
			key: 'beforeIqamah',
			type: 'number',
			label: 'Iqamah duration (minute)',
			placeholder: 'duration (minute)',
			minValue: 5,
			withButton: true
		},
		{
			key: 'prayerDuration',
			type: 'number',
			label: 'Prayer duration (minute)',
			placeholder: 'duration (minute)',
			minValue: 5,
			withButton: true
		},
		{
			key: 'taraweehFromIsya',
			type: 'number',
			label: 'Isya to Taraweeh time (minute)',
			placeholder: 'duration (minute)',
			minValue: 0,
			withButton: true
		},
		{
			key: 'taraweehDuration',
			type: 'number',
			label: 'Taraweeh Duration (minute)',
			placeholder: 'duration (minute)',
			minValue: 0,
			withButton: true
		}
	];

	async function loadConfig() {
		const res = await fetch('/api/config');
		if (!res.ok) return;

		const data = await res.json();
		if (!data) return;

		configValues = { ...configValues, ...data };

		logoUrl = data.logo ?? undefined;
		updatedAt = data.updatedAt;

		loading = false;
	}

	onMount(loadConfig);

	async function submit() {
		loading = true;

		const formData = new FormData();

		for (const [key, value] of Object.entries(configValues)) {
			if (value === null || value === undefined) continue;

			// If File
			if (value instanceof File) {
				formData.append(key, value);
			}
			// If number
			else if (typeof value === 'number') {
				formData.append(key, value.toString());
			}
			// If string
			else {
				formData.append(key, value);
			}
		}

		await fetch('/api/config', {
			method: 'POST',
			body: formData
		});

		await loadConfig();
		loading = false;
	}
</script>

<div class="m-auto my-2 w-4xl max-w-[95vw] space-y-4 md:my-4 md:max-w-[90vw]">
	<h1 class="text-3xl font-semibold">App Config</h1>

	<div class="rounded-md bg-foreground p-4 text-primary shadow-sm">
		<div class="flex w-full flex-col gap-4">
			<div class="flex flex-col gap-4">
				{#each fields as field}
					{@const key = field.key}
					{#if field.type === 'image'}
						{#key updatedAt}
							<ConfigInput
								disabled={loading}
								type="image"
								label={field.label}
								src={logoUrl}
								placeholder={field.placeholder}
								bind:value={configValues[key] as File | undefined}
							/>
						{/key}
					{:else if field.type === 'string'}
						<ConfigInput
							disabled={loading}
							type={field.type}
							label={field.label}
							placeholder={field.placeholder}
							bind:value={configValues[key] as string}
						/>
					{:else}
						<ConfigInput
							disabled={loading}
							type={field.type}
							label={field.label}
							placeholder={field.placeholder}
							minValue={field.minValue}
							withButton={field.withButton}
							bind:value={configValues[key] as number}
						/>
					{/if}
				{/each}
			</div>

			<Button disabled={loading} onclick={submit}>
				{#if loading}
					<Loader />
				{:else}
					Save
				{/if}
			</Button>
		</div>
	</div>
</div>
