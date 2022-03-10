export enum TransactionTypeEnum {
    credit = 'credit',
    debit = 'debit',
    debtor = 'debtor',
    staff = 'staff',
    case = 'case',
    narrative = 'narrative',
    product = 'product'
}

export class ViewSupportData {
    reasonSupportCollection: any;
    localCurrency: string;
    productRecordedOnWIP: boolean;
    splitWipMultiDebtor: boolean;
    transferAssociatedDiscount: boolean;
    wipWriteDownRestricted: boolean;
    restrictOnWIP: boolean;
    writeDownLimit: number;
}

export enum AdjustmentTypeEnum {
    caseWipTransfer = 1003,
    debtorWipTransfer = 1004,
    debitWipAdjustment = 1000,
    creditWipAdjustment = 1001,
    staffWipTransfer = 1002,
    productWipTransfer = 1007
}

export class AdjustWipRequest {
    entityKey: number;
    transKey: number;
    wipSeqNo: number;
    logDateTimeStamp: Date;
    transDate: Date;
    requestedByStaffKey: number;
    newLocal?: number;
    newForeign?: number;
    reasonCode: string;
    newCaseKey?: number;
    newAcctClientKey?: number;
    newStaffKey?: number;
    newProductKey?: number;
    newQuotationKey?: number;
    newNarrativeKey?: number;
    newActivityCode: string;
    newDebitNoteText: string;
    adjustmentType?: number;
    newTotalTime: Date;
    newTotalUnits?: number;
    newChargeRate?: number;
    isAdjustToZero: boolean;
    newTransKey?: number;
}