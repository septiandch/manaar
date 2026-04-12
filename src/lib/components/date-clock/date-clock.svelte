<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import type { ClassValue } from 'clsx';

	type PropsType = {
		now: Date;
		format?: string;
		class?: ClassValue;
	};

	const MONTHS_ID = [
		'Januari',
		'Februari',
		'Maret',
		'April',
		'Mei',
		'Juni',
		'Juli',
		'Agustus',
		'September',
		'Oktober',
		'November',
		'Desember'
	];

	const DAYS_ID = ['Ahad', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

	let { now, format = 'HH:mm:ss', class: className }: PropsType = $props();

	const timeTokens = ['H', 'm', 's'];
	const dateTokens = ['D', 'M', 'Y'];

	const hasTime = timeTokens.some((t) => format.includes(t));
	const hasDate = dateTokens.some((t) => format.includes(t));

	function formatDate(date: Date, fmt: string) {
		const dayIndex = date.getDay();
		const monthIndex = date.getMonth();

		const map: Record<string, string> = {
			// 🔹 Day name
			dddd: DAYS_ID[dayIndex],
			ddd: DAYS_ID[dayIndex].slice(0, 3),

			// 🔹 Year
			YYYY: date.getFullYear().toString(),
			YY: date.getFullYear().toString().slice(-2),

			// 🔹 Month
			MMMM: MONTHS_ID[monthIndex],
			MM: (monthIndex + 1).toString().padStart(2, '0'),

			// 🔹 Day of month
			DD: date.getDate().toString().padStart(2, '0'),

			// 🔹 Time
			HH: date.getHours().toString().padStart(2, '0'),
			mm: date.getMinutes().toString().padStart(2, '0'),
			ss: date.getSeconds().toString().padStart(2, '0')
		};

		return (
			Object.entries(map)
				// longest tokens first = no collisions
				.sort(([a], [b]) => b.length - a.length)
				.reduce((acc, [key, value]) => acc.replaceAll(key, value), fmt)
		);
	}
</script>

<span class={cn(className)}>
	{#if hasDate && !hasTime}
		<!-- 📅 Calendar only -->
		{formatDate(now, format)}
	{:else}
		<!-- ⏰ Clock or mixed -->
		{formatDate(now, format)}
	{/if}
</span>
