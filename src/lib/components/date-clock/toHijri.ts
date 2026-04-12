type HijriDate = {
	day: number;
	month: number;
	year: number;
	monthName: string;
};

const HIJRI_MONTHS = [
	'Muharram',
	'Safar',
	'Rabiul-Awwal',
	'Rabiul-Akhir',
	'Jumadil-Awwal',
	'Jumadil-Akhir',
	'Rajab',
	"Sya'ban",
	'Ramadan',
	'Syawal',
	"Dzulqa'dah",
	'Dzulhijjah'
];

export function toHijri(date: Date, adjustment: number = 0, maghribTime?: Date): HijriDate {
	const adjusted = new Date(date);

	// 🌅 If current time is AFTER maghrib → shift to next day
	if (maghribTime && date >= maghribTime) {
		adjusted.setDate(adjusted.getDate() + 1);
	}

	// manual adjustment (if needed)
	if (adjustment !== 0) {
		adjusted.setDate(adjusted.getDate() + adjustment);
	}

	return calcHijri(adjusted);
}

export function isRamadhan(date: Date, adjustment: number = 0, maghribTime?: Date): boolean {
	const hijri = toHijri(date, adjustment, maghribTime);
	return hijri.month === 9;
}

function calcHijri(date: Date): HijriDate {
	const jd = Math.floor(date.getTime() / 86400000) + 2440588;

	const islamicEpoch = 1948439;
	const daysSinceEpoch = jd - islamicEpoch;

	const year = Math.floor((30 * daysSinceEpoch + 10646) / 10631);

	let month = 1;
	while (month < 12 && jd >= hijriToJD(year, month + 1, 1)) {
		month++;
	}

	const firstDayOfMonth = hijriToJD(year, month, 1);
	const day = jd - firstDayOfMonth + 1;

	return {
		day,
		month,
		year,
		monthName: HIJRI_MONTHS[month - 1]
	};
}

function hijriToJD(year: number, month: number, day: number) {
	return (
		day +
		Math.ceil(29.5 * (month - 1)) +
		(year - 1) * 354 +
		Math.floor((3 + 11 * year) / 30) +
		1948439
	);
}
