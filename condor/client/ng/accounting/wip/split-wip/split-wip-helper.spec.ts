import { SplitWipHelper } from './split-wip-helper';
import { SplitWipData, SplitWipType } from './split-wip.model';

describe('SplitWipHelper', () => {
    let helper: SplitWipHelper;
    const wipData: SplitWipData = {
        localAmount: 500,
        foreignBalance: 50,
        localValue: 500,
        foreignValue: 349,
        foreignCurrency: 'USD',
        caseReference: '1234',
        staffName: 'staff',
        narrativeCode: 'N',
        narrativeKey: 5,
        wipCategoryCode: 'W',
        wipDescription: 'Description',
        wipCode: 'AC',
        wipSeqKey: 1,
        entityKey: 123456,
        responsibleName: '',
        balance: 500,
        isCreditWip: false,
        localCurrency: 'AUD',
        exchRate: 1.5,
        localDeciamlPlaces: 2,
        foreignDecimalPlaces: 2,
        transDate: new Date(),
        transKey: 123,
        responsibleNameCode: 'RS'
    };
    beforeEach(() => {

        helper = new SplitWipHelper(wipData);
    });

    it('should create', () => {
        expect(helper).toBeTruthy();
    });

    it('should call appliedAmount', () => {
        helper.isForeignCurrency = true;
        const activeData: any = {
            localAmount: 500,
            foreignBalance: 50,
            localValue: 500,
            foreignValue: 349,
            foreignCurrency: 'USD',
            balance: 500,
            isCreditWip: false,
            localCurrency: 'AUD',
            exchRate: 1.5,
            localDeciamlPlaces: 2,
            foreignDecimalPlaces: 2
        };
        const validRows = [{ foreignValue: 100 }, { foreignValue: 20 }];
        const result = helper.appliedAmount(validRows, true, activeData);
        expect(result).toBe(120);
    });

    it('should call appliedPercent', () => {
        helper.isForeignCurrency = true;
        const activeData: any = {
            localAmount: 500,
            foreignBalance: 5000,
            localValue: 500,
            foreignValue: 349,
            foreignCurrency: 'USD',
            balance: 500,
            isCreditWip: false,
            localCurrency: 'AUD',
            exchRate: 1.5,
            localDeciamlPlaces: 2,
            foreignDecimalPlaces: 2,
            splitPercent: 50
        };
        jest.spyOn(helper, 'appliedAmount').mockReturnValue(50);
        const validRows = [{ splitPercent: 10 }, { splitPercent: 20 }];
        const result = helper.appliedPercent(validRows, true, activeData);
        expect(result).toBe(30);
    });

    it('should set LocalAndForeignValue', () => {
        helper.isForeignCurrency = true;
        const form = {
            dirty: true,
            patchValue: jest.fn(),
            reset: jest.fn(),
            controls: {
                splitPercent: {
                    setErrors: jest.fn(),
                    setValue: jest.fn(),
                    value: 50
                },
                amount: {
                    setErrors: jest.fn(),
                    setValue: jest.fn(),
                    markAsPristine: jest.fn(),
                    value: 300
                }
            }
        };
        jest.spyOn(helper, 'appliedAmount').mockReturnValue(50);
        const result = helper.setLocalAndForeignValue(form, SplitWipType.amount);
        expect(form.patchValue).toBeCalled();
        expect(result).toBeTruthy();
    });

    it('should set adjustLocalValue', () => {
        const form = {
            dirty: true,
            patchValue: jest.fn(),
            reset: jest.fn(),
            controls: {
                splitPercent: {
                    setErrors: jest.fn(),
                    setValue: jest.fn(),
                    value: 50
                },
                localValue: {
                    setErrors: jest.fn(),
                    setValue: jest.fn()
                }
            }
        };
        helper.isForeignCurrency = true;
        const currentRow: any = {
            localAmount: 500,
            foreignBalance: 500,
            localValue: 50,
            foreignValue: 349,
            foreignCurrency: 'USD',
            balance: 50,
            isCreditWip: false,
            localCurrency: 'AUD',
            exchRate: 1.5,
            localDeciamlPlaces: 2,
            foreignDecimalPlaces: 2,
            formGroup: {
                value: {
                    localValue: 250
                }
            }
        };

        const validRows = [{ foreignValue: 100, localValue: 100 }, { foreignValue: 20, localValue: 300 }];
        jest.spyOn(helper, 'appliedAmount').mockReturnValue(50);
        jest.spyOn(helper, 'splitPercentageBalance').mockReturnValue(10);
        helper.adjustLocalValue(currentRow, validRows, form, currentRow, SplitWipType.amount);
        expect(form.controls.localValue.setValue).toHaveBeenCalled();
        expect(form.controls.splitPercent.setValue).toHaveBeenCalled();
    });

    it('should call getAmount', () => {
        helper.isForeignCurrency = false;
        const result = helper.getAmount(10);
        expect(result).toBe(50);
    });

    it('should call splitItemsEqually', () => {
        helper.isForeignCurrency = false;
        const items = [{ splitPercent: 10, foreignValue: 100, localValue: 10 }, { splitPercent: 20, foreignValue: 200, localValue: 20 }];
        jest.spyOn(helper, 'splitPercentageBalance');
        jest.spyOn(helper, 'splitForeignBalance');
        jest.spyOn(helper, 'splitBalance');
        helper.splitItemsEqually(items);
        expect(helper.splitPercentageBalance).toHaveBeenCalledWith(items);
        expect(helper.splitForeignBalance).toHaveBeenCalledWith(items);
        expect(helper.splitBalance).toHaveBeenCalledWith(items);
    });

    it('should call splitBalance', () => {
        helper.isForeignCurrency = false;
        const items = [{ splitPercent: 10, foreignValue: 100, localValue: 10 }, { splitPercent: 20, foreignValue: 200, localValue: 20 }];
        jest.spyOn(helper, 'splitPercentageBalance');
        const result = helper.splitBalance(items);
        expect(result).toBe(470);
    });

    it('should call splitForeignBalance', () => {
        helper.isForeignCurrency = true;
        const items = [{ splitPercent: 10, foreignValue: 15, localValue: 10 }, { splitPercent: 20, foreignValue: 20, localValue: 20 }];
        const result = helper.splitForeignBalance(items);
        expect(result).toBe(15);
    });

    it('should call splitPercentageBalance', () => {
        helper.isForeignCurrency = false;
        const items = [{ splitPercent: 10, foreignValue: 100, localValue: 10 }, { splitPercent: 20, foreignValue: 200, localValue: 20 }];
        const result = helper.splitPercentageBalance(items);
        expect(result).toBe(70);
    });

    it('should call round', () => {
        const result = helper.round(100.576, 2);
        expect(result).toBe(100.58);
    });

});