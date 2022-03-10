import { BillingType, WipCategory } from 'accounting/billing/billing.model';
import { BehaviorSubject } from 'rxjs';
import * as _ from 'underscore';
import { TransactionType } from './maintain-billed-amount.component';
export class WipSelectionHelper {
    constructor(private readonly localDecimalPlaces: number, private readonly siteControls: any, private readonly billCurrency: string, private readonly itemType: number, private readonly billSettings: any) { }

    round = (num: number, decimalPlaces: number): number => {
        const places = !decimalPlaces ? this.localDecimalPlaces : decimalPlaces;

        return Number(num.toFixed(places));
    };

    getWipsForAutoWriteUp = (availableWipData: BehaviorSubject<any>) => {

        const availableWips = [...availableWipData.getValue()];
        _.each(availableWips.filter(w => w.LocalBilled), wip => {
            if (!this.siteControls.ChargeVariableFee
                && this.billSettings.MinimumWipReasonCode
                && (this.billSettings.MinimumWipValues && this.billSettings.MinimumWipValues.length > 0)) {
                this.writeUpBillRules(wip);
            } else if (this.siteControls.ChargeVariableFee && !wip.IsDraft && !wip.IsDiscount && !wip.IsMargin
                && (wip.VariableFeeAmount && wip.VariableFeeAmount !== 0 && wip.VariableFeeType === 1) && !wip.IsUsedInWriteUpCalc) {
                this.autoWriteUpForVariableFee(wip, availableWips);
            } else if (!this.siteControls.ChargeVariableFee) {
                this.autoWriteUpForExchRate(wip, availableWips);
            }
        });

        availableWipData.next(availableWips);
    };

    autoWriteUpForVariableFee = (wip: any, allAvailableItems: Array<any>) => {
        let localAmountBilledToVariableWip = 0;
        if (wip.VariableFeeWipCode !== null && wip.VariableFeeWipCode !== '') {
            const variableFeeAvailableWiPs = allAvailableItems.filter(w => w.WipCode === wip.VariableFeeWipCode && !wip.IsDraft);
            localAmountBilledToVariableWip = variableFeeAvailableWiPs.reduce((sum, current) => sum + current.Balance, 0);
            _.each(variableFeeAvailableWiPs, w => {
                w.IsUsedInWriteUpCalc = true;
                w.DraftItemColor = DraftItemColorEnum.gray;
                w.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.wipVariableFee';
            });
        }

        const allVariableWips = allAvailableItems.filter(w => w.WipCode === wip.WipCode && !w.IsDraft && w.VariableFeeType === 1);
        const allVariableFee = allVariableWips.reduce((sum, current) => sum + current.VariableFeeAmount, 0);
        const allLocalBilled = allVariableWips.reduce((sum, current) => sum + current.Balance, 0);
        let allLocalVariableFee = 0;
        if ((wip.VariableFeeCurrency && wip.VariableFeeCurrency !== null && wip.VariableFeeCurrency !== '') && wip.LocalBilled) {
            const exchRate = this.round((wip.ForeignBilled / wip.LocalBilled), 4);
            allLocalVariableFee = this.round((allVariableFee / exchRate), this.localDecimalPlaces);
        } else {
            allLocalVariableFee = allVariableFee;
        }

        if (allLocalBilled + localAmountBilledToVariableWip < allLocalVariableFee) {
            wip.ReasonCode = wip.VariableFeeReason;
            wip.LocalBilled = allLocalVariableFee - allLocalBilled + wip.Balance - localAmountBilledToVariableWip;
            wip.TransactionType = TransactionType.writeUp;
            this.setLocalAndForeignValue(wip);
        }

        _.each(allVariableWips, w => {
            w.IsUsedInWriteUpCalc = true;
            w.DraftItemColor = DraftItemColorEnum.orange;
            w.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.variableFeeApplied';
        });
    };

