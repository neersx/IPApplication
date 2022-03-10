import { AfterViewInit, ChangeDetectionStrategy, ChangeDetectorRef, Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FormBuilder, FormControl, FormGroup } from '@angular/forms';
import { ItemDateValidator } from 'accounting/item-date-validator';
import { CaseValidCombinationService } from 'portfolio/case/case-valid-combination.service'; import { distinctUntilChanged, startWith, tap } from 'rxjs/operators';
import { HeaderEntityType } from '../billing-maintenance/case-debtor.model';
import { BillingService } from '../billing-service';
import { BillingStepsPersistanceService } from '../billing-steps-persistance.service';
import { EntityOldNewValue } from '../billing.model';

@Component({
    selector: 'ipx-billing-header',
    templateUrl: './billing-header.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush,
    providers: [ItemDateValidator]
})

export class BillingHeaderComponent implements OnInit, AfterViewInit {
    defaultLanguage: string;
    defaultLanguageId: number;
    openItemData: any;
    formGroup: any;
    viewData: any;
    @Input() entities: any;
    @Output() readonly onFieldChange = new EventEmitter();
    isFinalised: boolean;
    oldNewAction: EntityOldNewValue;
    oldNewRenewalCheck: EntityOldNewValue;
    extendedActionQuery: any;
    validCombinationDescriptionsMap: any;
    initialFormDataForVC = { caseType: {}, jurisdiction: {}, propertyType: {}, openAction: {} };
    formDataForVC = { ...this.initialFormDataForVC };

    constructor(private readonly service: BillingService, private readonly fb: FormBuilder,
        private readonly cdRef: ChangeDetectorRef, private readonly itemDateValidator: ItemDateValidator,
        private readonly billingStepsService: BillingStepsPersistanceService,
        public cvs: CaseValidCombinationService) {
        this.validCombinationDescriptionsMap = this.cvs.validCombinationDescriptionsMap;
        this.extendedActionQuery = this.cvs.extendValidCombinationPickList;
    }

    ngOnInit(): void {
        this.cvs.initFormData(this.formDataForVC);

        this.service.openItemData$.pipe(
            distinctUntilChanged(),
            tap((openItem) => {
                this.openItemData = openItem;
                this.isFinalised = openItem.Status === 1;
            })
        ).subscribe(() => {
            if (this.openItemData) {
                this.createFormGroup();
                if (this.openItemData.OpenItemNo) {
                    this.defaultLanguage = this.openItemData.LanguageDescription;
                }
                this.formGroup.controls.itemDate.setValue(new Date(this.openItemData.ItemDate));
                this.initializeStepData();
                this.cdRef.markForCheck();
            }
        });

        this.service.currentAction$.pipe(
            distinctUntilChanged(), tap((formData) => {
                this.formDataForVC = formData ? formData : {};
            })
        ).subscribe(() => {
            this.cvs.initFormData(this.formDataForVC);
            if (this.formGroup) {
                const action = this.formDataForVC && this.formDataForVC.openAction ? this.formDataForVC.openAction : null;
                this.setOldNewAction(action, action);
                this.formGroup.controls.currentAction.setValue(action);
            }
            this.cdRef.markForCheck();
        });

        this.service.currentLanguage$.pipe(
            distinctUntilChanged(), tap((language) => {
                if (language) {
                    this.defaultLanguageId = language.id;
                    this.defaultLanguage = language.description;
                } else {
                    this.defaultLanguageId = null;
                    this.defaultLanguage = null;
                    this.formGroup.controls.currentAction.setValue(this.formDataForVC && this.formDataForVC.openAction ? this.formDataForVC.openAction : null);
                }
                this.cdRef.markForCheck();
            })).subscribe(() => {
                this.cdRef.markForCheck();
            });

        this.service.revertChanges$.pipe(
            distinctUntilChanged()).subscribe((res) => {
                if (res && this.formGroup) {
                    if (res.entity === HeaderEntityType.ActionPicklist) {
                        this.formGroup.controls.currentAction.setValue(res.oldValue, { emitEvent: false });
                    } else if (res.entity === HeaderEntityType.RenewalCheckBox) {
                        this.formGroup.controls.useRenewalDebtor.setValue(res.oldValue, { emitEvent: false });
                    }
                }
                this.cdRef.markForCheck();
            });

        this.formGroup.controls.itemDate.valueChanges.pipe(startWith(new Date(this.openItemData.ItemDate))).subscribe(value => {
            if (!this.isFinalised) {
                this.itemDateValidator.validateItemDate(value, 'billing/open-item', this.formGroup.controls.itemDate);
            }
        });

        this.formGroup.valueChanges.pipe(distinctUntilChanged()).subscribe(value => {
            if (value) {
                this.initializeStepData();
            }
        });
        this.formGroup.controls.entity.valueChanges.pipe(distinctUntilChanged())
            .subscribe(value => {
                this.service.entityChange$.next(value);
            });
    }

