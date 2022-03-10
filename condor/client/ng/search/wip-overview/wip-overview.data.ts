import { BillingType } from 'accounting/billing/billing.model';

export class BillPreparationData {
    entityId: number;
    raisedBy: any;
    fromDate?: Date;
    toDate?: Date;
    includeNonRenewal: boolean;
    includeRenewal: boolean;
    useRenewalDebtor: boolean;
}

export class SingleBillViewData {
    billPreparationData: BillPreparationData;
    selectedItems: Array<any>;
    itemType: BillingType;
    selectedCases?: Array<any>;
    debtorKey?: number;
}
