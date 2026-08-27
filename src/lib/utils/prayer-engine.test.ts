import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import {
	buildPrayerSequence,
	createPrayerEngine,
	type PrayerEventState,
	type PrayerTimeType
} from './prayer-engine.ts';

const minute = 60_000;
const at = (day: number, hour: number, minuteValue = 0) =>
	new Date(2026, 7, day, hour, minuteValue);

function times(day = 27): PrayerTimeType {
	return {
		Imsyak: at(day, 4, 20),
		Subuh: at(day, 4, 30),
		Syuruq: at(day, 5, 45),
		Dzuhur: at(day, 12),
		Ashar: at(day, 15, 15),
		Maghrib: at(day, 18),
		Isya: at(day, 19, 15),
		Tarawih: at(day, 19, 45)
	};
}

const config = {
	beforeNotice: 5,
	beforeAdhan: 5,
	adhanDuration: 7,
	beforeIqamah: 7,
	prayerDuration: 10,
	jumuahDuration: 30
};

function stateAt(prayerTimes: PrayerTimeType, values: Date[]) {
	const engine = createPrayerEngine(prayerTimes, config);
	return values.map((value) => {
		engine.update(value);
		return engine.getState()?.state;
	});
}

describe('prayer engine boundaries', () => {
	test('builds the normal sequence from configured durations', () => {
		const adhan = at(27, 12);
		const sequence = buildPrayerSequence(adhan, config);
		assert.equal(sequence.beforeAdhan.getTime(), adhan.getTime() - 5 * minute);
		assert.equal(sequence.adhanEnd.getTime(), adhan.getTime() + 7 * minute);
		assert.equal(sequence.iqamahTime.getTime(), adhan.getTime() + 14 * minute);
		assert.equal(sequence.prayerEnd.getTime(), adhan.getTime() + 24 * minute);
	});

	test('transitions countdown -> adhan -> iqamah -> prayer -> finished', () => {
		const prayerTimes = times();
		assert.deepEqual(
			stateAt(prayerTimes, [
				at(27, 11, 55),
				at(27, 12),
				at(27, 12, 7),
				at(27, 12, 14),
				at(27, 12, 24)
			]),
			['COUNTDOWN', 'ADHAN', 'IQAMAH', 'PRAYER', 'FINISHED']
		);
	});

	test('holds finished briefly, then advances to the next prayer', () => {
		const prayerTimes = times();
		const events: PrayerEventState[] = [];
		const engine = createPrayerEngine(prayerTimes, config, (event) => events.push({ ...event }));
		engine.update(at(27, 11, 55));
		engine.update(at(27, 12, 24));
		engine.update(new Date(at(27, 12, 24).getTime() + 4_999));
		assert.equal(engine.getState()?.state, 'FINISHED');
		engine.update(new Date(at(27, 12, 24).getTime() + 5_000));
		assert.equal(engine.getState()?.prayer, 'Ashar');
		assert.equal(engine.getState()?.state, 'IDLE');
		assert.deepEqual(events.map((event) => event.state), ['COUNTDOWN', 'FINISHED', 'IDLE']);
	});

	test('transitions notice prayers and does not remain pinned after notice', () => {
		const prayerTimes = times();
		assert.deepEqual(
			stateAt(prayerTimes, [at(27, 4, 15), at(27, 4, 20), at(27, 4, 21)]),
			['COUNTDOWN', 'NOTICE', 'FINISHED']
		);
		const engine = createPrayerEngine(prayerTimes, config);
		engine.update(at(27, 4, 15));
		engine.update(at(27, 4, 21));
		engine.update(new Date(at(27, 4, 21).getTime() + 5_000));
		assert.equal(engine.getState()?.prayer, 'Subuh');
	});

	test('uses the Friday Jumuah sequence without iqamah or regular prayer states', () => {
		const prayerTimes = times(28); // Friday
		assert.deepEqual(
			stateAt(prayerTimes, [
				at(28, 11, 55),
				at(28, 12),
				at(28, 12, 7),
				at(28, 12, 37)
			]),
			['COUNTDOWN', 'ADHAN', 'JUMUAH', 'FINISHED']
		);
	});

	test('does not replay a sequence when starting after it has ended', () => {
		const engine = createPrayerEngine(times(), config);
		engine.update(at(27, 12, 30));
		assert.equal(engine.getState()?.prayer, 'Ashar');
		assert.equal(engine.getState()?.state, 'IDLE');
	});
});
