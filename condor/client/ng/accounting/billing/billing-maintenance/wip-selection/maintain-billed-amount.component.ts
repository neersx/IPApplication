import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { WipCategory } from 'accounting/billing/billing.model';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, take } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { IpxDestroy } from 'shared/utilities/ipx-destroy';

@Component({
    selector: 'ipx-billed-amount',
    templateUrl: './maintain-billed-amount.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [IpxDestroy]
})
export class MaintainBilledAmountComponent implements OnInit {
    @Input() dataItem: any;
    @Input() reasons: any;
    @Input() isWipWriteDownRestricted: boolean;
    @Input() writeDownLimit: number;
    @Input() isCreditNote: boolean;
    @Input() sellRateOnlyForNewWip: boolean;
    formGroup: any;
    get transactionTypeEnum(): typeof TransactionType {
        return TransactionType;
    }
    formData = {
        transactionType: TransactionType.none
    };
    numericStyle = { maxWidth: '150px', marginLeft: '-10px' };
    errorStyle = { marginLeft: '-80px' };
    showWriteUp: boolean;
    onClose$ = new Subject();
    @Input() localCurrency: string;
    @Input() localDecimalPlaces: number;
    @ViewChild('reasonElement', { static: false }) reasonElement: any;
    @ViewChild('localBilled', { static: false }) localBilled: any;
    @ViewChild('foreignBilled', { static: false }) foreignBilled: any;
    shouldShowPartialBilling = true;

    constructor(private readonly sbsModalRef: BsModalRef, private readonly fb: FormBuilder,
        private readonly cdRef: ChangeDetectorRef, private readonly notificationService: IpxNotificationService) {
    }

    ngOnInit(): void {
        this.createFormGroup();
        if (this.dataItem.TransactionType) {
            this.showWriteUp = this.dataItem.TransactionType === this.transactionTypeEnum.writeUp;
            this.formData.transactionType = this.dataItem.TransactionType;
        }
        this.cdRef.markForCheck();

        this.formGroup.controls.LocalBilled.valueChanges
            .pipe(debounceTime(500), distinctUntilChanged())
            .subscribe((value) => {
                if (value !== null) {
                    let localBilled = value;
                    if (this.dataItem.Balance * localBilled < 0) {
                        localBilled = localBilled * -1;
                        this.formGroup.controls.LocalBilled.setValue(localBilled, { emitEvent: false });
                    }
                    if (this.dataItem.ForeignBalance && this.dataItem.Balance !== 0) {
                        const exchRate = this.getWipExchRate(this.dataItem);
                        if (this.dataItem.IsAutoWriteUp && exchRate) {
                            this.formGroup.controls.ForeignBilled.setValue(this.round(localBilled * exchRate, this.dataItem.ForeignDecimalPlaces), { emitEvent: false });
                        } else {
                            this.formGroup.controls.ForeignBilled.setValue(this.round(localBilled * (this.dataItem.ForeignBalance / this.dataItem.Balance), this.dataItem.ForeignDecimalPlaces), { emitEvent: false });
                        }
                    }
                    if (value === this.dataItem.Balance) {
                        this.setTransactionTypeNone();
                    } else {
                        this.shouldShowPartialBilling = localBilled !== 0;
                        this.onBilledChange(this.dataItem.Balance < localBilled ? true : false);
                    }
                } else {
                    this.setTransactionTypeNone();
                }
            });

        this.formGroup.controls.ForeignBilled.valueChanges
            .pipe(debounceTime(500), distinctUntilChanged())
            .subscribe((value) => {
                if (value !== null) {
                    let foreignBilled = value;
                    if (this.dataItem.ForeignBalance * value < 0) {
                        foreignBilled = value * -1;
                        this.formGroup.controls.ForeignBilled.setValue(foreignBilled, { emitEvent: false });
                    }
                    if (this.dataItem.Balance && this.dataItem.Balance !== 0) {
                        const exchRate = this.getWipExchRate(this.dataItem);
                        if (this.dataItem.IsAutoWriteUp && exchRate) {
                            this.formGroup.controls.LocalBilled.setValue(this.round(foreignBilled / exchRate, this.localDecimalPlaces), { emitEvent: false });
                        } else {
                            this.formGroup.controls.LocalBilled.setValue(this.round(foreignBilled / (this.dataItem.ForeignBalance / this.dataItem.Balance), this.localDecimalPlaces), { emitEvent: false });
                        }
                    }
                    if (value === this.dataItem.ForeignBalance) {
                        this.setTransactionTypeNone();
                    } else {
                        this.shouldShowPartialBilling = foreignBilled !== 0;
                        this.onBilledChange(this.dataItem.ForeignBalance < foreignBilled ? true : false);
                    }
                } else {
                    this.setTransactionTypeNone();
                }
            });
    }

