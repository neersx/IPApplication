export class DisbursementDissectionWip {
    date: Date;
    name: any;
    case: any;
    staff: any;
    disbursement: any;
    foreignAmount?: number;
    amount?: number;
    margin?: number;
    value?: number;
    discount?: number;
    quantity?: number;
    narrative?: any;

    prepareGridDataRequest(grid: any, formGroup: any): any {
        const dissectedDisbursements = [];
        if (grid.wrapper.data && formGroup.value) {
            const data: any = grid.wrapper.data;
            data.forEach(row => {
                const disbursementWip = {
                    wipSeqNo: row.wipSeqNo,
                    transDate: row.date,
                    nameKey: row.name ? row.name.key : null,
                    nameCode: row.name ? row.name.code : null,
                    name: row.name ? row.name.displayName : null,
                    caseKey: row.case ? row.case.key : null,
                    irn: row.case ? row.case.value : null,
                    staffKey: row.staff ? row.staff.key : null,
                    staffNameCode: row.staff ? row.staff.code : null,
                    staffName: row.staff ? row.staff.displayName : null,
                    wipCode: row.disbursement ? row.disbursement.key : null,
                    description: row.disbursement ? row.disbursement.value : null,
                    productCode: row.productCode,
                    productKey: row.productKey,
                    productCodeDescription: row.productCodeDescription,
                    amount: row.amount,
                    margin: row.margin,
                    foreignMargin: row.foreignMargin,
                    discount: row.discount,
                    foreignDiscount: row.foreignDiscount,
                    currencyCode: formGroup.value.currency ? formGroup.value.currency.code : null,
                    foreignAmount: row.foreignAmount,
                    exchRate: formGroup.value.exchRate ? formGroup.value.exchRate : null,
                    quantity: row.quantity,
                    narrativeKey: row.narrative ? row.narrative.key : null,
                    narrativeCode: row.narrative ? row.narrative.code : null,
                    narrativeText: row.narrative ? row.narrative.text : null,
                    debitNoteText: row.debitNoteText,
                    verificationNo: row.verificationNo,
                    localCost1: row.LocalCost1,
                    localCost2: row.LocalCost2,
                    marginNo: row.marginNo,
                    localDiscountForMargin: row.marginDiscount,
                    foreignDiscountForMargin: (row.disbursement && row.foreignAmount) ? row.foreignMarginDiscount : null,
                    dateStyle: row.dateStyle,
                    isSplitDebtorWip: row.isSplitDebtorWip,
                    debtorSplitPercentage: row.debtorSplitPercentage
                };

                dissectedDisbursements.push(disbursementWip);
            });

            return dissectedDisbursements;
        }
    }
}