<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import { onMount } from 'svelte';

	let { children } = $props();

	onMount(() => {
		const idleTimeoutMs = 60_000;
		const cursorClasses = ['cursor-none!', '[&_*]:cursor-none!'];
		const root = document.documentElement;
		const activityEvents = ['pointermove', 'pointerdown', 'pointerup', 'wheel', 'keydown', 'keyup'];
		let timeout: ReturnType<typeof setTimeout>;

		function resetCursorTimeout() {
			clearTimeout(timeout);
			root.classList.remove(...cursorClasses);
			timeout = setTimeout(() => {
				root.classList.add(...cursorClasses);
			}, idleTimeoutMs);
		}

		for (const event of activityEvents) {
			window.addEventListener(event, resetCursorTimeout, { capture: true, passive: true });
		}
		resetCursorTimeout();

		return () => {
			clearTimeout(timeout);
			root.classList.remove(...cursorClasses);
			for (const event of activityEvents) {
				window.removeEventListener(event, resetCursorTimeout, { capture: true });
			}
		};
	});
</script>

<svelte:head><link rel="icon" href={favicon} /></svelte:head>
{@render children()}