    getWipExchRate = (wip: any): number => {

        return this.sellRateOnlyForNewWip || wip.WipCategory === WipCategory.ServiceCharge ? wip.WipSellRate : wip.WipBuyRate;
    };

    setTransactionTypeNone = () => {
        this.formData.transactionType = this.transactionTypeEnum.none;
        this.formGroup.controls.TransactionType.setValue(this.formData.transactionType, { emitEvent: false });
        this.formGroup.controls.LocalVariation.setValue(null);
        this.formGroup.controls.ForeignVariation.setValue(null);
        this.formGroup.controls.ReasonCode.setValue(null);
    };

    onBilledChange = (showWriteUp: boolean) => {
        this.showWriteUp = showWriteUp;
        this.setVariation();
        if (this.showWriteUp) {
            this.formData.transactionType = this.transactionTypeEnum.writeUp;
        } else {
            if (this.formData.transactionType === this.transactionTypeEnum.writeUp || this.formData.transactionType === this.transactionTypeEnum.none) {
                this.formData.transactionType = this.transactionTypeEnum.writeDown;
            }
        }
        this.formGroup.controls.TransactionType.setValue(this.formData.transactionType, { emitEvent: false });
        if (this.formData.transactionType === this.transactionTypeEnum.writeDown) {
            this.validateWriteDown();
        }
        this.cdRef.markForCheck();
    };

    onTransactionTypeChange = () => {
        this.formGroup.controls.TransactionType.setValue(this.formData.transactionType);
        if (this.formData.transactionType === this.transactionTypeEnum.partialBilling) {
            this.formGroup.controls.ReasonCode.setValue(null);
            this.setControlErrorAsNull();

        } else if (this.formData.transactionType === this.transactionTypeEnum.writeDown) {
            this.validateWriteDown();
        }
        this.cdRef.markForCheck();
    };

    round = (num: number, decimalPlaces: number): number => {
        const places = !decimalPlaces ? 2 : decimalPlaces;

        return Number(num.toFixed(places));
    };

    setVariation = () => {
        this.formGroup.controls.LocalVariation.setValue(this.round(this.formGroup.value.LocalBilled - this.dataItem.Balance, this.localDecimalPlaces));
        if (this.dataItem.ForeignBalance) {
            this.formGroup.controls.ForeignVariation.setValue(this.round(this.formGroup.value.ForeignBilled - this.dataItem.ForeignBalance, this.dataItem.ForeignDecimalPlaces));
        }
    };

    validateWriteDown = (): boolean => {
        if (this.dataItem.ShouldPreventWriteDown) {
            this.setControlError('preventWriteDown');

            return false;
        }
        if (!this.isWipWriteDownRestricted) {
            this.setControlErrorAsNull();

            return true;
        }
        if (!this.writeDownLimit || this.writeDownLimit === 0) {
            this.setControlError('writeDownLimitNotProvided');

            return false;
        }
        if (this.writeDownLimit < this.formGroup.controls.LocalVariation.value * -1
            || (this.isCreditNote && this.writeDownLimit < this.formGroup.controls.LocalVariation.value)) {
            this.setControlError('writeDownLimit');

            return false;
        }

        this.setControlErrorAsNull();

        return true;
    };

    setControlErrorAsNull = () => {
        this.formGroup.controls.LocalBilled.setErrors(null);
        this.localBilled.showError$.next(false);
    };

