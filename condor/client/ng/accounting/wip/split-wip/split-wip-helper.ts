import { GridColumnDefinition } from 'shared/component/grid/ipx-grid.models';
import * as _ from 'underscore';
import { SplitWipData, SplitWipType } from './split-wip.model';

export class SplitWipHelper {
    isForeignCurrency: boolean;
    constructor(private readonly splitWipData: SplitWipData) {
        this.isForeignCurrency = splitWipData.foreignCurrency ? true : false;
    }

    appliedAmount = (validRows: any, isAdding: boolean, activeDataItemAmount: number): number => {
        return isAdding || validRows.length === 0 ? this.totalAllocatedAmount(validRows) : this.totalAllocatedAmount(validRows) - activeDataItemAmount;
    };

    totalAllocatedAmount = (validRows: any) => {
        if (validRows.length === 0) { return 0; }

        return this.isForeignCurrency ? this.round(validRows.map(x => x.foreignValue).reduce((a, b) => a + b), this.splitWipData.foreignDecimalPlaces)
            : this.round(validRows.map(x => x.localValue).reduce((a, b) => a + b), this.splitWipData.localDeciamlPlaces);
    };

    appliedPercent = (validRows: any, isAdding: boolean, activeDataItemPercent: number): number => {
        if (validRows.length === 0) { return 0; }

        const percentageAllocated = validRows.map(x => x.splitPercent).reduce((a, b) => a + b);

        return isAdding ? percentageAllocated : this.round(percentageAllocated - activeDataItemPercent, 2);
    };

    setLocalAndForeignValue = (form: any, splitByType: SplitWipType): boolean => {
        const amount = form.controls.amount.value;
        if (splitByType === SplitWipType.amount) {
            if (!amount || amount === 0) {
                form.controls.amount.markAsTouched();
                form.controls.amount.markAsDirty();
                form.controls.amount.setErrors({ required: true });

                return false;
            }
        } else {
            if (!form.controls.splitPercent.value) {
                form.controls.splitPercent.markAsTouched();
                form.controls.splitPercent.markAsDirty();
                form.controls.splitPercent.setErrors({ required: true });

                return false;
            }
        }
        const localAmount = this.isForeignCurrency ? amount * (this.splitWipData.balance / this.splitWipData.foreignBalance) : amount;
        form.patchValue({
            localValue: this.round(localAmount, this.splitWipData.localDeciamlPlaces),
            foreignValue: this.isForeignCurrency ? this.round(amount, this.splitWipData.foreignDecimalPlaces) : null
        });

        return true;
    };

    adjustLocalValue = (currentRow: any, validRows: any, form: any, activeDataItem: any, splitByType: SplitWipType, isAdding: boolean): void => {
        if (validRows.length === 0 || splitByType !== SplitWipType.amount) { return; }
        const currentLocalValue = currentRow.formGroup.value.localValue;
        let assignedLocalValue = validRows.map(x => x.localValue).reduce((a, b) => a + b);
        if (!isAdding) {
            assignedLocalValue = assignedLocalValue - activeDataItem.localValue;
        }
        if ((assignedLocalValue + currentLocalValue) > this.splitWipData.balance) {
            const diff = assignedLocalValue + currentLocalValue - this.splitWipData.balance;
            const adjustedValue = this.round(currentRow.formGroup.value.localValue - diff, this.splitWipData.localDeciamlPlaces);
            form.controls.localValue.setValue(adjustedValue);
            activeDataItem.localValue = adjustedValue;
            const percent = this.splitPercentageBalance(validRows);
            form.controls.splitPercent.setValue(percent);
        }
        if (this.splitWipData.foreignBalance && this.splitWipData.foreignBalance !== 0) {
            const assignedForeignValue = validRows.map(x => x.foreignValue).reduce((a, b) => a + b);
            const unAllocatedAmount = this.splitWipData.foreignBalance - (assignedForeignValue + currentRow.formGroup.value.foreignValue);
            if (unAllocatedAmount === 0 && (assignedLocalValue + currentLocalValue) < this.splitWipData.balance) {
                const diff = this.splitWipData.balance - (assignedLocalValue + currentLocalValue);
                const adjustedValue = this.round(currentRow.formGroup.value.localValue + diff, this.splitWipData.localDeciamlPlaces);
                form.controls.localValue.setValue(adjustedValue);
                activeDataItem.localValue = adjustedValue;
            }
        }
    };

