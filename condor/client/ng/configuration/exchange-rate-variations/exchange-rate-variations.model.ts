
'use strict';

export class ExchangeRateVariationPermissions {
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
}

export class ExchangeRateVariationFilterModel {
    currencyCode?: string;
    exchangeRateScheduleId?: number;
    caseId?: number;
    caseType?: string;
    countryCode?: string;
    propertyType?: string;
    caseCategory?: string;
    subType?: string;
    isExactMatch?: boolean;

    constructor(data?: any) {
        if (!!data) {
            Object.assign(this, data);
        }
    }
}

export class ExchangeRateVariationModel {
    id?: number;
    currency: any;
    exchRateSch: any;
    buyRate?: number;
    buyFactor: number;
    sellRate?: number;
    sellFactor: number;
    caseCategory?: any;
    caseType?: any;
    country?: any;
    propertyType?: any;
    subType?: any;
    effectiveDate?: any;
    notes?: string;
}

export class ExchangeRateVariationRequest {
    id?: number;
    currencyCode: string;
    exchScheduleId: number;
    buyRate?: number;
    buyFactor: number;
    sellRate?: number;
    sellFactor: number;
    caseCategoryCode?: any;
    caseTypeCode?: string;
    countryCode?: string;
    propertyTypeCode?: string;
    subTypeCode?: any;
    effectiveDate: any;
    notes?: string;
}

export class ExchangeRateVariationFormData {
    currency: any;
    exchangeRateSchedule: any;
    case: any;
    caseType: any;
    jurisdiction: any;
    propertyType: any;
    caseCategory: any;
    subType: any;
    isExactMatch = true;
    useCase: boolean;

    constructor(data?: any) {
        if (!!data) { Object.assign(this, data); }
    }

    private readonly getKey = (searchCriteria: any, propertyName: string, key: string) => {
        return searchCriteria[propertyName] && searchCriteria[propertyName][key];
    };

    getServerReady = (): ExchangeRateVariationFilterModel => {
        return new ExchangeRateVariationFilterModel({
            currencyCode: !!this.currency ? this.currency.code : null,
            exchangeRateScheduleId: !!this.exchangeRateSchedule ? this.exchangeRateSchedule.id : null,
            caseType: !!this.caseType ? this.caseType.code : null,
            propertyType: !!this.propertyType ? this.propertyType.code : null,
            countryCode: !!this.jurisdiction ? this.jurisdiction.code : null,
            caseCategory: !!this.caseCategory ? this.caseCategory.code : null,
            subType: !!this.subType ? this.subType.code : null,
            isExactMatch: this.isExactMatch
        });
    };
}