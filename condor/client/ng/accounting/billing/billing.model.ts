import { HeaderEntityType } from './billing-maintenance/case-debtor.model';

export type BillingWizardStep = {
    id: number;
    selected: boolean;
    stepData?: any;
    isDefault: boolean;
    title: string;
};

export type EntityOldNewValue = {
    entity: HeaderEntityType,
    oldValue?: any;
    value?: any;
};

export enum TypeOfDetails {
    Summary = 'Summary',
    Details = 'Detailed'
}

export enum BillingType {
    debit = 510,
    credit = 511
}

export enum WipCategory {
    ServiceCharge = 'SC',
    PaidDisbursements = 'PD',
    Recoverables = 'OR'
}