    writeUpBillRules(item: any): void {
        if (this.billSettings.MinimumWipValues.some(mwv => mwv.WipCode === item.WipCode)) {
            const minValue = this.billSettings.MinimumWipValues.filter(mwv => mwv.WipCode === item.WipCode)[0].MinValue;
            if (minValue && item.LocalBilled < minValue) {
                item.LocalBilled = minValue;
                item.ReasonCode = this.billSettings.MinimumWipReasonCode;
                item.IsAutoWriteUp = true;
                item.DraftItemColor = DraftItemColorEnum.green;
                item.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.minWipWriteUp';
                item.TransactionType = TransactionType.writeUp;
                this.setLocalAndForeignValue(item);
            }
        }
    }

    autoWriteUpForExchRate = (wip: any, allAvailableItems: Array<any>) => {
        if (!this.siteControls.BillWriteUpForExchRate || !this.siteControls.BillWriteUpExchReason ||
            !wip.ForeignCurrency || !wip.ForeignBalance || wip.ForeignBalance !== wip.ForeignBilled) {

            return;
        }

        let exchRate: number = null;
        if (wip.IsDiscount) {
            const mainWips = allAvailableItems.filter(w => w.TransactionId === wip.TransactionId && w.EntityId === wip.EntityId
                && !w.IsDiscount && w.WipSeqNo === wip.WipSeqNo - 1);
            if (mainWips.length > 0) {
                exchRate = this.getAutoWriteUpExchRate(mainWips[0]);
            }
        } else {
            exchRate = this.getAutoWriteUpExchRate(wip);
        }
        if (!exchRate || exchRate === 0) {

            return;
        }

        const writeUpValue = this.round(wip.ForeignBalance / exchRate, wip.ForeignDecimalPlaces);
        if (wip.Balance < writeUpValue) {
            wip.ReasonCode = this.siteControls.BillWriteUpExchReason;
            wip.LocalBilled = writeUpValue;
            wip.IsAutoWriteUp = true;
            wip.LocalVariation = this.round(wip.LocalBilled - wip.Balance, this.localDecimalPlaces);
            wip.TransactionType = TransactionType.writeUp;
            wip.DraftItemColor = DraftItemColorEnum.green;
            wip.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.exchangeRateWriteUp';
        }
    };

    getAutoWriteUpExchRate = (wip: any): number => {
        if (this.siteControls.SellRateOnlyforNewWIP || wip.WipCategory === WipCategory.ServiceCharge) {

            return wip.WipSellRate ?? (wip.ForeignCurrency === this.billCurrency ? wip.BillSellRate : null);
        }

        return wip.WipBuyRate ?? wip.BillBuyRate;
    };

    isSelectedWip = (wip: any) => {

        return wip.LocalBilled || (wip.LocalBilled === 0 && wip.LocalVariation * -1 === wip.Balance && wip.ReasonCode);
    };

    adjustDiscount = (wip: any, availableWipData: Array<any>) => {
        let discountWip: any = null;
        if (wip.IsDraft) {
            const discountWips = _.filter(availableWipData, (w: any) => w.IsDiscount && w.DraftWipRefId === wip.DraftWipRefId && (this.isSelectedWip(w) || (w.LocalBilled !== null && w.IsDiscountAdjustedToZero)));
            if (discountWips.length > 0) {
                discountWip = discountWips[0];
            }
        } else {
            const discountWips = _.filter(availableWipData, (w: any) => w.IsDiscount && w.TransactionId === wip.TransactionId && (this.isSelectedWip(w) || (w.LocalBilled !== null && w.IsDiscountAdjustedToZero)));
            if (discountWips.length > 0) {
                discountWip = discountWips[0];
            }
        }

        if (discountWip) {
            this.reduceDiscountByRatio(discountWip, wip);
        }
    };