    setControlError = (errorString: string) => {
        this.formGroup.controls.LocalBilled.markAsTouched();
        this.formGroup.controls.LocalBilled.markAsDirty();
        switch (errorString) {
            case 'preventWriteDown': {
                this.formGroup.controls.LocalBilled.setErrors({ 'billing.validations.preventWriteDown': true });
                break;
            }
            case 'writeDownLimitNotProvided': {
                this.formGroup.controls.LocalBilled.setErrors({ 'billing.validations.writeDownLimitNotProvided': true });
                break;
            }
            case 'writeDownLimit': {
                this.formGroup.controls.LocalBilled.setErrors({ 'billing.validations.writeDownLimit': true });
                break;
            }
            default: {
                break;
            }
        }
        this.localBilled.showError$.next(true);
    };

    createFormGroup = (): FormGroup => {
        const maxAllowedValue = 99999999999.99;
        this.formGroup = this.fb.group({
            UniqueReferenceId: new FormControl(this.dataItem.UniqueReferenceId),
            ReasonCode: new FormControl(this.dataItem.ReasonCode),
            LocalBilled: new FormControl(this.dataItem.LocalBilled, Validators.compose([Validators.max(maxAllowedValue)])),
            Balance: new FormControl(this.dataItem.Balance),
            LocalVariation: new FormControl(this.dataItem.LocalVariation),
            ForeignCurrency: new FormControl(this.dataItem.ForeignCurrency),
            ForeignBalance: new FormControl(this.dataItem.ForeignBalance),
            ForeignBilled: new FormControl(this.dataItem.ForeignBilled),
            ForeignVariation: new FormControl(this.dataItem.ForeignVariation),
            status: new FormControl(rowStatus.editing),
            TransactionType: new FormControl(this.dataItem.TransactionType ? this.dataItem.TransactionType : this.transactionTypeEnum.none),
            Description: new FormControl(this.dataItem.Description),
            TransactionDate: new FormControl(this.dataItem.TransactionDate),
            ShortNarrative: new FormControl(this.dataItem.ShortNarrative),
            WipCategoryDescription: new FormControl(this.dataItem.WipCategoryDescription),
            WipTypeDescription: new FormControl(this.dataItem.WipTypeDescription),
            WipCode: new FormControl(this.dataItem.WipCode),
            EntityName: new FormControl(this.dataItem.EntityName),
            ProfitCentreDescription: new FormControl(this.dataItem.ProfitCentreDescription)
        });

        return this.formGroup;
    };

    validateRequiredFiled(): boolean {
        if (!this.formGroup.controls.ReasonCode.value && this.formData.transactionType !== this.transactionTypeEnum.none && this.formData.transactionType !== this.transactionTypeEnum.partialBilling) {
            this.formGroup.controls.ReasonCode.markAsTouched();
            this.formGroup.controls.ReasonCode.markAsDirty();
            this.formGroup.controls.ReasonCode.setErrors({ required: true });
            this.reasonElement.el.nativeElement.querySelector('select').click();
            this.cdRef.detectChanges();

            return false;
        }

        return true;
    }

    apply = (): void => {
        if (this.formGroup.dirty && this.formGroup.status !== 'INVALID' && this.validateRequiredFiled()) {
            this.formGroup.setErrors(null);
            const status = { success: true, formGroup: this.formGroup };
            this.onClose$.next(status);
            this.sbsModalRef.hide();
        }
    };

    cancel = (): void => {
        if (this.formGroup.dirty) {
            const modal = this.notificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm(false);
                });
        } else {
            this.resetForm(false);
        }
    };

    resetForm = (isDirty: boolean): void => {
        this.formGroup.reset();
        const formStatus = { success: isDirty, formGroup: this.formGroup };
        this.onClose$.next(formStatus);
        this.sbsModalRef.hide();
    };
}

export enum TransactionType {
    writeUp = 'writeUp',
    writeDown = 'writeDown',
    partialBilling = 'partialBilling',
    none = 'none'
}

export enum AdjustedType {
    writeUp = 'writeUp',
    writeDown = 'writeDown',
    none = 'none'
}