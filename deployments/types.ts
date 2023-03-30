export interface SynthArgs {
	address: string|null;
	name: string;
	symbol: string;
	feed: string|null;
	price: string|null;
	mintFee: string;
	burnFee: string;
	isFeedSecondary: boolean;
	secondarySource: string|null;
	isFeeToken: boolean;
}

export interface CollateralArgs {
	address: string|null;
	name: string;
	symbol: string;
	decimals: number|null;
	feed: string|null;
	price: string|null;
	params: CollateralInitArgs;
	isNew: boolean;
	isCToken: boolean;
	isAToken: boolean;
	poolAddressesProvider: string|null;
	isFeedSecondary: boolean;
	secondarySource: string|null;
}

export interface CollateralInitArgs {
	cap: string,
	baseLTV: number,
	liqThreshold: number,
	liqBonus: number,
}