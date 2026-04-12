type StringField = {
	type: 'string';
	label: string;
	placeholder?: string;
};

type NumberField = {
	type: 'number';
	label: string;
	placeholder?: string;
	minValue?: number;
	withButton?: boolean;
};

type ImageField = {
	type: 'image';
	label: string;
	placeholder?: string;
};

export type ConfigType = {
	logo: File | string | null;
	title: string;
	subtitle: string;
	carouselDuration: number;
	hijriAdj: number;
	latitude: number;
	longitude: number;
	beforeNotice: number;
	beforeAdhan: number;
	adhanDuration: number;
	beforeIqamah: number;
	prayerDuration: number;
	jumuahDuration: number;
	taraweehFromIsya: number;
	taraweehDuration: number;
};

export type ConfigField = (StringField | NumberField | ImageField) & {
	key: keyof ConfigType;
};