    reduceDiscountByRatio = (discountWip: any, modifiedWip: any) => {
        if (discountWip.IsDiscount) {
            discountWip.IsDiscountAdjustedToZero = false;
            let ratio = 0;
            let newValue = 0;
            if (modifiedWip.IsDraft && modifiedWip.OriginalLocalBilled) {
                ratio = modifiedWip.LocalBilled / modifiedWip.OriginalLocalBilled ?? 0;
                newValue = discountWip.LocalBilled * ratio;
            } else if (modifiedWip.Balance) {
                ratio = modifiedWip.LocalBilled / modifiedWip.Balance ?? 0;
                newValue = discountWip.Balance * ratio;
            }
            discountWip.LocalBilled = this.round(newValue, this.localDecimalPlaces);
            if (discountWip.LocalBilled === 0) {
                discountWip.IsDiscountAdjustedToZero = true;
            }
            this.setLocalAndForeignValue(discountWip);

            if (modifiedWip.ReasonCode && modifiedWip.ReasonCode !== '') {
                discountWip.ReasonCode = modifiedWip.ReasonCode;
                this.handleTransactionType(discountWip);
            }
        }
    };

    get IsCreditNote(): boolean {
        return this.itemType === BillingType.credit;
    }

    setLocalAndForeignValue = (dataItem: any): any => {
        dataItem.LocalVariation = this.round(dataItem.LocalBilled - dataItem.Balance, this.localDecimalPlaces);
        if (dataItem.ForeignBalance && dataItem.Balance !== 0) {
            dataItem.ForeignBilled = dataItem.WipExchRate
                ? this.round(dataItem.LocalBilled * dataItem.WipExchRate, dataItem.ForeignDecimalPlaces)
                : this.round(dataItem.LocalBilled * (dataItem.ForeignBalance / dataItem.Balance), dataItem.ForeignDecimalPlaces);
            dataItem.ForeignVariation = this.round(dataItem.ForeignBilled - dataItem.ForeignBalance, dataItem.ForeignDecimalPlaces);
        }
    };

    handleTransactionType = (wip: any) => {
        if (wip.LocalBilled > wip.Balance) {
            wip.TransactionType = this.IsCreditNote ? TransactionType.writeDown : TransactionType.writeUp;
        } else if (wip.LocalBilled < wip.Balance) {
            wip.TransactionType = this.IsCreditNote ? TransactionType.writeUp : TransactionType.writeDown;
        } else {
            wip.LocalVariation = null;
            wip.ReasonCode = null;
            wip.IsDiscountDisconnectedWarningToBeDisplayed = false;
        }
    };

    setRowColors = (wipItem: any, isFinalised = false) => {
        // tslint:disable-next-line: prefer-conditional-expression
        if (wipItem.IsAdvanceBill) {
            wipItem.DraftItemColor = DraftItemColorEnum.purple;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.advanceBill';

            return;
        } else if (this.siteControls.ChargeVariableFee && !isFinalised && wipItem.VariableFeeType === 1) {
            wipItem.DraftItemColor = DraftItemColorEnum.orange;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.variableFeeApplied';

            return;
        } else if (wipItem.IsDiscount && wipItem.Balance > 0) {
            wipItem.DraftItemColor = DraftItemColorEnum.red;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.discountWithPositive';

            return;
        } else if (!wipItem.IsDiscount && wipItem.Balance < 0) {
            wipItem.DraftItemColor = DraftItemColorEnum.red;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.wipWithNegative';

            return;
        } else if (wipItem.IsBillingDiscount) {
            wipItem.DraftItemColor = DraftItemColorEnum.yellow;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.billingDiscount';

            return;
        } else if (wipItem.IsDraft) {
            wipItem.DraftItemColor = DraftItemColorEnum.blue;
            wipItem.DraftItemToolTip = 'accounting.billing.step3.gridHeaderLegends.draftWIP';

            return;
        }

        wipItem.DraftItemColor = null;
        wipItem.DraftItemToolTip = '';

        return;
    };
}

export enum DraftItemColorEnum {
    red = 'red',
    blue = 'blue',
    gray = 'gray',
    purple = 'purple',
    yellow = 'yellow',
    orange = 'orangered',
    green = 'green'
}