<script lang="ts">
	import { cn } from '$lib/utils/cn';
	import type { ClassValue } from 'clsx';

	type PropsType = {
		digit: string;
		containerClass?: ClassValue;
		digitClass?: ClassValue;
	};

	let { digit, digitClass, containerClass }: PropsType = $props();

	let prevDigit = $state('');
	let nextDigit = $state('');
	let phase = $state<'idle' | 'top' | 'bottom'>('idle');

	let initialized = false;

	$effect.pre(() => {
		if (!initialized) {
			prevDigit = digit;
			nextDigit = digit;
			initialized = true;
		}
	});

	let topTimeout: ReturnType<typeof setTimeout>;
	let bottomTimeout: ReturnType<typeof setTimeout>;

	$effect(() => {
		if (!initialized) return;
		if (digit === prevDigit) return;

		clearTimeout(topTimeout);
		clearTimeout(bottomTimeout);

		// 1️⃣ start top flip
		phase = 'top';

		topTimeout = setTimeout(() => {
			// 2️⃣ immediately switch values after top closes
			prevDigit = digit;
			nextDigit = digit;

			// start bottom animation
			phase = 'bottom';

			bottomTimeout = setTimeout(() => {
				// 3️⃣ finish
				phase = 'idle';
			}, 300);
		}, 300);

		return () => {
			clearTimeout(topTimeout);
			clearTimeout(bottomTimeout);
		};
	});
</script>

<div
	class={cn('perspective-500 relative h-16 w-12 font-bold text-gray-600 shadow-sm', containerClass)}
>
	<!-- base -->
	<div
		class={cn(
			'absolute inset-0 flex items-center justify-center rounded-md bg-gray-200',
			digitClass
		)}
	>
		{digit}
	</div>

	<!-- Top Half -->
	<div
		class={cn(
			'absolute top-0 left-0 z-10 h-1/2 w-full origin-bottom overflow-hidden rounded-t-md bg-gray-200 outline-0 transition-transform duration-300',
			phase === 'top' && 'animate-flip-top',
			digitClass
		)}
	>
		<div class="flex h-full w-full items-end justify-center">
			<span class="translate-y-1/2 text-9xl">{prevDigit}</span>
		</div>
	</div>

	<!-- Bottom Half -->
	<div
		class={cn(
			'absolute bottom-0 left-0 z-10 h-1/2 w-full origin-top overflow-hidden rounded-b-md bg-gray-200 outline-0 brightness-95 transition-transform delay-300 duration-300',
			phase === 'bottom' && 'animate-flip-bottom',
			digitClass
		)}
	>
		<div class="flex h-full w-full items-start justify-center">
			<span class="-translate-y-1/2 text-9xl">{nextDigit}</span>
		</div>
	</div>
</div>
