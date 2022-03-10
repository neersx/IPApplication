import { Component } from '@angular/core';
import { WipCategory } from 'accounting/billing/billing.model';
import { BehaviorSubject } from 'rxjs';
import { TransactionType } from './maintain-billed-amount.component';
import { DraftItemColorEnum, WipSelectionHelper } from './wip-selection.helper';

describe('Wip Selection Helper', () => {
    let helper: WipSelectionHelper;
    const localDeciamlPlaces = 2;
    const siteControls = {
        ChargeVariableFee: true,
        BillWriteUpForExchRate: true,
        BillWriteUpExchReason: 'DS',
        SellRateOnlyforNewWIP: false
    };
    const currency = 'USD';
    const itemType = 510;
    const billSettings: any = {
        MinimumWipReasonCode: null,
        MinimumWipValues: null
    };
    let availableWipData: BehaviorSubject<any>;
    beforeEach(() => {
        helper = new WipSelectionHelper(localDeciamlPlaces, siteControls, currency, itemType, billSettings);
        availableWipData = new BehaviorSubject<any>([{
            Balance: 100,
            LocalBilled: 100,
            ForeignBalance: 120,
            ForeignBilled: 120,
            ForeignDecimalPlaces: 4,
            IsDraft: false,
            IsDiscount: false,
            IsMargin: false,
            VariableFeeAmount: 1000,
            VariableFeeType: 1,
            VariableFeeWipCode: 'TEL',
            WipCode: 'PHO',
            VariableFeeReason: 'ER'
        }, {
            Balance: 200,
            LocalBilled: 200,
            IsDraft: true,
            IsDiscount: false,
            IsMargin: false,
            WipCode: 'TEL'
        }, {
            Balance: 200,
            LocalBilled: 200,
            IsDraft: false,
            IsAdvanceBill: true,
            IsDiscount: true,
            IsMargin: false,
            WipCode: 'DIS'
        }, {
            Balance: 100,
            LocalBilled: 100,
            IsDraft: false,
            IsDiscount: false,
            IsMargin: false,
            WipCode: 'Mar',
            ForeignCurrency: 'USD',
            ForeignBalance: 210,
            ForeignBilled: 210,
            WipSellRate: 1.5,
            WipBuyRate: 0.97,
            WipCategory: WipCategory.ServiceCharge,
            ForeignDecimalPlaces: 2
        }]);
    });
    it('should create', () => {
        expect(helper).toBeTruthy();
    });
    describe('Variable Fee auto write up', () => {
        it('should set auto write up for variable fee', () => {
            helper.getWipsForAutoWriteUp(availableWipData);
            const data = availableWipData.getValue();
            expect(data[0].LocalVariation).toBe(700);
            expect(data[0].TransactionType).toBe(TransactionType.writeUp);
            expect(data[0].ReasonCode).toBe('ER');
            expect(data[0].ForeignBilled).toBe(800 * 120 / 100);
            expect(data[0].DraftItemColor).toBe(DraftItemColorEnum.orange);
            expect(data[1].DraftItemColor).toBe(DraftItemColorEnum.gray);
        });
        it('should use variable fee in foreign currency if set', () => {
            const data = availableWipData.getValue();
            data[0].VariableFeeCurrency = 'USD';
            availableWipData.next(data);
            helper.getWipsForAutoWriteUp(availableWipData);
            const newData = availableWipData.getValue();
            expect(newData[0].LocalVariation).toBe(533.33); // 1000 * (100 / 120) as variable fee
            expect(newData[0].DraftItemColor).toBe(DraftItemColorEnum.orange);
        });
        it('should not set variable fee if site control is off', () => {
            siteControls.ChargeVariableFee = false;
            helper.autoWriteUpForVariableFee = jest.fn();
            helper.getWipsForAutoWriteUp(availableWipData);
            expect(helper.autoWriteUpForVariableFee).not.toBeCalled();
        });

        it('should not update discount or margin rows', () => {
            helper.getWipsForAutoWriteUp(availableWipData);
            const data = availableWipData.getValue();
            expect(data[2].DraftItemColor).toBe(undefined);
        });
    });
    describe('exchange rate auto writeup', () => {
        it('should not call auto writeup if site controls are not set', () => {
            siteControls.BillWriteUpForExchRate = false;
            helper.getWipsForAutoWriteUp(availableWipData);
            const data = availableWipData.getValue();
            expect(data[3].DraftItemColor).toBe(undefined);
        });
        it('should not call auto writeup if site controls are set', () => {
            siteControls.BillWriteUpForExchRate = true;
            helper.getWipsForAutoWriteUp(availableWipData);
            const data = availableWipData.getValue();
            expect(data[3].LocalVariation).toBe(40);
            expect(data[3].DraftItemColor).toBe(DraftItemColorEnum.green);
            expect(data[3].TransactionType).toBe(TransactionType.writeUp);
        });
        it('should use wip bill rate if sell rate not available', () => {
            let data = availableWipData.getValue();
            data[3].WipSellRate = null;
            data[3].BillSellRate = 1.75;
            availableWipData.next(data);
            helper.getWipsForAutoWriteUp(availableWipData);
            data = availableWipData.getValue();
            expect(data[3].LocalVariation).toBe(20);
            expect(data[3].DraftItemColor).toBe(DraftItemColorEnum.green);
            expect(data[3].TransactionType).toBe(TransactionType.writeUp);
        });
        it('should use wip buy rate if sell rate not available', () => {
            let data = availableWipData.getValue();
            data.push({
                Balance: 100,
                LocalBilled: 100,
                IsDraft: false,
                IsDiscount: false,
                IsMargin: false,
                WipCode: 'Mar',
                ForeignCurrency: 'USD',
                ForeignBalance: 210,
                ForeignBilled: 210,
                WipSellRate: null,
                WipBuyRate: 1.25,
                WipCategory: 'PD',
                ForeignDecimalPlaces: 2
            });
            availableWipData.next(data);
            helper.getWipsForAutoWriteUp(availableWipData);
            data = availableWipData.getValue();
            expect(data[4].LocalVariation).toBe(68);
            expect(data[4].DraftItemColor).toBe('green');
            expect(data[4].TransactionType).toBe(TransactionType.writeUp);
        });
    });
    describe('auto adjust discount', () => {
        let wipData: Array<any>;
        beforeEach(() => {
            wipData = [{
                EntityId: 1,
                TransactionId: 101,
                WipSeqNo: 1,
                Balance: 100,
                LocalBilled: 120,
                LocalVariation: 20,
                ForeignBalance: 120,
                ForeignBilled: 135,
                ForeignVariation: 15,
                ForeignDecimalPlaces: 4,
                IsDraft: false,
                IsDiscount: false,
                IsMargin: false,
                WipCode: 'PHO',
                TransactionType: TransactionType.writeUp,
                ReasonCode: 'ER'
            }, {
                EntityId: 1,
                TransactionId: 101,
                WipSeqNo: 2,
                Balance: -20,
                LocalBilled: -20,
                IsDraft: false,
                IsDiscount: true,
                IsMargin: false,
                WipCode: 'DIS',
                ForeignBalance: -30,
                ForeignBilled: -30
            }, {
                EntityId: 1,
                TransactionId: 102,
                WipSeqNo: 1,
                Balance: 200,
                LocalBilled: 200,
                IsDraft: false,
                IsDiscount: false,
                IsMargin: false,
                WipCode: 'ABC'
            }];
        });
        it('should reduce discount value by ratio', () => {
            helper.adjustDiscount(wipData[0], wipData);
            const discountWip = wipData[1];
            expect(discountWip.ReasonCode).toBe('ER');
            expect(discountWip.TransactionType).toBe(TransactionType.writeDown);
            expect(discountWip.LocalBilled).toBe(-24);
            expect(discountWip.ForeignBilled).toBe(-36);
            expect(discountWip.LocalVariation).toBe(-4);
            expect(discountWip.ForeignVariation).toBe(-6);
        });
        it('should not reduce ratio if not discount', () => {
            helper.adjustDiscount(wipData[0], wipData);
            expect(wipData[2].LocalBilled).toBe(wipData[2].Balance);
        });
        it('should auto adjust discount for draft wip', () => {
            wipData[0].IsDraft = true;
            wipData[0].DraftWipRefId = 11;
            wipData[0].OriginalLocalBilled = 100;

            wipData[1].IsDraft = true;
            wipData[1].DraftWipRefId = 11;
            helper.adjustDiscount(wipData[0], wipData);
            const discountWip = wipData[1];
            expect(discountWip.ReasonCode).toBe('ER');
            expect(discountWip.TransactionType).toBe(TransactionType.writeDown);
            expect(discountWip.LocalBilled).toBe(-24);
            expect(discountWip.ForeignBilled).toBe(-36);
        });
    });
    describe('set colors for WIP items', () => {
        it('should not set color if not flag is set to true', () => {
            helper.setRowColors(availableWipData);
            const data = availableWipData.getValue();
            expect(data[0].DraftItemColor).toBeUndefined();
        });
        it('should set color to blue if isDraft is set to true', () => {
            const data = availableWipData.getValue();
            helper.setRowColors(data[1]);
            const updatedData = availableWipData.getValue();
            expect(updatedData[1].DraftItemColor).toEqual(DraftItemColorEnum.blue);
        });
        it('should set color to purple if isAdvanceBill is set to true', () => {
            const data = availableWipData.getValue();
            data[1].IsAdvanceBill = true;
            helper.setRowColors(data[1]);
            const updatedData = availableWipData.getValue();
            expect(updatedData[1].DraftItemColor).toEqual(DraftItemColorEnum.purple);
        });
        it('should set color to red if IsDiscount is set to true', () => {
            const data = availableWipData.getValue();
            data[1].IsDiscount = true;
            helper.setRowColors(data[1]);
            const updatedData = availableWipData.getValue();
            expect(updatedData[1].DraftItemColor).toEqual(DraftItemColorEnum.red);
        });
    });

    describe('writeup bill rules', () => {
        beforeEach(() => {
            billSettings.MinimumWipReasonCode = 'R';
            billSettings.MinimumWipValues = [{ WipCode: 'CORR', MinValue: 1000 }, { WipCode: 'PHO', MinValue: 2000 }];
        });
        it('should not set color if not flag is set to true', () => {
            jest.spyOn(helper, 'setLocalAndForeignValue');
            const data = availableWipData.getValue();
            helper.writeUpBillRules(data[0]);
            expect(data[0].DraftItemColor).toBe(DraftItemColorEnum.green);
            expect(data[0].IsAutoWriteUp).toBeTruthy();
            expect(data[0].TransactionType).toBe(TransactionType.writeUp);
            expect(helper.setLocalAndForeignValue).toHaveBeenCalled();
        });
        it('should set color to blue if isDraft is set to true', () => {
            const data = availableWipData.getValue();
            helper.setLocalAndForeignValue(data[0]);
            expect(data[0].LocalVariation).toBe(0);
            expect(data[0].ForeignBalance).toBe(120);
        });
    });
});