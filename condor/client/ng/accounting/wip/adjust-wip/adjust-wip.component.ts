import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, Renderer2, ViewChild } from '@angular/core';
import { FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { TimeRecordingService } from 'accounting/time-recording/time-recording-service';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { WarningService } from 'accounting/warnings/warning-service';
import { NotificationService } from 'ajs-upgraded-providers/notification-service.provider';
import { WindowParentMessagingService } from 'core/window-parent-messaging.service';
import { of } from 'rxjs';
import { distinctUntilChanged, switchMap, take, takeUntil, takeWhile } from 'rxjs/operators';
import { dataTypeEnum } from 'shared/component/forms/ipx-data-type/datatype-enum';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import { AdjustmentTypeEnum, TransactionTypeEnum, ViewSupportData } from './adjust-wip.model';
import { AdjustWipService } from './adjust-wip.service';

@Component({
    selector: 'ipx-adjust-wip',
    templateUrl: './adjust-wip.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class AdjustWipComponent implements OnInit {
    @ViewChild('localValueEl', { static: false }) localValueEl: any;
    @ViewChild('localAdjustmentEl', { static: false }) localAdjustmentEl: any;
    @ViewChild('foreignValueEl', { static: false }) foreignValueEl: any;
    @ViewChild('foreignAdjustmentEl', { static: false }) foreignAdjustmentEl: any;
    @ViewChild('newStaffEl', { static: false }) newStaffEl: any;
    @ViewChild('newCaseEl', { static: false }) newCaseEl: any;
    @ViewChild('newDebtorEl', { static: false }) newDebtorEl: any;
    @ViewChild('newProductEl', { static: false }) newProductEl: any;
    @ViewChild('debitNoteTextEl', { static: false }) debitNoteTextEl: any;
    formGroup: any;
    viewData: ViewSupportData;
    originalWipAdjustmentData: any;
    entityKey: number;
    transKey: number;
    wipSeqKey: number;
    adjustmentType: number;
    dataType: any = dataTypeEnum;
    localCurrency: string;
    foreignCurrency: string;
    hostId = null;
    numericStyle = { maxWidth: '150px', marginLeft: '-10px' };
    isItemDateWarningSuppressed = false;
    get transactionTypeEnum(): typeof TransactionTypeEnum {
        return TransactionTypeEnum;
    }
    formData = {
        transactionType: TransactionTypeEnum.debit
    };

    constructor(private readonly service: AdjustWipService, private readonly cdRef: ChangeDetectorRef, private readonly fb: FormBuilder, private readonly datePipe: DatePipe, private readonly notificationService: NotificationService, private readonly ipxNotificationService: IpxNotificationService, private readonly windowParentMessagingService: WindowParentMessagingService, private readonly timeService: TimeRecordingService, private readonly warningChecker: WarningCheckerService, readonly warningService: WarningService) {
    }

    ngOnInit(): void {
        this.createFormGroup();
        this.service.getAdjustWipSupportData$().subscribe((response: any) => {
            this.viewData = response;
            this.warningService.restrictOnWip = this.viewData.restrictOnWIP;
            this.warningChecker.restrictOnWip = this.viewData.restrictOnWIP;
            this.service.getItemForWipAdjustment$(this.entityKey, this.transKey, this.wipSeqKey).subscribe((res: any) => {
                if (res && res.alerts && res.alerts.length > 0) {
                    const message = res.alerts[0];
                    this.notificationService.info({
                        title: 'modal.unableToComplete',
                        message,
                        continue: 'Ok'
                    }).then(() => {
                        this.closeModal();
                    });

                    return;
                }
                this.originalWipAdjustmentData = res;
                this.setFormData(res);
                this.cdRef.markForCheck();
            });
        });
    }

    validateWriteLimit(value: number): void {
        if (!value) {
            return;
        }
        this.formData.transactionType = (value && value < 0) ? TransactionTypeEnum.credit : TransactionTypeEnum.debit;
        if (this.viewData.wipWriteDownRestricted && this.viewData.writeDownLimit) {
            this.formGroup.controls.localAdjustment.markAsDirty();
            this.formGroup.controls.localAdjustment.markAsTouched();
            if (value * -1 > this.viewData.writeDownLimit) {
                this.formGroup.controls.localAdjustment.setErrors({ writeDownLimitMessage: true });
            } else {
                this.formGroup.controls.localAdjustment.setErrors(null);
            }
            this.cdRef.markForCheck();
        }
    }

    calculateByLocalValue(): void {
        if (!this.formGroup.controls.localValue.value) {
            this.clearAll();

            return;
        }

        this.formGroup.patchValue({ localAdjustment: +this.formGroup.controls.localValue.value - +this.formGroup.controls.currentLocalValue.value });
        this.formGroup.patchValue({ foreignValue: +this.formGroup.controls.localValue.value * (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.formGroup.patchValue({ foreignAdjustment: +this.formGroup.controls.localAdjustment.value * (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.validateWriteLimit(this.formGroup.controls.localAdjustment.value);
    }

    calculateByLocalAdjustedValue(): void {
        if (!this.formGroup.controls.localAdjustment.value) {
            this.clearAll();

            return;
        }

        this.formGroup.patchValue({ localValue: +this.formGroup.controls.localAdjustment.value + +this.formGroup.controls.currentLocalValue.value });
        this.formGroup.patchValue({ foreignValue: +this.formGroup.controls.localValue.value * (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.formGroup.patchValue({ foreignAdjustment: +this.formGroup.controls.localAdjustment.value * (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.validateWriteLimit(this.formGroup.controls.localAdjustment.value);
    }

    calculateByForeignValue(): void {
        if (!this.formGroup.controls.foreignValue.value) {
            this.clearAll();

            return;
        }

        this.formGroup.patchValue({ foreignAdjustment: +this.formGroup.controls.foreignValue.value - +this.formGroup.controls.currentForeignValue.value });
        this.formGroup.patchValue({ localValue: +this.formGroup.controls.foreignValue.value / (+this.formGroup.controls.currentForeignValue.value / this.formGroup.controls.currentLocalValue.value) });
        this.formGroup.patchValue({ localAdjustment: +this.formGroup.controls.foreignAdjustment.value / (+this.formGroup.controls.currentForeignValue.value / this.formGroup.controls.currentLocalValue.value) });
        this.validateWriteLimit(this.formGroup.controls.localAdjustment.value);
    }

    calculateByForeignAdjustedValue(): void {
        if (!this.formGroup.controls.foreignAdjustment.value) {
            this.clearAll();

            return;
        }

        this.formGroup.patchValue({ foreignValue: +this.formGroup.controls.foreignAdjustment.value + +this.formGroup.controls.currentForeignValue.value });
        this.formGroup.patchValue({ localValue: +this.formGroup.controls.foreignValue.value / (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.formGroup.patchValue({ localAdjustment: +this.formGroup.controls.foreignAdjustment.value / (+this.formGroup.controls.currentForeignValue.value / +this.formGroup.controls.currentLocalValue.value) });
        this.validateWriteLimit(this.formGroup.controls.localAdjustment.value);
    }

    clearAll(): void {
        this.formGroup.patchValue({ localValue: null, localAdjustment: null, foreignValue: null, foreignAdjustment: null });
        this.localValueEl.clearValue();
        this.localAdjustmentEl.clearValue();
        if (this.foreignValueEl) {
            this.foreignValueEl.clearValue();
            this.foreignAdjustmentEl.clearValue();
        }
        this.cdRef.markForCheck();
    }

    createFormGroup = (): FormGroup => {
        const maxAllowedValue = 99999999999.99;
        this.formGroup = this.fb.group({
            requestedByStaff: new FormControl(),
            wipCode: new FormControl(),
            reason: new FormControl(),
            transactionDate: new FormControl(),
            originalTransDate: new FormControl(),
            localValue: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            localAdjustment: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            currentLocalValue: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            foreignValue: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            foreignAdjustment: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            currentForeignValue: new FormControl(null, Validators.compose([Validators.max(maxAllowedValue)])),
            newCase: new FormControl(),
            newDebtor: new FormControl(),
            newStaff: new FormControl(),
            newProduct: new FormControl(),
            currentCase: new FormControl(),
            currentDebtor: new FormControl(),
            currentStaff: new FormControl(),
            currentProduct: new FormControl(),
            isAssociatedDiscount: new FormControl(false),
            debitNoteText: new FormControl(null),
            newNarrative: new FormControl()
        });

        return this.formGroup;
    };

    setFormData(data): any {
        this.localCurrency = data.adjustWipItem.originalWIPItem.localCurrency;
        this.foreignCurrency = data.adjustWipItem.originalWIPItem.foreignCurrency;
        this.adjustmentType = data.adjustWipItem.adjustmentType;
        this.formGroup.patchValue({
            requestedByStaff: { key: data.adjustWipItem.requestedByStaffKey, code: data.adjustWipItem.requestedByStaffCode, displayName: data.adjustWipItem.requestedByStaffName },
            wipCode: data.adjustWipItem.originalWIPItem.wipDescription,
            reason: null,
            transactionDate: data.adjustWipItem.transDate ? new Date(data.adjustWipItem.transDate) : null,
            originalTransDate: data.adjustWipItem.originalWIPItem.transDate ? new Date(data.adjustWipItem.originalWIPItem.transDate) : null,
            localValue: null,
            localAdjustment: null,
            currentLocalValue: data.adjustWipItem.originalWIPItem.balance,
            foreignValue: null,
            foreignAdjustment: null,
            currentForeignValue: data.adjustWipItem.originalWIPItem.foreignBalance,
            currentCase: { key: data.adjustWipItem.originalWIPItem.caseKey, code: data.adjustWipItem.originalWIPItem.irn },
            currentDebtor: {
                key: data.adjustWipItem.originalWIPItem.acctClientKey, code: data.adjustWipItem.originalWIPItem.acctClientCode, displayName: data.adjustWipItem.originalWIPItem.acctClientName
            },
            currentStaff: { key: data.adjustWipItem.originalWIPItem.staffKey, code: data.adjustWipItem.originalWIPItem.staffCode, displayName: data.adjustWipItem.originalWIPItem.staffName },
            debitNoteText: data.adjustWipItem.originalWIPItem.debitNoteText,
            newNarrative: { key: data.adjustWipItem.originalWIPItem.narrativeKey, code: data.adjustWipItem.originalWIPItem.narrativeCode, value: data.adjustWipItem.originalWIPItem.narrativeTitle }
        });
    }

    private handleDebitNoteTextField(): void {
        if (!this.formGroup.controls.debitNoteText.value && this.formGroup.controls.debitNoteText.invalid) {
            this.formGroup.patchValue({ debitNoteText: null });
            this.formGroup.controls.debitNoteText.markAsPristine();
        }
    }

    onTransactionTypeChange(type: any): void {
        if (type === this.transactionTypeEnum.credit || type === this.transactionTypeEnum.debit) {
            this.formGroup.patchValue({ localAdjustment: this.formGroup.controls.localAdjustment.value * -1 });
            this.calculateByLocalAdjustedValue();
            this.formGroup.patchValue({
                newCase: null,
                newStaff: null,
                newProduct: null,
                newDebtor: null
            });
            this.formGroup.controls.newCase.markAsPristine();
            this.formGroup.controls.newStaff.markAsPristine();
            this.formGroup.controls.newProduct.markAsPristine();
            this.formGroup.controls.newDebtor.markAsPristine();
            this.adjustmentType = type === this.transactionTypeEnum.credit ? AdjustmentTypeEnum.creditWipAdjustment : AdjustmentTypeEnum.debitWipAdjustment;
        }
        if (type === this.transactionTypeEnum.debtor) {
            this.formGroup.patchValue({
                localValue: null,
                localAdjustment: null,
                foreignValue: null,
                foreignAdjustment: null,
                newCase: null,
                newStaff: null,
                newProduct: null
            });
            this.formGroup.controls.newCase.markAsPristine();
            this.formGroup.controls.newStaff.markAsPristine();
            this.formGroup.controls.newProduct.markAsPristine();
            this.adjustmentType = AdjustmentTypeEnum.debtorWipTransfer;
        }
        if (type === this.transactionTypeEnum.staff) {
            this.formGroup.patchValue({
                localValue: null,
                localAdjustment: null,
                foreignValue: null,
                foreignAdjustment: null,
                newCase: null,
                newDebtor: null,
                newProduct: null
            });
            this.formGroup.controls.newCase.markAsPristine();
            this.formGroup.controls.newDebtor.markAsPristine();
            this.formGroup.controls.newProduct.markAsPristine();
            this.adjustmentType = AdjustmentTypeEnum.staffWipTransfer;
        }
        if (type === this.transactionTypeEnum.case) {
            this.formGroup.patchValue({
                localValue: null,
                localAdjustment: null,
                foreignValue: null,
                foreignAdjustment: null,
                newStaff: null,
                newDebtor: null,
                newProduct: null
            });
            this.formGroup.controls.newStaff.markAsPristine();
            this.formGroup.controls.newDebtor.markAsPristine();
            this.formGroup.controls.newProduct.markAsPristine();
            this.adjustmentType = AdjustmentTypeEnum.caseWipTransfer;
        }
        if (type === this.transactionTypeEnum.product) {
            this.formGroup.patchValue({
                localValue: null,
                localAdjustment: null,
                foreignValue: null,
                foreignAdjustment: null,
                newStaff: null,
                newDebtor: null,
                newCase: null
            });
            this.formGroup.controls.newStaff.markAsPristine();
            this.formGroup.controls.newDebtor.markAsPristine();
            this.formGroup.controls.newCase.markAsPristine();
            this.adjustmentType = AdjustmentTypeEnum.productWipTransfer;
        }
        if (type === this.transactionTypeEnum.narrative) {
            this.formGroup.patchValue({
                localValue: null,
                localAdjustment: null,
                foreignValue: null,
                foreignAdjustment: null,
                newStaff: null,
                newDebtor: null,
                newCase: null,
                newProduct: null
            });
            this.formGroup.controls.newStaff.markAsPristine();
            this.formGroup.controls.newDebtor.markAsPristine();
            this.formGroup.controls.newCase.markAsPristine();
            this.formGroup.controls.newProduct.markAsPristine();
            this.adjustmentType = null;
        }
        this.handleDebitNoteTextField();
        this.formData.transactionType = type;
        this.clearAll();
        this.cdRef.markForCheck();
    }

    onCaseChanged(event: any): void {
        if (!!event && event.key) {
            const caseKey = event.key;
            of(caseKey).pipe(
                distinctUntilChanged(),
                switchMap((newCaseKey) => {
                    return this.warningChecker.performCaseWarningsCheck(newCaseKey, new Date());
                })
            ).subscribe((result: boolean) => this._handleCaseWarningsResult(result));
        }
    }

    onDebtorChanged(event: any): void {
        if (!!event && event.key) {
            this.warningChecker.performNameWarningsCheck(event.key, event.value, new Date())
                .pipe(take(1))
                .subscribe((result: boolean) => this._handleNameWarningResult(result));
        }
    }

    private readonly _handleNameWarningResult = (selected: boolean): void => {
        if (!selected) {
            this.formGroup.patchValue({ newDebtor: null });
            this.formGroup.controls.newDebtor.markAsPristine();
        }
    };

    private readonly _handleCaseWarningsResult = (selected: boolean): void => {
        if (!selected) {
            this.formGroup.patchValue({ newCase: null });
            this.formGroup.controls.newCase.markAsPristine();
        }
    };

    private validateRequiredFileds(): boolean {
        if (this.formGroup && this.formGroup.controls) {
            if (this.formData.transactionType === this.transactionTypeEnum.staff) {
                if (this.formGroup.controls.newStaff.value) {
                    this.formGroup.controls.newStaff.markAsPristine();
                    this.formGroup.controls.newStaff.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.newStaff.setErrors({ required: true });
                this.formGroup.controls.newStaff.markAsTouched();
                this.formGroup.controls.newStaff.markAsDirty();
                this.clickEvents();

                return false;
            } else if (this.formData.transactionType === this.transactionTypeEnum.debtor) {
                if (this.formGroup.controls.newDebtor.value) {
                    this.formGroup.controls.newDebtor.markAsPristine();
                    this.formGroup.controls.newDebtor.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.newDebtor.setErrors({ required: true });
                this.formGroup.controls.newDebtor.markAsTouched();
                this.formGroup.controls.newDebtor.markAsDirty();
                this.clickEvents();

                return false;
            } else if (this.formData.transactionType === this.transactionTypeEnum.case) {
                if (this.formGroup.controls.newCase.value) {
                    this.formGroup.controls.newCase.markAsPristine();
                    this.formGroup.controls.newCase.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.newCase.setErrors({ required: true });
                this.formGroup.controls.newCase.markAsTouched();
                this.formGroup.controls.newCase.markAsDirty();
                this.clickEvents();

                return false;
            } else if (this.formData.transactionType === this.transactionTypeEnum.debit || this.formData.transactionType === this.transactionTypeEnum.credit) {
                if (this.formGroup.controls.localValue.value) {
                    this.formGroup.controls.localValue.markAsPristine();
                    this.formGroup.controls.localValue.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.localValue.markAsTouched();
                this.formGroup.controls.localValue.markAsDirty();
                this.formGroup.controls.localValue.setErrors({ required: true });
                this.clickEvents();

                return false;
            } else if (this.formData.transactionType === this.transactionTypeEnum.product) {
                if (this.formGroup.controls.newProduct.value) {
                    this.formGroup.controls.newProduct.markAsPristine();
                    this.formGroup.controls.newProduct.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.newProduct.setErrors({ required: true });
                this.formGroup.controls.newProduct.markAsTouched();
                this.formGroup.controls.newProduct.markAsDirty();
                this.clickEvents();

                return false;
            } else if (this.formData.transactionType === this.transactionTypeEnum.narrative) {
                if (this.formGroup.controls.debitNoteText.value && this.formGroup.controls.debitNoteText.dirty) {
                    this.formGroup.controls.debitNoteText.markAsPristine();
                    this.formGroup.controls.debitNoteText.setErrors(null);
                    this.clickEvents();

                    return true;
                }
                this.formGroup.controls.debitNoteText.markAsTouched();
                if (this.formGroup.controls.debitNoteText.value && !this.formGroup.controls.debitNoteText.dirty) {
                    this.formGroup.controls.debitNoteText.markAsDirty();
                    this.formGroup.controls.debitNoteText.setErrors({ debitNoteTextNotModified: true });
                } else {
                    this.formGroup.controls.debitNoteText.markAsDirty();
                    this.formGroup.controls.debitNoteText.setErrors({ required: true });
                }

                this.clickEvents();

                return false;
            }
        }

        return true;
    }

    clickEvents(): void {
        if (this.formData.transactionType === this.transactionTypeEnum.debit || this.formData.transactionType === this.transactionTypeEnum.credit) {
            this.localValueEl.el.nativeElement.querySelector('input').click();
        }
        if (this.newCaseEl) {
            this.newCaseEl.el.nativeElement.querySelector('input').click();
        }
        if (this.newStaffEl) {
            this.newStaffEl.el.nativeElement.querySelector('input').click();
        }
        if (this.newDebtorEl) {
            this.newDebtorEl.el.nativeElement.querySelector('input').click();
        }
        if (this.newProductEl) {
            this.newProductEl.el.nativeElement.querySelector('input').click();
        }
        if (this.debitNoteTextEl) {
            this.debitNoteTextEl.el.nativeElement.querySelector('textarea').click();
        }
        this.cdRef.markForCheck();
    }

    submit(): void {
        const validForm = this.validateRequiredFileds();
        if (!validForm) {
            return;
        }

        if (this.formGroup.valid && this.formGroup.value && this.formGroup.dirty) {
            const formData = {
                isItemDateWarningSuppressed: this.isItemDateWarningSuppressed,
                entity: {
                    entityKey: this.entityKey,
                    transKey: this.transKey,
                    wipSeqNo: this.wipSeqKey,
                    logDateTimeStamp: this.originalWipAdjustmentData.adjustWipItem.logDateTimeStamp,
                    adjustmentType: this.adjustmentType,
                    newLocal: this.formGroup.value.localValue,
                    newForeign: this.formGroup.value.foreignValue,
                    transDate: this.timeService.toLocalDate(this.formGroup.value.transactionDate, false),
                    requestedByStaffKey: this.formGroup.value.requestedByStaff ? this.formGroup.value.requestedByStaff.key : null,
                    reasonCode: this.formGroup.value.reason,
                    newCaseKey: this.formGroup.controls.newCase.value ? this.formGroup.controls.newCase.value.key : null,
                    newAcctClientKey: this.formGroup.controls.newDebtor.value ? this.formGroup.controls.newDebtor.value.key : null,
                    newStaffKey: this.formGroup.controls.newStaff.value ? this.formGroup.controls.newStaff.value.key : null,
                    newProductKey: this.formGroup.controls.newProduct.value ? this.formGroup.controls.newProduct.value.key : null,
                    newNarrativeKey: this.formGroup.controls.newNarrative.value ? this.formGroup.controls.newNarrative.value.key : null,
                    newDebitNoteText: this.formGroup.value.debitNoteText,
                    adjustDiscount: this.formGroup.value.isAssociatedDiscount
                }
            };

            this.service.submitAdjustWip(formData).subscribe((res) => {
                if (res && res.validationErrors && res.validationErrors.length > 0) {
                    const message = res.validationErrors[0].message;
                    const title = 'modal.unableToComplete';
                    this.notificationService.alert({ title, message });
                } else {
                    this.notificationService.info({
                        title: 'wip.adjustWip.info',
                        message: 'wip.adjustWip.success',
                        continue: 'Ok'
                    }).then(() => {
                        this.closeModal();
                    });
                }
            });
        }
    }

    validateItemDate = (date: any) => {
        if (date) {
            this.isItemDateWarningSuppressed = false;
            const transDate = this.datePipe.transform(this.timeService.toLocalDate(date, true), 'yyyy-MM-dd');
            this.service.validateItemDate(transDate).subscribe((res: any) => {
                if (res && res.hasError) {
                    if (res.validationErrorList[0].warningCode) {
                        const confirmationRef = this.ipxNotificationService.openConfirmationModal('Warning', 'field.errors.ac124', 'Proceed', 'Cancel');
                        confirmationRef.content.confirmed$.pipe(take(1)).subscribe(() => {
                            this.isItemDateWarningSuppressed = true;
                        });
                        confirmationRef.content.cancelled$.pipe(takeWhile(() => !!confirmationRef))
                            .subscribe(() => { this.formGroup.controls.transactionDate.setValue(new Date()); });
                    } else {
                        switch (res.validationErrorList[0].errorCode) {
                            case 'AC126': return this.formGroup.controls.transactionDate.setErrors({ ac126: true });
                            case 'AC208': return this.formGroup.controls.transactionDate.setErrors({ ac208: true });
                            default: {
                                break;
                            }
                        }
                    }
                    this.cdRef.markForCheck();
                }
            });
        } else {
            this.formGroup.controls.transactionDate.setValue(new Date());
        }
        this.formGroup.controls.originalTransDate.markAsPristine();
        this.formGroup.controls.transactionDate.markAsPristine();
        this.cdRef.markForCheck();
    };

    closeModal = () => {
        this.windowParentMessagingService.postLifeCycleMessage({
            action: 'onChange',
            target: this.hostId,
            payload: {
                close: true
            }
        });
    };

    close = () => {
        if (this.formGroup.dirty) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.closeModal();
                });
        } else {
            this.closeModal();
        }
    };

    onNarrativeChange = (value: any): void => {
        if (value && value.text) {
            this.formGroup.controls.debitNoteText.setValue(value.text);
        } else {
            this.formGroup.controls.debitNoteText.setValue(null);
        }
    };
}