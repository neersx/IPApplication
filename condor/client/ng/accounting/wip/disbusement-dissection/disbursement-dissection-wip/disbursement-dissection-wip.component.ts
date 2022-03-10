import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, Input, OnInit, ViewChild } from '@angular/core';
import { AbstractControl, FormBuilder, FormControl, FormGroup, Validators } from '@angular/forms';
import { WarningCheckerService } from 'accounting/warnings/warning-checker.service';
import { BsModalRef } from 'ngx-bootstrap/modal';
import { of, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, take } from 'rxjs/operators';
import { rowStatus } from 'shared/component/grid/ipx-kendo-grid.component';
import { IpxNotificationService } from 'shared/component/notification/notification/ipx-notification.service';
import * as _ from 'underscore';
import { DisbursementDissectionService } from '../disbursement-dissection.service';

@Component({
    selector: 'disbursement-dissection-wip',
    templateUrl: './disbursement-dissection-wip.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class DisbursementDissectionWipComponent implements OnInit, AfterViewInit {
    @Input() isAdding: boolean;
    @Input() isAddAnother: boolean;
    @Input() grid: any;
    @Input() dataItem: any;
    @Input() rowIndex: any;
    @Input() currency: string;
    @Input() localCurrency: string;
    @Input() transactionDate: Date;
    @Input() entityKey: number;
    onClose$ = new Subject();
    isAddAnotherChecked = false;
    form: any;
    activityExtendQuery: any;
    caseExtendQuery: any;
    externalScope: any;
    numericStyle = { width: '150px', marginLeft: '-10px' };
    errorStyle = { marginLeft: '7px' };
    @ViewChild('caseEl', { static: false }) caseEl: any;
    @ViewChild('nameEl', { static: false }) nameEl: any;
    @ViewChild('staffEl', { static: false }) staffEl: any;

    constructor(private readonly service: DisbursementDissectionService,
        private readonly ipxNotificationService: IpxNotificationService,
        private readonly sbsModalRef: BsModalRef,
        private readonly formBuilder: FormBuilder,
        private readonly warningChecker: WarningCheckerService,
        private readonly cdRef: ChangeDetectorRef) {
        this.activityExtendQuery = this.activitiesFor.bind(this);
        this.caseExtendQuery = this.casesFor.bind(this);
        this.externalScope = this.nameExternalScopeForCase.bind(this);
    }

    ngOnInit(): void {
        this.createFormGroup(this.dataItem);
        this.isAddAnotherChecked = !this.isAdding ? false : this.service.isAddAnotherChecked.getValue();
    }

    ngAfterViewInit(): void {
        if (!this.isAddAnother) {
            this.form.markAsPristine();
        }

        this.form.controls.foreignAmount.valueChanges
            .pipe(debounceTime(500), distinctUntilChanged())
            .subscribe((value) => {
                if (value) {
                    this.form.controls.amount.setValue(null, { emitEvent: false });
                    this.calculateWip(value, true);
                }
            });

        this.form.controls.amount.valueChanges
            .pipe(debounceTime(500), distinctUntilChanged())
            .subscribe((value) => {
                if (value) {
                    this.calculateWip(value, true);
                }
            });
        this.form.controls.amount.setErrors(null);
        this.form.controls.foreignAmount.setErrors(null);
        this.form.markAsPristine();
    }

    calculateWip = (value: number, calledFromAmount = false) => {
        let amount = value;
        if (!calledFromAmount) {
            amount = this.currency ? this.form.controls.foreignAmount.value : this.form.controls.amount.value;
        }
        if (amount && (this.case.value || this.name.value) && this.disbursement.value) {
            this.getWipCost();
        } else if (!amount) {
            this.clearAllCost();
        }
    };

    createFormGroup = (dataItem: any): FormGroup => {
        if (dataItem) {
            const maxAllowedValue = 99999999999.99;
            this.form = this.formBuilder.group({
                id: new FormControl(this.rowIndex),
                date: new FormControl(this.transactionDate),
                name: new FormControl(dataItem.name),
                case: new FormControl(dataItem.case),
                staff: new FormControl(dataItem.staff),
                amount: new FormControl(dataItem.amount, Validators.compose([Validators.min(1), Validators.max(maxAllowedValue)])),
                foreignAmount: new FormControl(dataItem.foreignAmount, Validators.compose([Validators.min(1), Validators.max(maxAllowedValue)])),
                disbursement: new FormControl(dataItem.disbursement),
                quantity: new FormControl(dataItem.quantity),
                narrative: new FormControl(dataItem.narrative),
                debitNoteText: new FormControl(dataItem.debitNoteText),
                discount: new FormControl(dataItem.discount),
                foreignDiscount: new FormControl(dataItem.foreignDiscount),
                margin: new FormControl(dataItem.margin),
                foreignMargin: new FormControl(dataItem.foreignMargin),
                value: new FormControl(dataItem.value),
                foreignValue: new FormControl(dataItem.marginDiscount),
                marginDiscount: new FormControl(dataItem.marginDiscount),
                foreignMarginDiscount: new FormControl(dataItem.foreignMarginDiscount),
                localCost1: new FormControl(dataItem.costCalculation1),
                localCost2: new FormControl(dataItem.costCalculation2),
                exchangeRate: new FormControl(dataItem.exchangeRate),
                currency: new FormControl(this.currency),
                localCurrency: new FormControl(this.localCurrency)
            });

            return this.form;
        }

        return this.formBuilder.group({});
    };

    get name(): AbstractControl {
        return this.form.get('name');
    }
    get case(): AbstractControl {
        return this.form.get('case');
    }
    get staff(): AbstractControl {
        return this.form.get('staff');
    }
    get narrative(): AbstractControl {
        return this.form.get('narrative');
    }

    get disbursement(): AbstractControl {
        return this.form.get('disbursement');
    }

    onCheckChanged = (): void => {
        this.service.isAddAnotherChecked.next(this.isAddAnotherChecked);
    };

    casesFor(query: any): void {
        const selectedName = this.name ? this.name.value : null;
        const extended = _.extend({}, query, {
            nameKey: selectedName ? selectedName.key : null
        });

        return extended;
    }

    activitiesFor(query: any): void {
        const extended = _.extend({}, query, {
            isTimesheetActivity: false,
            onlyDisbursements: true
        });

        return extended;
    }

    nameExternalScopeForCase(): any {
        if (this.name && !!this.name.value) {
            return {
                label: 'Instructor',
                value: this.name.value ? this.name.value.displayName : null
            };
        }
    }

    caseNameMandatoryValidation(): boolean {
        if (this.form && this.form.controls) {
            if (!this.form.controls.case.value && !this.form.controls.name.value) {
                this.form.controls.case.setErrors({ caseOrNameRequired: true });
                this.form.controls.case.markAsTouched();
                this.form.controls.case.markAsDirty();
                this.form.controls.name.setErrors({ caseOrNameRequired: true });
                this.form.controls.name.markAsTouched();
                this.form.controls.name.markAsDirty();
                this.validateStaff();
                this.clickEvents();

                return false;
            }
            this.form.controls.case.setErrors(null);
            this.form.controls.name.setErrors(null);

            return true;
        }
    }

    clickEvents(): void {
        this.caseEl.el.nativeElement.querySelector('input').click();
        this.nameEl.el.nativeElement.querySelector('input').click();
    }

    validateStaff(): boolean {
        if (!this.form.controls.staff.value || !this.form.controls.staff.value.key) {
            this.form.controls.staff.setErrors({ required: true });
            this.form.controls.staff.markAsTouched();
            this.form.controls.staff.markAsDirty();
            this.staffEl.el.nativeElement.querySelector('input').click();

            return false;
        }
        this.form.controls.staff.setErrors(null);

        return true;
    }

    getDefaultWipFromCase(caseKey): any {
        this.service.getDefaultWipItems$(caseKey).subscribe(res => {
            if (res) {
                this.setDefaultItem(res);
                this.service.allDefaultWips.push(res);
            }
        });
    }

    setDefaultItem = (res: any) => {
        this.form.patchValue({
            name: { key: res.nameKey, code: res.nameCode, displayName: res.name },
            staff: { key: res.staffKey, code: res.staffCode, displayName: res.staffName }
        });
        this.calculateWip(null);
        this.cdRef.markForCheck();
    };

    onCaseChange = (value: any): void => {
        if (value && value.key) {
            const caseKey = value.key;
            of(caseKey).pipe(distinctUntilChanged(),
                switchMap((newCaseKey) => {

                    return this.warningChecker.performCaseWarningsCheck(newCaseKey, new Date());
                })
            ).subscribe((result: boolean) => this._handleCaseWarningsResult(result, caseKey));
        } else {
            this.clearCaseDefaultedFields();
        }
    };

    clearCaseDefaultedFields = (): void => {
        this.form.controls.name.setValue(null);
        this.form.controls.staff.setValue(null);
    };

    private readonly _handleCaseWarningsResult = (selected: boolean, caseKey: number): void => {
        if (!selected) {
            this.case.setValue(null);
        } else {
            const defaultWipForCase = _.filter(this.service.allDefaultWips, (wip: any) => {
                return wip.caseKey === caseKey;
            });
            if (defaultWipForCase.length > 0) {
                this.setDefaultItem(_.first(defaultWipForCase));
            } else {
                this.getDefaultWipFromCase(caseKey);
            }
        }
    };

    private readonly _handleNameWarningResult = (selected: boolean): void => {
        if (!selected) {
            this.form.patchValue({ name: null });
            this.form.controls.name.markAsPristine();
        } else {
            this.calculateWip(null);
        }
    };

    onNameChange = (value: any): void => {
        if (value && value.key) {
            this.caseNameMandatoryValidation();
            this.warningChecker.performNameWarningsCheck(value.key, value.value, new Date())
                .pipe(take(1))
                .subscribe((result: boolean) => this._handleNameWarningResult(result));
        }
    };

    onStaffChange = (value: any): void => {
        if (!value) {
            this.validateStaff();
        }
    };

    onNarrativeChange = (value: any): void => {
        if (value && value.text) {
            this.form.controls.debitNoteText.setValue(value.text);
        } else {
            this.form.controls.debitNoteText.setValue(null);
        }
    };

    disbursementsOnChange = (value: any): void => {
        if (value) {
            this.narrative.disable();
            const activityKey = value ? value.key : '';
            const entryCase = this.case.value;
            const entryDebtor = this.name.value;
            this.service.getDefaultNarrativeFromActivity(activityKey, !!entryCase ? entryCase.key : null, !!entryDebtor ? entryDebtor.key : null, this.staff.value ? this.staff.value.key : null)
                .subscribe((narrative: any) => {
                    this.narrative.setValue(narrative);
                    if (narrative && narrative.text) {
                        this.form.controls.debitNoteText.setValue(narrative.text);
                    }
                    this.narrative.enable();
                });
            this.calculateWip(null);
        }
    };

    clearAllCost = () => {
        this.form.patchValue({
            discount: null,
            localCost1: null,
            localCost2: null,
            margin: null,
            marginNo: null,
            amount: null,
            foreignDiscount: null,
            foreignMargin: null,
            foreignMarginDiscount: null,
            value: null,
            foreignValue: null
        });
        this.form.markAsPristine();
        this.form.controls.amount.setErrors(null);
        this.form.controls.foreignAmount.setErrors(null);
        this.cdRef.markForCheck();
    };

    getWipCost = (): void => {
        const wipCostParams = {
            entityKey: this.entityKey,
            transactionDate: this.transactionDate,
            nameKey: this.name.value ? this.name.value.key : null,
            caseKey: this.case.value ? this.case.value.key : null,
            staffKey: this.staff.value ? this.staff.value.key : null,
            wipCode: this.disbursement.value ? this.disbursement.value.key : null,
            isChargeGeneration: false,
            isServiceCharge: false,
            marginRequired: true,
            currencyCode: this.currency,
            foreignValueBeforeMargin: this.form.controls.foreignAmount.value,
            localValueBeforeMargin: this.form.controls.amount.value,
            LocalDecimalPlaces: 2
        };
        this.service.getDefaultWipCost$(wipCostParams).subscribe((response) => {
            if (response) {
                this.form.patchValue({
                    discount: response.localDiscount,
                    localCost1: response.costCalculation1,
                    localCost2: response.costCalculation2,
                    margin: response.marginValue,
                    marginNo: response.marginNo,
                    exchangeRate: response.exchangeRate,
                    value: response.localValue,
                    marginDiscount: response.localDiscountForMargin
                });
                if (this.currency) {
                    this.form.patchValue({
                        amount: response.localValueBeforeMargin,
                        foreignMargin: response.marginValue,
                        foreignDiscount: response.foreignDiscount,
                        margin: this.round(response.marginValue / response.exchangeRate),
                        marginNo: response.marginNo,
                        foreignMarginDiscount: response.foreignDiscountForMargin,
                        foreignValue: response.foreignValue
                    });
                }
                this.cdRef.markForCheck();
            }
        });
    };

    round = (num: number): number => {
        return Number(num.toFixed(2));
    };

    checkAmountValidation = () => {
        if (this.currency && !this.form.controls.foreignAmount.value) {
            this.form.controls.foreignAmount.markAsTouched();
            this.form.controls.foreignAmount.markAsDirty();
            this.form.controls.foreignAmount.setErrors({ required: true });

            return false;
        }
        if (!this.form.controls.amount.value) {
            this.form.controls.amount.markAsTouched();
            this.form.controls.amount.markAsDirty();
            this.form.controls.amount.setErrors({ required: true });

            return false;
        }

        return true;
    };

    checkDisbursementValidation = () => {
        if (!this.form.controls.disbursement.value) {
            this.form.controls.disbursement.markAsTouched();
            this.form.controls.disbursement.markAsDirty();
            this.form.controls.disbursement.setErrors({ required: true });

            return false;
        }

        return true;
    };

    apply = (): void => {
        if (this.form.invalid || !this.caseNameMandatoryValidation() || !this.validateStaff() || !this.checkDisbursementValidation() || !this.checkAmountValidation()) { return; }

        this.form.setErrors(null);
        this.onClose$.next({ success: true, formGroup: this.form });
        this.sbsModalRef.hide();
    };

    cancel = (): void => {
        if (this.form.dirty) {
            const modal = this.ipxNotificationService.openDiscardModal();
            modal.content.confirmed$.pipe(
                take(1))
                .subscribe(() => {
                    this.resetForm(true);
                });
        } else {
            this.resetForm(false);
        }
    };

    resetForm = (isDirty: boolean): void => {
        if (this.dataItem.status === rowStatus.Adding && this.isAdding) {
            this.grid.rowCancelHandler(this, this.rowIndex, this.form.value);
        }
        this.service.isAddAnotherChecked.next(false);
        this.form.reset();
        this.onClose$.next(isDirty);
        this.sbsModalRef.hide();
    };
}