    getAmount = (value: number) => {
        return this.isForeignCurrency ?
            this.round(this.splitWipData.foreignBalance * value / 100, this.splitWipData.foreignDecimalPlaces)
            : this.round(this.splitWipData.balance * value / 100, this.splitWipData.localDeciamlPlaces);
    };

    splitItemsEqually = (items: any) => {
        items.forEach(wip => {
            wip.splitPercent = this.round((1 / items.length) * 100, 2);
            wip.localValue = this.round(this.splitWipData.balance / items.length, this.splitWipData.localDeciamlPlaces);
            if (this.isForeignCurrency) {
                wip.foreignValue = this.round(this.splitWipData.foreignBalance / items.length, this.splitWipData.foreignDecimalPlaces);
                wip.amount = wip.foreignValue;
            } else {
                wip.amount = wip.localValue;
            }
        });

        const lastWip: any = _.last(items);
        lastWip.splitPercent = this.round(lastWip.splitPercent + this.splitPercentageBalance(items), 2);
        lastWip.foreignValue = this.round(lastWip.foreignValue + this.splitForeignBalance(items), this.splitWipData.foreignDecimalPlaces);
        lastWip.localValue = this.round(lastWip.localValue + this.splitBalance(items), this.splitWipData.localDeciamlPlaces);
    };

    splitBalance = (items: Array<any>): number => {
        const totalSum = items.reduce((sum, current) => sum + current.localValue, 0);

        return this.round(this.splitWipData.balance - totalSum, this.splitWipData.localDeciamlPlaces);
    };

    splitForeignBalance = (items: Array<any>): number => {
        if (!this.isForeignCurrency) { return null; }
        const totalSum = items.reduce((sum, current) => sum + current.foreignValue, 0);

        return this.round(this.splitWipData.foreignBalance - totalSum, this.splitWipData.foreignDecimalPlaces);
    };

    splitPercentageBalance = (items: Array<any>): number => {
        const totalSum = items.reduce((sum, current) => sum + current.splitPercent, 0);

        return this.round(100 - totalSum, 2);
    };

    round = (num: number, decimalPlaces: number): number => {
        const places = !decimalPlaces ? this.splitWipData.localDeciamlPlaces : decimalPlaces;

        return Number(num.toFixed(places));
    };

    getColumns = (): Array<GridColumnDefinition> => {
        const columns: Array<GridColumnDefinition> = [
            {
                title: 'wip.splitWip.name',
                field: 'name',
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.case',
                field: 'case',
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.staff',
                field: 'staff',
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.profitCentre',
                field: 'profitCentre',
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.localValue',
                field: 'localValue',
                template: true,
                headerClass: 'k-header-right-aligned',
                width: 110,
                sortable: false
            },
            {
                title: 'wip.splitWip.foreignAmount',
                field: 'foreignValue',
                hidden: !this.isForeignCurrency,
                template: true,
                headerClass: 'k-header-right-aligned',
                width: 110,
                sortable: false
            },
            {
                title: 'wip.splitWip.exchRate',
                field: 'exchRate',
                hidden: !this.isForeignCurrency,
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.splitPercent',
                field: 'splitPercent',
                template: true,
                sortable: false
            },
            {
                title: 'wip.splitWip.narrative',
                field: 'narrative',
                template: true,
                sortable: false
            }
        ];

        return columns;
    };
}