
'use strict';

export class CurrencyPermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class CurrencyItems {
    id?: string;
    currencyCode: string;
    currencyDescription: string;
    bankRate?: number;
    dateChanged: Date;
    buyRate?: number;
    buyFactor?: number;
    sellFactor?: number;
    sellRate?: number;
}

export class CurrencyRequest extends CurrencyItems {
    roundedBillValues?: number;
}