    ngAfterViewInit(): void {
        this.service.openItemData$.subscribe((res: any) => {
            if (res) {
                if (res.ItemEntityId) {
                    this.formGroup.controls.entity.setValue(res.ItemEntityId);
                    this.initializeStepData();
                    this.cdRef.markForCheck();
                }
            }
        });
    }

    initializeStepData = (): void => {
        const step1 = this.billingStepsService.getStepData(1).stepData;
        if (step1) {
            step1.itemDate = this.formGroup.controls.itemDate.value;
            step1.entity = this.formGroup.controls.entity.value;
            step1.raisedBy = this.formGroup.controls.raisedBy.value;
            step1.useRenewalDebtor = this.formGroup.controls.useRenewalDebtor.value;
            step1.currentAction = this.formGroup.controls.currentAction.value;
            step1.language = this.defaultLanguage;
            step1.languageId = this.defaultLanguageId;
        }
    };

    setOldNewAction = (newValue: any, oldValue?: any) => {
        if (!this.formGroup) { return; }
        this.oldNewAction = {
            entity: HeaderEntityType.ActionPicklist,
            oldValue: oldValue ? oldValue : null,
            value: newValue
        };
    };

    setOldNewRenewalCheck = (newValue, oldValue?: any) => {
        if (!this.formGroup) { return; }
        this.oldNewRenewalCheck = {
            entity: HeaderEntityType.RenewalCheckBox,
            oldValue: oldValue ? oldValue : false,
            value: newValue
        };
    };

    createFormGroup = (): FormGroup => {
        const renewalCheck = this.openItemData.IncludeOnlyWip === 'R';
        this.formGroup = this.fb.group({
            entity: new FormControl({ value: this.openItemData.ItemEntityId, disabled: this.isFinalised }),
            raisedBy: new FormControl({ value: { key: this.openItemData.StaffId, displayName: this.openItemData.StaffName }, disabled: this.isFinalised }),
            useRenewalDebtor: new FormControl({ value: renewalCheck, disabled: this.isFinalised }),
            currentAction: new FormControl({ value: null, disabled: this.isFinalised }),
            itemDate: new FormControl({ value: new Date(this.openItemData.ItemDate), disabled: this.isFinalised })
        });
        this.setOldNewRenewalCheck(renewalCheck);

        return this.formGroup;
    };

    validateItemDate = (date: any) => {
        if (!date) { return; }

        this.itemDateValidator.validateItemDate(date, 'billing/open-item', this.formGroup.controls.itemDate);
    };

    onActionChange(action): void {
        if (action && action.key) {
            this.setOldNewAction(action, this.oldNewAction.oldValue);
            this.onFieldChange.emit({ form: this.formGroup.value, values: this.oldNewAction });
        }
    }

    onRenewalDebtorChange(value): void {
        this.setOldNewRenewalCheck(value, !value);
        this.onFieldChange.emit({ form: this.formGroup.value, values: this.oldNewRenewalCheck });
    }
}