export class TaxCodeCriteria {
    text?: string;
}

export class TaxCodes {
    taxCode: string;
    description: string;
}
export enum TaxCodeState {
    Adding = 'adding',
    Updating = 'updating'
}

export enum TaxRateInlineState {
    Added = 'A',
    Modified = 'M',
    Deleted = 'D'
}